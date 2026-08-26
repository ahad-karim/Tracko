import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column; // Hide Drift's Column to avoid clashing with Flutter's UI Column
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../database/database.dart';
import '../providers/database_provider.dart';
import '../services/nlp_service.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  String _selectedType = 'expense';
  String _selectedCategory = 'food'; // Default category

  // A basic list of categories for the dropdown
  final List<String> _categories = ['food', 'transport', 'salary', 'utilities', 'other', 'movie'];

  // --- Voice & AI State Variables ---
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = '';
  final NLPService _nlpService = NLPService();

  @override
  void initState() {
    super.initState();
    // Initialize the microphone and load the AI brain
    _speech = stt.SpeechToText();
    _nlpService.initializeModel();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // --- Voice Logic ---
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
            _processVoiceCommand();
          }
        },
        onError: (errorNotification) => print('Error: $errorNotification'),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _spokenText = 'Listening... Speak now!'; // Initial prompt
        });
        _speech.listen(
          onResult: (result) => setState(() {
            _spokenText = result.recognizedWords; // Updates UI live as you speak!
          }),
        );
      }
    } else {
      // Manual stop
      setState(() => _isListening = false);
      _speech.stop();
      _processVoiceCommand();
    }
  }

  Future<void> _processVoiceCommand() async {
    if (_spokenText.isEmpty || _spokenText.startsWith('Listening')) return;

    try {
      print("====================================");
      print("🎤 HEARD: $_spokenText");

      // 1. Get Category from AI Model
      final category = _nlpService.classifyTransaction(_spokenText);
      print("🧠 PREDICTED CATEGORY: $category");

      // 2. Extract the amount
      final numberMatch = RegExp(r'\d+').firstMatch(_spokenText);
      final amount = numberMatch != null ? double.parse(numberMatch.group(0)!) : 0.0;
      print("💰 EXTRACTED AMOUNT: $amount");
      print("====================================");

      // 3. Update local state variables first
      setState(() {
        _amountController.text = amount.toString();
        _selectedCategory = _categories.contains(category) ? category : 'other';
        _selectedType = category == 'salary' ? 'income' : 'expense';
      });

      // 4. Await the database insert completely BEFORE touching navigation
      final db = ref.read(databaseProvider);
      final newTransaction = TransactionsCompanion(
        amount: Value(amount),
        type: Value(_selectedType),
        category: Value(_selectedCategory),
        date: Value(_selectedDate),
      );

      await db.insertTransaction(newTransaction);

      // 5. Safely check if the screen is still open before popping
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print("❌ CRASH PREVENTED IN VOICE COMMAND: $e");
      print(stackTrace);

      // Reset UI state so it doesn't stay stuck
      if (mounted) {
        setState(() {
          _spokenText = 'Error processing speech. Try again.';
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final db = ref.read(databaseProvider);
      final parsedAmount = double.parse(_amountController.text);

      final newTransaction = TransactionsCompanion(
        amount: Value(parsedAmount),
        type: Value(_selectedType),
        category: Value(_selectedCategory),
        date: Value(_selectedDate),
      );

      await db.insertTransaction(newTransaction);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Live Speech Display Card ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _spokenText.isEmpty ? 'Tap the mic and speak your transaction...' : _spokenText,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Visual indicator for type
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      _selectedType == 'expense'
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 40,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '\$ ',
                    labelText: 'Amount',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter an amount';
                    if (double.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Type Toggle
                const Text("Transaction Type", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Expense'),
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text('Income'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.substring(0, 1).toUpperCase() + category.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                ),
                const SizedBox(height: 24),

                // Date Picker field
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Save Button
                FilledButton.icon(
                  onPressed: _saveTransaction,
                  icon: const Icon(Icons.check),
                  label: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // --- Microphone Button ---
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        backgroundColor: _isListening ? Colors.red : colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
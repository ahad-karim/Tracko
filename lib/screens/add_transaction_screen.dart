import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column; // Hide Drift's Column to avoid clashing with Flutter's UI Column
import '../database/database.dart';
import '../providers/database_provider.dart';

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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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

      // Create the Companion object for the insert
      final newTransaction = TransactionsCompanion(
        amount: Value(parsedAmount),
        type: Value(_selectedType),
        category: Value(_selectedCategory),
        date: Value(_selectedDate),
      );

      // Insert it into Drift
      await db.insertTransaction(newTransaction);

      // Pop the screen off the navigation stack to go back to the dashboard
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
    );
  }
}

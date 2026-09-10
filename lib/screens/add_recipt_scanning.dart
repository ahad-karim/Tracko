import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/database.dart';
import '../providers/database_provider.dart';

class ReceiptScanningScreen extends ConsumerStatefulWidget {
  const ReceiptScanningScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReceiptScanningScreen> createState() =>
      _ReceiptScanningScreenState();
}

class _ReceiptScanningScreenState extends ConsumerState<ReceiptScanningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  File? _image;
  bool _scanning = false;
  DateTime _date = DateTime.now();
  String _type = 'expense';
  String _category = 'food';

  final categories = [
    'food',
    'transport',
    'salary',
    'utilities',
    'other',
    'movie',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _recognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);

    if (picked == null) return;

    setState(() => _image = File(picked.path));
    await _scanReceipt();
  }

  Future<void> _scanReceipt() async {
    if (_image == null) return;

    setState(() => _scanning = true);

    try {
      final input = InputImage.fromFile(_image!);
      final result = await _recognizer.processImage(input);

      final amount = _extractAmount(result.text);
      final date = _extractDate(result.text);

      setState(() {
        if (amount != null) {
          _amountController.text = amount.toStringAsFixed(2);
        }
        if (date != null) _date = date;
      });

      if (amount == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Total not found. Enter amount manually.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  double? _extractAmount(String text) {
    final lines = text.split('\n');
    final number = RegExp(r'(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})');
    final keywords = RegExp(
      r'(total|amount due|grand total|balance due|amount paid)',
      caseSensitive: false,
    );

    double? largest;

    for (final line in lines) {
      final matches = number.allMatches(line);
      if (matches.isEmpty) continue;

      final raw = matches.last.group(1)!.replaceAll(',', '.');
      final value = double.tryParse(_normalize(raw));
      if (value == null) continue;

      if (keywords.hasMatch(line)) return value;
      if (largest == null || value > largest) largest = value;
    }

    return largest;
  }

  String _normalize(String value) {
    final parts = value.split(RegExp(r'[.,]'));

    if (parts.length <= 2) {
      return value.replaceAll(',', '.');
    }

    final decimal = parts.removeLast();
    return '${parts.join()}.$decimal';
  }

  DateTime? _extractDate(String text) {
    final patterns = [
      RegExp(r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})\b'),
      RegExp(r'\b(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      try {
        if (match.group(1)!.length == 4) {
          return DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
          );
        }

        var year = int.parse(match.group(3)!);
        if (year < 100) year += 2000;

        return DateTime(
          year,
          int.parse(match.group(2)!),
          int.parse(match.group(1)!),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> _save() async {
    if (_image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scan a receipt first')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final db = ref.read(databaseProvider);

    await db.insertTransaction(
      TransactionsCompanion(
        amount: Value(amount),
        type: Value(_type),
        category: Value(_category),
        date: Value(_date),
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _imagePreview(colors),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '\$ ',
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Transaction Type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
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
                selected: {_type},
                onSelectionChanged: (value) {
                  setState(() => _type = value.first);
                },
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items:
                    categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category[0].toUpperCase() + category.substring(1),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => _pickDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('${_date.day}/${_date.month}/${_date.year}'),
                ),
              ),
              const SizedBox(height: 45),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePreview(ColorScheme colors) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          _scanning
              ? const Center(child: CircularProgressIndicator())
              : _image == null
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No receipt scanned yet',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              )
              : Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) setState(() => _date = picked);
  }
}

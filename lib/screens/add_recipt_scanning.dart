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
  ConsumerState<ReceiptScanningScreen> createState() => _State();
}

class _State extends ConsumerState<ReceiptScanningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final categories = ['food', 'transport', 'salary', 'utilities', 'other', 'movie'];
  final _totalRe = RegExp(r'(total|amount due|grand total|balance due|amount paid)', caseSensitive: false);
  final _numRe = RegExp(r'(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})');
  final _dateRes = [RegExp(r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})\b'), RegExp(r'\b(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\b')];
  File? _image; bool _scanning = false; DateTime _date = DateTime.now(); String _type = 'expense', _category = 'food';

  @override
  void dispose() { _amountCtrl.dispose(); _recognizer.close(); super.dispose(); }

  Future<void> _pickImage(ImageSource src) async {
    final picked = await _picker.pickImage(source: src, imageQuality: 85);
    if (picked == null) return;
    setState(() => _image = File(picked.path));
    await _scanReceipt();
  }

  Future<void> _scanReceipt() async {
    if (_image == null) return;
    setState(() => _scanning = true);
    try {
      final result = await _recognizer.processImage(InputImage.fromFile(_image!));
      final amount = _extractAmount(result.text), date = _extractDate(result.text);
      setState(() { if (amount != null) _amountCtrl.text = amount.toStringAsFixed(2); if (date != null) _date = date; });
      if (amount == null && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Total not found. Enter amount manually.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  double? _extractAmount(String text) {
    double? largest;
    for (final line in text.split('\n')) {
      final m = _numRe.allMatches(line);
      if (m.isEmpty) continue;
      final value = double.tryParse(_normalize(m.last.group(1)!.replaceAll(',', '.')));
      if (value == null) continue;
      if (_totalRe.hasMatch(line)) return value;
      if (largest == null || value > largest) largest = value;
    }
    return largest;
  }

  String _normalize(String v) {
    final parts = v.split(RegExp(r'[.,]'));
    if (parts.length <= 2) return v.replaceAll(',', '.');
    final dec = parts.removeLast();
    return '${parts.join()}.$dec';
  }

  DateTime? _extractDate(String text) {
    for (final p in _dateRes) {
      final m = p.firstMatch(text);
      if (m == null) continue;
      try {
        if (m.group(1)!.length == 4) return DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
        var year = int.parse(m.group(3)!);
        if (year < 100) year += 2000;
        return DateTime(year, int.parse(m.group(2)!), int.parse(m.group(1)!));
      } catch (_) {}
    }
    return null;
  }

  Future<void> _save() async {
    if (_image == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan a receipt first'))); return; }
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text);
    await ref.read(databaseProvider).insertTransaction(TransactionsCompanion(amount: Value(amount), type: Value(_type), category: Value(_category), date: Value(_date)));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2101));
    if (picked != null) setState(() => _date = picked);
  }

  Widget _preview(ColorScheme c) => Container(height: 220, decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(16)), clipBehavior: Clip.antiAlias,
    child: _scanning ? const Center(child: CircularProgressIndicator()) : _image == null
      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.receipt_long_outlined, size: 48, color: c.onSurfaceVariant), const SizedBox(height: 8), Text('No receipt scanned yet', style: TextStyle(color: c.onSurfaceVariant))]))
      : Image.file(_image!, fit: BoxFit.cover, width: double.infinity));

  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)));

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(appBar: AppBar(title: const Text('Scan Receipt'), centerTitle: true),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _preview(colors), const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Camera'))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery'))),
        ]),
        const SizedBox(height: 30),
        TextFormField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          decoration: InputDecoration(hintText: '0.00', prefixText: '\$ ', labelText: 'Amount', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter an amount' : (double.tryParse(v) == null ? 'Enter a valid number' : null)),
        const SizedBox(height: 24),
        const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)), ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.add_circle_outline))],
          selected: {_type}, onSelectionChanged: (v) => setState(() => _type = v.first)),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(value: _category, decoration: _dec('Category', Icons.category_outlined),
          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
          onChanged: (v) { if (v != null) setState(() => _category = v); }),
        const SizedBox(height: 24),
        InkWell(onTap: _pickDate, child: InputDecorator(decoration: _dec('Date', Icons.calendar_today_outlined), child: Text('${_date.day}/${_date.month}/${_date.year}'))),
        const SizedBox(height: 45),
        FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Save Transaction')),
      ]))),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/database.dart';
import '../providers/database_provider.dart';

class ReceiveVoiceInputScreen extends ConsumerStatefulWidget {
  const ReceiveVoiceInputScreen({super.key});
  @override
  ConsumerState<ReceiveVoiceInputScreen> createState() => _State();
}

class _State extends ConsumerState<ReceiveVoiceInputScreen>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  bool _avail = false, _listening = false;
  String _transcript = '', _type = 'expense', _cat = 'food';
  DateTime _date = DateTime.now();
  late AnimationController _pulse;
  late Animation<double> _anim;

  static const _cats = [
    'food',
    'transport',
    'salary',
    'utilities',
    'other',
    'movie',
  ];
  static const _catKw = {
    'food': [
      'food',
      'lunch',
      'dinner',
      'breakfast',
      'meal',
      'groceries',
      'restaurant',
      'coffee',
      'snack',
    ],
    'transport': [
      'transport',
      'uber',
      'taxi',
      'bus',
      'train',
      'fuel',
      'petrol',
      'gas',
      'ride',
      'car',
    ],
    'salary': ['salary', 'paycheck', 'wage', 'payroll'],
    'utilities': [
      'utility',
      'utilities',
      'electricity',
      'water',
      'internet',
      'wifi',
      'phone',
      'bill',
    ],
    'movie': ['movie', 'cinema', 'film', 'netflix', 'streaming', 'ticket'],
    'other': ['other', 'misc'],
  };
  static final _numRe = RegExp(r'\b(\d+(?:\.\d{1,2})?)\b');

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween(
      begin: 1.0,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _speech
        .initialize(
          onStatus: (s) {
            if (s == 'done' || s == 'notListening') {
              if (mounted) setState(() => _listening = false);
              _pulse.stop();
              _pulse.reset();
            }
          },
          onError: (e) {
            if (mounted) {
              setState(() => _listening = false);
              _pulse.stop();
              _pulse.reset();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: ${e.errorMsg}')));
            }
          },
        )
        .then((ok) {
          if (mounted) setState(() => _avail = ok);
        });
  }

  @override
  void dispose() {
    _speech.stop();
    _amountCtrl.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_avail) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mic unavailable')));
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      _pulse.stop();
      _pulse.reset();
      _parse(_transcript);
    } else {
      setState(() {
        _listening = true;
        _transcript = '';
      });
      _pulse.repeat(reverse: true);
      await _speech.listen(
        onResult: (r) {
          setState(() => _transcript = r.recognizedWords);
          if (r.finalResult) _parse(r.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          localeId: 'en_US',
          listenMode: ListenMode.dictation,
        ),
      );
    }
  }

  void _parse(String text) {
    if (text.isEmpty) return;
    final lo = text.toLowerCase();
    final m = _numRe.firstMatch(lo.replaceAll(',', ''));
    if (m != null)
      _amountCtrl.text = double.parse(m.group(1)!).toStringAsFixed(2);
    if (RegExp(r'\b(income|earned|received|got paid)\b').hasMatch(lo))
      _type = 'income';
    else if (RegExp(r'\b(spent|expense|paid|bought|cost)\b').hasMatch(lo))
      _type = 'expense';
    for (final e in _catKw.entries) {
      if (e.value.any(lo.contains)) {
        _cat = e.key;
        break;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(databaseProvider)
        .insertTransaction(
          TransactionsCompanion(
            amount: Value(double.parse(_amountCtrl.text)),
            type: Value(_type),
            category: Value(_cat),
            date: Value(_date),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  InputDecoration _dec(String l, IconData i) => InputDecoration(
    labelText: l,
    prefixIcon: Icon(i),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Input'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _anim,
                  builder:
                      (_, ch) => Transform.scale(
                        scale: _listening ? _anim.value : 1.0,
                        child: ch,
                      ),
                  child: GestureDetector(
                    onTap: _toggle,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor:
                          _listening ? c.errorContainer : c.primaryContainer,
                      child: Icon(
                        _listening ? Icons.mic : Icons.mic_none_outlined,
                        size: 48,
                        color:
                            _listening
                                ? c.onErrorContainer
                                : c.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _listening
                      ? 'Listening… tap to stop'
                      : _avail
                      ? 'Tap the mic to speak'
                      : 'Mic unavailable',
                  style: TextStyle(color: c.onSurfaceVariant),
                ),
              ),
              if (_transcript.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '"$_transcript"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
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
                  prefixText: r'$ ',
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? 'Enter an amount'
                            : double.tryParse(v) == null
                            ? 'Invalid number'
                            : null,
              ),
              const SizedBox(height: 20),
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
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _cat,
                decoration: _dec('Category', Icons.category_outlined),
                items:
                    _cats
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s[0].toUpperCase() + s.substring(1)),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _cat = v);
                },
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (p != null) setState(() => _date = p);
                },
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _dec('Date', Icons.calendar_today_outlined),
                  child: Text('${_date.day}/${_date.month}/${_date.year}'),
                ),
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text(
                  'Save Transaction',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

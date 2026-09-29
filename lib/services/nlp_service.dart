import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class NLPService {
  Interpreter? _interpreter;


  final List<String> _vocab = [
    '', '[UNK]', 'taka', 'i', 'on', 'for', 'just', 'it', 'cost', 'paid',
    'spent', 'bought', 'a', 'got', 'an', 'cleared', 'salary', 'bill',
    'movie', 'tickets', 'ticket', 'ordered', 'from', 'took', 'earned',
    'received', 'purchased', 'made', 'ate', 'at', 'grabbed', 'film',
    'paycheck', 'cash', 'shopping', 'domain', 'cloudns', 'the', 'electric',
    'daraz', 'tutoring', 'spotify', 'plan', 'my', 'family', 'watch', 'strap',
    'new', 'electricity', 'water', 'internet', 'clothes', 'wifi', 'netflix',
    'cinema', 'bonus', 'taxi', 'uber', 'pathao', 'theatre', 'plectrums',
    'guitar', 'rickshaw', 'money', 'freelance', 'bus', 'cng', 'ride', 'dinner',
    'unique', 'flavours', 'gyro', 'bhai', 'lunch', 'coffee', 'shawarma',
    'burgers', 'japanese', 'food', 'pizza', 'burger', 'snacks'
  ];

  final List<String> _categories = [
    'food', 'transport', 'salary', 'utilities', 'movie', 'other'
  ];


  Future<void> initializeModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print('NLP Model loaded successfully!');
    } catch (e) {
      print('Failed to load NLP model: $e');
    }
  }


  List<int> _vectorizeText(String text) {
    final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
    List<int> vector = [];

    for (var word in words) {
      int index = _vocab.indexOf(word);
      vector.add(index != -1 ? index : 1);
    }


    if (vector.length < 15) {
      vector.addAll(List.filled(15 - vector.length, 0));
    } else {
      vector = vector.sublist(0, 15);
    }

    return vector;
  }


  String classifyTransaction(String text) {
    if (_interpreter == null) {
      return 'other';
    }


    final inputVector = [_vectorizeText(text)];


    final output = List.filled(1, List.filled(6, 0.0));


    _interpreter!.run(inputVector, output);


    final probabilities = output[0];
    double maxProbability = 0.0;
    int highestIndex = 0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProbability) {
        maxProbability = probabilities[i];
        highestIndex = i;
      }
    }

    return _categories[highestIndex];
  }

  void dispose() {
    _interpreter?.close();
  }
}
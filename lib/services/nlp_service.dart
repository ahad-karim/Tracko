import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class NLPService {
  Interpreter? _interpreter;

  // The exact vocabulary mapped from your Python training script
  final List<String> _vocab = [
    '', '[UNK]', 'taka', 'i', 'on', 'for', 'just', 'it', 'cost', 'paid',
    'spent', 'bought', 'a', 'tickets', 'an', 'got', 'bill', 'cinema',
    'cleared', 'film', 'movie', 'took', 'tutoring', 'salary', 'my',
    'domain', 'cloudns', 'received', 'internet', 'rickshaw', 'ordered',
    'from', 'ticket', 'bus', 'purchased', 'paycheck', 'money', 'freelance',
    'uber', 'ride', 'water', 'earned', 'the', 'made', 'electric', 'daraz',
    'cash', 'ate', 'at', 'plectrums', 'guitar', 'spotify', 'plan',
    'family', 'watch', 'strap', 'new', 'unique', 'flavours', 'grabbed',
    'clothes', 'lunch', 'japanese', 'food', 'burger', 'shawarma', 'gyro', 'bhai'
  ];

  final List<String> _categories = [
    'food', 'transport', 'salary', 'utilities', 'movie', 'other'
  ];

  /// Loads the TFLite model from assets
  Future<void> initializeModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print('NLP Model loaded successfully!');
    } catch (e) {
      print('Failed to load NLP model: $e');
    }
  }

  /// Converts a raw string into an array of integer IDs based on our vocabulary
  List<int> _vectorizeText(String text) {
    final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
    List<int> vector = [];

    for (var word in words) {
      int index = _vocab.indexOf(word);
      vector.add(index != -1 ? index : 1); // 1 is our [UNK] token
    }

    // Pad or truncate to match the 15-length sequence expected by the model
    if (vector.length < 15) {
      vector.addAll(List.filled(15 - vector.length, 0));
    } else {
      vector = vector.sublist(0, 15);
    }

    return vector;
  }

  /// Takes a spoken sentence and returns the predicted category
  String classifyTransaction(String text) {
    if (_interpreter == null) {
      return 'other';
    }

    // 1. Convert text to the integer tensor format the model expects
    final inputVector = [_vectorizeText(text)];

    // 2. Prepare the output buffer (1 row, 6 probabilities)
    final output = List.filled(1, List.filled(6, 0.0));

    // 3. Run inference with integer numbers instead of strings
    _interpreter!.run(inputVector, output);

    // 4. Find the highest probability index
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
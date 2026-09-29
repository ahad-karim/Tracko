import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  // Use String.fromEnvironment or replace with your actual API key.
  static const String apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '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');
  static const String baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<Map<String, dynamic>?> extractTransactionFromImage(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "qwen/qwen3.8-27b",
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": "Extract the expense details from this receipt image. Return a JSON object strictly containing: 'title' (string, name of merchant/item), 'amount' (number, total amount without currency symbol), and 'category' (string, choose strictly one from: Food, Transport, Utilities, Movie, Other)."
                },
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image"
                  }
                }
              ]
            }
          ],
          "temperature": 0.1,
          "response_format": {"type": "json_object"}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String contentStr = data['choices'][0]['message']['content'];
        if (contentStr.contains('```json')) {
          contentStr = contentStr.split('```json')[1].split('```')[0];
        } else if (contentStr.contains('```')) {
          contentStr = contentStr.split('```')[1].split('```')[0];
        }
        final extractedJson = jsonDecode(contentStr.trim());
        return extractedJson;
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in GroqService: $e');
      return null;
    }
  }
}

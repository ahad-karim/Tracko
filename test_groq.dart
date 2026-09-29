import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // 32x32 red pixel PNG in base64
  final base64Image = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAWElEQVRYw+3RwQkAAAgDQLv/0L0UimB/L2Yc76pSAAAAABJRU5ErkJggg==";
  final apiKey = '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';
  final baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  print('Sending request...');
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
                "url": "data:image/png;base64,$base64Image"
              }
            }
          ]
        }
      ],
      "temperature": 0.1,
      "response_format": {"type": "json_object"}
    }),
  );

  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}

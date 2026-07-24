import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<bool> guardarTasas(String json) async {
    final response = await http.post(
      Uri.parse('/api/save'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contenido': json,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }

    print(response.body);
    return false;
  }
}

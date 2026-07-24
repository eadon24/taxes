import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<bool> guardarTasas(String json) async {
    final response = await http.post(
      Uri.parse('https://taxes-ten.vercel.app/api/save'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contenido': json,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return response.statusCode == 200;
  }
}

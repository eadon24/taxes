import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tasa.dart';

class JsonService {
  Future<Map<String, dynamic>> cargarDatos() async {
    final response = await http.get(Uri.parse('/tasas.json'));

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar tasas.json');
    }

    final data = jsonDecode(response.body);

    return {
      'fecha': data['fecha'],
      'bcv': (data['bcv'] as num).toDouble(),
      'tasas': (data['tasas'] as List).map((e) => Tasa.fromJson(e)).toList(),
    };
  }

  String generarJson({
    required String fecha,
    required double bcv,
    required List<Tasa> tasas,
  }) {
    final mapa = {
      'fecha': fecha,
      'bcv': bcv,
      'tasas': tasas.map((e) => e.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(mapa);
  }
}

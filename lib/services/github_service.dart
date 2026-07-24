import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubService {
  static const owner = "eadon24";
  static const repo = "taxes";
  static const branch = "main";

  // IMPORTANTE:
  // El token ya no debe estar aquí.
  // Más adelante lo moveremos a un backend seguro.
  static const token = "";

  Future<bool> subirArchivo({
    required String ruta,
    required String contenido,
  }) async {
    if (token.isEmpty) {
      throw Exception(
        "No hay token configurado. El token se moverá al backend por seguridad.",
      );
    }

    final url = Uri.parse(
      "https://api.github.com/repos/$owner/$repo/contents/$ruta",
    );

    final get = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/vnd.github+json",
      },
    );

    if (get.statusCode != 200) {
      print(get.body);
      return false;
    }

    final sha = jsonDecode(get.body)["sha"];

    final put = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/vnd.github+json",
      },
      body: jsonEncode({
        "message": "Actualización automática de tasas",
        "content": base64Encode(utf8.encode(contenido)),
        "sha": sha,
        "branch": branch,
      }),
    );

    print(put.body);

    return put.statusCode == 200 || put.statusCode == 201;
  }

  Future<bool> guardarTasas(String json) async {
    final ok1 = await subirArchivo(
      ruta: "web/tasas.json",
      contenido: json,
    );

    final ok2 = await subirArchivo(
      ruta: "build/web/tasas.json",
      contenido: json,
    );

    return ok1 && ok2;
  }
}

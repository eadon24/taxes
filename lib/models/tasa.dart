class Tasa {
  String pais;
  double tasa;
  String modo;
  String bandera;
  String tipo;

  Tasa({
    required this.pais,
    required this.tasa,
    required this.modo,
    required this.bandera,
    required this.tipo,
  });

  factory Tasa.fromJson(Map<String, dynamic> json) {
    return Tasa(
      pais: json['pais'],
      tasa: (json['tasa'] as num).toDouble(),
      modo: json['modo'],
      bandera: json['bandera'],
      tipo: json['tipo'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pais': pais,
      'tasa': tasa,
      'modo': modo,
      'bandera': bandera,
      'tipo': tipo,
    };
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ExchangeCalculator extends StatefulWidget {
  const ExchangeCalculator({super.key});

  @override
  _ExchangeCalculatorState createState() => _ExchangeCalculatorState();
}

class _ExchangeCalculatorState extends State<ExchangeCalculator> {
  final TextEditingController _solesController = TextEditingController();
  final TextEditingController _bolivaresController = TextEditingController();
  final TextEditingController _dollarBCVController = TextEditingController();

  List<Map<String, dynamic>> tasasPorPais = [];

  double dollarBCVRate = 0.0;
  int selectedIndex = 0;

  String updateText = '';
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarTasas();
  }

  Future<void> cargarTasas() async {
    try {
      final response = await http.get(
        Uri.parse('/tasas.json'),
      );

      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          updateText = "Actualización ${data['fecha']}";
          dollarBCVRate = (data['bcv'] as num).toDouble();
          tasasPorPais = List<Map<String, dynamic>>.from(data['tasas']);
          cargando = false;
        });
      } else {
        setState(() {
          cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando JSON: $e");

      setState(() {
        cargando = false;
      });
    }
  }

  void _updateFields({String source = ''}) {
    double soles = double.tryParse(_solesController.text) ?? 0.0;
    double bolivares = double.tryParse(_bolivaresController.text) ?? 0.0;
    double dollarsBCV = double.tryParse(_dollarBCVController.text) ?? 0.0;

    final tasaInfo = tasasPorPais[selectedIndex];
    double exchangeRate = tasaInfo['tasa'];
    bool esDivision = tasaInfo['modo'] == 'dividir';

    if (source == 'soles') {
      bolivares = esDivision ? soles / exchangeRate : soles * exchangeRate;
      dollarsBCV = bolivares / dollarBCVRate;
    } else if (source == 'bolivares') {
      soles = esDivision ? bolivares * exchangeRate : bolivares / exchangeRate;
      dollarsBCV = bolivares / dollarBCVRate;
    } else if (source == 'dollarBCV') {
      bolivares = dollarsBCV * dollarBCVRate;
      soles = esDivision ? bolivares * exchangeRate : bolivares / exchangeRate;
    }

    setState(() {
      if (source != 'soles') _solesController.text = soles.toStringAsFixed(2);
      if (source != 'bolivares') {
        _bolivaresController.text = bolivares.toStringAsFixed(2);
      }
      if (source != 'dollarBCV') {
        _dollarBCVController.text = dollarsBCV.toStringAsFixed(2);
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texto copiado al portapapeles')),
    );
  }

  void _resetFields() {
    _solesController.clear();
    _bolivaresController.clear();
    _dollarBCVController.clear();
  }

  void _copyAllValues() {
    double tasa = tasasPorPais[selectedIndex]['tasa'];
    String pais = tasasPorPais[selectedIndex]['pais'];
    String bandera = tasasPorPais[selectedIndex]['bandera'];

    String allValues = "Calculadora EADON\n"
        "$updateText\n"
        "País seleccionado: $bandera $pais\n"
        "Cantidad enviada: ${_solesController.text}\n"
        "Tasa: $tasa Bs.\n"
        "Cantidad en Bs. a recibir: ${_bolivaresController.text}\n"
        "Dólares (BCV): ${_dollarBCVController.text} - Tasa BCV: $dollarBCVRate Bs.";

    Clipboard.setData(ClipboardData(text: allValues));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Montos copiados al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasasPorPais.isEmpty) {
      return const Center(
        child: Text(
          'No se pudieron cargar las tasas',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    double exchangeRate = tasasPorPais[selectedIndex]['tasa'];
    String pais = tasasPorPais[selectedIndex]['pais'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            updateText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
        DropdownButton<int>(
          value: selectedIndex,
          isExpanded: true,
          items: List.generate(tasasPorPais.length, (index) {
            final item = tasasPorPais[index];
            return DropdownMenuItem<int>(
              value: index,
              child: Text(
                "${item['bandera']} ${item['pais']} - ${item['tasa']} Bs",
              ),
            );
          }),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedIndex = value;
                _updateFields();
              });
            }
          },
        ),
        TextField(
          controller: _solesController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Tasa $exchangeRate Bs - Monto a Enviar ($pais)',
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () => _copyToClipboard(_solesController.text),
            ),
          ),
          onChanged: (value) => _updateFields(source: 'soles'),
        ),
        TextField(
          controller: _bolivaresController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Cantidad en Bs. a Recibir',
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () => _copyToClipboard(_bolivaresController.text),
            ),
          ),
          onChanged: (value) => _updateFields(source: 'bolivares'),
        ),
        TextField(
          controller: _dollarBCVController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Dólar (BCV) - $dollarBCVRate Bs',
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () => _copyToClipboard(_dollarBCVController.text),
            ),
          ),
          onChanged: (value) => _updateFields(source: 'dollarBCV'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _resetFields,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF685FEE),
          ),
          child: const Text(
            'Reiniciar',
            style: TextStyle(
              color: Color.fromARGB(255, 246, 244, 244),
              fontSize: 16.0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _copyAllValues,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF121212),
          ),
          child: const Text(
            'Copiar Todos los Montos',
            style: TextStyle(color: Colors.white, fontSize: 16.0),
          ),
        ),
      ],
    );
  }
}

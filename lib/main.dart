import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200.0),
          child: AppBar(
            backgroundColor: const Color.fromARGB(255, 14, 14, 14),
            flexibleSpace: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Flexible(child: Image.asset('assets/logo.png', scale: 2)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              ),
            ],
          ),
        ),
        body: Container(
          color: Colors.white.withOpacity(0.95),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Actualización 17-07-2025',
                  style: TextStyle(
                    color: Color.fromARGB(255, 8, 8, 8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                CalculatorContainer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CalculatorContainer extends StatelessWidget {
  const CalculatorContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Calculadora E-ADON',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          ExchangeCalculator(),
        ],
      ),
    );
  }
}

class ExchangeCalculator extends StatefulWidget {
  const ExchangeCalculator({super.key});

  @override
  _ExchangeCalculatorState createState() => _ExchangeCalculatorState();
}

class _ExchangeCalculatorState extends State<ExchangeCalculator> {
  final TextEditingController _solesController = TextEditingController();
  final TextEditingController _bolivaresController = TextEditingController();
  final TextEditingController _dollarBCVController = TextEditingController();

  double exchangeRate = 40.50; // Tasa de cambio soles a bolívares
  double dollarBCVRate = 117.40; // Tasa de cambio bolívares a dólares BCV
  String updateText = 'Actualización 17-07-2025';

  void _updateFields({String source = ''}) {
    double soles = double.tryParse(_solesController.text) ?? 0.0;
    double bolivares = double.tryParse(_bolivaresController.text) ?? 0.0;
    double dollarsBCV = double.tryParse(_dollarBCVController.text) ?? 0.0;

    if (source == 'soles') {
      bolivares = soles * exchangeRate;
      dollarsBCV = bolivares / dollarBCVRate;
    } else if (source == 'bolivares') {
      soles = bolivares / exchangeRate;
      dollarsBCV = bolivares / dollarBCVRate;
    } else if (source == 'dollarBCV') {
      bolivares = dollarsBCV * dollarBCVRate;
      soles = bolivares / exchangeRate;
    }

    setState(() {
      if (source != 'soles') _solesController.text = soles.toStringAsFixed(2);
      if (source != 'bolivares')
        _bolivaresController.text = bolivares.toStringAsFixed(2);
      if (source != 'dollarBCV')
        _dollarBCVController.text = dollarsBCV.toStringAsFixed(2);
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
    String allValues = """
Calculadora EADON
$updateText
Cantidad en Soles: ${_solesController.text} - Tasa: $exchangeRate Bs.
Cantidad en Bs. a Recibir: ${_bolivaresController.text}
Dólares (BCV): ${_dollarBCVController.text} - Tasa: $dollarBCVRate Bs.
""";
    Clipboard.setData(ClipboardData(text: allValues));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Montos copiados al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _solesController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Tasa $exchangeRate Bs - Soles a Enviar',
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

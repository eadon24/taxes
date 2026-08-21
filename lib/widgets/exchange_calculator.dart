import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ExchangeCalculator extends StatefulWidget {
  const ExchangeCalculator({super.key});

  @override
  State<ExchangeCalculator> createState() => _ExchangeCalculatorState();
}

class _ExchangeCalculatorState extends State<ExchangeCalculator> {
  final TextEditingController _solesController = TextEditingController();
  final TextEditingController _bolivaresController = TextEditingController();
  final TextEditingController _dollarBCVController = TextEditingController();

  List<Map<String, dynamic>> tasasPorPais = [];

  double dollarBCVRate = 0.0;

  String selectedPais = '';
  String updateText = '';

  String categoriaPeru = 'regular';
  double tasaActual = 0.0;

  String mensajeMejora = '';
  String mensajeProximoNivel = '';

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarTasas();
  }

  @override
  void dispose() {
    _solesController.dispose();
    _bolivaresController.dispose();
    _dollarBCVController.dispose();
    super.dispose();
  }

  // ==========================================================
  // CARGAR TASAS
  // ==========================================================

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

          final paises = _obtenerPaises();

          if (paises.isNotEmpty) {
            selectedPais = paises.first;
          }

          _actualizarTasaInicial();

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

  // ==========================================================
  // OBTENER PAÍSES SIN DUPLICADOS
  // ==========================================================

  List<String> _obtenerPaises() {
    final Set<String> paises = {};

    for (final tasa in tasasPorPais) {
      paises.add(tasa['pais'].toString());
    }

    return paises.toList();
  }

  // ==========================================================
  // SABER SI ES PERÚ
  // ==========================================================

  bool _esPeru() {
    return selectedPais == 'Perú';
  }

  // ==========================================================
  // OBTENER TASA DE PERÚ
  // ==========================================================

  double _obtenerTasaPeru(String tipo) {
    final resultados = tasasPorPais.where((tasa) {
      return tasa['pais'] == 'Perú' && tasa['tipo'] == tipo;
    }).toList();

    if (resultados.isNotEmpty) {
      return (resultados.first['tasa'] as num).toDouble();
    }

    // Compatibilidad con JSON anteriores.
    if (tipo == 'regular') {
      final peru = tasasPorPais.where((tasa) {
        return tasa['pais'] == 'Perú';
      }).toList();

      if (peru.isNotEmpty) {
        return (peru.first['tasa'] as num).toDouble();
      }
    }

    return 0.0;
  }

  // ==========================================================
  // OBTENER TASA NORMAL DE OTRO PAÍS
  // ==========================================================

  double _obtenerTasaPaisNormal(String pais) {
    final resultados = tasasPorPais.where((tasa) {
      return tasa['pais'] == pais;
    }).toList();

    if (resultados.isEmpty) {
      return 0.0;
    }

    return (resultados.first['tasa'] as num).toDouble();
  }

  // ==========================================================
  // OBTENER MODO
  // ==========================================================

  String _obtenerModoPais(String pais) {
    final resultados = tasasPorPais.where((tasa) {
      return tasa['pais'] == pais;
    }).toList();

    if (resultados.isEmpty) {
      return 'multiplicar';
    }

    return resultados.first['modo'].toString();
  }

  // ==========================================================
  // TASA INICIAL
  // ==========================================================

  void _actualizarTasaInicial() {
    if (_esPeru()) {
      categoriaPeru = 'regular';
      tasaActual = _obtenerTasaPeru('regular');
    } else {
      tasaActual = _obtenerTasaPaisNormal(selectedPais);
    }

    mensajeMejora = '';
    mensajeProximoNivel = '';
  }

  // ==========================================================
  // DETERMINAR CATEGORÍA PERÚ
  //
  // Regular: S/ 10 - S/ 399.99
  // VIP 1:    S/ 400 - S/ 999.99
  // VIP 2:    S/ 1,000+
  // ==========================================================

  void _determinarCategoriaPeru(double soles) {
    if (!_esPeru()) {
      return;
    }

    final String categoriaAnterior = categoriaPeru;

    if (soles >= 1000) {
      categoriaPeru = 'vip2';
      tasaActual = _obtenerTasaPeru('vip2');
    } else if (soles >= 400) {
      categoriaPeru = 'vip1';
      tasaActual = _obtenerTasaPeru('vip1');
    } else {
      categoriaPeru = 'regular';
      tasaActual = _obtenerTasaPeru('regular');
    }

    // Mostrar mensaje solamente cuando sube de categoría.
    if (categoriaAnterior != categoriaPeru) {
      if (categoriaPeru == 'vip1') {
        mensajeMejora = '⭐ ¡Mejoraste tu tasa! Ahora tienes VIP 1';
      } else if (categoriaPeru == 'vip2') {
        mensajeMejora = '👑 ¡Llegaste a VIP 2! Esta es nuestra mejor tasa';
      } else {
        mensajeMejora = '';
      }
    }

    _actualizarMensajeProximoNivel(soles);
  }

  // ==========================================================
  // MENSAJE PRÓXIMO NIVEL
  // ==========================================================

  void _actualizarMensajeProximoNivel(double soles) {
    if (!_esPeru()) {
      mensajeProximoNivel = '';
      return;
    }

    if (soles < 400) {
      final faltante = 400 - soles;

      mensajeProximoNivel =
          'Envía S/ ${faltante.toStringAsFixed(2)} más para obtener VIP 1 ⭐';
    } else if (soles < 1000) {
      final faltante = 1000 - soles;

      mensajeProximoNivel =
          'Envía S/ ${faltante.toStringAsFixed(2)} más para obtener VIP 2 👑';
    } else {
      mensajeProximoNivel = '👑 Tienes nuestra mejor tasa';
    }
  }

  // ==========================================================
  // ACTUALIZAR CAMPOS
  //
  // Los tres campos pueden activar la tasa VIP:
  //
  // Soles → determina directamente el rango.
  // Bs → convierte a soles usando la tasa regular.
  // Dólares → convierte primero a Bs y luego a soles.
  //
  // El BCV permanece fijo.
  // ==========================================================

  void _updateFields({String source = ''}) {
    double soles = double.tryParse(
          _solesController.text.replaceAll(',', '.'),
        ) ??
        0.0;

    double bolivares = double.tryParse(
          _bolivaresController.text.replaceAll(',', '.'),
        ) ??
        0.0;

    double dollarsBCV = double.tryParse(
          _dollarBCVController.text.replaceAll(',', '.'),
        ) ??
        0.0;

    // ========================================================
    // PERÚ
    // ========================================================

    if (_esPeru()) {
      // El cliente escribe SOLES.
      if (source == 'soles') {
        _determinarCategoriaPeru(soles);
      }

      // El cliente escribe BOLÍVARES.
      else if (source == 'bolivares') {
        final double tasaRegular = _obtenerTasaPeru('regular');

        if (tasaRegular > 0) {
          final double solesReferencia = bolivares / tasaRegular;

          _determinarCategoriaPeru(
            solesReferencia,
          );
        }
      }

      // El cliente escribe DÓLARES.
      else if (source == 'dollarBCV') {
        final double tasaRegular = _obtenerTasaPeru('regular');

        if (tasaRegular > 0 && dollarBCVRate > 0) {
          final double bolivaresReferencia = dollarsBCV * dollarBCVRate;

          final double solesReferencia = bolivaresReferencia / tasaRegular;

          _determinarCategoriaPeru(
            solesReferencia,
          );
        }
      }
    }

    // ========================================================
    // OTROS PAÍSES
    // ========================================================

    else {
      tasaActual = _obtenerTasaPaisNormal(selectedPais);
    }

    final String modo = _obtenerModoPais(selectedPais);

    final bool esDivision = modo == 'dividir';

    // ========================================================
    // SOLES → BS → DÓLARES
    // ========================================================

    if (source == 'soles') {
      if (tasaActual > 0) {
        bolivares = esDivision ? soles / tasaActual : soles * tasaActual;
      }

      if (dollarBCVRate > 0) {
        dollarsBCV = bolivares / dollarBCVRate;
      }
    }

    // ========================================================
    // BS → SOLES → DÓLARES
    // ========================================================

    else if (source == 'bolivares') {
      if (tasaActual > 0) {
        soles = esDivision ? bolivares * tasaActual : bolivares / tasaActual;
      }

      if (dollarBCVRate > 0) {
        dollarsBCV = bolivares / dollarBCVRate;
      }
    }

    // ========================================================
    // DÓLARES → BS → SOLES
    // ========================================================

    else if (source == 'dollarBCV') {
      if (dollarBCVRate > 0) {
        bolivares = dollarsBCV * dollarBCVRate;
      }

      if (tasaActual > 0) {
        soles = esDivision ? bolivares * tasaActual : bolivares / tasaActual;
      }
    }

    // ========================================================
    // ACTUALIZAR CAMPOS
    // ========================================================

    setState(() {
      if (source != 'soles') {
        _solesController.text = soles.toStringAsFixed(2);
      }

      if (source != 'bolivares') {
        _bolivaresController.text = bolivares.toStringAsFixed(2);
      }

      if (source != 'dollarBCV') {
        _dollarBCVController.text = dollarsBCV.toStringAsFixed(2);
      }

      if (_esPeru()) {
        _actualizarMensajeProximoNivel(
          soles,
        );
      }
    });
  }

  // ==========================================================
  // SELECCIONAR PAÍS
  // ==========================================================

  void _seleccionarPais(String pais) {
    setState(() {
      selectedPais = pais;

      _solesController.clear();
      _bolivaresController.clear();
      _dollarBCVController.clear();

      mensajeMejora = '';
      mensajeProximoNivel = '';

      if (_esPeru()) {
        categoriaPeru = 'regular';
        tasaActual = _obtenerTasaPeru('regular');
      } else {
        tasaActual = _obtenerTasaPaisNormal(pais);
      }
    });
  }

  // ==========================================================
  // NOMBRE CATEGORÍA
  // ==========================================================

  String _nombreCategoria() {
    if (!_esPeru()) {
      return 'TASA ACTIVA';
    }

    switch (categoriaPeru) {
      case 'vip1':
        return 'VIP 1';

      case 'vip2':
        return 'VIP 2';

      default:
        return 'REGULAR';
    }
  }

  // ==========================================================
  // ICONO CATEGORÍA
  // ==========================================================

  IconData _iconoCategoria() {
    if (!_esPeru()) {
      return Icons.currency_exchange;
    }

    if (categoriaPeru == 'vip2') {
      return Icons.workspace_premium;
    }

    if (categoriaPeru == 'vip1') {
      return Icons.star;
    }

    return Icons.star_border;
  }

  // ==========================================================
  // COLOR CATEGORÍA
  // ==========================================================

  Color _colorCategoria() {
    if (!_esPeru()) {
      return const Color(0xFF685FEE);
    }

    if (categoriaPeru == 'vip2') {
      return const Color(0xFFC69214);
    }

    if (categoriaPeru == 'vip1') {
      return const Color(0xFF685FEE);
    }

    return Colors.grey.shade700;
  }

  // ==========================================================
  // COPIAR UN CAMPO
  // ==========================================================

  void _copyToClipboard(String text) {
    Clipboard.setData(
      ClipboardData(text: text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado al portapapeles'),
      ),
    );
  }

  // ==========================================================
  // REINICIAR
  // ==========================================================

  void _resetFields() {
    setState(() {
      _solesController.clear();
      _bolivaresController.clear();
      _dollarBCVController.clear();

      categoriaPeru = 'regular';

      mensajeMejora = '';
      mensajeProximoNivel = '';

      if (_esPeru()) {
        tasaActual = _obtenerTasaPeru('regular');
      } else {
        tasaActual = _obtenerTasaPaisNormal(
          selectedPais,
        );
      }
    });
  }

  // ==========================================================
  // COPIAR TODO
  // ==========================================================

  void _copyAllValues() {
    final resultado = tasasPorPais.firstWhere(
      (tasa) => tasa['pais'] == selectedPais,
      orElse: () => {
        'bandera': '🌎',
      },
    );

    final String bandera = resultado['bandera'];

    final String categoria = _esPeru() ? _nombreCategoria() : 'TASA ACTIVA';

    final String allValues = "Calculadora EADON\n"
        "$updateText\n"
        "País seleccionado: "
        "$bandera $selectedPais\n"
        "Categoría: $categoria\n"
        "Cantidad enviada: "
        "${_solesController.text}\n"
        "Tasa: $tasaActual Bs.\n"
        "Cantidad en Bs. a recibir: "
        "${_bolivaresController.text}\n"
        "Dólares (BCV): "
        "${_dollarBCVController.text}"
        " - Tasa BCV: "
        "$dollarBCVRate Bs.";

    Clipboard.setData(
      ClipboardData(text: allValues),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Montos copiados al portapapeles'),
      ),
    );
  }

  // ==========================================================
  // INTERFAZ
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (tasasPorPais.isEmpty) {
      return const Center(
        child: Text(
          'No se pudieron cargar las tasas',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      );
    }

    final List<String> paises = _obtenerPaises();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ======================================================
        // FECHA
        // ======================================================

        Center(
          child: Text(
            updateText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ======================================================
        // SELECTOR DE PAÍS
        // ======================================================

        DropdownButton<String>(
          value: selectedPais,
          isExpanded: true,
          items: paises.map((pais) {
            final resultado = tasasPorPais.firstWhere(
              (tasa) => tasa['pais'] == pais,
              orElse: () => {
                'bandera': '🌎',
              },
            );

            final String banderaPais = resultado['bandera'];

            return DropdownMenuItem<String>(
              value: pais,
              child: Text(
                '$banderaPais $pais',
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _seleccionarPais(value);
            }
          },
        ),

        // ======================================================
        // TARJETA GRANDE DE TASA ACTIVA
        // ======================================================

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _colorCategoria().withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _colorCategoria().withOpacity(0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _iconoCategoria(),
                color: _colorCategoria(),
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _esPeru()
                          ? 'PERÚ · ${_nombreCategoria()}'
                          : '$selectedPais · TASA ACTIVA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _colorCategoria(),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _esPeru()
                          ? '${tasaActual.toStringAsFixed(0)} Bs'
                          : selectedPais == 'Chile'
                              ? '${tasaActual.toStringAsFixed(3)} Bs'
                              : '${tasaActual.toStringAsFixed(0)} Bs',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // MENSAJE DE MEJORA - SOLO PERÚ
        // ======================================================

        if (_esPeru() && mensajeMejora.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEAFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              mensajeMejora,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF685FEE),
              ),
            ),
          ),
        ],

        // ======================================================
        // PRÓXIMO NIVEL - SOLO PERÚ
        // ======================================================

        if (_esPeru() && mensajeProximoNivel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            mensajeProximoNivel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ],

        const SizedBox(height: 10),

        // ======================================================
        // SOLES
        // ======================================================

        TextField(
          controller: _solesController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            labelText: _esPeru()
                ? 'Monto a Enviar ($selectedPais)'
                : 'Monto a Enviar ($selectedPais)',
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () {
                _copyToClipboard(
                  _solesController.text,
                );
              },
            ),
          ),
          onChanged: (value) {
            _updateFields(
              source: 'soles',
            );
          },
        ),

        // ======================================================
        // BOLÍVARES
        // ======================================================

        TextField(
          controller: _bolivaresController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            labelText: 'Cantidad en Bs. a Recibir',
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () {
                _copyToClipboard(
                  _bolivaresController.text,
                );
              },
            ),
          ),
          onChanged: (value) {
            _updateFields(
              source: 'bolivares',
            );
          },
        ),

        // ======================================================
        // DÓLAR BCV FIJO
        // ======================================================

        TextField(
          controller: _dollarBCVController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            labelText: 'Dólar (BCV) - '
                '$dollarBCVRate Bs',
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () {
                _copyToClipboard(
                  _dollarBCVController.text,
                );
              },
            ),
          ),
          onChanged: (value) {
            _updateFields(
              source: 'dollarBCV',
            );
          },
        ),

        const SizedBox(height: 20),

        // ======================================================
        // REINICIAR
        // ======================================================

        ElevatedButton(
          onPressed: _resetFields,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF685FEE),
          ),
          child: const Text(
            'Reiniciar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ======================================================
        // COPIAR TODO
        // ======================================================

        ElevatedButton(
          onPressed: _copyAllValues,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF121212),
          ),
          child: const Text(
            'Copiar Todos los Montos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

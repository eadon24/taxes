import 'package:flutter/material.dart';

import '../models/tasa.dart';
import '../services/json_service.dart';
import '../services/api_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final JsonService jsonService = JsonService();
  final ApiService apiService = ApiService();

  final TextEditingController fechaController = TextEditingController();
  final TextEditingController bcvController = TextEditingController();

  List<Tasa> tasas = [];

  bool cargando = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  @override
  void dispose() {
    fechaController.dispose();
    bcvController.dispose();
    super.dispose();
  }

  Future<void> cargar() async {
    try {
      final datos = await jsonService.cargarDatos();

      setState(() {
        fechaController.text = datos["fecha"].toString();
        bcvController.text = datos["bcv"].toString();
        tasas = datos["tasas"];
        cargando = false;
      });
    } catch (e) {
      debugPrint("Error cargando tasas: $e");

      setState(() {
        cargando = false;
      });
    }
  }

  void agregarPais() {
    setState(() {
      tasas.add(
        Tasa(
          pais: "",
          tasa: 0,
          modo: "multiplicar",
          bandera: "🌎",
          tipo: "normal",
        ),
      );
    });
  }

  void eliminarPais(int index) {
    setState(() {
      tasas.removeAt(index);
    });
  }

  Future<void> guardar() async {
    final bcv = double.tryParse(
      bcvController.text.replaceAll(',', '.'),
    );

    if (bcv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ El BCV no es válido"),
        ),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final json = jsonService.generarJson(
        fecha: fechaController.text,
        bcv: bcv,
        tasas: tasas,
      );

      final ok = await apiService.guardarTasas(json);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? "✅ Tasas actualizadas correctamente" : "❌ Error al guardar",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Administrador EADON"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --------------------------------------------------
            // FECHA Y BCV
            // --------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fechaController,
                    decoration: const InputDecoration(
                      labelText: "Fecha",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: bcvController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "BCV",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // TABLA DE TASAS
            // --------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(
                        label: Text("Bandera"),
                      ),
                      DataColumn(
                        label: Text("País"),
                      ),
                      DataColumn(
                        label: Text("Tipo"),
                      ),
                      DataColumn(
                        label: Text("Tasa"),
                      ),
                      DataColumn(
                        label: Text("Modo"),
                      ),
                      DataColumn(
                        label: Text("Acción"),
                      ),
                    ],
                    rows: List.generate(
                      tasas.length,
                      (index) {
                        final tasa = tasas[index];

                        return DataRow(
                          cells: [
                            // --------------------------------
                            // BANDERA
                            // --------------------------------
                            DataCell(
                              SizedBox(
                                width: 60,
                                child: TextFormField(
                                  initialValue: tasa.bandera,
                                  onChanged: (value) {
                                    tasa.bandera = value;
                                  },
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // --------------------------------
                            // PAÍS
                            // --------------------------------
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: TextFormField(
                                  initialValue: tasa.pais,
                                  onChanged: (value) {
                                    tasa.pais = value;
                                  },
                                ),
                              ),
                            ),

                            // --------------------------------
                            // TIPO
                            // --------------------------------
                            DataCell(
                              DropdownButton<String>(
                                value: [
                                  "normal",
                                  "regular",
                                  "vip1",
                                  "vip2",
                                ].contains(tasa.tipo)
                                    ? tasa.tipo
                                    : "normal",
                                items: const [
                                  DropdownMenuItem(
                                    value: "normal",
                                    child: Text("Normal"),
                                  ),
                                  DropdownMenuItem(
                                    value: "regular",
                                    child: Text("Regular"),
                                  ),
                                  DropdownMenuItem(
                                    value: "vip1",
                                    child: Text("VIP 1"),
                                  ),
                                  DropdownMenuItem(
                                    value: "vip2",
                                    child: Text("VIP 2"),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;

                                  setState(() {
                                    tasa.tipo = value;
                                  });
                                },
                              ),
                            ),

                            // --------------------------------
                            // TASA
                            // --------------------------------
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  initialValue: tasa.tasa.toString(),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (value) {
                                    tasa.tasa = double.tryParse(
                                          value.replaceAll(',', '.'),
                                        ) ??
                                        0;
                                  },
                                ),
                              ),
                            ),

                            // --------------------------------
                            // MODO
                            // --------------------------------
                            DataCell(
                              DropdownButton<String>(
                                value: tasa.modo,
                                items: const [
                                  DropdownMenuItem(
                                    value: "multiplicar",
                                    child: Text("Multiplicar"),
                                  ),
                                  DropdownMenuItem(
                                    value: "dividir",
                                    child: Text("Dividir"),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;

                                  setState(() {
                                    tasa.modo = value;
                                  });
                                },
                              ),
                            ),

                            // --------------------------------
                            // ELIMINAR
                            // --------------------------------
                            DataCell(
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: "Eliminar",
                                onPressed: () {
                                  eliminarPais(index);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // BOTONES
            // --------------------------------------------------
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: agregarPais,
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar País"),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: guardando ? null : guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    guardando ? "Guardando..." : "Guardar",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

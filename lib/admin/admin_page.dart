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

  Future<void> cargar() async {
    final datos = await jsonService.cargarDatos();

    setState(() {
      fechaController.text = datos["fecha"];
      bcvController.text = datos["bcv"].toString();
      tasas = datos["tasas"];
      cargando = false;
    });
  }

  void agregarPais() {
    setState(() {
      tasas.add(Tasa(pais: "", tasa: 0, modo: "multiplicar", bandera: "🌎"));
    });
  }

  void eliminarPais(int index) {
    setState(() {
      tasas.removeAt(index);
    });
  }

  Future<void> guardar() async {
    setState(() {
      guardando = true;
    });

    final json = jsonService.generarJson(
      fecha: fechaController.text,
      bcv: double.parse(bcvController.text),
      tasas: tasas,
    );

    final ok = await apiService.guardarTasas(json);

    if (!mounted) return;

    setState(() {
      guardando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? "✅ Tasas actualizadas correctamente" : "❌ Error al guardar",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "BCV",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Bandera")),
                    DataColumn(label: Text("País")),
                    DataColumn(label: Text("Tasa")),
                    DataColumn(label: Text("Modo")),
                    DataColumn(label: Text("Acción")),
                  ],
                  rows: List.generate(tasas.length, (index) {
                    final tasa = tasas[index];

                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 50,
                            child: TextFormField(
                              initialValue: tasa.bandera,
                              onChanged: (v) => tasa.bandera = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              initialValue: tasa.pais,
                              onChanged: (v) => tasa.pais = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              initialValue: tasa.tasa.toString(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (v) {
                                tasa.tasa = double.tryParse(v) ?? 0;
                              },
                            ),
                          ),
                        ),
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
                            onChanged: (v) {
                              setState(() {
                                tasa.modo = v!;
                              });
                            },
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => eliminarPais(index),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                  label: Text(guardando ? "Guardando..." : "Guardar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

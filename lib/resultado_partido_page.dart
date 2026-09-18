import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResultadoPartidoPage extends StatefulWidget {
  final int partidoId;
  final String token;

  const ResultadoPartidoPage({
    super.key,
    required this.partidoId,
    required this.token,
  });

  @override
  State<ResultadoPartidoPage> createState() =>
      _ResultadoPartidoPageState();
}

class _ResultadoPartidoPageState
    extends State<ResultadoPartidoPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  final _formKey = GlobalKey<FormState>();

  final golesLocalCtrl = TextEditingController();
  final golesVisitanteCtrl = TextEditingController();
  final fechaCtrl = TextEditingController();
  final horaCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();

  bool cargando = true;
  bool guardando = false;

  String? error;

  String equipoLocal = '';
  String equipoVisitante = '';

  @override
  void initState() {
    super.initState();
    cargarPartido();
  }

  @override
  void dispose() {
    golesLocalCtrl.dispose();
    golesVisitanteCtrl.dispose();
    fechaCtrl.dispose();
    horaCtrl.dispose();
    observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarPartido() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http.get(
        Uri.parse(
          '$baseUrl/api/partidos/${widget.partidoId}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos =
            jsonDecode(respuesta.body);

        if (datos is Map<String, dynamic> &&
            datos['partido'] is Map<String, dynamic>) {
          final partido =
              Map<String, dynamic>.from(
            datos['partido'],
          );

          final local = partido['equipoLocal'];
          final visitante = partido['equipoVisitante'];

          if (local is Map) {
            equipoLocal =
                local['nombre']?.toString() ?? '';
          }

          if (visitante is Map) {
            equipoVisitante =
                visitante['nombre']?.toString() ?? '';
          }

          golesLocalCtrl.text =
              partido['golesLocal']?.toString() ?? '';

          golesVisitanteCtrl.text =
              partido['golesVisitante']?.toString() ?? '';

          observacionesCtrl.text =
              partido['observaciones']?.toString() ?? '';

          final fechaHora = partido['fechaHora'];

          if (fechaHora != null) {
            final fecha =
                DateTime.tryParse(
              fechaHora.toString(),
            );

            if (fecha != null) {
              fechaCtrl.text =
                  '${fecha.year.toString().padLeft(4, '0')}-'
                  '${fecha.month.toString().padLeft(2, '0')}-'
                  '${fecha.day.toString().padLeft(2, '0')}';

              horaCtrl.text =
                  '${fecha.hour.toString().padLeft(2, '0')}:'
                  '${fecha.minute.toString().padLeft(2, '0')}';
            }
          }

          if (mounted) {
            setState(() {});
          }
        } else {
          setState(() {
            error =
                'La respuesta del servidor no tiene el formato esperado.';
          });
        }
      } else if (respuesta.statusCode == 401) {
        setState(() {
          error =
              'Sesión no autorizada o token vencido.';
        });
      } else {
        setState(() {
          error =
              'No fue posible cargar el partido. Código ${respuesta.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        error =
            'No se pudo conectar con el servidor.';
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> seleccionarFecha() async {
    DateTime inicial = DateTime.now();

    final actual =
        DateTime.tryParse(fechaCtrl.text);

    if (actual != null) {
      inicial = actual;
    }

    final seleccionada =
        await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (seleccionada == null) {
      return;
    }

    setState(() {
      fechaCtrl.text =
          '${seleccionada.year.toString().padLeft(4, '0')}-'
          '${seleccionada.month.toString().padLeft(2, '0')}-'
          '${seleccionada.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> seleccionarHora() async {
    TimeOfDay inicial = TimeOfDay.now();

    final partes =
        horaCtrl.text.split(':');

    if (partes.length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);

      if (h != null && m != null) {
        inicial = TimeOfDay(
          hour: h,
          minute: m,
        );
      }
    }

    final seleccionada =
        await showTimePicker(
      context: context,
      initialTime: inicial,
    );

    if (seleccionada == null) {
      return;
    }

    setState(() {
      horaCtrl.text =
          '${seleccionada.hour.toString().padLeft(2, '0')}:'
          '${seleccionada.minute.toString().padLeft(2, '0')}';
    });
  }

  void mostrarMensaje(
    String mensaje, {
    bool esError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            esError
                ? Colors.red.shade700
                : Colors.green.shade700,
      ),
    );
  }

  Future<void> guardarResultado() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final golesLocal =
        int.tryParse(
      golesLocalCtrl.text.trim(),
    );

    final golesVisitante =
        int.tryParse(
      golesVisitanteCtrl.text.trim(),
    );

    if (golesLocal == null ||
        golesVisitante == null) {
      mostrarMensaje(
        'Los goles deben ser valores numéricos.',
        esError: true,
      );
      return;
    }

    if (golesLocal < 0 ||
        golesVisitante < 0) {
      mostrarMensaje(
        'Los goles no pueden ser negativos.',
        esError: true,
      );
      return;
    }

    final fecha =
        fechaCtrl.text.trim();

    final hora =
        horaCtrl.text.trim();

    if (fecha.isEmpty || hora.isEmpty) {
      mostrarMensaje(
        'Debe seleccionar fecha y hora.',
        esError: true,
      );
      return;
    }

    final fechaHora =
        DateTime.tryParse(
      '${fecha}T$hora:00',
    );

    if (fechaHora == null) {
      mostrarMensaje(
        'La fecha u hora no es válida.',
        esError: true,
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    final body = {
      'golesLocal': golesLocal,
      'golesVisitante': golesVisitante,
      'fechaHora':
          fechaHora.toIso8601String(),
      'observaciones':
          observacionesCtrl.text
                  .trim()
                  .isEmpty
              ? null
              : observacionesCtrl.text.trim(),
    };

    try {
      final respuesta =
          await http.put(
        Uri.parse(
          '$baseUrl/api/partidos/${widget.partidoId}/resultado',
        ),
        headers: {
          'Content-Type':
              'application/json',
          'Accept':
              'application/json',
          'Authorization':
              'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      if (respuesta.statusCode == 200 ||
          respuesta.statusCode == 204) {
        if (!mounted) return;

        mostrarMensaje(
          'Resultado registrado correctamente.',
        );

        await Future.delayed(
          const Duration(
            milliseconds: 400,
          ),
        );

        if (!mounted) return;

        Navigator.pop(
          context,
          true,
        );
      } else {
        String mensaje =
            'No fue posible registrar el resultado. Código ${respuesta.statusCode}.';

        try {
          final dynamic datos =
              jsonDecode(
            respuesta.body,
          );

          if (datos is Map<String, dynamic>) {
            mensaje =
                datos['mensaje']?.toString() ??
                    datos['message']?.toString() ??
                    mensaje;
          }
        } catch (_) {}

        mostrarMensaje(
          mensaje,
          esError: true,
        );
      }
    } catch (e) {
      mostrarMensaje(
        'No se pudo conectar con el servidor.',
        esError: true,
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
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Registrar resultado',
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 70,
                  color: Colors.red,
                ),
                const SizedBox(
                    height: 18),
                Text(
                  error!,
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                    height: 20),
                FilledButton.icon(
                  onPressed:
                      cargarPartido,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text(
                    'REINTENTAR',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text(
          'Registrar resultado',
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 650,
            ),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(20),
                      child: Text(
                        '$equipoLocal  vs  $equipoVisitante',
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                      height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller:
                              golesLocalCtrl,
                          keyboardType:
                              TextInputType.number,
                          decoration:
                              InputDecoration(
                            labelText:
                                equipoLocal.isEmpty
                                    ? 'Goles local'
                                    : 'Goles $equipoLocal',
                            prefixIcon:
                                const Icon(
                              Icons
                                  .sports_soccer,
                            ),
                            border:
                                const OutlineInputBorder(),
                          ),
                          validator:
                              (valor) {
                            final goles =
                                int.tryParse(
                              valor?.trim() ??
                                  '',
                            );

                            if (goles ==
                                null) {
                              return 'Ingrese los goles.';
                            }

                            if (goles <
                                0) {
                              return 'Valor inválido.';
                            }

                            return null;
                          },
                        ),
                      ),

                      const SizedBox(
                          width: 14),

                      Expanded(
                        child: TextFormField(
                          controller:
                              golesVisitanteCtrl,
                          keyboardType:
                              TextInputType.number,
                          decoration:
                              InputDecoration(
                            labelText:
                                equipoVisitante
                                        .isEmpty
                                    ? 'Goles visitante'
                                    : 'Goles $equipoVisitante',
                            prefixIcon:
                                const Icon(
                              Icons
                                  .sports_soccer,
                            ),
                            border:
                                const OutlineInputBorder(),
                          ),
                          validator:
                              (valor) {
                            final goles =
                                int.tryParse(
                              valor?.trim() ??
                                  '',
                            );

                            if (goles ==
                                null) {
                              return 'Ingrese los goles.';
                            }

                            if (goles <
                                0) {
                              return 'Valor inválido.';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 14),

                  TextFormField(
                    controller:
                        fechaCtrl,
                    readOnly: true,
                    onTap:
                        seleccionarFecha,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Fecha del partido',
                      prefixIcon:
                          Icon(
                        Icons.calendar_month,
                      ),
                      suffixIcon:
                          Icon(
                        Icons.edit_calendar,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                      height: 14),

                  TextFormField(
                    controller:
                        horaCtrl,
                    readOnly: true,
                    onTap:
                        seleccionarHora,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Hora del partido',
                      prefixIcon:
                          Icon(
                        Icons.access_time,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                      height: 14),

                  TextFormField(
                    controller:
                        observacionesCtrl,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Observaciones',
                      prefixIcon:
                          Icon(Icons.notes),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                      height: 24),

                  SizedBox(
                    height: 52,
                    child:
                        FilledButton.icon(
                      onPressed:
                          guardando
                              ? null
                              : guardarResultado,
                      icon:
                          guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Icon(
                                  Icons.save,
                                ),
                      label: Text(
                        guardando
                            ? 'GUARDANDO...'
                            : 'REGISTRAR RESULTADO',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
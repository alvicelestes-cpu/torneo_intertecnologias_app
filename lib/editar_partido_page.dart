import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditarPartidoPage extends StatefulWidget {
  final int partidoId;
  final String token;

  const EditarPartidoPage({
    super.key,
    required this.partidoId,
    required this.token,
  });

  @override
  State<EditarPartidoPage> createState() =>
      _EditarPartidoPageState();
}

class _EditarPartidoPageState extends State<EditarPartidoPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  final _formKey = GlobalKey<FormState>();

  final faseCtrl = TextEditingController();
  final llaveCtrl = TextEditingController();
  final jornadaCtrl = TextEditingController();
  final equipoLocalIdCtrl = TextEditingController();
  final equipoVisitanteIdCtrl = TextEditingController();
  final fechaCtrl = TextEditingController();
  final horaCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();

  bool cargando = true;
  bool guardando = false;

  String? error;
  String estado = 'PROGRAMADO';

  String equipoLocalNombre = '';
  String equipoVisitanteNombre = '';

  @override
  void initState() {
    super.initState();
    cargarPartido();
  }

  @override
  void dispose() {
    faseCtrl.dispose();
    llaveCtrl.dispose();
    jornadaCtrl.dispose();
    equipoLocalIdCtrl.dispose();
    equipoVisitanteIdCtrl.dispose();
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
        final dynamic datos = jsonDecode(respuesta.body);

        if (datos is Map<String, dynamic> &&
            datos['partido'] is Map<String, dynamic>) {
          final partido = Map<String, dynamic>.from(
            datos['partido'],
          );

          final local = partido['equipoLocal'];
          final visitante = partido['equipoVisitante'];

          faseCtrl.text =
              partido['fase']?.toString() ?? '';

          llaveCtrl.text =
              partido['llave']?.toString() ?? '';

          jornadaCtrl.text =
              partido['jornada']?.toString() ?? '';

          if (local is Map) {
            equipoLocalIdCtrl.text =
                local['id']?.toString() ?? '';

            equipoLocalNombre =
                local['nombre']?.toString() ?? '';
          }

          if (visitante is Map) {
            equipoVisitanteIdCtrl.text =
                visitante['id']?.toString() ?? '';

            equipoVisitanteNombre =
                visitante['nombre']?.toString() ?? '';
          }

          final fechaHora = partido['fechaHora'];

          if (fechaHora != null) {
            final fecha =
                DateTime.tryParse(fechaHora.toString());

            if (fecha != null) {
              final anio = fecha.year.toString();

              final mes = fecha.month
                  .toString()
                  .padLeft(2, '0');

              final dia = fecha.day
                  .toString()
                  .padLeft(2, '0');

              final hora = fecha.hour
                  .toString()
                  .padLeft(2, '0');

              final minuto = fecha.minute
                  .toString()
                  .padLeft(2, '0');

              fechaCtrl.text =
                  '$anio-$mes-$dia';

              horaCtrl.text =
                  '$hora:$minuto';
            }
          }

          final estadoServidor =
              partido['estado']?.toString().trim();

          if (estadoServidor != null &&
              estadoServidor.isNotEmpty) {
            estado = estadoServidor;
          }

          observacionesCtrl.text =
              partido['observaciones']?.toString() ?? '';

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
      } else if (respuesta.statusCode == 404) {
        setState(() {
          error = 'Partido no encontrado.';
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
    DateTime fechaInicial = DateTime.now();

    final fechaActual =
        DateTime.tryParse(fechaCtrl.text);

    if (fechaActual != null) {
      fechaInicial = fechaActual;
    }

    final seleccionada =
        await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (seleccionada == null) {
      return;
    }

    final anio =
        seleccionada.year.toString();

    final mes = seleccionada.month
        .toString()
        .padLeft(2, '0');

    final dia = seleccionada.day
        .toString()
        .padLeft(2, '0');

    setState(() {
      fechaCtrl.text =
          '$anio-$mes-$dia';
    });
  }

  Future<void> seleccionarHora() async {
    TimeOfDay horaInicial =
        TimeOfDay.now();

    final partes =
        horaCtrl.text.split(':');

    if (partes.length == 2) {
      final hora =
          int.tryParse(partes[0]);

      final minuto =
          int.tryParse(partes[1]);

      if (hora != null &&
          minuto != null &&
          hora >= 0 &&
          hora <= 23 &&
          minuto >= 0 &&
          minuto <= 59) {
        horaInicial = TimeOfDay(
          hour: hora,
          minute: minuto,
        );
      }
    }

    final seleccionada =
        await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );

    if (seleccionada == null) {
      return;
    }

    final hora = seleccionada.hour
        .toString()
        .padLeft(2, '0');

    final minuto = seleccionada.minute
        .toString()
        .padLeft(2, '0');

    setState(() {
      horaCtrl.text =
          '$hora:$minuto';
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
        backgroundColor: esError
            ? Colors.red.shade700
            : Colors.green.shade700,
      ),
    );
  }

  Future<void> guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final jornada =
        int.tryParse(jornadaCtrl.text.trim());

    final equipoLocalId =
        int.tryParse(
      equipoLocalIdCtrl.text.trim(),
    );

    final equipoVisitanteId =
        int.tryParse(
      equipoVisitanteIdCtrl.text.trim(),
    );

    if (jornada == null ||
        equipoLocalId == null ||
        equipoVisitanteId == null) {
      mostrarMensaje(
        'Jornada y equipos deben tener valores válidos.',
        esError: true,
      );
      return;
    }

    if (equipoLocalId == equipoVisitanteId) {
      mostrarMensaje(
        'El equipo local y visitante no pueden ser el mismo.',
        esError: true,
      );
      return;
    }

    String? fechaHora;

    final fecha =
        fechaCtrl.text.trim();

    final hora =
        horaCtrl.text.trim();

    if (fecha.isNotEmpty ||
        hora.isNotEmpty) {
      if (fecha.isEmpty ||
          hora.isEmpty) {
        mostrarMensaje(
          'Debe seleccionar tanto la fecha como la hora.',
          esError: true,
        );
        return;
      }

      final fechaCompleta =
          DateTime.tryParse(
        '${fecha}T$hora:00',
      );

      if (fechaCompleta == null) {
        mostrarMensaje(
          'La fecha u hora seleccionada no es válida.',
          esError: true,
        );
        return;
      }

      fechaHora =
          fechaCompleta.toIso8601String();
    }

    final body = {
      'fase':
          faseCtrl.text.trim(),
      'llave':
          llaveCtrl.text.trim().isEmpty
              ? null
              : llaveCtrl.text.trim(),
      'jornada':
          jornada,
      'equipoLocalId':
          equipoLocalId,
      'equipoVisitanteId':
          equipoVisitanteId,
      'fechaHora':
          fechaHora,
      'estado':
          estado,
      'observaciones':
          observacionesCtrl.text.trim().isEmpty
              ? null
              : observacionesCtrl.text.trim(),
    };

    setState(() {
      guardando = true;
    });

    try {
      final respuesta = await http.put(
        Uri.parse(
          '$baseUrl/api/partidos/${widget.partidoId}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      if (respuesta.statusCode == 200 ||
          respuesta.statusCode == 204) {
        if (!mounted) return;

        mostrarMensaje(
          'Partido actualizado correctamente.',
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
            'No fue posible actualizar el partido. Código ${respuesta.statusCode}.';

        try {
          final dynamic datos =
              jsonDecode(respuesta.body);

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
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Editar partido',
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
                const SizedBox(height: 18),
                Text(
                  error!,
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(height: 20),
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
          'Editar partido',
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
                    elevation: 2,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Partido',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$equipoLocalNombre  vs  $equipoVisitanteNombre',
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextFormField(
                    controller:
                        faseCtrl,
                    decoration:
                        const InputDecoration(
                      labelText: 'Fase',
                      prefixIcon:
                          Icon(Icons.flag),
                      border:
                          OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          valor.trim().isEmpty) {
                        return 'Ingrese la fase.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        llaveCtrl,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Llave (opcional)',
                      prefixIcon:
                          Icon(
                        Icons.account_tree,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        jornadaCtrl,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        const InputDecoration(
                      labelText: 'Jornada',
                      prefixIcon:
                          Icon(Icons.numbers),
                      border:
                          OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          int.tryParse(
                                valor.trim(),
                              ) ==
                              null) {
                        return 'Ingrese una jornada válida.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        equipoLocalIdCtrl,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        InputDecoration(
                      labelText:
                          'ID equipo local',
                      helperText:
                          equipoLocalNombre,
                      prefixIcon:
                          const Icon(
                        Icons.home,
                      ),
                      border:
                          const OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          int.tryParse(
                                valor.trim(),
                              ) ==
                              null) {
                        return 'Ingrese un ID válido.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        equipoVisitanteIdCtrl,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        InputDecoration(
                      labelText:
                          'ID equipo visitante',
                      helperText:
                          equipoVisitanteNombre,
                      prefixIcon:
                          const Icon(
                        Icons.groups,
                      ),
                      border:
                          const OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          int.tryParse(
                                valor.trim(),
                              ) ==
                              null) {
                        return 'Ingrese un ID válido.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        fechaCtrl,
                    readOnly: true,
                    onTap:
                        seleccionarFecha,
                    decoration:
                        const InputDecoration(
                      labelText: 'Fecha',
                      hintText:
                          'Fecha por definir',
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

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        horaCtrl,
                    readOnly: true,
                    onTap:
                        seleccionarHora,
                    decoration:
                        const InputDecoration(
                      labelText: 'Hora',
                      hintText:
                          'Hora por definir',
                      prefixIcon:
                          Icon(
                        Icons.access_time,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue:
                        estado.isEmpty
                            ? null
                            : estado,
                    decoration:
                        const InputDecoration(
                      labelText: 'Estado',
                      prefixIcon:
                          Icon(
                        Icons.info_outline,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'PROGRAMADO',
                        child: Text(
                          'PROGRAMADO',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'EN_CURSO',
                        child: Text(
                          'EN CURSO',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'FINALIZADO',
                        child: Text(
                          'FINALIZADO',
                        ),
                      ),
                    ],
                    onChanged: guardando
                        ? null
                        : (valor) {
                            if (valor == null) {
                              return;
                            }

                            setState(() {
                              estado = valor;
                            });
                          },
                  ),

                  const SizedBox(height: 14),

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

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child:
                        FilledButton.icon(
                      onPressed: guardando
                          ? null
                          : guardarCambios,
                      icon: guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.save,
                            ),
                      label: Text(
                        guardando
                            ? 'GUARDANDO...'
                            : 'GUARDAR CAMBIOS',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
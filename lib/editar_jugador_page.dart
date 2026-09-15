import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditarJugadorPage extends StatefulWidget {
  final int jugadorId;
  final String token;

  const EditarJugadorPage({
    super.key,
    required this.jugadorId,
    required this.token,
  });

  @override
  State<EditarJugadorPage> createState() =>
      _EditarJugadorPageState();
}

class _EditarJugadorPageState
    extends State<EditarJugadorPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  final _formKey = GlobalKey<FormState>();

  final nombresCtrl = TextEditingController();
  final apellidosCtrl = TextEditingController();
  final numeroCamisetaCtrl = TextEditingController();
  final documentoCtrl = TextEditingController();
  final fechaNacimientoCtrl = TextEditingController();
  final posicionCtrl = TextEditingController();
  final observacionCtrl = TextEditingController();

  bool cargando = true;
  bool guardando = false;

  String? error;

  int? equipoId;
  String equipoNombre = '';
  String fotoJugador = '';
  String estado = 'PENDIENTE';

  @override
  void initState() {
    super.initState();
    cargarJugador();
  }

  @override
  void dispose() {
    nombresCtrl.dispose();
    apellidosCtrl.dispose();
    numeroCamisetaCtrl.dispose();
    documentoCtrl.dispose();
    fechaNacimientoCtrl.dispose();
    posicionCtrl.dispose();
    observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarJugador() async {
    setState(() {
      cargando = true;
      error = null;
    });

    final url =
        '$baseUrl/api/jugadores/${widget.jugadorId}';

    try {
      final respuesta = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos =
            jsonDecode(respuesta.body);

        if (datos is Map<String, dynamic> &&
            datos['jugador'] is Map<String, dynamic>) {
          final jugador =
              Map<String, dynamic>.from(
            datos['jugador'],
          );

          final equipo =
              jugador['equipo'];

          setState(() {
            equipoId =
                jugador['equipoId'] is int
                    ? jugador['equipoId']
                    : int.tryParse(
                        jugador['equipoId']
                                ?.toString() ??
                            '',
                      );

            if (equipo is Map<String, dynamic>) {
              equipoNombre =
                  equipo['nombre']
                          ?.toString() ??
                      '';
            }

            nombresCtrl.text =
                jugador['nombres']
                        ?.toString() ??
                    '';

            apellidosCtrl.text =
                jugador['apellidos']
                        ?.toString() ??
                    '';

            numeroCamisetaCtrl.text =
                jugador['numeroCamiseta']
                        ?.toString() ??
                    '';

            documentoCtrl.text =
                jugador['documento']
                        ?.toString() ??
                    '';

            fechaNacimientoCtrl.text =
                formatearFechaParaCampo(
              jugador['fechaNacimiento'],
            );

            posicionCtrl.text =
                jugador['posicion']
                        ?.toString() ??
                    '';

            fotoJugador =
                jugador['fotoJugador']
                        ?.toString() ??
                    '';

            estado =
                jugador['estado']
                        ?.toString() ??
                    'PENDIENTE';

            observacionCtrl.text =
                jugador['observacionAdmin']
                        ?.toString() ??
                    '';
          });
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
              'No fue posible cargar el jugador. Código ${respuesta.statusCode}.';
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

  String formatearFechaParaCampo(
      dynamic fecha) {
    if (fecha == null) {
      return '';
    }

    final valor =
        fecha.toString().trim();

    if (valor.isEmpty) {
      return '';
    }

    final date =
        DateTime.tryParse(valor);

    if (date == null) {
      return '';
    }

    final anio =
        date.year.toString();

    final mes =
        date.month
            .toString()
            .padLeft(2, '0');

    final dia =
        date.day
            .toString()
            .padLeft(2, '0');

    return '$anio-$mes-$dia';
  }

  String obtenerFotoUrl() {
    final valor =
        fotoJugador.trim();

    if (valor.isEmpty ||
        valor.toLowerCase() == 'string') {
      return '';
    }

    if (valor.startsWith('http://') ||
        valor.startsWith('https://')) {
      return valor;
    }

    if (valor.startsWith('/')) {
      return '$baseUrl$valor';
    }

    return '$baseUrl/$valor';
  }

  Future<void> seleccionarFecha() async {
    DateTime fechaInicial =
        DateTime.now();

    final actual =
        DateTime.tryParse(
      fechaNacimientoCtrl.text,
    );

    if (actual != null) {
      fechaInicial = actual;
    }

    final fechaSeleccionada =
        await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (fechaSeleccionada == null) {
      return;
    }

    final anio =
        fechaSeleccionada.year
            .toString();

    final mes =
        fechaSeleccionada.month
            .toString()
            .padLeft(2, '0');

    final dia =
        fechaSeleccionada.day
            .toString()
            .padLeft(2, '0');

    setState(() {
      fechaNacimientoCtrl.text =
          '$anio-$mes-$dia';
    });
  }

  Future<void> guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (equipoId == null) {
      mostrarMensaje(
        'El jugador no tiene un equipo válido.',
        esError: true,
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    final url =
        '$baseUrl/api/jugadores/${widget.jugadorId}';

    int? numeroCamiseta;

    if (numeroCamisetaCtrl.text
        .trim()
        .isNotEmpty) {
      numeroCamiseta =
          int.tryParse(
        numeroCamisetaCtrl.text.trim(),
      );

      if (numeroCamiseta == null) {
        mostrarMensaje(
          'El número de camiseta debe ser numérico.',
          esError: true,
        );

        setState(() {
          guardando = false;
        });

        return;
      }
    }

    String? fechaNacimiento;

    if (fechaNacimientoCtrl.text
        .trim()
        .isNotEmpty) {
      final fecha =
          DateTime.tryParse(
        fechaNacimientoCtrl.text.trim(),
      );

      if (fecha == null) {
        mostrarMensaje(
          'La fecha de nacimiento no es válida.',
          esError: true,
        );

        setState(() {
          guardando = false;
        });

        return;
      }

      fechaNacimiento =
          fecha.toIso8601String();
    }

    final body = {
      'equipoId': equipoId,
      'nombres':
          nombresCtrl.text.trim(),
      'apellidos':
          apellidosCtrl.text.trim(),
      'numeroCamiseta':
          numeroCamiseta,
      'documento':
          documentoCtrl.text
                  .trim()
                  .isEmpty
              ? null
              : documentoCtrl.text.trim(),
      'fechaNacimiento':
          fechaNacimiento,
      'posicion':
          posicionCtrl.text
                  .trim()
                  .isEmpty
              ? null
              : posicionCtrl.text.trim(),
      'fotoJugador':
          fotoJugador.trim().isEmpty
              ? null
              : fotoJugador.trim(),
      'estado': estado,
      'observacionAdmin':
          observacionCtrl.text
                  .trim()
                  .isEmpty
              ? null
              : observacionCtrl.text.trim(),
    };

    try {
      final respuesta =
          await http.put(
        Uri.parse(url),
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
          'Jugador actualizado correctamente.',
        );

        await Future.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );

        if (!mounted) return;

        Navigator.pop(
          context,
          true,
        );
      } else {
        String mensaje =
            'No fue posible actualizar el jugador. Código ${respuesta.statusCode}.';

        try {
          final datos =
              jsonDecode(
            respuesta.body,
          );

          if (datos
              is Map<String, dynamic>) {
            mensaje =
                datos['mensaje']
                        ?.toString() ??
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

  void mostrarMensaje(
    String mensaje, {
    bool esError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            esError
                ? Colors.red.shade700
                : Colors.green.shade700,
      ),
    );
  }

  Widget construirFoto() {
    final fotoUrl =
        obtenerFotoUrl();

    if (fotoUrl.isEmpty) {
      return const CircleAvatar(
        radius: 55,
        child: Icon(
          Icons.person,
          size: 55,
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(20),
      child: Image.network(
        fotoUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder:
            (
              context,
              error,
              stackTrace,
            ) {
          return const CircleAvatar(
            radius: 55,
            child: Icon(
              Icons.person,
              size: 55,
            ),
          );
        },
      ),
    );
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
            'Editar jugador',
          ),
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
                      cargarJugador,
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
          'Editar jugador',
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
                children: [
                  construirFoto(),

                  const SizedBox(
                      height: 16),

                  if (equipoNombre
                      .isNotEmpty)
                    Text(
                      equipoNombre,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                  const SizedBox(
                      height: 24),

                  TextFormField(
                    controller:
                        nombresCtrl,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Nombres',
                      prefixIcon:
                          Icon(
                        Icons.person,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                    validator:
                        (valor) {
                      if (valor == null ||
                          valor
                              .trim()
                              .isEmpty) {
                        return 'Ingrese los nombres.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                      height: 14),

                  TextFormField(
                    controller:
                        apellidosCtrl,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Apellidos',
                      prefixIcon:
                          Icon(
                        Icons.person_outline,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                    validator:
                        (valor) {
                      if (valor == null ||
                          valor
                              .trim()
                              .isEmpty) {
                        return 'Ingrese los apellidos.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                      height: 14),

                  TextFormField(
                    controller:
                        numeroCamisetaCtrl,
                    keyboardType:
                        TextInputType
                            .number,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Número de camiseta',
                      prefixIcon:
                          Icon(
                        Icons
                            .confirmation_number,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                      height: 14),

                  TextFormField(
                    controller:
                        documentoCtrl,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Documento',
                      prefixIcon:
                          Icon(
                        Icons.badge,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                      height: 14),

                  TextFormField(
                    controller:
                        fechaNacimientoCtrl,
                    readOnly: true,
                    onTap:
                        seleccionarFecha,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Fecha de nacimiento',
                      prefixIcon:
                          Icon(
                        Icons
                            .calendar_month,
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
                        posicionCtrl,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Posición',
                      prefixIcon:
                          Icon(
                        Icons
                            .sports_soccer,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                      height: 14),

                  DropdownButtonFormField<
                      String>(
                    value:
                        estado.isEmpty
                            ? null
                            : estado,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Estado',
                      prefixIcon:
                          Icon(
                        Icons.verified,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value:
                            'PENDIENTE',
                        child: Text(
                          'PENDIENTE',
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                            'VALIDADO',
                        child: Text(
                          'VALIDADO',
                        ),
                      ),
                    ],
                    onChanged:
                        guardando
                            ? null
                            : (valor) {
                                if (valor ==
                                    null) {
                                  return;
                                }

                                setState(() {
                                  estado =
                                      valor;
                                });
                              },
                  ),

                  const SizedBox(
                      height: 14),

                  TextFormField(
                    controller:
                        observacionCtrl,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Observación del administrador',
                      prefixIcon:
                          Icon(
                        Icons.notes,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                      height: 24),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 52,

                    child:
                        FilledButton.icon(
                      onPressed:
                          guardando
                              ? null
                              : guardarCambios,

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
                            : 'GUARDAR CAMBIOS',
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
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GolesPartidoPage extends StatefulWidget {
  final int partidoId;
  final String token;

  const GolesPartidoPage({
    super.key,
    required this.partidoId,
    required this.token,
  });

  @override
  State<GolesPartidoPage> createState() =>
      _GolesPartidoPageState();
}

class _GolesPartidoPageState extends State<GolesPartidoPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  bool cargando = true;
  bool guardando = false;

  String? error;

  Map<String, dynamic>? partido;

  List<Map<String, dynamic>> goles = [];
  List<Map<String, dynamic>> jugadores = [];

  int? jugadorSeleccionadoId;

  final minutoCtrl = TextEditingController();
  final observacionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarTodo();
  }

  @override
  void dispose() {
    minutoCtrl.dispose();
    observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarTodo() async {
    if (mounted) {
      setState(() {
        cargando = true;
        error = null;
      });
    }

    try {
      await cargarPartido();
      await cargarJugadores();
      await cargarGoles();
    } catch (e) {
      if (mounted) {
        setState(() {
          error =
              'No se pudo cargar la información del partido.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> cargarPartido() async {
    final respuesta = await http.get(
      Uri.parse(
        '$baseUrl/api/partidos/${widget.partidoId}',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (respuesta.statusCode != 200) {
      throw Exception(
        'Error cargando partido',
      );
    }

    final dynamic datos =
        jsonDecode(respuesta.body);

    if (datos is! Map<String, dynamic> ||
        datos['partido'] is! Map<String, dynamic>) {
      throw Exception(
        'Formato inválido',
      );
    }

    partido =
        Map<String, dynamic>.from(
      datos['partido'],
    );
  }

  Future<void> cargarJugadores() async {
    if (partido == null) {
      return;
    }

    final equipoLocal =
        partido!['equipoLocal'];

    final equipoVisitante =
        partido!['equipoVisitante'];

    if (equipoLocal is! Map ||
        equipoVisitante is! Map) {
      throw Exception(
        'Equipos inválidos',
      );
    }

    final localId =
        int.tryParse(
          equipoLocal['id'].toString(),
        ) ??
        0;

    final visitanteId =
        int.tryParse(
          equipoVisitante['id'].toString(),
        ) ??
        0;

    final resultados =
        await Future.wait([
      cargarJugadoresEquipo(
        localId,
      ),
      cargarJugadoresEquipo(
        visitanteId,
      ),
    ]);

    final nombreLocal =
        equipoLocal['nombre']
                ?.toString()
                .trim() ??
            'Equipo local';

    final nombreVisitante =
        equipoVisitante['nombre']
                ?.toString()
                .trim() ??
            'Equipo visitante';

    final jugadoresLocal =
        resultados[0].map(
      (jugador) {
        return <String, dynamic>{
          ...jugador,
          '_equipoNombre':
              nombreLocal,
        };
      },
    ).toList();

    final jugadoresVisitante =
        resultados[1].map(
      (jugador) {
        return <String, dynamic>{
          ...jugador,
          '_equipoNombre':
              nombreVisitante,
        };
      },
    ).toList();

    jugadores = [
      ...jugadoresLocal,
      ...jugadoresVisitante,
    ];

    jugadores.sort(
      (a, b) {
        final nombreA =
            '${a['nombres'] ?? ''} ${a['apellidos'] ?? ''}'
                .trim()
                .toLowerCase();

        final nombreB =
            '${b['nombres'] ?? ''} ${b['apellidos'] ?? ''}'
                .trim()
                .toLowerCase();

        return nombreA.compareTo(
          nombreB,
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>>
      cargarJugadoresEquipo(
    int equipoId,
  ) async {
    final respuesta =
        await http.get(
      Uri.parse(
        '$baseUrl/api/equipos/$equipoId/jugadores',
      ),
      headers: {
        'Accept':
            'application/json',
        'Authorization':
            'Bearer ${widget.token}',
      },
    );

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudieron cargar los jugadores del equipo $equipoId',
      );
    }

    final dynamic datos =
        jsonDecode(
      respuesta.body,
    );

    if (datos is! Map<String, dynamic> ||
        datos['jugadores'] is! List) {
      return [];
    }

    final lista =
        datos['jugadores'] as List;

    return lista
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  Future<void> cargarGoles() async {
    final respuesta =
        await http.get(
      Uri.parse(
        '$baseUrl/api/goles/partido/${widget.partidoId}',
      ),
      headers: {
        'Accept':
            'application/json',
        'Authorization':
            'Bearer ${widget.token}',
      },
    );

    if (respuesta.statusCode != 200) {
      throw Exception(
        'Error cargando goles',
      );
    }

    final dynamic datos =
        jsonDecode(
      respuesta.body,
    );

    if (datos is Map<String, dynamic> &&
        datos['goles'] is List) {
      goles =
          (datos['goles'] as List)
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();
    }
  }

  String nombreEquipo(
    dynamic equipo,
  ) {
    if (equipo is Map &&
        equipo['nombre'] != null) {
      return equipo['nombre']
          .toString()
          .trim();
    }

    return 'Equipo';
  }

  String nombreJugador(
    Map<String, dynamic> jugador,
  ) {
    final nombres =
        jugador['nombres']
                ?.toString()
                .trim() ??
            '';

    final apellidos =
        jugador['apellidos']
                ?.toString()
                .trim() ??
            '';

    final equipo =
        jugador['_equipoNombre']
                ?.toString()
                .trim() ??
            '';

    final nombre =
        '$nombres $apellidos'.trim();

    if (equipo.isNotEmpty) {
      return '$nombre — $equipo';
    }

    return nombre;
  }

  void mostrarMensaje(
    String mensaje, {
    bool esError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(mensaje),
        backgroundColor:
            esError
                ? Colors.red.shade700
                : Colors.green.shade700,
      ),
    );
  }

  Future<void> registrarGol() async {
    if (jugadorSeleccionadoId ==
        null) {
      mostrarMensaje(
        'Seleccione un jugador.',
        esError: true,
      );
      return;
    }

    int? minuto;

    if (minutoCtrl.text
        .trim()
        .isNotEmpty) {
      minuto =
          int.tryParse(
        minutoCtrl.text.trim(),
      );

      if (minuto == null ||
          minuto < 0 ||
          minuto > 300) {
        mostrarMensaje(
          'Ingrese un minuto válido.',
          esError: true,
        );
        return;
      }
    }

    setState(() {
      guardando = true;
    });

    try {
      final respuesta =
          await http.post(
        Uri.parse(
          '$baseUrl/api/goles',
        ),
        headers: {
          'Content-Type':
              'application/json',
          'Accept':
              'application/json',
          'Authorization':
              'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'partidoId':
              widget.partidoId,
          'jugadorId':
              jugadorSeleccionadoId,
          'minuto':
              minuto,
          'observacion':
              observacionCtrl.text
                      .trim()
                      .isEmpty
                  ? null
                  : observacionCtrl.text
                      .trim(),
        }),
      );

      if (respuesta.statusCode ==
              200 ||
          respuesta.statusCode ==
              201) {
        mostrarMensaje(
          'Gol registrado correctamente.',
        );

        jugadorSeleccionadoId =
            null;

        minutoCtrl.clear();
        observacionCtrl.clear();

        await cargarGoles();

        if (mounted) {
          setState(() {});
        }
      } else {
        String mensaje =
            'No fue posible registrar el gol.';

        try {
          final dynamic datos =
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
          guardando =
              false;
        });
      }
    }
  }

  Future<void> confirmarEliminarGol(
    Map<String, dynamic> gol,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (
        context,
      ) {
        return AlertDialog(
          title:
              const Text(
            'Eliminar gol',
          ),
          content:
              Text(
            '¿Deseas eliminar el gol de '
            '${gol['jugador'] ?? 'este jugador'}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'CANCELAR',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text(
                'ELIMINAR',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await eliminarGol(
        int.parse(
          gol['id'].toString(),
        ),
      );
    }
  }

  Future<void> eliminarGol(
    int golId,
  ) async {
    try {
      final respuesta =
          await http.delete(
        Uri.parse(
          '$baseUrl/api/goles/$golId',
        ),
        headers: {
          'Accept':
              'application/json',
          'Authorization':
              'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode ==
          200) {
        mostrarMensaje(
          'Gol eliminado correctamente.',
        );

        await cargarGoles();

        if (mounted) {
          setState(() {});
        }
      } else {
        String mensaje =
            'No fue posible eliminar el gol.';

        try {
          final dynamic datos =
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
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
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
          title:
              const Text(
            'Goles del partido',
          ),
        ),
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets
                    .all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize
                      .min,
              children: [
                const Icon(
                  Icons
                      .error_outline,
                  size: 70,
                  color:
                      Colors.red,
                ),
                const SizedBox(
                  height: 18,
                ),
                Text(
                  error!,
                  textAlign:
                      TextAlign
                          .center,
                ),
                const SizedBox(
                  height: 20,
                ),
                FilledButton
                    .icon(
                  onPressed:
                      cargarTodo,
                  icon:
                      const Icon(
                    Icons.refresh,
                  ),
                  label:
                      const Text(
                    'REINTENTAR',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final local =
        nombreEquipo(
      partido?[
          'equipoLocal'],
    );

    final visitante =
        nombreEquipo(
      partido?[
          'equipoVisitante'],
    );

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF4F7FB,
      ),

      appBar: AppBar(
        title:
            const Text(
          'Goles del partido',
        ),
        centerTitle:
            true,
      ),

      body: RefreshIndicator(
        onRefresh:
            cargarTodo,
        child: ListView(
          padding:
              const EdgeInsets
                  .all(16),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(18),
                child: Column(
                  children: [
                    const Icon(
                      Icons
                          .sports_soccer,
                      size: 34,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      '$local vs $visitante',
                      textAlign:
                          TextAlign
                              .center,
                      style:
                          const TextStyle(
                        fontSize:
                            20,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    const Text(
                      'Registrar gol',
                      style:
                          TextStyle(
                        fontSize:
                            19,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    DropdownButtonFormField<int>(
                      value:
                          jugadorSeleccionadoId,
                      isExpanded:
                          true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Jugador',
                        prefixIcon:
                            Icon(
                          Icons.person,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      items:
                          jugadores.map(
                        (
                          jugador,
                        ) {
                          final id =
                              int.parse(
                            jugador['id']
                                .toString(),
                          );

                          final nombre =
                              nombreJugador(
                            jugador,
                          );

                          return DropdownMenuItem<int>(
                            value:
                                id,
                            child:
                                Text(
                              nombre,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged:
                          guardando
                              ? null
                              : (
                                  valor,
                                ) {
                                  setState(
                                    () {
                                      jugadorSeleccionadoId =
                                          valor;
                                    },
                                  );
                                },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextFormField(
                      controller:
                          minutoCtrl,
                      keyboardType:
                          TextInputType
                              .number,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Minuto',
                        prefixIcon:
                            Icon(
                          Icons.timer,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextFormField(
                      controller:
                          observacionCtrl,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Observación',
                        prefixIcon:
                            Icon(
                          Icons.notes,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    SizedBox(
                      height: 50,
                      child:
                          FilledButton
                              .icon(
                        onPressed:
                            guardando
                                ? null
                                : registrarGol,
                        icon:
                            guardando
                                ? const SizedBox(
                                    width:
                                        20,
                                    height:
                                        20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .add,
                                  ),
                        label:
                            Text(
                          guardando
                              ? 'GUARDANDO...'
                              : 'REGISTRAR GOL',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            Text(
              'Goles registrados (${goles.length})',
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight
                        .bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            if (goles
                .isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets
                          .all(20),
                  child: Text(
                    'No hay goles registrados para este partido.',
                    textAlign:
                        TextAlign
                            .center,
                  ),
                ),
              )
            else
              ...goles.map(
                (
                  gol,
                ) {
                  final minuto =
                      gol['minuto'];

                  final equipo =
                      gol['equipo']
                              ?.toString() ??
                          '';

                  final observacion =
                      gol['observacion']
                              ?.toString()
                              .trim() ??
                          '';

                  return Card(
                    child:
                        ListTile(
                      leading:
                          const CircleAvatar(
                        child:
                            Icon(
                          Icons
                              .sports_soccer,
                        ),
                      ),
                      title:
                          Text(
                        gol['jugador']
                                ?.toString() ??
                            'Jugador',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      subtitle:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          if (equipo
                              .isNotEmpty)
                            Text(
                              equipo,
                            ),

                          if (minuto !=
                              null)
                            Text(
                              'Minuto: $minuto',
                            ),

                          if (observacion
                              .isNotEmpty)
                            Text(
                              observacion,
                            ),
                        ],
                      ),
                      trailing:
                          IconButton(
                        tooltip:
                            'Eliminar gol',
                        onPressed:
                            () {
                          confirmarEliminarGol(
                            gol,
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .delete_outline,
                          color:
                              Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
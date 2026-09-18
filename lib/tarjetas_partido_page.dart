import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TarjetasPartidoPage extends StatefulWidget {
  final int partidoId;
  final String token;

  const TarjetasPartidoPage({
    super.key,
    required this.partidoId,
    required this.token,
  });

  @override
  State<TarjetasPartidoPage> createState() =>
      _TarjetasPartidoPageState();
}

class _TarjetasPartidoPageState
    extends State<TarjetasPartidoPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  bool cargando = true;
  bool guardando = false;

  String? error;

  Map<String, dynamic>? partido;

  List<Map<String, dynamic>> tarjetas = [];
  List<Map<String, dynamic>> jugadores = [];

  int? jugadorSeleccionadoId;
  String tipoSeleccionado = 'AMARILLA';

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
      await cargarTarjetas();
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
      cargarJugadoresEquipo(localId),
      cargarJugadoresEquipo(visitanteId),
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
          '_equipoNombre': nombreLocal,
        };
      },
    ).toList();

    final jugadoresVisitante =
        resultados[1].map(
      (jugador) {
        return <String, dynamic>{
          ...jugador,
          '_equipoNombre': nombreVisitante,
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

  Future<void> cargarTarjetas() async {
    final respuesta =
        await http.get(
      Uri.parse(
        '$baseUrl/api/tarjetas/partido/${widget.partidoId}',
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
        'Error cargando tarjetas',
      );
    }

    final dynamic datos =
        jsonDecode(
      respuesta.body,
    );

    if (datos is Map<String, dynamic> &&
        datos['tarjetas'] is List) {
      tarjetas =
          (datos['tarjetas'] as List)
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
        content: Text(
          mensaje,
        ),
        backgroundColor:
            esError
                ? Colors.red.shade700
                : Colors.green.shade700,
      ),
    );
  }

  Future<void> registrarTarjeta() async {
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
          '$baseUrl/api/tarjetas',
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
          'tipo':
              tipoSeleccionado,
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
          'Tarjeta registrada correctamente.',
        );

        jugadorSeleccionadoId =
            null;

        tipoSeleccionado =
            'AMARILLA';

        minutoCtrl.clear();
        observacionCtrl.clear();

        await cargarTarjetas();

        if (mounted) {
          setState(() {});
        }
      } else {
        String mensaje =
            'No fue posible registrar la tarjeta.';

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

  Future<void> confirmarEliminarTarjeta(
    Map<String, dynamic> tarjeta,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar tarjeta',
          ),
          content: Text(
            '¿Deseas eliminar la tarjeta '
            '${tarjeta['tipo'] ?? ''} de '
            '${tarjeta['jugador'] ?? 'este jugador'}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
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
              child: const Text(
                'ELIMINAR',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await eliminarTarjeta(
        int.parse(
          tarjeta['id'].toString(),
        ),
      );
    }
  }

  Future<void> eliminarTarjeta(
    int tarjetaId,
  ) async {
    try {
      final respuesta =
          await http.delete(
        Uri.parse(
          '$baseUrl/api/tarjetas/$tarjetaId',
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
          'Tarjeta eliminada correctamente.',
        );

        await cargarTarjetas();

        if (mounted) {
          setState(() {});
        }
      } else {
        String mensaje =
            'No fue posible eliminar la tarjeta.';

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

  Widget iconoTipoTarjeta(
    String tipo,
  ) {
    final esRoja =
        tipo.toUpperCase() == 'ROJA';

    return Container(
      width: 28,
      height: 38,
      decoration: BoxDecoration(
        color:
            esRoja
                ? Colors.red
                : Colors.amber,
        borderRadius:
            BorderRadius.circular(
          4,
        ),
      ),
    );
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
          title: const Text(
            'Tarjetas del partido',
          ),
        ),
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(
                    24),
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
                  height: 18,
                ),
                Text(
                  error!,
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                  height: 20,
                ),
                FilledButton.icon(
                  onPressed:
                      cargarTodo,
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

    final local =
        nombreEquipo(
      partido?['equipoLocal'],
    );

    final visitante =
        nombreEquipo(
      partido?['equipoVisitante'],
    );

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF4F7FB,
      ),

      appBar: AppBar(
        title: const Text(
          'Tarjetas del partido',
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: cargarTodo,
        child: ListView(
          padding:
              const EdgeInsets.all(
                  16),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                        18),
                child: Column(
                  children: [
                    const Icon(
                      Icons.style,
                      size: 34,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      '$local vs $visitante',
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

            const SizedBox(
              height: 16,
            ),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                        18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Registrar tarjeta',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    DropdownButtonFormField<int>(
                      value:
                          jugadorSeleccionadoId,
                      isExpanded: true,
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

                          return DropdownMenuItem<
                              int>(
                            value: id,
                            child: Text(
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
                              : (valor) {
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

                    DropdownButtonFormField<
                        String>(
                      value:
                          tipoSeleccionado,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Tipo de tarjeta',
                        prefixIcon:
                            Icon(
                          Icons.style,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      items:
                          const [
                        DropdownMenuItem(
                          value:
                              'AMARILLA',
                          child:
                              Text(
                            'AMARILLA',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'ROJA',
                          child:
                              Text(
                            'ROJA',
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

                                  setState(
                                    () {
                                      tipoSeleccionado =
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
                                : registrarTarjeta,
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
                                    Icons.add,
                                  ),
                        label: Text(
                          guardando
                              ? 'GUARDANDO...'
                              : 'REGISTRAR TARJETA',
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
              'Tarjetas registradas (${tarjetas.length})',
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            if (tarjetas.isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(
                          20),
                  child: Text(
                    'No hay tarjetas registradas para este partido.',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              )
            else
              ...tarjetas.map(
                (
                  tarjeta,
                ) {
                  final tipo =
                      tarjeta['tipo']
                              ?.toString() ??
                          '';

                  final minuto =
                      tarjeta['minuto'];

                  final equipo =
                      tarjeta['equipo']
                              ?.toString() ??
                          '';

                  final observacion =
                      tarjeta[
                                  'observacion']
                              ?.toString()
                              .trim() ??
                          '';

                  return Card(
                    child: ListTile(
                      leading:
                          iconoTipoTarjeta(
                        tipo,
                      ),
                      title: Text(
                        tarjeta['jugador']
                                ?.toString() ??
                            'Jugador',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          if (equipo
                              .isNotEmpty)
                            Text(
                              equipo,
                            ),

                          Text(
                            'Tarjeta: $tipo',
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
                            'Eliminar tarjeta',
                        onPressed: () {
                          confirmarEliminarTarjeta(
                            tarjeta,
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
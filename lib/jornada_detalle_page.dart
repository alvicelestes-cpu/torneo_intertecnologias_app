import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'partido_detalle_page.dart';

class JornadaDetallePage extends StatefulWidget {
  final int numeroJornada;
  final String token;

  const JornadaDetallePage({
    super.key,
    required this.numeroJornada,
    required this.token,
  });

  @override
  State<JornadaDetallePage> createState() =>
      _JornadaDetallePageState();
}

class _JornadaDetallePageState extends State<JornadaDetallePage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  bool cargando = true;
  String? error;

  Map<String, dynamic>? jornada;
  List<dynamic> partidos = [];

  @override
  void initState() {
    super.initState();
    cargarJornada();
  }

  Future<void> cargarJornada() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http.get(
        Uri.parse(
          '$baseUrl/api/jornadas/${widget.numeroJornada}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos = jsonDecode(respuesta.body);

        if (datos is Map<String, dynamic>) {
          final listaPartidos = datos['partidos'];

          setState(() {
            jornada = datos;

            if (listaPartidos is List) {
              partidos = listaPartidos;
            } else {
              partidos = [];
            }
          });
        } else {
          setState(() {
            error =
                'La respuesta del servidor no tiene el formato esperado.';
          });
        }
      } else if (respuesta.statusCode == 401) {
        setState(() {
          error = 'Sesión no autorizada o token vencido.';
        });
      } else if (respuesta.statusCode == 404) {
        setState(() {
          error = 'La jornada no fue encontrada.';
        });
      } else {
        setState(() {
          error =
              'No fue posible cargar la jornada. Código ${respuesta.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        error = 'No se pudo conectar con el servidor.';
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  int obtenerEntero(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    return int.tryParse(
          valor?.toString() ?? '',
        ) ??
        0;
  }

  String formatearFase(dynamic fase) {
    if (fase == null) {
      return 'Sin fase';
    }

    final valor = fase
        .toString()
        .replaceAll('_', ' ')
        .trim();

    if (valor.isEmpty) {
      return 'Sin fase';
    }

    return valor;
  }

  String formatearFechaHora(dynamic fechaHora) {
    if (fechaHora == null) {
      return 'Fecha por definir';
    }

    final valor = fechaHora.toString().trim();

    if (valor.isEmpty) {
      return 'Fecha por definir';
    }

    final fecha = DateTime.tryParse(valor);

    if (fecha == null) {
      return valor;
    }

    final dia =
        fecha.day.toString().padLeft(2, '0');

    final mes =
        fecha.month.toString().padLeft(2, '0');

    final anio = fecha.year.toString();

    final hora =
        fecha.hour.toString().padLeft(2, '0');

    final minuto =
        fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio - $hora:$minuto';
  }

  String obtenerMarcador(
    Map<String, dynamic> partido,
  ) {
    final golesLocal =
        partido['golesLocal'];

    final golesVisitante =
        partido['golesVisitante'];

    if (golesLocal == null ||
        golesVisitante == null) {
      return '-';
    }

    return '$golesLocal - $golesVisitante';
  }

  Color obtenerColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'FINALIZADA':
      case 'FINALIZADO':
        return Colors.green;

      case 'EN_CURSO':
        return Colors.orange;

      case 'PROGRAMADA':
      case 'PROGRAMADO':
        return Colors.blue;

      case 'CANCELADA':
      case 'CANCELADO':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  Widget datoResumen(
    IconData icono,
    String titulo,
    int valor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              size: 25,
            ),
            const SizedBox(height: 6),
            Text(
              valor.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> abrirPartido(int partidoId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartidoDetallePage(
          partidoId: partidoId,
          token: widget.token,
        ),
      ),
    );

    if (mounted) {
      await cargarJornada();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Jornada ${widget.numeroJornada}',
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Jornada ${widget.numeroJornada}',
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 70,
                  color: Colors.red,
                ),
                const SizedBox(height: 18),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: cargarJornada,
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

    if (jornada == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Jornada ${widget.numeroJornada}',
          ),
        ),
        body: const Center(
          child: Text(
            'No hay información de la jornada.',
          ),
        ),
      );
    }

    final numero =
        jornada!['jornada']?.toString() ??
            widget.numeroJornada.toString();

    final estado =
        jornada!['estado']
                ?.toString()
                .trim() ??
            'SIN ESTADO';

    final cantidadPartidos =
        obtenerEntero(
      jornada!['cantidadPartidos'],
    );

    final finalizados =
        obtenerEntero(
      jornada!['partidosFinalizados'],
    );

    final programados =
        obtenerEntero(
      jornada!['partidosProgramados'],
    );

    final cancelados =
        obtenerEntero(
      jornada!['partidosCancelados'],
    );

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: Text(
          'Jornada $numero',
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: cargarJornada,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: Text(
                            numero,
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Jornada $numero',
                                style:
                                    const TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      obtenerColorEstado(
                                    estado,
                                  ).withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(20),
                                ),
                                child: Text(
                                  estado,
                                  style: TextStyle(
                                    color:
                                        obtenerColorEstado(
                                      estado,
                                    ),
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        datoResumen(
                          Icons.sports_soccer,
                          'Partidos',
                          cantidadPartidos,
                        ),
                        const SizedBox(width: 8),
                        datoResumen(
                          Icons.check_circle,
                          'Finalizados',
                          finalizados,
                        ),
                        const SizedBox(width: 8),
                        datoResumen(
                          Icons.schedule,
                          'Programados',
                          programados,
                        ),
                        const SizedBox(width: 8),
                        datoResumen(
                          Icons.cancel,
                          'Cancelados',
                          cancelados,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'Partidos de la jornada',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            if (partidos.isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No hay partidos registrados en esta jornada.',
                    ),
                  ),
                ),
              ),

            ...partidos.map((item) {
              final partido =
                  Map<String, dynamic>.from(
                item,
              );

              final partidoId =
                  obtenerEntero(
                partido['id'],
              );

              final local =
                  partido['equipoLocal']
                          ?.toString()
                          .trim() ??
                      'Equipo local';

              final visitante =
                  partido['equipoVisitante']
                          ?.toString()
                          .trim() ??
                      'Equipo visitante';

              final fase =
                  formatearFase(
                partido['fase'],
              );

              final fechaHora =
                  formatearFechaHora(
                partido['fechaHora'],
              );

              final estadoPartido =
                  partido['estado']
                          ?.toString()
                          .trim() ??
                      'SIN ESTADO';

              final marcador =
                  obtenerMarcador(
                partido,
              );

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Card(
                  elevation: 2,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(
                            12),
                    onTap: partidoId > 0
                        ? () {
                            abrirPartido(
                              partidoId,
                            );
                          }
                        : null,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                              18),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  fase,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.black54,
                                  ),
                                ),
                              ),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      obtenerColorEstado(
                                    estadoPartido,
                                  ).withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(20),
                                ),
                                child: Text(
                                  estadoPartido,
                                  style: TextStyle(
                                    color:
                                        obtenerColorEstado(
                                      estadoPartido,
                                    ),
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            fechaHora,
                            style:
                                const TextStyle(
                              color:
                                  Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  local,
                                  textAlign:
                                      TextAlign.right,
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFEAF2FB,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(10),
                                ),
                                child: Text(
                                  marcador,
                                  style:
                                      const TextStyle(
                                    fontSize: 19,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Text(
                                  visitante,
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              const Icon(
                                Icons.chevron_right,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
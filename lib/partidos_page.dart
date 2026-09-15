import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'partido_detalle_page.dart';

class PartidosPage extends StatefulWidget {
  final String token;

  const PartidosPage({
    super.key,
    required this.token,
  });

  @override
  State<PartidosPage> createState() => _PartidosPageState();
}

class _PartidosPageState extends State<PartidosPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  bool cargando = true;
  String? error;

  List<dynamic> partidos = [];

  @override
  void initState() {
    super.initState();
    cargarPartidos();
  }

  Future<void> cargarPartidos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http.get(
        Uri.parse('$baseUrl/api/partidos'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos = jsonDecode(respuesta.body);

        if (datos is List) {
          setState(() {
            partidos = datos;
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
      } else {
        setState(() {
          error =
              'No fue posible cargar los partidos. Código ${respuesta.statusCode}.';
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

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio - $hora:$minuto';
  }

  String formatearFase(dynamic fase) {
    if (fase == null) {
      return 'Sin fase';
    }

    return fase
        .toString()
        .replaceAll('_', ' ')
        .trim();
  }

  String obtenerMarcador(
    Map<String, dynamic> partido,
  ) {
    final golesLocal = partido['golesLocal'];
    final golesVisitante = partido['golesVisitante'];

    if (golesLocal == null || golesVisitante == null) {
      return '-';
    }

    return '$golesLocal - $golesVisitante';
  }

  Color obtenerColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'FINALIZADO':
        return Colors.green;

      case 'EN_CURSO':
        return Colors.orange;

      case 'PROGRAMADO':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  int? obtenerPartidoId(
    Map<String, dynamic> partido,
  ) {
    if (partido['id'] is int) {
      return partido['id'];
    }

    return int.tryParse(
      partido['id']?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text('Partidos'),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: cargarPartidos,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (error != null) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),

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
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: FilledButton.icon(
                      onPressed: cargarPartidos,
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label: const Text(
                        'REINTENTAR',
                      ),
                    ),
                  ),
                ],
              );
            }

            if (partidos.isEmpty) {
              return const Center(
                child: Text(
                  'No hay partidos registrados.',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),

              itemCount: partidos.length,

              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),

              itemBuilder: (context, index) {
                final partido =
                    Map<String, dynamic>.from(
                  partidos[index],
                );

                final partidoId =
                    obtenerPartidoId(partido);

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

                final estado =
                    partido['estado']
                            ?.toString()
                            .trim() ??
                        'SIN ESTADO';

                final jornada =
                    partido['jornada']?.toString() ??
                        '-';

                final fase =
                    formatearFase(
                  partido['fase'],
                );

                final fechaHora =
                    formatearFechaHora(
                  partido['fechaHora'],
                );

                final marcador =
                    obtenerMarcador(partido);

                return Card(
                  elevation: 2,

                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(12),

                    onTap: () {
                      if (partidoId == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'El partido no tiene un ID válido.',
                            ),
                          ),
                        );

                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PartidoDetallePage(
                            partidoId: partidoId,
                            token: widget.token,
                          ),
                        ),
                      );
                    },

                    child: Padding(
                      padding:
                          const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Jornada $jornada',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),

                              Text(
                                fase,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.black54,
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

                              const SizedBox(width: 16),

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
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: Text(
                                  visitante,
                                  textAlign:
                                      TextAlign.left,
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              const Spacer(),

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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
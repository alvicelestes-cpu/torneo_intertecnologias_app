import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'jornada_detalle_page.dart';

class JornadasPage extends StatefulWidget {
  final String token;

  const JornadasPage({
    super.key,
    required this.token,
  });

  @override
  State<JornadasPage> createState() => _JornadasPageState();
}

class _JornadasPageState extends State<JornadasPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  bool cargando = true;
  String? error;

  int cantidadJornadas = 0;
  List<dynamic> jornadas = [];

  @override
  void initState() {
    super.initState();
    cargarJornadas();
  }

  Future<void> cargarJornadas() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http.get(
        Uri.parse('$baseUrl/api/jornadas'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos = jsonDecode(respuesta.body);

        if (datos is Map<String, dynamic>) {
          final lista = datos['jornadas'];

          if (lista is List) {
            setState(() {
              cantidadJornadas =
                  datos['cantidadJornadas'] is int
                      ? datos['cantidadJornadas']
                      : int.tryParse(
                            datos['cantidadJornadas']?.toString() ?? '',
                          ) ??
                          lista.length;

              jornadas = lista;
            });
          } else {
            setState(() {
              error =
                  'La respuesta no contiene una lista válida de jornadas.';
            });
          }
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
              'No fue posible cargar las jornadas. Código ${respuesta.statusCode}.';
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

  Color obtenerColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'FINALIZADA':
        return Colors.green;

      case 'EN_CURSO':
        return Colors.orange;

      case 'PROGRAMADA':
        return Colors.blue;

      case 'CANCELADA':
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              valor.toString(),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> abrirJornada(
    int numeroJornada,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JornadaDetallePage(
          numeroJornada: numeroJornada,
          token: widget.token,
        ),
      ),
    );

    if (mounted) {
      await cargarJornadas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text('Jornadas'),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: cargarJornadas,
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
                      onPressed: cargarJornadas,
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

            if (jornadas.isEmpty) {
              return const Center(
                child: Text(
                  'No hay jornadas registradas.',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          child: Icon(
                            Icons.calendar_month,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total de jornadas',
                                style: TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                cantidadJornadas.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                ...jornadas.map((item) {
                  final jornada =
                      Map<String, dynamic>.from(item);

                  final numero =
                      obtenerEntero(
                    jornada['jornada'],
                  );

                  final cantidadPartidos =
                      obtenerEntero(
                    jornada['cantidadPartidos'],
                  );

                  final finalizados =
                      obtenerEntero(
                    jornada['partidosFinalizados'],
                  );

                  final programados =
                      obtenerEntero(
                    jornada['partidosProgramados'],
                  );

                  final cancelados =
                      obtenerEntero(
                    jornada['partidosCancelados'],
                  );

                  final conFecha =
                      obtenerEntero(
                    jornada['partidosConFecha'],
                  );

                  final sinFecha =
                      obtenerEntero(
                    jornada['partidosSinFecha'],
                  );

                  final estado =
                      jornada['estado']
                              ?.toString()
                              .trim() ??
                          'SIN ESTADO';

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: numero > 0
                            ? () {
                                abrirJornada(
                                  numero,
                                );
                              }
                            : null,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Jornada $numero',
                                      style:
                                          const TextStyle(
                                        fontSize: 20,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),

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
                                          BorderRadius.circular(
                                              20),
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

                              const SizedBox(height: 16),

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
                                ],
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  datoResumen(
                                    Icons.event_available,
                                    'Con fecha',
                                    conFecha,
                                  ),
                                  const SizedBox(width: 8),
                                  datoResumen(
                                    Icons.event_busy,
                                    'Sin fecha',
                                    sinFecha,
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
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
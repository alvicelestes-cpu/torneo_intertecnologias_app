import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GoleadoresPage extends StatefulWidget {
  final String token;

  const GoleadoresPage({
    super.key,
    required this.token,
  });

  @override
  State<GoleadoresPage> createState() => _GoleadoresPageState();
}

class _GoleadoresPageState extends State<GoleadoresPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  bool cargando = true;
  String? error;

  List<Map<String, dynamic>> goleadores = [];

  @override
  void initState() {
    super.initState();
    cargarGoleadores();
  }

  Future<void> cargarGoleadores() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http.get(
        Uri.parse('$baseUrl/api/goleadores'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos =
            jsonDecode(respuesta.body);

        if (datos is List) {
          final lista = datos
              .map(
                (item) => Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();

          if (mounted) {
            setState(() {
              goleadores = lista;
            });
          }

          await cargarFotosJugadores();
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
              'No fue posible cargar los goleadores. Código ${respuesta.statusCode}.';
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

  Future<void> cargarFotosJugadores() async {
    for (int i = 0; i < goleadores.length; i++) {
      final jugadorId =
          obtenerEntero(
        goleadores[i]['jugadorId'],
      );

      if (jugadorId <= 0) {
        continue;
      }

      try {
        final respuesta = await http.get(
          Uri.parse(
            '$baseUrl/api/jugadores/$jugadorId',
          ),
          headers: {
            'Accept': 'application/json',
            'Authorization':
                'Bearer ${widget.token}',
          },
        );

        if (respuesta.statusCode == 200) {
          final dynamic datos =
              jsonDecode(respuesta.body);

          if (datos is Map<String, dynamic> &&
              datos['jugador']
                  is Map<String, dynamic>) {
            final jugador =
                Map<String, dynamic>.from(
              datos['jugador'],
            );

            final foto =
                jugador['fotoJugador']
                    ?.toString()
                    .trim();

            if (foto != null &&
                foto.isNotEmpty) {
              goleadores[i]['fotoJugador'] =
                  foto;
            }
          }
        }
      } catch (_) {
        // Si una foto falla, continuamos
        // con el resto de goleadores.
      }

      if (mounted) {
        setState(() {});
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

  String obtenerFotoUrl(
    dynamic fotoJugador,
  ) {
    if (fotoJugador == null) {
      return '';
    }

    final valor =
        fotoJugador.toString().trim();

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

  String obtenerIniciales(
    String jugador,
  ) {
    final partes = jugador
        .trim()
        .split(' ')
        .where(
          (parte) => parte.trim().isNotEmpty,
        )
        .toList();

    if (partes.isEmpty) {
      return 'JG';
    }

    if (partes.length == 1) {
      final nombre = partes.first;

      return nombre.length >= 2
          ? nombre.substring(0, 2).toUpperCase()
          : nombre.toUpperCase();
    }

    return '${partes[0][0]}${partes[1][0]}'
        .toUpperCase();
  }

  Color colorPosicion(int posicion) {
    switch (posicion) {
      case 1:
        return Colors.amber.shade700;

      case 2:
        return Colors.blueGrey;

      case 3:
        return Colors.brown.shade400;

      default:
        return Colors.blueGrey.shade100;
    }
  }

  Widget construirIniciales(
    String jugador,
  ) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        obtenerIniciales(jugador),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D4F7A),
        ),
      ),
    );
  }

  Widget construirFoto(
    Map<String, dynamic> goleador,
  ) {
    final jugador =
        goleador['jugador']
                ?.toString()
                .trim() ??
            'Jugador';

    final fotoUrl =
        obtenerFotoUrl(
      goleador['fotoJugador'],
    );

    if (fotoUrl.isEmpty) {
      return construirIniciales(
        jugador,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        fotoUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return construirIniciales(
            jugador,
          );
        },
      ),
    );
  }

  Widget construirPosicion(
    int posicion,
  ) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorPosicion(
          posicion,
        ),
        shape: BoxShape.circle,
      ),
      child: posicion <= 3
          ? Icon(
              posicion == 1
                  ? Icons.emoji_events
                  : Icons.workspace_premium,
              color: Colors.white,
            )
          : Text(
              posicion.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text(
          'Goleadores',
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: cargarGoleadores,
        child: Builder(
          builder: (context) {
            if (cargando &&
                goleadores.isEmpty) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (error != null) {
              return ListView(
                padding:
                    const EdgeInsets.all(24),
                children: [
                  const SizedBox(
                    height: 80,
                  ),

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
                    style:
                        const TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Center(
                    child:
                        FilledButton.icon(
                      onPressed:
                          cargarGoleadores,
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

            if (goleadores.isEmpty) {
              return const Center(
                child: Text(
                  'No hay goleadores registrados.',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              );
            }

            return ListView(
              padding:
                  const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                            18),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          child: Icon(
                            Icons.emoji_events,
                            size: 30,
                          ),
                        ),

                        const SizedBox(
                          width: 16,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Tabla de goleadores',
                                style:
                                    TextStyle(
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                '${goleadores.length} jugadores clasificados',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                ...goleadores.map(
                  (goleador) {
                    final posicion =
                        obtenerEntero(
                      goleador['posicion'],
                    );

                    final jugador =
                        goleador['jugador']
                                ?.toString()
                                .trim() ??
                            'Jugador sin nombre';

                    final equipo =
                        goleador['equipo']
                                ?.toString()
                                .trim() ??
                            'Sin equipo';

                    final sigla =
                        goleador['siglaEquipo']
                                ?.toString()
                                .trim() ??
                            '';

                    final numero =
                        goleador[
                            'numeroCamiseta'];

                    final goles =
                        obtenerEntero(
                      goleador['goles'],
                    );

                    return Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        bottom: 10,
                      ),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(16),
                          child: Row(
                            children: [
                              construirPosicion(
                                posicion,
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              construirFoto(
                                goleador,
                              ),

                              const SizedBox(
                                width: 16,
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      jugador,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            17,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      sigla.isEmpty
                                          ? equipo
                                          : '$equipo ($sigla)',
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors
                                                .black54,
                                      ),
                                    ),

                                    if (numero !=
                                        null)
                                      Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                          top: 3,
                                        ),
                                        child:
                                            Text(
                                          'Camiseta: $numero',
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors
                                                    .black54,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

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
                                          .circular(
                                              12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      goles
                                          .toString(),
                                      style:
                                          const TextStyle(
                                        fontSize: 24,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color: Color(
                                          0xFF1D4F7A,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'GOLES',
                                      style:
                                          TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                        color:
                                            Colors
                                                .black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
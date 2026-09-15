import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'jugador_detalle_page.dart';

class JugadoresEquipoPage extends StatefulWidget {
  final int equipoId;
  final String equipoNombre;
  final String token;

  const JugadoresEquipoPage({
    super.key,
    required this.equipoId,
    required this.equipoNombre,
    required this.token,
  });

  @override
  State<JugadoresEquipoPage> createState() =>
      _JugadoresEquipoPageState();
}

class _JugadoresEquipoPageState
    extends State<JugadoresEquipoPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  bool cargando = true;
  String? error;

  List<dynamic> jugadores = [];

  @override
  void initState() {
    super.initState();
    cargarJugadores();
  }

  Future<void> cargarJugadores() async {
    setState(() {
      cargando = true;
      error = null;
    });

    final url =
        '$baseUrl/api/equipos/${widget.equipoId}/jugadores';

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

        if (datos is Map<String, dynamic>) {
          final dynamic lista =
              datos['jugadores'];

          if (lista is List) {
            setState(() {
              jugadores = lista;
            });
          } else {
            setState(() {
              error =
                  'La respuesta no contiene una lista de jugadores.';
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
          error =
              'Sesión no autorizada o token vencido.';
        });
      } else {
        setState(() {
          error =
              'No fue posible cargar los jugadores. Código ${respuesta.statusCode}.';
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

  String obtenerFotoUrl(dynamic fotoJugador) {
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
      Map<String, dynamic> jugador) {
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

    String iniciales = '';

    if (nombres.isNotEmpty) {
      iniciales += nombres[0];
    }

    if (apellidos.isNotEmpty) {
      iniciales += apellidos[0];
    }

    if (iniciales.isEmpty) {
      return 'JG';
    }

    return iniciales.toUpperCase();
  }

  Widget construirFoto(
      Map<String, dynamic> jugador) {
    final fotoUrl =
        obtenerFotoUrl(
      jugador['fotoJugador'],
    );

    if (fotoUrl.isEmpty) {
      return construirIniciales(
        jugador,
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(14),
      child: Image.network(
        fotoUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return construirIniciales(
            jugador,
          );
        },
      ),
    );
  }

  Widget construirIniciales(
      Map<String, dynamic> jugador) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            const Color(0xFFEAF2FB),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Text(
        obtenerIniciales(jugador),
        style: const TextStyle(
          fontSize: 18,
          fontWeight:
              FontWeight.bold,
          color:
              Color(0xFF1D4F7A),
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
        title: Text(
          widget.equipoNombre,
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: cargarJugadores,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (error != null) {
              return ListView(
                padding:
                    const EdgeInsets.all(
                        24),
                children: [
                  const SizedBox(
                      height: 80),

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
                    style:
                        const TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(
                      height: 20),

                  Center(
                    child:
                        FilledButton.icon(
                      onPressed:
                          cargarJugadores,
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

            if (jugadores.isEmpty) {
              return const Center(
                child: Text(
                  'No hay jugadores registrados.',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding:
                  const EdgeInsets.all(
                      16),

              itemCount:
                  jugadores.length,

              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                          height: 10),

              itemBuilder:
                  (context, index) {
                final jugador =
                    Map<String, dynamic>.from(
                  jugadores[index],
                );

                final nombres =
                    jugador['nombres']
                            ?.toString() ??
                        '';

                final apellidos =
                    jugador['apellidos']
                            ?.toString() ??
                        '';

                final numero =
                    jugador['numeroCamiseta'];

                final posicion =
                    jugador['posicion']
                            ?.toString() ??
                        '';

                final estado =
                    jugador['estado']
                            ?.toString() ??
                        '';

                final nombreCompleto =
                    '$nombres $apellidos'
                        .trim();

                return Card(
                  elevation: 2,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(12),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JugadorDetallePage(
                            jugador: jugador,
                            equipoNombre:
                                widget.equipoNombre,
                            token:
                                widget.token,
                          ),
                        ),
                      );
                    },

                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                              14),

                      child: Row(
                        children: [
                          construirFoto(
                            jugador,
                          ),

                          const SizedBox(
                              width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  nombreCompleto
                                          .isEmpty
                                      ? 'Jugador sin nombre'
                                      : nombreCompleto,
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                    height: 5),

                                if (numero !=
                                    null)
                                  Text(
                                    'Camiseta: $numero',
                                  ),

                                if (posicion
                                    .isNotEmpty)
                                  Text(
                                    'Posición: $posicion',
                                  ),

                                if (estado
                                    .isNotEmpty)
                                  Text(
                                    'Estado: $estado',
                                    style:
                                        TextStyle(
                                      color:
                                          estado ==
                                                  'VALIDADO'
                                              ? Colors
                                                  .green
                                              : Colors
                                                  .orange,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.chevron_right,
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
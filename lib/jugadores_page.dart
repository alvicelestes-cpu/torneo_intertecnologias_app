import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'jugador_detalle_page.dart';

class JugadoresPage extends StatefulWidget {
  final String token;

  const JugadoresPage({
    super.key,
    required this.token,
  });

  @override
  State<JugadoresPage> createState() => _JugadoresPageState();
}

class _JugadoresPageState extends State<JugadoresPage> {
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

    try {
      final respuesta = await http.get(
        Uri.parse('$baseUrl/api/jugadores'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos = jsonDecode(respuesta.body);

        if (datos is List) {
          setState(() {
            jugadores = datos;
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
              'No fue posible cargar los jugadores. Código ${respuesta.statusCode}.';
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

  String obtenerFotoUrl(dynamic fotoJugador) {
    if (fotoJugador == null) {
      return '';
    }

    final valor = fotoJugador.toString().trim();

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
    Map<String, dynamic> jugador,
  ) {
    final nombres =
        jugador['nombres']?.toString().trim() ?? '';

    final apellidos =
        jugador['apellidos']?.toString().trim() ?? '';

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

  Widget construirIniciales(
    Map<String, dynamic> jugador,
  ) {
    return Container(
      width: 62,
      height: 62,
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
    Map<String, dynamic> jugador,
  ) {
    final fotoUrl =
        obtenerFotoUrl(jugador['fotoJugador']);

    if (fotoUrl.isEmpty) {
      return construirIniciales(jugador);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        fotoUrl,
        width: 62,
        height: 62,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return construirIniciales(jugador);
        },
      ),
    );
  }

  String obtenerEquipoNombre(
    Map<String, dynamic> jugador,
  ) {
    final equipo = jugador['equipo'];

    // GET /api/jugadores devuelve:
    // "equipo": "GREMIO HFC"
    if (equipo is String &&
        equipo.trim().isNotEmpty) {
      return equipo.trim();
    }

    // Compatibilidad con respuestas donde
    // "equipo" venga como objeto.
    if (equipo is Map<String, dynamic>) {
      final nombre =
          equipo['nombre']?.toString().trim();

      if (nombre != null &&
          nombre.isNotEmpty) {
        return nombre;
      }
    }

    final equipoNombre =
        jugador['equipoNombre']
            ?.toString()
            .trim();

    if (equipoNombre != null &&
        equipoNombre.isNotEmpty) {
      return equipoNombre;
    }

    return 'Sin equipo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text('Jugadores'),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: cargarJugadores,
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
                      onPressed: cargarJugadores,
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
              padding: const EdgeInsets.all(16),

              itemCount: jugadores.length,

              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),

              itemBuilder: (context, index) {
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

                final nombreCompleto =
                    '$nombres $apellidos'.trim();

                final estado =
                    jugador['estado']
                            ?.toString() ??
                        '';

                final equipoNombre =
                    obtenerEquipoNombre(jugador);

                return Card(
                  elevation: 2,

                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(12),

                    onTap: () async {
                      final actualizado =
                          await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JugadorDetallePage(
                            jugador: jugador,
                            equipoNombre:
                                equipoNombre,
                            token:
                                widget.token,
                          ),
                        ),
                      );

                      if (actualizado == true &&
                          mounted) {
                        await cargarJugadores();
                      }
                    },

                    child: Padding(
                      padding:
                          const EdgeInsets.all(14),

                      child: Row(
                        children: [
                          construirFoto(jugador),

                          const SizedBox(width: 14),

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
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  equipoNombre,
                                  style:
                                      const TextStyle(
                                    fontSize: 15,
                                    color:
                                        Colors.black54,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                if (estado.isNotEmpty)
                                  Text(
                                    'Estado: $estado',
                                    style: TextStyle(
                                      color:
                                          estado ==
                                                  'VALIDADO'
                                              ? Colors.green
                                              : Colors.orange,
                                      fontWeight:
                                          FontWeight.w600,
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
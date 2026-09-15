import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PosicionesPage extends StatefulWidget {
  final String token;

  const PosicionesPage({
    super.key,
    required this.token,
  });

  @override
  State<PosicionesPage> createState() => _PosicionesPageState();
}

class _PosicionesPageState extends State<PosicionesPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  bool cargando = true;
  String? error;
  List<dynamic> posiciones = [];

  @override
  void initState() {
    super.initState();
    cargarPosiciones();
  }

  Future<void> cargarPosiciones() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http.get(
        Uri.parse('$baseUrl/api/posiciones'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos = jsonDecode(respuesta.body);

        if (datos is List) {
          setState(() {
            posiciones = datos;
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
              'No fue posible cargar las posiciones. Código ${respuesta.statusCode}.';
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

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  String diferenciaGol(dynamic valor) {
    final diferencia = obtenerEntero(valor);

    if (diferencia > 0) {
      return '+$diferencia';
    }

    return diferencia.toString();
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

  Widget encabezado(
    String texto, {
    double ancho = 50,
    TextAlign alineacion = TextAlign.center,
  }) {
    return SizedBox(
      width: ancho,
      child: Text(
        texto,
        textAlign: alineacion,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget dato(
    String texto, {
    double ancho = 50,
    bool negrita = false,
    TextAlign alineacion = TextAlign.center,
  }) {
    return SizedBox(
      width: ancho,
      child: Text(
        texto,
        textAlign: alineacion,
        style: TextStyle(
          fontSize: 14,
          fontWeight:
              negrita ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget construirEncabezado() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          encabezado('POS', ancho: 45),
          encabezado(
            'EQUIPO',
            ancho: 180,
            alineacion: TextAlign.left,
          ),
          encabezado('PJ'),
          encabezado('PG'),
          encabezado('PE'),
          encabezado('PP'),
          encabezado('GF'),
          encabezado('GC'),
          encabezado('DG'),
          encabezado('PTS', ancho: 60),
        ],
      ),
    );
  }

  Widget construirFila(Map<String, dynamic> equipo) {
    final posicion =
        obtenerEntero(equipo['posicion']);

    final nombre =
        equipo['equipo']?.toString().trim() ??
            'Sin equipo';

    final sigla =
        equipo['sigla']?.toString().trim() ?? '';

    final pj = obtenerEntero(equipo['pj']);
    final pg = obtenerEntero(equipo['pg']);
    final pe = obtenerEntero(equipo['pe']);
    final pp = obtenerEntero(equipo['pp']);
    final gf = obtenerEntero(equipo['gf']);
    final gc = obtenerEntero(equipo['gc']);
    final dg = diferenciaGol(equipo['dg']);
    final puntos = obtenerEntero(equipo['puntos']);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black12,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorPosicion(posicion),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  posicion.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: posicion <= 3
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (sigla.isNotEmpty)
                  Text(
                    sigla,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),

          dato(pj.toString()),
          dato(pg.toString()),
          dato(pe.toString()),
          dato(pp.toString()),
          dato(gf.toString()),
          dato(gc.toString()),
          dato(dg),

          dato(
            puntos.toString(),
            ancho: 60,
            negrita: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text(
          'Tabla de posiciones',
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: cargarPosiciones,
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
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: FilledButton.icon(
                      onPressed: cargarPosiciones,
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

            if (posiciones.isEmpty) {
              return const Center(
                child: Text(
                  'No hay posiciones disponibles.',
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
                          radius: 27,
                          child: Icon(
                            Icons.emoji_events,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Clasificación general',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '${posiciones.length} equipos en competencia',
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 685,
                        child: Column(
                          children: [
                            construirEncabezado(),

                            ...posiciones.map(
                              (item) {
                                final equipo =
                                    Map<String, dynamic>.from(
                                  item,
                                );

                                return construirFila(
                                  equipo,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'PJ: Jugados  •  PG: Ganados  •  PE: Empatados  •  PP: Perdidos  •  GF: Goles a favor  •  GC: Goles en contra  •  DG: Diferencia de gol  •  PTS: Puntos',
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EstadisticasPage extends StatefulWidget {
  final String token;

  const EstadisticasPage({
    super.key,
    required this.token,
  });

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  bool cargando = true;
  String? error;

  Map<String, dynamic>? estadisticas;

  @override
  void initState() {
    super.initState();
    cargarEstadisticas();
  }

  Future<void> cargarEstadisticas() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http.get(
        Uri.parse('$baseUrl/api/estadisticas'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos = jsonDecode(respuesta.body);

        if (datos is Map<String, dynamic>) {
          setState(() {
            estadisticas = datos;
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
              'No fue posible cargar las estadísticas. Código ${respuesta.statusCode}.';
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

  String obtenerFotoUrl(dynamic fotoJugador) {
    if (fotoJugador == null) {
      return '';
    }

    final valor = fotoJugador.toString().trim();

    if (valor.isEmpty || valor.toLowerCase() == 'string') {
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

  Widget tarjetaEquipo(
    String titulo,
    Map<String, dynamic>? equipo,
    IconData icono,
  ) {
    if (equipo == null) {
      return const SizedBox.shrink();
    }

    final nombre =
        equipo['nombre']?.toString().trim() ?? 'Sin equipo';

    final sigla =
        equipo['sigla']?.toString().trim() ?? '';

    final partidos =
        obtenerEntero(equipo['partidosJugados']);

    final golesFavor =
        obtenerEntero(equipo['golesFavor']);

    final golesContra =
        obtenerEntero(equipo['golesContra']);

    final diferencia =
        obtenerEntero(equipo['diferenciaGol']);

    final amarillas =
        obtenerEntero(equipo['amarillas']);

    final rojas =
        obtenerEntero(equipo['rojas']);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(icono),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (sigla.isNotEmpty)
              Text(
                sigla,
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                Text('PJ: $partidos'),
                Text('GF: $golesFavor'),
                Text('GC: $golesContra'),
                Text(
                  'DG: ${diferencia > 0 ? '+' : ''}$diferencia',
                ),
                Text('Amarillas: $amarillas'),
                Text('Rojas: $rojas'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget tarjetaGoleador(
    Map<String, dynamic>? goleador,
  ) {
    if (goleador == null) {
      return const SizedBox.shrink();
    }

    final nombres =
        goleador['nombres']?.toString().trim() ?? '';

    final apellidos =
        goleador['apellidos']?.toString().trim() ?? '';

    final nombreCompleto =
        '$nombres $apellidos'.trim();

    final equipo =
        goleador['equipoNombre']?.toString().trim() ??
            'Sin equipo';

    final goles =
        obtenerEntero(goleador['goles']);

    final fotoUrl =
        obtenerFotoUrl(goleador['fotoJugador']);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            if (fotoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  fotoUrl,
                  width: 82,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const CircleAvatar(
                      radius: 40,
                      child: Icon(
                        Icons.person,
                        size: 40,
                      ),
                    );
                  },
                ),
              )
            else
              const CircleAvatar(
                radius: 40,
                child: Icon(
                  Icons.person,
                  size: 40,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Goleador del torneo',
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nombreCompleto,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    equipo,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    goles.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4F7A),
                    ),
                  ),
                  const Text(
                    'GOLES',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tablaFairPlay(List<dynamic> fairPlay) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Equipo')),
              DataColumn(label: Text('PJ')),
              DataColumn(label: Text('Amarillas')),
              DataColumn(label: Text('Rojas')),
              DataColumn(label: Text('Puntos FP')),
            ],
            rows: fairPlay.map((item) {
              final equipo =
                  Map<String, dynamic>.from(item);

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      equipo['nombre']
                              ?.toString()
                              .trim() ??
                          'Sin equipo',
                    ),
                  ),
                  DataCell(
                    Text(
                      obtenerEntero(
                        equipo['partidosJugados'],
                      ).toString(),
                    ),
                  ),
                  DataCell(
                    Text(
                      obtenerEntero(
                        equipo['amarillas'],
                      ).toString(),
                    ),
                  ),
                  DataCell(
                    Text(
                      obtenerEntero(
                        equipo['rojas'],
                      ).toString(),
                    ),
                  ),
                  DataCell(
                    Text(
                      obtenerEntero(
                        equipo['puntosFairPlay'],
                      ).toString(),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Estadísticas'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: cargarEstadisticas,
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
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: FilledButton.icon(
                      onPressed: cargarEstadisticas,
                      icon: const Icon(Icons.refresh),
                      label: const Text('REINTENTAR'),
                    ),
                  ),
                ],
              );
            }

            if (estadisticas == null) {
              return const Center(
                child: Text(
                  'No hay estadísticas disponibles.',
                ),
              );
            }

            final valla =
                estadisticas!['vallaMenosVencida']
                        is Map<String, dynamic>
                    ? Map<String, dynamic>.from(
                        estadisticas!['vallaMenosVencida'],
                      )
                    : null;

            final goleador =
                estadisticas!['goleador']
                        is Map<String, dynamic>
                    ? Map<String, dynamic>.from(
                        estadisticas!['goleador'],
                      )
                    : null;

            final menosAmarillas =
                estadisticas!['menosAmarillas']
                        is Map<String, dynamic>
                    ? Map<String, dynamic>.from(
                        estadisticas!['menosAmarillas'],
                      )
                    : null;

            final menosRojas =
                estadisticas!['menosRojas']
                        is Map<String, dynamic>
                    ? Map<String, dynamic>.from(
                        estadisticas!['menosRojas'],
                      )
                    : null;

            final masGoleador =
                estadisticas!['equipoMasGoleador']
                        is Map<String, dynamic>
                    ? Map<String, dynamic>.from(
                        estadisticas!['equipoMasGoleador'],
                      )
                    : null;

            final mejorDiferencia =
                estadisticas!['mejorDiferenciaGol']
                        is Map<String, dynamic>
                    ? Map<String, dynamic>.from(
                        estadisticas!['mejorDiferenciaGol'],
                      )
                    : null;

            final fairPlay =
                estadisticas!['fairPlay'] is List
                    ? estadisticas!['fairPlay']
                        as List<dynamic>
                    : <dynamic>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: Icon(
                            Icons.bar_chart,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Resumen estadístico del torneo',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                tarjetaGoleador(goleador),

                const SizedBox(height: 12),

                tarjetaEquipo(
                  'Valla menos vencida',
                  valla,
                  Icons.shield,
                ),

                const SizedBox(height: 12),

                tarjetaEquipo(
                  'Equipo más goleador',
                  masGoleador,
                  Icons.sports_soccer,
                ),

                const SizedBox(height: 12),

                tarjetaEquipo(
                  'Mejor diferencia de gol',
                  mejorDiferencia,
                  Icons.trending_up,
                ),

                const SizedBox(height: 12),

                tarjetaEquipo(
                  'Menos tarjetas amarillas',
                  menosAmarillas,
                  Icons.style,
                ),

                const SizedBox(height: 12),

                tarjetaEquipo(
                  'Menos tarjetas rojas',
                  menosRojas,
                  Icons.block,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Fair Play',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                if (fairPlay.isNotEmpty)
                  tablaFairPlay(fairPlay)
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No hay datos de Fair Play.',
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
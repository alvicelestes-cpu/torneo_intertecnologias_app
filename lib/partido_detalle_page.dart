import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'editar_partido_page.dart';

class PartidoDetallePage extends StatefulWidget {
  final int partidoId;
  final String token;

  const PartidoDetallePage({
    super.key,
    required this.partidoId,
    required this.token,
  });

  @override
  State<PartidoDetallePage> createState() =>
      _PartidoDetallePageState();
}

class _PartidoDetallePageState
    extends State<PartidoDetallePage> {
  static const String baseUrl =
      'https://torneointertecnologias-production-7ae9.up.railway.app';

  bool cargando = true;
  String? error;

  Map<String, dynamic>? partido;
  Map<String, dynamic>? resumen;

  @override
  void initState() {
    super.initState();
    cargarPartido();
  }

  Future<void> cargarPartido() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http.get(
        Uri.parse(
          '$baseUrl/api/partidos/${widget.partidoId}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos =
            jsonDecode(respuesta.body);

        if (datos is Map<String, dynamic> &&
            datos['partido'] is Map<String, dynamic>) {
          setState(() {
            partido =
                Map<String, dynamic>.from(
              datos['partido'],
            );

            if (datos['resumen']
                is Map<String, dynamic>) {
              resumen =
                  Map<String, dynamic>.from(
                datos['resumen'],
              );
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
          error =
              'Sesión no autorizada o token vencido.';
        });
      } else if (respuesta.statusCode == 404) {
        setState(() {
          error =
              'Partido no encontrado.';
        });
      } else {
        setState(() {
          error =
              'No fue posible cargar el partido. Código ${respuesta.statusCode}.';
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

  String obtenerNombreEquipo(
    dynamic equipo,
    String valorDefecto,
  ) {
    if (equipo is Map<String, dynamic>) {
      final nombre =
          equipo['nombre']
              ?.toString()
              .trim();

      if (nombre != null &&
          nombre.isNotEmpty) {
        return nombre;
      }
    }

    if (equipo is String &&
        equipo.trim().isNotEmpty) {
      return equipo.trim();
    }

    return valorDefecto;
  }

  String formatearFechaHora(dynamic fechaHora) {
    if (fechaHora == null) {
      return 'Fecha por definir';
    }

    final valor =
        fechaHora.toString().trim();

    if (valor.isEmpty) {
      return 'Fecha por definir';
    }

    final fecha =
        DateTime.tryParse(valor);

    if (fecha == null) {
      return valor;
    }

    final dia =
        fecha.day.toString().padLeft(2, '0');

    final mes =
        fecha.month.toString().padLeft(2, '0');

    final anio =
        fecha.year.toString();

    final hora =
        fecha.hour.toString().padLeft(2, '0');

    final minuto =
        fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio - $hora:$minuto';
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

  String obtenerMarcador() {
    if (partido == null) {
      return '-';
    }

    final golesLocal =
        partido!['golesLocal'];

    final golesVisitante =
        partido!['golesVisitante'];

    if (golesLocal == null ||
        golesVisitante == null) {
      return '-';
    }

    return '$golesLocal - $golesVisitante';
  }

  Color obtenerColorEstado(
    String estado,
  ) {
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

  Widget filaDato(
    IconData icono,
    String titulo,
    String valor,
  ) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(icono),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> abrirEdicion() async {
    final actualizado =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPartidoPage(
          partidoId: widget.partidoId,
          token: widget.token,
        ),
      ),
    );

    if (actualizado == true && mounted) {
      await cargarPartido();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Detalle del partido',
          ),
        ),
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
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
                      cargarPartido,
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

    if (partido == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No hay información del partido.',
          ),
        ),
      );
    }

    final local =
        obtenerNombreEquipo(
      partido!['equipoLocal'],
      'Equipo local',
    );

    final visitante =
        obtenerNombreEquipo(
      partido!['equipoVisitante'],
      'Equipo visitante',
    );

    final estado =
        partido!['estado']
                ?.toString()
                .trim() ??
            'SIN ESTADO';

    final jornada =
        partido!['jornada']
                ?.toString() ??
            '-';

    final fase =
        formatearFase(
      partido!['fase'],
    );

    final llave =
        partido!['llave']
                ?.toString()
                .trim() ??
            '';

    final observaciones =
        partido!['observaciones']
                ?.toString()
                .trim() ??
            '';

    final fechaHora =
        formatearFechaHora(
      partido!['fechaHora'],
    );

    final marcador =
        obtenerMarcador();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text(
          'Detalle del partido',
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 700,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),

                    child: Column(
                      children: [
                        Text(
                          'Jornada $jornada',
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          fase,
                          style:
                              const TextStyle(
                            color:
                                Colors.black54,
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                local,
                                textAlign:
                                    TextAlign.center,
                                style:
                                    const TextStyle(
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFEAF2FB,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),
                              child: Text(
                                marcador,
                                style:
                                    const TextStyle(
                                  fontSize: 26,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            Expanded(
                              child: Text(
                                visitante,
                                textAlign:
                                    TextAlign.center,
                                style:
                                    const TextStyle(
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
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
                            style:
                                TextStyle(
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
                ),

                const SizedBox(
                  height: 18,
                ),

                filaDato(
                  Icons.calendar_month,
                  'Fecha y hora',
                  fechaHora,
                ),

                filaDato(
                  Icons.flag,
                  'Fase',
                  fase,
                ),

                filaDato(
                  Icons.numbers,
                  'Jornada',
                  jornada,
                ),

                if (llave.isNotEmpty)
                  filaDato(
                    Icons.account_tree,
                    'Llave',
                    llave,
                  ),

                filaDato(
                  Icons.info_outline,
                  'Estado',
                  estado,
                ),

                if (observaciones
                    .isNotEmpty)
                  filaDato(
                    Icons.notes,
                    'Observaciones',
                    observaciones,
                  ),

                const SizedBox(
                  height: 24,
                ),

                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed:
                        abrirEdicion,
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label: const Text(
                      'EDITAR PARTIDO',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
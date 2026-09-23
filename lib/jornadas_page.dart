import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'models/jornada.dart';
import 'services/jornadas_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/status_chip.dart';

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
  final JornadasService _jornadasService = JornadasService();

  bool cargando = true;
  String? error;
  int cantidadJornadas = 0;
  List<Jornada> jornadas = [];

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
      final res = await _jornadasService.getJornadas(token: widget.token);
      if (mounted) {
        setState(() {
          cantidadJornadas = res.cantidadJornadas;
          jornadas = res.jornadas;
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'No se pudo conectar con el servidor.');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Widget datoResumen(IconData icono, String titulo, int valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icono, size: 24, color: AppColors.primary),
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
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> abrirJornada(int numeroJornada) async {
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
      cargarJornadas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Jornadas'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: cargarJornadas,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarJornadas,
              );
            }

            if (jornadas.isEmpty) {
              return const AppEmptyView(
                message: 'No hay jornadas registradas.',
                icon: Icons.calendar_month_outlined,
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(Icons.calendar_month, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total de jornadas',
                                style: TextStyle(color: Colors.black54),
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
                ...jornadas.map((jornada) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: InkWell(
                        onTap: jornada.numero > 0 ? () => abrirJornada(jornada.numero) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Jornada ${jornada.numero}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  StatusChip(status: jornada.estado),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  datoResumen(Icons.sports_soccer, 'Partidos', jornada.cantidadPartidos),
                                  const SizedBox(width: 8),
                                  datoResumen(Icons.check_circle, 'Finalizados', jornada.partidosFinalizados),
                                  const SizedBox(width: 8),
                                  datoResumen(Icons.schedule, 'Programados', jornada.partidosProgramados),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  datoResumen(Icons.cancel, 'Cancelados', jornada.partidosCancelados),
                                  const SizedBox(width: 8),
                                  datoResumen(Icons.event_available, 'Con fecha', jornada.partidosConFecha),
                                  const SizedBox(width: 8),
                                  datoResumen(Icons.event_busy, 'Sin fecha', jornada.partidosSinFecha),
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
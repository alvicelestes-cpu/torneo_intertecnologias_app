import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'models/jornada.dart';
import 'models/partido.dart';
import 'services/jornadas_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/public_partido_row.dart';

import 'partido_detalle_page.dart';

class JornadaDetallePage extends StatefulWidget {
  final int numeroJornada;
  final String? token;

  const JornadaDetallePage({
    super.key,
    required this.numeroJornada,
    this.token,
  });

  @override
  State<JornadaDetallePage> createState() => _JornadaDetallePageState();
}

class _JornadaDetallePageState extends State<JornadaDetallePage> {
  final JornadasService _jornadasService = JornadasService();

  bool cargando = true;
  String? error;
  Jornada? jornada;

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
      final res = await _jornadasService.getJornadaDetalle(
        widget.numeroJornada,
        token: widget.token,
      );
      if (mounted) {
        setState(() {
          jornada = res;
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icono, size: 25, color: AppColors.primary),
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
              style: const TextStyle(color: Colors.black54, fontSize: 12),
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
      cargarJornada();
    }
  }

  Widget construirTarjetaPartido(int index, Partido partido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PublicPartidoRow(
        index: index,
        partido: partido,
        onTap: partido.id > 0 ? () => abrirPartido(partido.id) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Jornada ${widget.numeroJornada}'),
            ListenableBuilder(
              listenable: SessionManager(),
              builder: (context, _) => Text(
                SessionManager().selectedCampeonatoNombre,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: cargarJornada,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarJornada,
              );
            }

            final j = jornada;
            if (j == null) {
              return const AppEmptyView(
                message: 'No hay información de la jornada.',
                icon: Icons.calendar_today_outlined,
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0B3C68),
                          Color(0xFF1565C0),
                          Color(0xFF1E88E5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white24,
                              child: Text(
                                '${j.numero}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'PRIMERA FASE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jornada ${j.numero}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${j.cantidadPartidos} ${j.cantidadPartidos == 1 ? 'partido' : 'partidos'} • ${j.estado}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              datoResumen(Icons.sports_soccer, 'Partidos', j.cantidadPartidos),
                              const SizedBox(width: 6),
                              datoResumen(Icons.check_circle, 'Finalizados', j.partidosFinalizados),
                              const SizedBox(width: 6),
                              datoResumen(Icons.schedule, 'Programados', j.partidosProgramados),
                              const SizedBox(width: 6),
                              datoResumen(Icons.cancel, 'Cancelados', j.partidosCancelados),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Partidos de la jornada',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (j.partidos.isEmpty)
                  const AppEmptyView(
                    message: 'No hay partidos registrados en esta jornada.',
                    icon: Icons.sports_soccer_outlined,
                  )
                else
                  ...j.partidos.asMap().entries.map(
                        (entry) => construirTarjetaPartido(entry.key + 1, entry.value),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
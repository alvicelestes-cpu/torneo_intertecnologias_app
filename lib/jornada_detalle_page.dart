import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/text_utils.dart';
import 'models/jornada.dart';
import 'models/partido.dart';
import 'services/jornadas_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/status_chip.dart';

import 'partido_detalle_page.dart';

class JornadaDetallePage extends StatefulWidget {
  final int numeroJornada;
  final String token;

  const JornadaDetallePage({
    super.key,
    required this.numeroJornada,
    required this.token,
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

  Widget construirTarjetaPartido(Partido partido) {
    final fase = TextUtils.formatFase(partido.fase);
    final fechaHora = AppDateUtils.formatDateTime(partido.fechaHora);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: partido.id > 0 ? () => abrirPartido(partido.id) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fase,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    StatusChip(status: partido.estado),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        partido.equipoLocalNombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        partido.marcador,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        partido.equipoVisitanteNombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      fechaHora,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    if (partido.cancha != null && partido.cancha!.isNotEmpty) ...[
                      const SizedBox(width: 14),
                      const Icon(Icons.stadium_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        partido.cancha!,
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
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
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(Icons.calendar_month, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jornada ${j.numero}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  StatusChip(status: j.estado),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            datoResumen(Icons.sports_soccer, 'Partidos', j.cantidadPartidos),
                            const SizedBox(width: 8),
                            datoResumen(Icons.check_circle, 'Finalizados', j.partidosFinalizados),
                            const SizedBox(width: 8),
                            datoResumen(Icons.schedule, 'Programados', j.partidosProgramados),
                            const SizedBox(width: 8),
                            datoResumen(Icons.cancel, 'Cancelados', j.partidosCancelados),
                          ],
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
                  ...j.partidos.map(construirTarjetaPartido),
              ],
            );
          },
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/text_utils.dart';
import 'core/utils/ui_helpers.dart';
import 'models/partido.dart';
import 'services/partidos_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/status_chip.dart';

import 'partido_detalle_page.dart';

class PartidosPage extends StatefulWidget {
  final String token;

  const PartidosPage({
    super.key,
    required this.token,
  });

  @override
  State<PartidosPage> createState() => _PartidosPageState();
}

class _PartidosPageState extends State<PartidosPage> {
  final PartidosService _partidosService = PartidosService();

  bool cargando = true;
  String? error;
  List<Partido> partidos = [];

  @override
  void initState() {
    super.initState();
    cargarPartidos();
  }

  Future<void> cargarPartidos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final list = await _partidosService.getPartidos(token: widget.token);
      if (mounted) {
        setState(() {
          partidos = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Partidos'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: cargarPartidos,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarPartidos,
              );
            }

            if (partidos.isEmpty) {
              return const AppEmptyView(
                message: 'No hay partidos registrados.',
                icon: Icons.sports_soccer_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: partidos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final partido = partidos[index];
                final fase = TextUtils.formatFase(partido.fase);
                final fechaHora = AppDateUtils.formatDateTime(partido.fechaHora);
                final jornadaTexto = partido.jornada != null ? 'Jornada ${partido.jornada}' : '';

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      if (partido.id <= 0) {
                        UiHelpers.showError(context, 'El partido no tiene un ID válido.');
                        return;
                      }

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartidoDetallePage(
                            partidoId: partido.id,
                            token: widget.token,
                          ),
                        ),
                      );

                      if (mounted) {
                        cargarPartidos();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                [fase, jornadaTexto].where((t) => t.isNotEmpty).join(' • '),
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
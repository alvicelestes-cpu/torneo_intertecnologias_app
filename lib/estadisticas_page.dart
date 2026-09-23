import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'models/estadisticas.dart';
import 'services/torneo_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/campeonato_selector_bar.dart';
import 'widgets/player_avatar.dart';

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
  final TorneoService _torneoService = TorneoService();

  bool cargando = true;
  String? error;
  EstadisticasTorneo? estadisticas;

  @override
  void initState() {
    super.initState();
    SessionManager().addListener(_onSessionChanged);
    cargarEstadisticas();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) cargarEstadisticas();
  }

  Future<void> cargarEstadisticas() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final res = await _torneoService.getEstadisticas(token: widget.token);
      if (mounted) {
        setState(() {
          estadisticas = res;
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

  Widget tarjetaEquipo(String titulo, EquipoEstadistica? equipo, IconData icono) {
    if (equipo == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(icono, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              equipo.nombre,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            if (equipo.sigla.isNotEmpty)
              Text(
                equipo.sigla,
                style: const TextStyle(color: Colors.black54),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                Text('PJ: ${equipo.partidosJugados}'),
                Text('GF: ${equipo.golesFavor}'),
                Text('GC: ${equipo.golesContra}'),
                Text('DG: ${equipo.diferenciaGol > 0 ? '+' : ''}${equipo.diferenciaGol}'),
                Text('Amarillas: ${equipo.amarillas}'),
                Text('Rojas: ${equipo.rojas}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget tarjetaGoleador(GoleadorEstadistica? goleador) {
    if (goleador == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            PlayerAvatar(
              photoUrl: goleador.fotoJugador,
              playerName: goleador.nombreCompleto,
              radius: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Goleador del torneo',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goleador.nombreCompleto,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    goleador.equipoNombre,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    goleador.goles.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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

  Widget tablaFairPlay(List<EquipoFairPlay> fairPlay) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              return DataRow(
                cells: [
                  DataCell(Text(item.nombre)),
                  DataCell(Text(item.partidosJugados.toString())),
                  DataCell(Text(item.amarillas.toString())),
                  DataCell(Text(item.rojas.toString())),
                  DataCell(Text(item.puntosFairPlay.toString())),
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
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Estadísticas'),
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: CampeonatoSelectorBar(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cargarEstadisticas,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarEstadisticas,
              );
            }

            final stats = estadisticas;
            if (stats == null) {
              return const AppEmptyView(
                message: 'No hay estadísticas disponibles.',
                icon: Icons.bar_chart_outlined,
              );
            }

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
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(
                            Icons.bar_chart,
                            size: 30,
                            color: AppColors.primary,
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
                tarjetaGoleador(stats.goleador),
                const SizedBox(height: 12),
                tarjetaEquipo(
                  'Valla menos vencida',
                  stats.vallaMenosVencida,
                  Icons.shield,
                ),
                const SizedBox(height: 12),
                tarjetaEquipo(
                  'Equipo más goleador',
                  stats.equipoMasGoleador,
                  Icons.sports_soccer,
                ),
                const SizedBox(height: 12),
                tarjetaEquipo(
                  'Mejor diferencia de gol',
                  stats.mejorDiferenciaGol,
                  Icons.trending_up,
                ),
                const SizedBox(height: 12),
                tarjetaEquipo(
                  'Equipo con menos amarillas',
                  stats.menosAmarillas,
                  Icons.square,
                ),
                const SizedBox(height: 12),
                tarjetaEquipo(
                  'Equipo con menos rojas',
                  stats.menosRojas,
                  Icons.warning,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tabla Fair Play',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (stats.fairPlay.isNotEmpty)
                  tablaFairPlay(stats.fairPlay)
                else
                  const AppEmptyView(message: 'Sin registros de Fair Play.'),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
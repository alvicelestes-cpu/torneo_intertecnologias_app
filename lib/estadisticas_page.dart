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
  final String? token;

  const EstadisticasPage({
    super.key,
    this.token,
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

  Widget _buildStatChip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF1D4F7A)).withAlpha(18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? const Color(0xFF1D4F7A)).withAlpha(40),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF1D4F7A),
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget tarjetaEquipo({
    required String titulo,
    required EquipoEstadistica? equipo,
    required IconData icono,
    required Color iconoColor,
    required Color iconoBgColor,
  }) {
    if (equipo == null) return const SizedBox.shrink();

    final siglaTexto = equipo.sigla.isNotEmpty ? ' (${equipo.sigla})' : '';

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
                  radius: 20,
                  backgroundColor: iconoBgColor,
                  child: Icon(icono, color: iconoColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4F7A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${equipo.nombre}$siglaTexto',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatChip('PJ', equipo.partidosJugados.toString()),
                _buildStatChip('GF', equipo.golesFavor.toString()),
                _buildStatChip('GC', equipo.golesContra.toString()),
                _buildStatChip(
                  'DG',
                  '${equipo.diferenciaGol > 0 ? '+' : ''}${equipo.diferenciaGol}',
                ),
                _buildStatChip('Amarillas', equipo.amarillas.toString(), color: Colors.amber.shade800),
                _buildStatChip('Rojas', equipo.rojas.toString(), color: Colors.red.shade700),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.amber.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            PlayerAvatar(
              photoUrl: goleador.fotoJugador,
              playerName: goleador.nombreCompleto,
              radius: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events, size: 16, color: Colors.amber.shade800),
                      const SizedBox(width: 5),
                      Text(
                        'GOLEADOR DEL TORNEO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goleador.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goleador.equipoNombre,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    goleador.goles.toString(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4F7A),
                    ),
                  ),
                  const Text(
                    'GOLES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
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
            headingRowColor: WidgetStateProperty.all(const Color(0xFF1D4F7A).withAlpha(15)),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4F7A),
              fontSize: 13,
            ),
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
                  DataCell(Text(
                    item.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
                  DataCell(Text(item.partidosJugados.toString())),
                  DataCell(Text(
                    item.amarillas.toString(),
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(
                    item.rojas.toString(),
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(
                    item.puntosFairPlay.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4F7A),
                    ),
                  )),
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

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera deportiva azul
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
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.bar_chart, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'RESUMEN ESTADÍSTICO DEL TORNEO',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ListenableBuilder(
                                      listenable: SessionManager(),
                                      builder: (context, _) => Text(
                                        SessionManager().selectedCampeonatoNombre,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
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

                      // Goleador del torneo
                      tarjetaGoleador(stats.goleador),
                      const SizedBox(height: 12),

                      // Valla menos vencida
                      tarjetaEquipo(
                        titulo: 'Valla menos vencida',
                        equipo: stats.vallaMenosVencida,
                        icono: Icons.shield,
                        iconoColor: const Color(0xFF1D4F7A),
                        iconoBgColor: const Color(0xFFEAF2FB),
                      ),
                      const SizedBox(height: 12),

                      // Equipo más goleador
                      tarjetaEquipo(
                        titulo: 'Equipo más goleador',
                        equipo: stats.equipoMasGoleador,
                        icono: Icons.sports_soccer,
                        iconoColor: Colors.green.shade700,
                        iconoBgColor: Colors.green.shade50,
                      ),
                      const SizedBox(height: 12),

                      // Mejor diferencia de gol
                      tarjetaEquipo(
                        titulo: 'Mejor diferencia de gol',
                        equipo: stats.mejorDiferenciaGol,
                        icono: Icons.trending_up,
                        iconoColor: Colors.teal.shade700,
                        iconoBgColor: Colors.teal.shade50,
                      ),
                      const SizedBox(height: 12),

                      // Menos amarillas
                      tarjetaEquipo(
                        titulo: 'Equipo con menos amarillas',
                        equipo: stats.menosAmarillas,
                        icono: Icons.crop_portrait,
                        iconoColor: Colors.amber.shade800,
                        iconoBgColor: Colors.amber.shade50,
                      ),
                      const SizedBox(height: 12),

                      // Menos rojas
                      tarjetaEquipo(
                        titulo: 'Equipo con menos rojas',
                        equipo: stats.menosRojas,
                        icono: Icons.crop_portrait,
                        iconoColor: Colors.red.shade700,
                        iconoBgColor: Colors.red.shade50,
                      ),
                      const SizedBox(height: 20),

                      // Sección Fair Play
                      Row(
                        children: [
                          Icon(Icons.workspace_premium, color: Colors.blue.shade800, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Tabla Fair Play',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4F7A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (stats.fairPlay.isNotEmpty)
                        tablaFairPlay(stats.fairPlay)
                      else
                        const AppEmptyView(message: 'Sin registros de Fair Play.'),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
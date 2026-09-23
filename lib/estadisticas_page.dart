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
    final chipColor = color ?? const Color(0xFF0D233A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withAlpha(50), width: 1),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: chipColor,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w900),
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
      elevation: 2.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconoBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: iconoColor.withAlpha(80)),
                  ),
                  child: Icon(icono, color: iconoColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D233A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${equipo.nombre}$siglaTexto',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D233A),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatChip('PJ', equipo.partidosJugados.toString()),
                _buildStatChip('GF', equipo.golesFavor.toString(), color: const Color(0xFF16A34A)),
                _buildStatChip('GC', equipo.golesContra.toString(), color: const Color(0xFFDC2626)),
                _buildStatChip(
                  'DG',
                  '${equipo.diferenciaGol > 0 ? '+' : ''}${equipo.diferenciaGol}',
                  color: const Color(0xFF1565C0),
                ),
                _buildStatChip('Amarillas', equipo.amarillas.toString(), color: const Color(0xFFD97706)),
                _buildStatChip('Rojas', equipo.rojas.toString(), color: const Color(0xFFDC2626)),
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
      elevation: 2.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFDE68A), width: 1.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            PlayerAvatar(
              photoUrl: goleador.fotoJugador,
              playerName: goleador.nombreCompleto,
              radius: 34,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🥇 ', style: TextStyle(fontSize: 16)),
                      Text(
                        'MÁXIMO ARTILLERO',
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
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D233A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goleador.equipoNombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D233A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    goleador.goles.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'GOLES',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 0.5,
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

  Widget seccionFairPlay(List<EquipoFairPlay> lista) {
    if (lista.isEmpty) return const SizedBox.shrink();

    final lider = lista.first;

    return Card(
      elevation: 2.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF86EFAC), width: 1.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF16A34A)),
                  ),
                  child: const Icon(Icons.verified, color: Color(0xFF16A34A), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'PREMIO FAIR PLAY (JUEGO LIMPIO)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              lider.nombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D233A),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  'Puntos Fair Play',
                  lider.puntosFairPlay.toString(),
                  color: const Color(0xFF16A34A),
                ),
                _buildStatChip('PJ', lider.partidosJugados.toString()),
                _buildStatChip('Amarillas', lider.amarillas.toString(), color: const Color(0xFFD97706)),
                _buildStatChip('Rojas', lider.rojas.toString(), color: const Color(0xFFDC2626)),
              ],
            ),
            if (lista.length > 1) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),
              const Text(
                'Otros equipos destacados en Juego Limpio:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              ...lista.skip(1).take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.nombre,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.puntosFairPlay} pts',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
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

            final est = estadisticas;
            if (est == null) {
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
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera azul deportiva
                      Card(
                        elevation: 2.5,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0D233A),
                                Color(0xFF1565C0),
                                Color(0xFF1E88E5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.bar_chart,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'RENDIMIENTO Y DISTINCIONES',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      SessionManager().selectedCampeonatoNombre,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tarjeta Goleador
                      tarjetaGoleador(est.goleador),
                      const SizedBox(height: 12),

                      // Valla Menos Vencida
                      tarjetaEquipo(
                        titulo: 'VALLA MENOS VENCIDA',
                        equipo: est.vallaMenosVencida,
                        icono: Icons.security,
                        iconoColor: const Color(0xFF16A34A),
                        iconoBgColor: const Color(0xFFDCFCE7),
                      ),
                      const SizedBox(height: 12),

                      // Fair Play
                      seccionFairPlay(est.fairPlay),
                      const SizedBox(height: 12),

                      // Menos Amarillas
                      tarjetaEquipo(
                        titulo: 'EQUIPO CON MENOS AMARILLAS',
                        equipo: est.menosAmarillas,
                        icono: Icons.style,
                        iconoColor: const Color(0xFFD97706),
                        iconoBgColor: const Color(0xFFFEF3C7),
                      ),
                      const SizedBox(height: 12),

                      // Menos Rojas
                      tarjetaEquipo(
                        titulo: 'EQUIPO CON MENOS ROJAS',
                        equipo: est.menosRojas,
                        icono: Icons.style,
                        iconoColor: const Color(0xFFDC2626),
                        iconoBgColor: const Color(0xFFFEE2E2),
                      ),
                      const SizedBox(height: 24),
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
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'models/goleador.dart';
import 'services/torneo_config_service.dart';
import 'services/torneo_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/player_avatar.dart';
import 'widgets/public_navbar.dart';
import 'widgets/team_logo_avatar.dart';

class GoleadoresPage extends StatefulWidget {
  final String? token;

  const GoleadoresPage({
    super.key,
    this.token,
  });

  @override
  State<GoleadoresPage> createState() => _GoleadoresPageState();
}

class _GoleadoresPageState extends State<GoleadoresPage> {
  final TorneoService _torneoService = TorneoService();

  bool cargando = true;
  String? error;
  List<Goleador> goleadores = [];
  int get _topMax => TorneoConfigService().topGoleadoresMax;

  @override
  void initState() {
    super.initState();
    SessionManager().addListener(_onSessionChanged);
    cargarGoleadores();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) cargarGoleadores();
  }

  Future<void> cargarGoleadores() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final list = await _torneoService.getGoleadores(
        token: widget.token,
        cargarFotos: true,
      );
      // Restricción reglamentaria dinámica: Exclusivamente el Top configurado en el torneo
      list.sort((a, b) => b.goles.compareTo(a.goles));
      final topN = list.take(_topMax).toList();
      if (mounted) {
        setState(() {
          goleadores = topN;
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

  Widget _construirPosicion(int pos) {
    if (pos == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 24));
    }
    if (pos == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 24));
    }
    if (pos == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 24));
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        pos.toString(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const PublicTopNavBar(activeRoute: 'Goleadores'),
      body: RefreshIndicator(
        onRefresh: cargarGoleadores,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarGoleadores,
              );
            }

            if (goleadores.isEmpty) {
              return const AppEmptyView(
                message: 'No hay goleadores registrados en este campeonato.',
                icon: Icons.emoji_events_outlined,
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
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TABLA DE GOLEADORES • TOP $_topMax',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Top ${goleadores.length} máximos artilleros',
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

                      // Lista compacta de goleadores
                      ...goleadores.map((goleador) {
                        final rank = goleador.posicion ?? (goleadores.indexOf(goleador) + 1);
                        final sigla = goleador.siglaEquipo;
                        final equipoTexto = (sigla != null && sigla.isNotEmpty)
                            ? '${goleador.equipo} ($sigla)'
                            : goleador.equipo;

                        final esPrimero = rank == 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: esPrimero ? const Color(0xFFFFFBEB) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: esPrimero
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFE2E8F0),
                              width: esPrimero ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Posición (🥇 🥈 🥉 o número)
                              SizedBox(
                                width: 34,
                                child: Center(
                                  child: _construirPosicion(rank),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Foto compacta
                              PlayerAvatar(
                                photoUrl: goleador.fotoJugador,
                                playerName: goleador.nombreCompleto,
                                radius: 22,
                              ),
                              const SizedBox(width: 12),

                              // Jugador + Equipo + Camiseta
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      goleador.nombreCompleto,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D233A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        TeamLogoAvatar(
                                          teamName: goleador.equipo,
                                          sigla: goleador.siglaEquipo,
                                          size: 18,
                                          borderRadius: 4,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            equipoTexto,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (goleador.numeroCamiseta != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '#${goleador.numeroCamiseta}',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Marcador / Goles en pastilla azul oscuro
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D233A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      goleador.goles.toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      'GOLES',
                                      style: TextStyle(
                                        fontSize: 8.5,
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
                        );
                      }),
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
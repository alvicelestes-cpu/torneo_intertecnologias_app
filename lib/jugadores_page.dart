import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'models/equipo.dart';
import 'models/goleador.dart';
import 'models/jugador.dart';
import 'services/equipos_service.dart';
import 'services/jugadores_service.dart';
import 'services/torneo_service.dart';
import 'core/utils/player_sort_utils.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/public_age_group_section.dart';
import 'widgets/public_navbar.dart';

import 'jugador_detalle_page.dart';

class JugadoresPage extends StatefulWidget {
  final String? token;

  const JugadoresPage({
    super.key,
    this.token,
  });

  @override
  State<JugadoresPage> createState() => _JugadoresPageState();
}

class _JugadoresPageState extends State<JugadoresPage> {
  final JugadoresService _jugadoresService = JugadoresService();
  final EquiposService _equiposService = EquiposService();
  final TorneoService _torneoService = TorneoService();

  bool cargando = true;
  String? error;
  List<Jugador> jugadores = [];
  Map<int, Equipo> equiposMap = {};

  @override
  void initState() {
    super.initState();
    SessionManager().addListener(_onSessionChanged);
    cargarJugadores();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) cargarJugadores();
  }

  Future<void> cargarJugadores() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultados = await Future.wait([
        _jugadoresService.getJugadores(token: widget.token),
        _torneoService
            .getGoleadores(
              token: widget.token,
              campeonatoId: SessionManager().selectedCampeonatoId,
              cargarFotos: false,
            )
            .catchError((_) => <Goleador>[]),
        _equiposService.getEquipos(token: widget.token).catchError((_) => <Equipo>[]),
      ]);

      final listaJugadores = resultados[0] as List<Jugador>;
      final listaGoleadores = resultados[1] as List<Goleador>;
      final listaEquipos = resultados[2] as List<Equipo>;

      final mapEquipos = <int, Equipo>{};
      for (final e in listaEquipos) {
        mapEquipos[e.id] = e;
      }
      equiposMap = mapEquipos;

      // Mapear goles por jugador
      final golesMap = <int, int>{};
      for (final g in listaGoleadores) {
        golesMap[g.jugadorId] = g.goles;
      }

      final iniciales = listaJugadores.map((j) {
        final totalGoles = golesMap[j.id] ?? j.goles;
        final eq = mapEquipos[j.equipoId];
        return j.copyWith(
          goles: totalGoles,
          equipoNombre: j.equipoNombre?.trim().isNotEmpty == true
              ? j.equipoNombre
              : eq?.nombre,
          equipoSigla: j.equipoSigla?.trim().isNotEmpty == true
              ? j.equipoSigla
              : eq?.sigla,
          equipoColor: j.equipoColor?.trim().isNotEmpty == true
              ? j.equipoColor
              : eq?.colorPrincipal,
        );
      }).toList();

      if (mounted) {
        setState(() {
          jugadores = iniciales;
          cargando = false;
        });
      }

      // Enriquecer en segundo plano con tarjetas individuales
      _enriquecerEstadisticasTarjetas(iniciales);
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
          cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'No se pudo conectar con el servidor.';
          cargando = false;
        });
      }
    }
  }

  Future<void> _enriquecerEstadisticasTarjetas(List<Jugador> list) async {
    try {
      final enriquecidos = await Future.wait(
        list.map((j) async {
          try {
            final detalle = await _jugadoresService.getJugadorById(j.id, token: widget.token);
            return j.copyWith(
              goles: detalle.goles > 0 ? detalle.goles : j.goles,
              amarillas: detalle.amarillas,
              rojas: detalle.rojas,
            );
          } catch (_) {
            return j;
          }
        }),
      );

      if (mounted) {
        setState(() {
          jugadores = enriquecidos;
        });
      }
    } catch (_) {
      // Ignorar fallos de enriquecimiento en segundo plano
    }
  }

  Future<void> _abrirFicha(Jugador jugador) async {
    final equipoNombre = jugador.equipoNombre?.trim().isNotEmpty == true
        ? jugador.equipoNombre!
        : 'Sin equipo';

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JugadorDetallePage(
          jugador: jugador.toJson(),
          equipoNombre: equipoNombre,
          token: widget.token,
        ),
      ),
    );

    if (actualizado == true && mounted) {
      cargarJugadores();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const PublicTopNavBar(activeRoute: 'Inicio'),
      body: RefreshIndicator(
        onRefresh: cargarJugadores,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarJugadores,
              );
            }

            if (jugadores.isEmpty) {
              return const AppEmptyView(
                message: 'No hay jugadores registrados.',
                icon: Icons.person_search_outlined,
              );
            }

            final grupos = groupJugadoresPorEdad(jugadores);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
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
                                  Icons.badge,
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
                                      'CARNETS OFICIALES',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${jugadores.length} futbolistas inscritos',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // SECCIONES VISUALES DE CARNETS POR GRUPO DE EDAD
                      ...kAgeGroupsOrder.map((group) {
                        final list = grupos[group] ?? [];
                        if (list.isEmpty) return const SizedBox.shrink();
                        return PublicAgeGroupSection.fromGroup(
                          group: group,
                          jugadores: list,
                          onVerFicha: _abrirFicha,
                        );
                      }),
                      const SizedBox(height: 16),
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
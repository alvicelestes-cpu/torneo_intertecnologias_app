import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/ui_helpers.dart';
import 'models/equipo.dart';
import 'models/jugador.dart';
import 'services/equipos_service.dart';
import 'services/jugadores_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/public_navbar.dart';
import 'widgets/public_team_card.dart';

import 'jugadores_equipo_page.dart';

class EquiposPage extends StatefulWidget {
  final String? token;

  const EquiposPage({
    super.key,
    this.token,
  });

  @override
  State<EquiposPage> createState() => _EquiposPageState();
}

class _EquiposPageState extends State<EquiposPage> {
  final EquiposService _equiposService = EquiposService();
  final JugadoresService _jugadoresService = JugadoresService();

  bool cargando = true;
  String? error;
  List<Equipo> equipos = [];

  @override
  void initState() {
    super.initState();
    SessionManager().addListener(_onSessionChanged);
    cargarEquipos();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) cargarEquipos();
  }

  Future<void> cargarEquipos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultados = await Future.wait([
        _equiposService.getEquipos(token: widget.token),
        _jugadoresService.getJugadores(token: widget.token).catchError((_) => <Jugador>[]),
      ]);

      final listaEquipos = resultados[0] as List<Equipo>;
      final listaJugadores = resultados[1] as List<Jugador>;

      // Mapear cantidad de jugadores por equipo
      final conteoJugadores = <int, int>{};
      for (final j in listaJugadores) {
        conteoJugadores[j.equipoId] = (conteoJugadores[j.equipoId] ?? 0) + 1;
      }

      final equiposActualizados = listaEquipos.map((e) {
        final total = conteoJugadores[e.id] ?? e.cantidadJugadores;
        return e.copyWith(cantidadJugadores: total);
      }).toList();

      // ORDEN CONSISTENTE: ALFABÉTICO
      equiposActualizados.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      if (mounted) {
        setState(() {
          equipos = equiposActualizados;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'No se pudo conectar con el servidor.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  void _abrirPlantilla(Equipo equipo) {
    if (equipo.id <= 0) {
      UiHelpers.showError(
        context,
        'El equipo no tiene un ID válido.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JugadoresEquipoPage(
          equipoId: equipo.id,
          equipoNombre: equipo.nombre,
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const PublicTopNavBar(activeRoute: 'Equipos'),
      body: RefreshIndicator(
        onRefresh: cargarEquipos,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarEquipos,
              );
            }

            if (equipos.isEmpty) {
              return const AppEmptyView(
                message: 'No hay equipos registrados.',
                icon: Icons.groups_outlined,
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Cabecera deportiva azul con icono de trofeo
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
                                  const Text(
                                    'CLUBES PARTICIPANTES',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${equipos.length} equipos en contienda',
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

                    // Grid responsive de tarjetas de equipo (4 en desktop, 2 en tablet, 1 en móvil)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final int crossAxisCount = width >= 1050
                            ? 4
                            : (width >= 620 ? 2 : 1);

                        if (crossAxisCount == 1) {
                          return Column(
                            children: equipos
                                .map(
                                  (equipo) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: PublicTeamCard(
                                      equipo: equipo,
                                      onTap: () => _abrirPlantilla(equipo),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 232,
                          ),
                          itemCount: equipos.length,
                          itemBuilder: (context, index) {
                            final equipo = equipos[index];
                            return PublicTeamCard(
                              equipo: equipo,
                              onTap: () => _abrirPlantilla(equipo),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
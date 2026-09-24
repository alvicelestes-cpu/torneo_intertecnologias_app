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

import 'crear_jugador_page.dart';
import 'editar_equipo_page.dart';
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

  Future<void> _abrirInscripcion() async {
    final nuevoRegistrado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearJugadorPage(token: widget.token),
      ),
    );

    if (nuevoRegistrado == true && mounted) {
      cargarEquipos();
    }
  }

  Future<void> _abrirEditarEquipo(Equipo equipo) async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarEquipoPage(
          equipo: equipo,
          token: widget.token,
        ),
      ),
    );

    if (actualizado == true && mounted) {
      cargarEquipos();
    }
  }

  bool get _esAdmin {
    final session = SessionManager();
    final tieneTokenValido = (widget.token != null && widget.token!.isNotEmpty) || session.token.isNotEmpty;
    return tieneTokenValido && session.hasAdminAccess;
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

            final isMobile = MediaQuery.of(context).size.width < 600;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 16,
                  ),
                  children: [
                    // Cabecera: Fondo azul degradado con imagen de estadio, icono dorado de trofeo y título
                    Card(
                      elevation: 2.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/banner_blue.jpg'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Color(0xB30A192F),
                              BlendMode.srcOver,
                            ),
                          ),
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
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                        child: Row(
                          children: [
                            Container(
                              width: isMobile ? 44 : 52,
                              height: isMobile ? 44 : 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24, width: 1.2),
                              ),
                              child: Icon(
                                Icons.emoji_events,
                                color: const Color(0xFFFFD700),
                                size: isMobile ? 26 : 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Equipos participantes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 19 : 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ListenableBuilder(
                                    listenable: SessionManager(),
                                    builder: (context, _) => Text(
                                      SessionManager().selectedCampeonatoNombre,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isMobile ? 13 : 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Grid responsive de tarjetas de equipo (4 en desktop, 2 en tablet, 1 en móvil a ancho completo)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final int crossAxisCount = width >= 1050
                            ? 4
                            : (width >= 620 ? 2 : 1);

                        if (crossAxisCount == 1) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: equipos
                                .map(
                                  (equipo) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: PublicTeamCard(
                                        equipo: equipo,
                                        onTap: () => _abrirPlantilla(equipo),
                                        onEdit: _esAdmin ? () => _abrirEditarEquipo(equipo) : null,
                                      ),
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
                              onEdit: _esAdmin ? () => _abrirEditarEquipo(equipo) : null,
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
      floatingActionButton: _esAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: _abrirInscripcion,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Inscribir Jugador',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
    );
  }
}
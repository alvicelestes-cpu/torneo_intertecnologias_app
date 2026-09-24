import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/fixture_utils.dart';
import 'core/utils/ui_helpers.dart';
import 'models/partido.dart';
import 'partido_detalle_page.dart';
import 'services/partidos_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/public_jornada_accordion.dart';
import 'widgets/public_navbar.dart';

class PartidosPage extends StatefulWidget {
  final String? token;

  const PartidosPage({
    super.key,
    this.token,
  });

  @override
  State<PartidosPage> createState() => _PartidosPageState();
}

class _PartidosPageState extends State<PartidosPage> {
  final PartidosService _partidosService = PartidosService();

  bool cargando = true;
  String? error;
  List<Partido> partidos = [];
  List<FixtureSection> seccionesFixture = [];

  @override
  void initState() {
    super.initState();
    SessionManager().addListener(_onSessionChanged);
    cargarPartidos();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) cargarPartidos();
  }

  Future<void> cargarPartidos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final list = await _partidosService.getPartidos(token: widget.token);
      final sections = FixtureUtils.buildTournamentSections(
        partidos: list,
      );
      if (mounted) {
        setState(() {
          partidos = list;
          seccionesFixture = sections;
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

  Future<void> _abrirPartido(int partidoId) async {
    if (partidoId <= 0) {
      UiHelpers.showInfo(
        context,
        'Este enfrentamiento se encuentra pendiente de definición por clasificados.',
      );
      return;
    }

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
      cargarPartidos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const PublicTopNavBar(activeRoute: 'Partidos'),
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

            if (seccionesFixture.isEmpty) {
              return const AppEmptyView(
                message: 'No hay partidos registrados.',
                icon: Icons.sports_soccer_outlined,
              );
            }

            // Determinar qué fase/jornada expandir por defecto
            String seccionInicialId = 'jornada_1';
            for (final s in seccionesFixture) {
              if (s.partidos.any((p) => p.esEnCurso)) {
                seccionInicialId = s.id;
                break;
              }
            }
            if (seccionInicialId == 'jornada_1') {
              for (final s in seccionesFixture) {
                if (s.partidos.any((p) => p.esProgramado && p.id > 0)) {
                  seccionInicialId = s.id;
                  break;
                }
              }
            }

            final isMobile = MediaQuery.of(context).size.width < 600;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 16,
                  ),
                  children: [
                    // Cabecera: Banner azul con silueta de estadio, icono de calendario y título
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
                                Icons.calendar_month,
                                color: Colors.white,
                                size: isMobile ? 26 : 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Partidos por jornada',
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

                  // LISTA DE FASES Y JORNADAS EN ACORDEÓN (PRIMERA FASE, SEGUNDA RONDA, SEMIFINAL, FINAL)
                  ...seccionesFixture.map((seccion) {
                    return PublicJornadaAccordion(
                      numeroJornada: seccion.numeroJornada,
                      fase: seccion.fase,
                      tituloPersonalizado: seccion.titulo,
                      cantidadPartidos: seccion.cantidadPartidos,
                      partidos: seccion.partidos,
                      esPendiente: seccion.esPendiente,
                      mensajePendiente: seccion.mensajePendiente,
                      initiallyExpanded: seccion.id == seccionInicialId,
                      onPartidoTap: (partido) => _abrirPartido(partido.id),
                    );
                  }),
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
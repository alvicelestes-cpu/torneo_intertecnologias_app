import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/fixture_utils.dart';
import 'core/utils/ui_helpers.dart';
import 'models/partido.dart';
import 'models/posicion.dart';
import 'partido_detalle_page.dart';
import 'services/partidos_service.dart';
import 'services/torneo_service.dart';
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
  final TorneoService _torneoService = TorneoService();

  bool cargando = true;
  String? error;
  List<Partido> partidos = [];
  List<FixtureSection> seccionesFixture = [];
  List<Posicion> posiciones = [];
  String faseSeleccionada = 'TODAS';

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
      final resultados = await Future.wait([
        _partidosService.getPartidos(token: widget.token),
        _torneoService.getPosiciones(token: widget.token).catchError((_) => <Posicion>[]),
      ]);

      final list = resultados[0] as List<Partido>;
      final posList = resultados[1] as List<Posicion>;

      final sections = FixtureUtils.buildTournamentSections(
        partidos: list,
        posiciones: posList,
      );
      if (mounted) {
        setState(() {
          partidos = list;
          seccionesFixture = sections;
          posiciones = posList;
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

  Widget _construirSelectorFases() {
    final fases = [
      {'id': 'TODAS', 'nombre': 'Todas las Fases'},
      {'id': TournamentPhase.primeraFase, 'nombre': '1. Primera Fase'},
      {'id': TournamentPhase.segundaRonda, 'nombre': '2. Cuadrangulares'},
      {'id': TournamentPhase.terceraRonda, 'nombre': '3. Cuartos'},
      {'id': TournamentPhase.cuartaRonda, 'nombre': '4. Semifinales'},
      {'id': TournamentPhase.quintaRonda, 'nombre': '5. Gran Final'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fases.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = fases[index];
          final activa = faseSeleccionada == f['id'];

          return InkWell(
            onTap: () => setState(() => faseSeleccionada = f['id']!),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: activa ? const Color(0xFF0D233A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activa ? const Color(0xFF0D233A) : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
                boxShadow: activa
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  f['nombre']!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: activa ? FontWeight.w800 : FontWeight.w600,
                    color: activa ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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

            final seccionesVisibles = faseSeleccionada == 'TODAS'
                ? seccionesFixture
                : seccionesFixture.where((s) => s.fase == faseSeleccionada).toList();

            // Determinar qué fase/jornada expandir por defecto
            String seccionInicialId = 'jornada_1';
            for (final s in seccionesVisibles) {
              if (s.partidos.any((p) => p.esEnCurso)) {
                seccionInicialId = s.id;
                break;
              }
            }
            if (seccionInicialId == 'jornada_1') {
              for (final s in seccionesVisibles) {
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

                  // Selector de Pestañas para las 5 Fases
                  _construirSelectorFases(),

                  // LISTA DE FASES Y JORNADAS EN ACORDEÓN (5 FASES)
                  ...seccionesVisibles.map((seccion) {
                    return PublicJornadaAccordion(
                      numeroJornada: seccion.numeroJornada,
                      fase: seccion.fase,
                      tituloPersonalizado: seccion.titulo,
                      subtitulo: seccion.subtitulo,
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
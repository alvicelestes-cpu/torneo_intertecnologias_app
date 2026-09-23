import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/text_utils.dart';
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

  Future<void> _abrirPartido(int partidoId) async {
    if (partidoId <= 0) {
      UiHelpers.showError(context, 'El partido no tiene un ID válido.');
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

  /// Determina qué jornada abrir por defecto (actual con actividad o primera programada).
  /// El orden visual SIEMPRE se mantiene 1, 2, 3, 4, 5...
  int _determinarJornadaPorDefecto(
    Map<int, List<Partido>> agrupados,
    List<int> jornadasOrdenadas,
  ) {
    if (jornadasOrdenadas.isEmpty) return 1;

    // 1. Jornada en curso / en juego
    for (final j in jornadasOrdenadas) {
      if (agrupados[j]!.any((p) {
        final est = p.estado.toUpperCase();
        return est.contains('CURSO') || est.contains('JUEGO');
      })) {
        return j;
      }
    }

    // 2. Primera jornada con partidos programados (próxima a disputarse)
    for (final j in jornadasOrdenadas) {
      if (agrupados[j]!.any((p) => p.estado.toUpperCase() == 'PROGRAMADO')) {
        return j;
      }
    }

    // 3. Última jornada con actividad finalizada
    int ultimaConActividad = jornadasOrdenadas.first;
    for (final j in jornadasOrdenadas) {
      if (agrupados[j]!.any((p) => p.estado.toUpperCase() == 'FINALIZADO')) {
        ultimaConActividad = j;
      }
    }
    return ultimaConActividad;
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

            if (partidos.isEmpty) {
              return const AppEmptyView(
                message: 'No hay partidos registrados.',
                icon: Icons.sports_soccer_outlined,
              );
            }

            // Agrupar partidos por jornada
            final Map<int, List<Partido>> partidosPorJornada = {};
            for (final p in partidos) {
              final numJornada = p.jornada ?? 1;
              partidosPorJornada.putIfAbsent(numJornada, () => []).add(p);
            }

            // ORDEN ESTRICTAMENTE ASCENDENTE: Jornada 1, 2, 3, 4, 5...
            final List<int> jornadasOrdenadas = partidosPorJornada.keys.toList()..sort();

            final int jornadaDefecto = _determinarJornadaPorDefecto(
              partidosPorJornada,
              jornadasOrdenadas,
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Banner informativo con icono de calendario azul
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
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24, width: 1.2),
                              ),
                              child: const Icon(
                                Icons.calendar_month,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Partidos por jornada',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ListenableBuilder(
                                    listenable: SessionManager(),
                                    builder: (context, _) => Text(
                                      SessionManager().selectedCampeonatoNombre,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
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

                    // LISTA DE JORNADAS EN ACORDEÓN (SIEMPRE 1, 2, 3...)
                    ...jornadasOrdenadas.map((numeroJornada) {
                      final listaPartidos = partidosPorJornada[numeroJornada]!;
                      final primerPartido = listaPartidos.first;
                      final fase = primerPartido.fase != null
                          ? TextUtils.formatFase(primerPartido.fase)
                          : 'PRIMERA FASE';

                      return PublicJornadaAccordion(
                        numeroJornada: numeroJornada,
                        fase: fase,
                        cantidadPartidos: listaPartidos.length,
                        partidos: listaPartidos,
                        initiallyExpanded: numeroJornada == jornadaDefecto,
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
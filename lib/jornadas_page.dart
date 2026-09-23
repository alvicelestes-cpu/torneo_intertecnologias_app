import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/ui_helpers.dart';
import 'models/jornada.dart';
import 'models/partido.dart';
import 'partido_detalle_page.dart';
import 'services/jornadas_service.dart';
import 'services/partidos_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/campeonato_selector_bar.dart';
import 'widgets/public_jornada_accordion.dart';

class JornadasPage extends StatefulWidget {
  final String? token;

  const JornadasPage({
    super.key,
    this.token,
  });

  @override
  State<JornadasPage> createState() => _JornadasPageState();
}

class _JornadasPageState extends State<JornadasPage> {
  final JornadasService _jornadasService = JornadasService();
  final PartidosService _partidosService = PartidosService();

  bool cargando = true;
  String? error;
  int cantidadJornadas = 0;
  List<Jornada> jornadas = [];
  Map<int, List<Partido>> partidosPorJornada = {};

  @override
  void initState() {
    super.initState();
    SessionManager().addListener(_onSessionChanged);
    cargarJornadas();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) cargarJornadas();
  }

  Future<void> cargarJornadas() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultados = await Future.wait([
        _jornadasService.getJornadas(token: widget.token),
        _partidosService.getPartidos(token: widget.token).catchError((_) => <Partido>[]),
      ]);

      final resJornadas = resultados[0] as JornadasResponse;
      final listaPartidos = resultados[1] as List<Partido>;

      final map = <int, List<Partido>>{};
      for (final p in listaPartidos) {
        final j = p.jornada ?? 1;
        map.putIfAbsent(j, () => []).add(p);
      }

      // Ordenar jornadas ascendente
      final sortedJornadas = List<Jornada>.from(resJornadas.jornadas)
        ..sort((a, b) => a.numero.compareTo(b.numero));

      if (mounted) {
        setState(() {
          cantidadJornadas = resJornadas.cantidadJornadas;
          jornadas = sortedJornadas;
          partidosPorJornada = map;
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
      cargarJornadas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Jornadas'),
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
        onRefresh: cargarJornadas,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarJornadas,
              );
            }

            if (jornadas.isEmpty && partidosPorJornada.isEmpty) {
              return const AppEmptyView(
                message: 'No hay jornadas registradas.',
                icon: Icons.calendar_month_outlined,
              );
            }

            // Identificar todos los números de jornada existentes de manera ascendente
            final Set<int> todosLosNumeros = {
              ...jornadas.map((j) => j.numero),
              ...partidosPorJornada.keys,
            };
            final List<int> numerosAscendentes = todosLosNumeros.toList()..sort();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: ListView(
                  padding: const EdgeInsets.all(16),
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
                                Icons.calendar_month,
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
                                    'CALENDARIO POR JORNADAS',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${numerosAscendentes.length} ${numerosAscendentes.length == 1 ? 'Jornada oficial' : 'Jornadas oficiales'}',
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

                    // LISTA DE JORNADAS EN ACORDEÓN / TARJETAS DEPORTIVAS
                    ...numerosAscendentes.map((numJornada) {
                      final matches = partidosPorJornada[numJornada] ?? [];
                      final jMatch = jornadas.where((j) => j.numero == numJornada).firstOrNull;

                      final cant = matches.isNotEmpty
                          ? matches.length
                          : (jMatch?.cantidadPartidos ?? 0);

                      return PublicJornadaAccordion(
                        numeroJornada: numJornada,
                        fase: 'PRIMERA FASE',
                        cantidadPartidos: cant,
                        partidos: matches,
                        initiallyExpanded: numJornada == 1,
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
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'models/posicion.dart';
import 'services/torneo_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/campeonato_selector_bar.dart';
import 'widgets/team_logo_avatar.dart';

class PosicionesPage extends StatefulWidget {
  final String? token;

  const PosicionesPage({
    super.key,
    this.token,
  });

  @override
  State<PosicionesPage> createState() => _PosicionesPageState();
}

class _PosicionesPageState extends State<PosicionesPage> {
  final TorneoService _torneoService = TorneoService();

  bool cargando = true;
  String? error;
  List<Posicion> posiciones = [];

  @override
  void initState() {
    super.initState();
    SessionManager().addListener(_onSessionChanged);
    cargarPosiciones();
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) cargarPosiciones();
  }

  Future<void> cargarPosiciones() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final list = await _torneoService.getPosiciones(token: widget.token);
      if (mounted) {
        setState(() {
          posiciones = list;
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

  Widget _encabezado(String texto, {double ancho = 50, TextAlign alineacion = TextAlign.center}) {
    return SizedBox(
      width: ancho,
      child: Text(
        texto,
        textAlign: alineacion,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _dato(
    String texto, {
    double ancho = 50,
    bool negrita = false,
    TextAlign alineacion = TextAlign.center,
    Color? color,
  }) {
    return SizedBox(
      width: ancho,
      child: Text(
        texto,
        textAlign: alineacion,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
          color: color ?? const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _construirPodio(int pos) {
    if (pos == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 20));
    }
    if (pos == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 20));
    }
    if (pos == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 20));
    }
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$pos',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _construirEncabezadoTabla() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D233A),
            Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _encabezado('POS', ancho: 45),
          _encabezado('EQUIPO', ancho: 200, alineacion: TextAlign.left),
          _encabezado('PJ'),
          _encabezado('PG'),
          _encabezado('PE'),
          _encabezado('PP'),
          _encabezado('GF'),
          _encabezado('GC'),
          _encabezado('DG'),
          _encabezado('PTS', ancho: 60),
        ],
      ),
    );
  }

  Widget _construirFila(Posicion pos, int index) {
    final esPrimero = pos.posicion == 1;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: esPrimero
            ? const Color(0xFFFFFBEB)
            : (index.isEven ? Colors.white : const Color(0xFFFBFDFF)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esPrimero ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
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
          SizedBox(
            width: 45,
            child: Center(
              child: _construirPodio(pos.posicion),
            ),
          ),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                TeamLogoAvatar(
                  logoUrl: pos.logo,
                  teamName: pos.equipo,
                  sigla: pos.sigla,
                  size: 32,
                  borderRadius: 8,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pos.equipo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF0D233A),
                        ),
                      ),
                      if (pos.sigla.isNotEmpty)
                        Text(
                          pos.sigla,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _dato(pos.pj.toString()),
          _dato(pos.pg.toString()),
          _dato(pos.pe.toString()),
          _dato(pos.pp.toString()),
          _dato(pos.gf.toString()),
          _dato(pos.gc.toString()),
          _dato(
            pos.diferenciaGolTexto,
            negrita: true,
            color: pos.dg > 0
                ? const Color(0xFF16A34A)
                : (pos.dg < 0 ? const Color(0xFFDC2626) : null),
          ),
          // PTS DESTACADO EN PASTILLA AZUL OSCURO
          SizedBox(
            width: 60,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D233A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pos.pts.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
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
            const Text('Tabla de posiciones'),
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
        onRefresh: cargarPosiciones,
        child: Builder(
          builder: (context) {
            if (cargando) {
              return const AppLoadingIndicator();
            }

            if (error != null) {
              return AppErrorView(
                message: error!,
                onRetry: cargarPosiciones,
              );
            }

            if (posiciones.isEmpty) {
              return const AppEmptyView(
                message: 'No hay posiciones registradas en este campeonato.',
                icon: Icons.leaderboard_outlined,
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
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
                                  Icons.leaderboard,
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
                                      'CLASIFICACIÓN EN TIEMPO REAL',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${posiciones.length} equipos en competencia',
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

                      // Tabla responsive con scroll horizontal si es necesario
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 700),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _construirEncabezadoTabla(),
                                  ...posiciones.asMap().entries.map(
                                        (e) => _construirFila(e.value, e.key),
                                      ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
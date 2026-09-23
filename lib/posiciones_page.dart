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

  Color colorPosicion(int pos) {
    switch (pos) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.blueGrey;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.blueGrey.shade100;
    }
  }

  Widget encabezado(String texto, {double ancho = 50, TextAlign alineacion = TextAlign.center}) {
    return SizedBox(
      width: ancho,
      child: Text(
        texto,
        textAlign: alineacion,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget dato(String texto, {double ancho = 50, bool negrita = false, TextAlign alineacion = TextAlign.center, Color? color}) {
    return SizedBox(
      width: ancho,
      child: Text(
        texto,
        textAlign: alineacion,
        style: TextStyle(
          fontSize: 14,
          fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }

  Widget construirEncabezado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF1D4F7A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          encabezado('POS', ancho: 45),
          encabezado('EQUIPO', ancho: 190, alineacion: TextAlign.left),
          encabezado('PJ'),
          encabezado('PG'),
          encabezado('PE'),
          encabezado('PP'),
          encabezado('GF'),
          encabezado('GC'),
          encabezado('DG'),
          encabezado('PTS', ancho: 60),
        ],
      ),
    );
  }

  Widget construirFila(Posicion pos) {
    final esPodio = pos.posicion <= 3;
    final esPrimero = pos.posicion == 1;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: esPrimero ? const Color(0xFFFFFDE7) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esPrimero ? Colors.amber.shade200 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorPosicion(pos.posicion),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  pos.posicion.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: esPodio ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 190,
            child: Row(
              children: [
                TeamLogoAvatar(
                  logoUrl: pos.logo,
                  teamName: pos.equipo,
                  sigla: pos.sigla,
                  size: 34,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (pos.sigla.isNotEmpty)
                        Text(
                          pos.sigla,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          dato(pos.pj.toString()),
          dato(pos.pg.toString()),
          dato(pos.pe.toString()),
          dato(pos.pp.toString()),
          dato(pos.gf.toString()),
          dato(pos.gc.toString()),
          dato(pos.diferenciaGolTexto),
          dato(
            pos.pts.toString(),
            ancho: 60,
            negrita: true,
            color: const Color(0xFF1D4F7A),
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
                message: 'No hay datos de posiciones registrados.',
                icon: Icons.leaderboard_outlined,
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera deportiva azul
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0B3C68),
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
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.leaderboard, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TABLA OFICIAL DE CLASIFICACIÓN',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ListenableBuilder(
                                      listenable: SessionManager(),
                                      builder: (context, _) => Text(
                                        SessionManager().selectedCampeonatoNombre,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                construirEncabezado(),
                                const SizedBox(height: 6),
                                ...posiciones.map(construirFila),
                              ],
                            ),
                          ),
                        ),
                      ),
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
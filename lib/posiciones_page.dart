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
        return AppColors.podioOro;
      case 2:
        return AppColors.podioPlata;
      case 3:
        return AppColors.podioBronce;
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
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget dato(String texto, {double ancho = 50, bool negrita = false, TextAlign alineacion = TextAlign.center}) {
    return SizedBox(
      width: ancho,
      child: Text(
        texto,
        textAlign: alineacion,
        style: TextStyle(
          fontSize: 14,
          fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget construirEncabezado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          encabezado('POS', ancho: 45),
          encabezado('EQUIPO', ancho: 180, alineacion: TextAlign.left),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: colorPosicion(pos.posicion),
              child: Text(
                pos.posicion.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: pos.posicion <= 3 ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Row(
              children: [
                TeamLogoAvatar(
                  logoUrl: pos.logo,
                  teamName: pos.equipo,
                  sigla: pos.sigla,
                  size: 32,
                  borderRadius: 8,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pos.equipo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
          dato(pos.pts.toString(), ancho: 60, negrita: true),
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
              padding: const EdgeInsets.all(16),
              child: Card(
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
            );
          },
        ),
      ),
    );
  }
}
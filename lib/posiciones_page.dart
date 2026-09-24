import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'models/posicion.dart';
import 'services/torneo_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/public_navbar.dart';
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
  int _tabFase = 0; // 0: Primera Fase, 1: Segunda Ronda (Cuadrangulares)

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

  Widget _construirDistintivoVentaja(int posicion) {
    if (posicion == 1) {
      return Container(
        margin: const EdgeInsets.only(top: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 10, color: Color(0xFFB45309)),
            SizedBox(width: 3),
            Text(
              'Punto Invisible • Grupo A',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    }
    if (posicion == 2) {
      return Container(
        margin: const EdgeInsets.only(top: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E7FF),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF6366F1), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 10, color: Color(0xFF4338CA)),
            SizedBox(width: 3),
            Text(
              'Punto Invisible • Grupo B',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4338CA),
              ),
            ),
          ],
        ),
      );
    }
    if (posicion == 3 || posicion == 5 || posicion == 7) {
      return Container(
        margin: const EdgeInsets.only(top: 3),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 0.6),
        ),
        child: const Text(
          'Sembrado Grupo A',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      );
    }
    if (posicion == 4 || posicion == 6 || posicion == 8) {
      return Container(
        margin: const EdgeInsets.only(top: 3),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 0.6),
        ),
        child: const Text(
          'Sembrado Grupo B',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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
          _encabezado('EQUIPO', ancho: 230, alineacion: TextAlign.left),
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
    final esSegundo = pos.posicion == 2;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: esPrimero
            ? const Color(0xFFFFFBEB)
            : (esSegundo
                ? const Color(0xFFF5F7FF)
                : (index.isEven ? Colors.white : const Color(0xFFFBFDFF))),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esPrimero
              ? const Color(0xFFFDE68A)
              : (esSegundo ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0)),
          width: esPrimero || esSegundo ? 1.5 : 1.0,
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
            width: 230,
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
                      _construirDistintivoVentaja(pos.posicion),
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

  Widget _construirVistaCuadrangulares() {
    if (posiciones.length < 8) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Esperando el registro de los 8 equipos para la siembra de Cuadrangulares.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ),
      );
    }

    final grupoA = [posiciones[0], posiciones[2], posiciones[4], posiciones[6]];
    final grupoB = [posiciones[1], posiciones[3], posiciones[5], posiciones[7]];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card informativo
        Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: const Color(0xFFF8FAFC),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF4338CA), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'SEGUNDA RONDA - CUADRANGULARES SEMIFINALES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF312E81),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '• Los 8 equipos se siembran al finalizar la Fecha 7: Grupo A (1°, 3°, 5° y 7°) y Grupo B (2°, 4°, 6° y 8°).\n'
                        '• ★ Ventaja Deportiva ("Punto Invisible"): En caso de empate en puntos dentro del cuadrangular, el 1° y 2° de la Primera Fase obtienen la clasificación automática.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // GRUPO A
        _construirCardGrupo(
          titulo: 'CUADRANGULAR GRUPO A',
          subtitulo: '1°, 3°, 5° y 7° Puesto • 1° cuenta con Punto Invisible',
          equipos: grupoA,
          posicionVentaja: 1,
          colorGradiente: const [Color(0xFF312E81), Color(0xFF4338CA)],
        ),
        const SizedBox(height: 16),

        // GRUPO B
        _construirCardGrupo(
          titulo: 'CUADRANGULAR GRUPO B',
          subtitulo: '2°, 4°, 6° y 8° Puesto • 2° cuenta con Punto Invisible',
          equipos: grupoB,
          posicionVentaja: 2,
          colorGradiente: const [Color(0xFF1E1B4B), Color(0xFF3730A3)],
        ),
      ],
    );
  }

  Widget _construirCardGrupo({
    required String titulo,
    required String subtitulo,
    required List<Posicion> equipos,
    required int posicionVentaja,
    required List<Color> colorGradiente,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colorGradiente,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.groups, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _construirEncabezadoTabla(),
                    ...equipos.asMap().entries.map((e) => _construirFila(e.value, e.key)),
                  ],
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
      appBar: const PublicTopNavBar(activeRoute: 'Posiciones'),
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

                      // Selector de Pestañas: Primera Fase vs Cuadrangulares
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _tabFase = 0),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _tabFase == 0 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _tabFase == 0
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(12),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'PRIMERA FASE (General)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _tabFase == 0
                                            ? const Color(0xFF0D233A)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _tabFase = 1),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _tabFase == 1 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _tabFase == 1
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(12),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'SEGUNDA RONDA (Cuadrangulares)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _tabFase == 1
                                            ? const Color(0xFF312E81)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_tabFase == 0) ...[
                        // Aviso de Punto Invisible y Siembra
                        Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          color: const Color(0xFFF8FAFC),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'SISTEMA DE COMPETICIÓN & VENTAJA DEPORTIVA',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0D233A),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        '• Los 8 equipos avanzan a Cuadrangulares Semifinales (Grupo A: 1°, 3°, 5°, 7° | Grupo B: 2°, 4°, 6°, 8°).\n'
                                        '• ★ Ventaja Deportiva ("Punto Invisible"): El 1° y 2° de la Primera Fase ganan el desempate por puntos en su grupo.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF334155),
                                          height: 1.35,
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
                                constraints: const BoxConstraints(minWidth: 720),
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
                      ] else ...[
                        _construirVistaCuadrangulares(),
                      ],
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
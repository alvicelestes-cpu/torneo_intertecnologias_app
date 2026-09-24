import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/text_utils.dart';
import 'core/utils/ui_helpers.dart';
import 'models/gol.dart';
import 'models/partido_detalle.dart';
import 'models/tarjeta.dart';
import 'services/goles_service.dart';
import 'services/partidos_service.dart';
import 'services/tarjetas_service.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/status_chip.dart';
import 'widgets/team_logo_avatar.dart';

import 'editar_partido_page.dart';
import 'goles_partido_page.dart';
import 'resultado_partido_page.dart';
import 'tarjetas_partido_page.dart';

class PartidoDetallePage extends StatefulWidget {
  final int partidoId;
  final String? token;
  final PartidoDetalle? initialDetalle;

  const PartidoDetallePage({
    super.key,
    required this.partidoId,
    this.token,
    this.initialDetalle,
  });

  @override
  State<PartidoDetallePage> createState() => _PartidoDetallePageState();
}

class _PartidoDetallePageState extends State<PartidoDetallePage> {
  final PartidosService _partidosService = PartidosService();
  final GolesService _golesService = GolesService();
  final TarjetasService _tarjetasService = TarjetasService();

  bool cargando = true;
  bool reabriendo = false;
  String? error;
  PartidoDetalle? detalle;

  @override
  void initState() {
    super.initState();
    if (widget.initialDetalle != null) {
      detalle = widget.initialDetalle;
      cargando = false;
    } else {
      cargarPartido();
    }
  }

  Future<void> cargarPartido() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final res = await _partidosService.getPartidoById(
        widget.partidoId,
        token: widget.token,
      );
      var goles = res.goles;
      var tarjetas = res.tarjetas;
      if (goles.isEmpty && tarjetas.isEmpty) {
        try {
          final extras = await Future.wait([
            _golesService.getGolesPartido(widget.partidoId, token: widget.token),
            _tarjetasService.getTarjetasPartido(widget.partidoId, token: widget.token),
          ]);
          goles = extras[0] as List<Gol>;
          tarjetas = extras[1] as List<Tarjeta>;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          detalle = PartidoDetalle(
            partido: res.partido.copyWith(goles: goles, tarjetas: tarjetas),
            resumen: res.resumen,
            goles: goles,
            tarjetas: tarjetas,
          );
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

  Widget filaDato(IconData icono, String titulo, String valor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icono, color: AppColors.primary),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          valor,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> abrirEdicion() async {
    final token = widget.token ?? SessionManager().token;
    if (token.isEmpty) return;
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPartidoPage(
          partidoId: widget.partidoId,
          token: token,
        ),
      ),
    );

    if (actualizado == true && mounted) {
      cargarPartido();
    }
  }

  Future<void> abrirResultado() async {
    final token = widget.token ?? SessionManager().token;
    if (token.isEmpty) return;
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoPartidoPage(
          partidoId: widget.partidoId,
          token: token,
        ),
      ),
    );

    if (actualizado == true && mounted) {
      cargarPartido();
    }
  }

  Future<void> abrirGoles() async {
    final token = widget.token ?? SessionManager().token;
    if (token.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GolesPartidoPage(
          partidoId: widget.partidoId,
          token: token,
        ),
      ),
    );

    if (mounted) {
      cargarPartido();
    }
  }

  Future<void> abrirTarjetas() async {
    final token = widget.token ?? SessionManager().token;
    if (token.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TarjetasPartidoPage(
          partidoId: widget.partidoId,
          token: token,
        ),
      ),
    );

    if (mounted) {
      cargarPartido();
    }
  }

  Future<void> confirmarReapertura() async {
    final token = widget.token ?? SessionManager().token;
    if (token.isEmpty) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reabrir partido'),
        content: const Text(
          '¿Está seguro de reabrir este partido? El estado cambiará a EN CURSO y se recalcularán estadísticas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('REABRIR'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => reabriendo = true);

    try {
      await _partidosService.reabrirPartido(widget.partidoId, token: token);
      if (!mounted) return;
      UiHelpers.showSuccess(context, 'Partido reabierto correctamente.');
      await cargarPartido();
    } on AppException catch (e) {
      if (!mounted) return;
      UiHelpers.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      UiHelpers.showError(context, 'Error al reabrir el partido.');
    } finally {
      if (mounted) setState(() => reabriendo = false);
    }
  }

  Widget _construirSeccionIncidencias(PartidoDetalle det) {
    final partido = det.partido;
    final localId = partido.equipoLocalId;
    final visitanteId = partido.equipoVisitanteId;

    // 1. Filtrar goles por equipo
    final golesLocal = partido.goles.where((g) {
      if (localId != null && g.equipoId != null) {
        return g.equipoId == localId;
      }
      return g.equipoNombre.toUpperCase() == partido.equipoLocalNombre.toUpperCase();
    }).toList();

    final golesVisitante = partido.goles.where((g) {
      if (visitanteId != null && g.equipoId != null) {
        return g.equipoId == visitanteId;
      }
      return g.equipoNombre.toUpperCase() == partido.equipoVisitanteNombre.toUpperCase();
    }).toList();

    // Agrupar goles por jugador para formatear ej. "⚽ Juan Pérez (23', 54')"
    List<String> formatearGolesEquipo(List<Gol> goles) {
      final Map<String, List<int>> mapJugadorMinutos = {};
      final Map<String, int> mapGolesSinMinuto = {};

      for (final g in goles) {
        final nombre = g.nombreJugador.trim();
        if (g.minuto != null && g.minuto! > 0) {
          mapJugadorMinutos.putIfAbsent(nombre, () => []).add(g.minuto!);
        } else {
          mapGolesSinMinuto[nombre] = (mapGolesSinMinuto[nombre] ?? 0) + 1;
        }
      }

      final List<String> resultado = [];
      final todosNombres = {...mapJugadorMinutos.keys, ...mapGolesSinMinuto.keys}.toList();

      for (final nom in todosNombres) {
        final mins = mapJugadorMinutos[nom] ?? [];
        mins.sort();
        final sinMin = mapGolesSinMinuto[nom] ?? 0;

        if (mins.isNotEmpty) {
          final minsStr = mins.map((m) => "$m'").join(', ');
          if (sinMin > 0) {
            resultado.add('$nom ($minsStr, +$sinMin)');
          } else {
            resultado.add('$nom ($minsStr)');
          }
        } else {
          if (sinMin > 1) {
            resultado.add('$nom ($sinMin goles)');
          } else {
            resultado.add(nom);
          }
        }
      }

      return resultado;
    }

    final listaGolesLocal = formatearGolesEquipo(golesLocal);
    final listaGolesVisitante = formatearGolesEquipo(golesVisitante);
    final bool hayGoles = partido.goles.isNotEmpty;

    // 2. Filtrar tarjetas por equipo
    final tarjetasLocal = partido.tarjetas.where((t) {
      if (localId != null && t.equipoId != null) {
        return t.equipoId == localId;
      }
      return t.equipoNombre.toUpperCase() == partido.equipoLocalNombre.toUpperCase();
    }).toList();

    final tarjetasVisitante = partido.tarjetas.where((t) {
      if (visitanteId != null && t.equipoId != null) {
        return t.equipoId == visitanteId;
      }
      return t.equipoNombre.toUpperCase() == partido.equipoVisitanteNombre.toUpperCase();
    }).toList();

    final bool hayTarjetas = partido.tarjetas.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // SECCIÓN GOLES
            // ==========================================
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D233A).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    size: 20,
                    color: Color(0xFF0D233A),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Goles',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: Color(0xFF0D233A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!hayGoles)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sports_soccer_outlined, size: 18, color: Colors.black38),
                    SizedBox(width: 8),
                    Text(
                      'Sin goles registrados',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna Local
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partido.equipoLocalNombre.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (listaGolesLocal.isEmpty)
                          const Text(
                            '-',
                            style: TextStyle(color: Colors.black38, fontSize: 13),
                          )
                        else
                          ...listaGolesLocal.map((txt) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.sports_soccer,
                                      size: 15,
                                      color: Color(0xFF1E293B),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        txt,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  // Columna Visitante
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partido.equipoVisitanteNombre.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (listaGolesVisitante.isEmpty)
                          const Text(
                            '-',
                            style: TextStyle(color: Colors.black38, fontSize: 13),
                          )
                        else
                          ...listaGolesVisitante.map((txt) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.sports_soccer,
                                      size: 15,
                                      color: Color(0xFF1E293B),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        txt,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 18),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 16),

            // ==========================================
            // SECCIÓN TARJETAS Y SANCIONES DISCIPLINARIAS
            // ==========================================
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D233A).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.style,
                    size: 20,
                    color: Color(0xFF0D233A),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Tarjetas y Sanciones Disciplinarias',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: Color(0xFF0D233A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!hayTarjetas)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Sin amonestaciones registradas',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjetas Local
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partido.equipoLocalNombre.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (tarjetasLocal.isEmpty)
                          const Text(
                            '-',
                            style: TextStyle(color: Colors.black38, fontSize: 13),
                          )
                        else
                          ...tarjetasLocal.map((t) => _buildBadgeTarjeta(t)),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  // Tarjetas Visitante
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partido.equipoVisitanteNombre.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (tarjetasVisitante.isEmpty)
                          const Text(
                            '-',
                            style: TextStyle(color: Colors.black38, fontSize: 13),
                          )
                        else
                          ...tarjetasVisitante.map((t) => _buildBadgeTarjeta(t)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeTarjeta(Tarjeta t) {
    final esRoja = t.esRoja;
    final Color badgeColor = esRoja ? const Color(0xFFD32F2F) : const Color(0xFFFBC02D);
    final Color textColor = esRoja ? Colors.white : const Color(0xFF1F2937);
    final String label = t.nombreJugador + (t.minuto != null ? " (${t.minuto}')" : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 13,
            decoration: BoxDecoration(
              color: esRoja ? Colors.white : const Color(0xFFB78103),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Detalle del partido'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: _buildAppBar(),
        body: const AppLoadingIndicator(),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: _buildAppBar(),
        body: AppErrorView(message: error!, onRetry: cargarPartido),
      );
    }

    final det = detalle;
    if (det == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: _buildAppBar(),
        body: const Center(child: Text('No hay información del partido.')),
      );
    }

    final partido = det.partido;
    final fase = TextUtils.formatFase(partido.fase);
    final fechaHora = AppDateUtils.formatDateTime(partido.fechaHora);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (partido.jornada != null)
                          Text(
                            'Jornada ${partido.jornada}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          fase,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  TeamLogoAvatar(
                                    logoUrl: partido.equipoLocalLogo,
                                    teamName: partido.equipoLocalNombre,
                                    sigla: partido.equipoLocalSigla,
                                    size: 54,
                                    isCircle: true,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    partido.equipoLocalNombre,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                partido.marcador,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  TeamLogoAvatar(
                                    logoUrl: partido.equipoVisitanteLogo,
                                    teamName: partido.equipoVisitanteNombre,
                                    sigla: partido.equipoVisitanteSigla,
                                    size: 54,
                                    isCircle: true,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    partido.equipoVisitanteNombre,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        StatusChip(status: partido.estado, fontSize: 13),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _construirSeccionIncidencias(det),
                const SizedBox(height: 20),
                if (SessionManager().isAuthenticated) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: abrirEdicion,
                        icon: const Icon(Icons.edit),
                        label: const Text('EDITAR PARTIDO'),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
                        onPressed: abrirResultado,
                        icon: const Icon(Icons.sports_score),
                        label: const Text('RESULTADO'),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.indigo.shade700),
                        onPressed: abrirGoles,
                        icon: const Icon(Icons.sports_soccer),
                        label: const Text('GOLES'),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade900),
                        onPressed: abrirTarjetas,
                        icon: const Icon(Icons.style),
                        label: const Text('TARJETAS'),
                      ),
                      if (partido.esFinalizado)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
                          onPressed: reabriendo ? null : confirmarReapertura,
                          icon: reabriendo
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.lock_open),
                          label: const Text('REABRIR PARTIDO'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                filaDato(Icons.access_time, 'Fecha y hora', fechaHora),
                filaDato(
                  Icons.stadium_outlined,
                  'Cancha',
                  partido.cancha?.isNotEmpty == true ? partido.cancha! : 'Por definir',
                ),
                if (partido.llave != null && partido.llave!.isNotEmpty)
                  filaDato(Icons.account_tree_outlined, 'Llave', partido.llave!),
                if (SessionManager().isAuthenticated &&
                    partido.observaciones != null &&
                    partido.observaciones!.isNotEmpty)
                  filaDato(Icons.note_outlined, 'Observaciones', partido.observaciones!),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/text_utils.dart';
import 'core/utils/ui_helpers.dart';
import 'models/partido_detalle.dart';
import 'services/partidos_service.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/status_chip.dart';

import 'editar_partido_page.dart';
import 'goles_partido_page.dart';
import 'resultado_partido_page.dart';
import 'tarjetas_partido_page.dart';

class PartidoDetallePage extends StatefulWidget {
  final int partidoId;
  final String token;

  const PartidoDetallePage({
    super.key,
    required this.partidoId,
    required this.token,
  });

  @override
  State<PartidoDetallePage> createState() => _PartidoDetallePageState();
}

class _PartidoDetallePageState extends State<PartidoDetallePage> {
  final PartidosService _partidosService = PartidosService();

  bool cargando = true;
  bool reabriendo = false;
  String? error;
  PartidoDetalle? detalle;

  @override
  void initState() {
    super.initState();
    cargarPartido();
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
      if (mounted) {
        setState(() {
          detalle = res;
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
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPartidoPage(
          partidoId: widget.partidoId,
          token: widget.token,
        ),
      ),
    );

    if (actualizado == true && mounted) {
      cargarPartido();
    }
  }

  Future<void> abrirResultado() async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoPartidoPage(
          partidoId: widget.partidoId,
          token: widget.token,
        ),
      ),
    );

    if (actualizado == true && mounted) {
      cargarPartido();
    }
  }

  Future<void> abrirGoles() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GolesPartidoPage(
          partidoId: widget.partidoId,
          token: widget.token,
        ),
      ),
    );

    if (mounted) {
      cargarPartido();
    }
  }

  Future<void> abrirTarjetas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TarjetasPartidoPage(
          partidoId: widget.partidoId,
          token: widget.token,
        ),
      ),
    );

    if (mounted) {
      cargarPartido();
    }
  }

  Future<void> confirmarReapertura() async {
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
      await _partidosService.reabrirPartido(widget.partidoId, token: widget.token);
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

  Widget construirResumenIncidencias(PartidoDetalle det) {
    final resumen = det.resumen;
    if (resumen == null) return const SizedBox.shrink();

    final golesLocal = resumen.golesLocal;
    final golesVisitante = resumen.golesVisitante;
    final tarjetasLocal = resumen.tarjetasLocal;
    final tarjetasVisitante = resumen.tarjetasVisitante;

    final tieneGoles = golesLocal.isNotEmpty || golesVisitante.isNotEmpty;
    final tieneTarjetas = tarjetasLocal.isNotEmpty || tarjetasVisitante.isNotEmpty;

    if (!tieneGoles && !tieneTarjetas) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Resumen de incidencias',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (tieneGoles)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sports_soccer, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Goles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Divider(),
                  if (golesLocal.isNotEmpty) ...[
                    Text('${det.partido.equipoLocalNombre}:', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ...golesLocal.map((g) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text('• ${g.toString()}'),
                        )),
                    const SizedBox(height: 8),
                  ],
                  if (golesVisitante.isNotEmpty) ...[
                    Text('${det.partido.equipoVisitanteNombre}:', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ...golesVisitante.map((g) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text('• ${g.toString()}'),
                        )),
                  ],
                ],
              ),
            ),
          ),
        if (tieneTarjetas) ...[
          const SizedBox(height: 10),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Tarjetas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Divider(),
                  if (tarjetasLocal.isNotEmpty) ...[
                    Text('${det.partido.equipoLocalNombre}:', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ...tarjetasLocal.map((t) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text('• ${t.toString()}'),
                        )),
                    const SizedBox(height: 8),
                  ],
                  if (tarjetasVisitante.isNotEmpty) ...[
                    Text('${det.partido.equipoVisitanteNombre}:', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ...tarjetasVisitante.map((t) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text('• ${t.toString()}'),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
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
                              child: Text(
                                partido.equipoLocalNombre,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
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
                              child: Text(
                                partido.equipoVisitanteNombre,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 20),
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
                filaDato(Icons.access_time, 'Fecha y hora', fechaHora),
                filaDato(
                  Icons.stadium_outlined,
                  'Cancha',
                  partido.cancha?.isNotEmpty == true ? partido.cancha! : 'Por definir',
                ),
                if (partido.llave != null && partido.llave!.isNotEmpty)
                  filaDato(Icons.account_tree_outlined, 'Llave', partido.llave!),
                if (partido.observaciones != null && partido.observaciones!.isNotEmpty)
                  filaDato(Icons.note_outlined, 'Observaciones', partido.observaciones!),
                construirResumenIncidencias(det),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
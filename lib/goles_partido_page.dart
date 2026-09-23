import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/ui_helpers.dart';
import 'models/gol.dart';
import 'models/jugador.dart';
import 'models/partido_detalle.dart';
import 'services/equipos_service.dart';
import 'services/goles_service.dart';
import 'services/partidos_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';

class GolesPartidoPage extends StatefulWidget {
  final int partidoId;
  final String token;

  const GolesPartidoPage({
    super.key,
    required this.partidoId,
    required this.token,
  });

  @override
  State<GolesPartidoPage> createState() => _GolesPartidoPageState();
}

class _GolesPartidoPageState extends State<GolesPartidoPage> {
  final PartidosService _partidosService = PartidosService();
  final EquiposService _equiposService = EquiposService();
  final GolesService _golesService = GolesService();

  final _formKey = GlobalKey<FormState>();
  final minutoCtrl = TextEditingController();
  final observacionCtrl = TextEditingController();

  bool cargando = true;
  bool guardando = false;
  String? error;

  PartidoDetalle? detalle;
  List<Jugador> jugadores = [];
  List<Gol> goles = [];

  int? jugadorSeleccionadoId;

  @override
  void initState() {
    super.initState();
    cargarTodo();
  }

  @override
  void dispose() {
    minutoCtrl.dispose();
    observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarTodo() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resDetalle = await _partidosService.getPartidoById(widget.partidoId, token: widget.token);
      detalle = resDetalle;

      final p = resDetalle.partido;
      final localId = p.equipoLocalId ?? 0;
      final visitanteId = p.equipoVisitanteId ?? 0;

      final jugadoresFutures = await Future.wait([
        if (localId > 0)
          _equiposService.getJugadoresEquipo(localId, token: widget.token)
        else
          Future.value(<Jugador>[]),
        if (visitanteId > 0)
          _equiposService.getJugadoresEquipo(visitanteId, token: widget.token)
        else
          Future.value(<Jugador>[]),
        _golesService.getGolesPartido(widget.partidoId, token: widget.token),
      ]);

      final localList = (jugadoresFutures[0] as List<Jugador>).map((j) {
        return Jugador(
          id: j.id,
          equipoId: j.equipoId,
          equipoNombre: p.equipoLocalNombre,
          nombres: j.nombres,
          apellidos: j.apellidos,
          numeroCamiseta: j.numeroCamiseta,
          posicion: j.posicion,
        );
      }).toList();

      final visitanteList = (jugadoresFutures[1] as List<Jugador>).map((j) {
        return Jugador(
          id: j.id,
          equipoId: j.equipoId,
          equipoNombre: p.equipoVisitanteNombre,
          nombres: j.nombres,
          apellidos: j.apellidos,
          numeroCamiseta: j.numeroCamiseta,
          posicion: j.posicion,
        );
      }).toList();

      final todosJugadores = [...localList, ...visitanteList];
      todosJugadores.sort((a, b) => a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase()));

      if (mounted) {
        setState(() {
          jugadores = todosJugadores;
          goles = jugadoresFutures[2] as List<Gol>;
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

  Future<void> registrarGol() async {
    if (jugadorSeleccionadoId == null) {
      UiHelpers.showError(context, 'Seleccione un jugador.');
      return;
    }

    int? minuto;
    if (minutoCtrl.text.trim().isNotEmpty) {
      minuto = int.tryParse(minutoCtrl.text.trim());
      if (minuto == null || minuto < 0 || minuto > 300) {
        UiHelpers.showError(context, 'Ingrese un minuto válido.');
        return;
      }
    }

    setState(() => guardando = true);

    try {
      await _golesService.registrarGol(
        {
          'partidoId': widget.partidoId,
          'jugadorId': jugadorSeleccionadoId,
          'minuto': minuto,
          'observacion': observacionCtrl.text.trim().isEmpty ? null : observacionCtrl.text.trim(),
        },
        token: widget.token,
      );

      minutoCtrl.clear();
      observacionCtrl.clear();
      if (!mounted) return;
      setState(() => jugadorSeleccionadoId = null);
      UiHelpers.showSuccess(context, 'Gol registrado correctamente.');
      await cargarTodo();
    } on AppException catch (e) {
      if (!mounted) return;
      UiHelpers.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      UiHelpers.showError(context, 'Error al registrar el gol.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> eliminarGol(int golId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar gol'),
        content: const Text('¿Está seguro de eliminar este gol?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _golesService.eliminarGol(golId, token: widget.token);
      if (!mounted) return;
      UiHelpers.showSuccess(context, 'Gol eliminado.');
      await cargarTodo();
    } on AppException catch (e) {
      if (!mounted) return;
      UiHelpers.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      UiHelpers.showError(context, 'Error al eliminar el gol.');
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
            const Text('Goles del partido'),
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
      ),
      body: Builder(
        builder: (context) {
          if (cargando) {
            return const AppLoadingIndicator();
          }

          if (error != null) {
            return AppErrorView(
              message: error!,
              onRetry: cargarTodo,
            );
          }

          final p = detalle?.partido;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (p != null)
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '${p.equipoLocalNombre} ${p.marcador} ${p.equipoVisitanteNombre}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Registrar gol',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                initialValue: jugadorSeleccionadoId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Jugador',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                                items: jugadores.map((j) {
                                  final desc = '${j.nombreCompleto} (${j.equipoNombre})';
                                  return DropdownMenuItem<int>(
                                    value: j.id,
                                    child: Text(desc, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => jugadorSeleccionadoId = val);
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: minutoCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Minuto (opcional)',
                                  prefixIcon: Icon(Icons.timer_outlined),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: observacionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Observación (opcional)',
                                  prefixIcon: Icon(Icons.note_outlined),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: guardando ? null : registrarGol,
                                  icon: guardando
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.sports_soccer),
                                  label: Text(
                                    guardando ? 'REGISTRANDO...' : 'REGISTRAR GOL',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Goles registrados',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (goles.isEmpty)
                      const AppEmptyView(
                        message: 'No hay goles registrados en este partido.',
                        icon: Icons.sports_soccer_outlined,
                      )
                    else
                      ...goles.map((g) {
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                g.minuto != null ? "${g.minuto}'" : '⚽',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              g.jugadorNombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              [
                                g.equipoNombre,
                                if (g.observacion != null && g.observacion!.isNotEmpty) g.observacion!,
                              ].join(' • '),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => eliminarGol(g.id),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
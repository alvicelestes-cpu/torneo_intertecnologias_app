import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/utils/ui_helpers.dart';
import 'models/jugador.dart';
import 'models/partido_detalle.dart';
import 'models/tarjeta.dart';
import 'services/equipos_service.dart';
import 'services/partidos_service.dart';
import 'services/tarjetas_service.dart';
import 'widgets/app_empty_view.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';

class TarjetasPartidoPage extends StatefulWidget {
  final int partidoId;
  final String token;

  const TarjetasPartidoPage({
    super.key,
    required this.partidoId,
    required this.token,
  });

  @override
  State<TarjetasPartidoPage> createState() => _TarjetasPartidoPageState();
}

class _TarjetasPartidoPageState extends State<TarjetasPartidoPage> {
  final PartidosService _partidosService = PartidosService();
  final EquiposService _equiposService = EquiposService();
  final TarjetasService _tarjetasService = TarjetasService();

  final _formKey = GlobalKey<FormState>();
  final minutoCtrl = TextEditingController();
  final motivoCtrl = TextEditingController();

  bool cargando = true;
  bool guardando = false;
  String? error;

  PartidoDetalle? detalle;
  List<Jugador> jugadores = [];
  List<Tarjeta> tarjetas = [];

  int? jugadorSeleccionadoId;
  String tipoSeleccionado = 'AMARILLA';

  @override
  void initState() {
    super.initState();
    cargarTodo();
  }

  @override
  void dispose() {
    minutoCtrl.dispose();
    motivoCtrl.dispose();
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
        _tarjetasService.getTarjetasPartido(widget.partidoId, token: widget.token),
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
          tarjetas = jugadoresFutures[2] as List<Tarjeta>;
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

  Future<void> registrarTarjeta() async {
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
      await _tarjetasService.registrarTarjeta(
        {
          'partidoId': widget.partidoId,
          'jugadorId': jugadorSeleccionadoId,
          'tipo': tipoSeleccionado,
          'minuto': minuto,
          'motivo': motivoCtrl.text.trim().isEmpty ? null : motivoCtrl.text.trim(),
        },
        token: widget.token,
      );

      minutoCtrl.clear();
      motivoCtrl.clear();
      if (!mounted) return;
      setState(() => jugadorSeleccionadoId = null);
      UiHelpers.showSuccess(context, 'Tarjeta registrada correctamente.');
      await cargarTodo();
    } on AppException catch (e) {
      if (!mounted) return;
      UiHelpers.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      UiHelpers.showError(context, 'Error al registrar la tarjeta.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> eliminarTarjeta(int tarjetaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: const Text('¿Está seguro de eliminar esta tarjeta?'),
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
      await _tarjetasService.eliminarTarjeta(tarjetaId, token: widget.token);
      if (!mounted) return;
      UiHelpers.showSuccess(context, 'Tarjeta eliminada.');
      await cargarTodo();
    } on AppException catch (e) {
      if (!mounted) return;
      UiHelpers.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      UiHelpers.showError(context, 'Error al eliminar la tarjeta.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Tarjetas del partido'),
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
                                'Registrar tarjeta',
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
                              DropdownButtonFormField<String>(
                                initialValue: tipoSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de tarjeta',
                                  prefixIcon: Icon(Icons.style),
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'AMARILLA', child: Text('AMARILLA')),
                                  DropdownMenuItem(value: 'ROJA', child: Text('ROJA')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => tipoSeleccionado = val);
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
                                controller: motivoCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Motivo (opcional)',
                                  prefixIcon: Icon(Icons.note_outlined),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: tipoSeleccionado == 'ROJA'
                                        ? AppColors.tarjetaRoja
                                        : Colors.amber.shade800,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: guardando ? null : registrarTarjeta,
                                  icon: guardando
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.style),
                                  label: Text(
                                    guardando ? 'REGISTRANDO...' : 'REGISTRAR TARJETA',
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
                      'Tarjetas registradas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (tarjetas.isEmpty)
                      const AppEmptyView(
                        message: 'No hay tarjetas registradas en este partido.',
                        icon: Icons.style_outlined,
                      )
                    else
                      ...tarjetas.map((t) {
                        final esRoja = t.esRoja;

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Container(
                              width: 24,
                              height: 34,
                              decoration: BoxDecoration(
                                color: esRoja ? AppColors.tarjetaRoja : AppColors.tarjetaAmarilla,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            title: Text(
                              t.jugadorNombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              [
                                t.equipoNombre,
                                if (t.minuto != null) "${t.minuto}'",
                                if (t.motivo != null && t.motivo!.isNotEmpty) t.motivo!,
                              ].join(' • '),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => eliminarTarjeta(t.id),
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
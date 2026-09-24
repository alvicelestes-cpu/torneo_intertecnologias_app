import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/ui_helpers.dart';
import 'models/gol.dart';
import 'models/jugador.dart';
import 'models/partido_detalle.dart';
import 'models/tarjeta.dart';
import 'services/equipos_service.dart';
import 'services/goles_service.dart';
import 'services/partidos_service.dart';
import 'services/tarjetas_service.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';

class ResultadoPartidoPage extends StatefulWidget {
  final int partidoId;
  final String token;

  const ResultadoPartidoPage({
    super.key,
    required this.partidoId,
    required this.token,
  });

  @override
  State<ResultadoPartidoPage> createState() => _ResultadoPartidoPageState();
}

class _ResultadoPartidoPageState extends State<ResultadoPartidoPage> {
  final _formKey = GlobalKey<FormState>();
  final PartidosService _partidosService = PartidosService();
  final EquiposService _equiposService = EquiposService();
  final GolesService _golesService = GolesService();
  final TarjetasService _tarjetasService = TarjetasService();

  final golesLocalCtrl = TextEditingController();
  final golesVisitanteCtrl = TextEditingController();
  final fechaCtrl = TextEditingController();
  final horaCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();

  bool cargando = true;
  bool guardando = false;
  String? error;

  String equipoLocal = 'Equipo local';
  String equipoVisitante = 'Equipo visitante';
  int localEquipoId = 0;
  int visitanteEquipoId = 0;

  List<Jugador> localJugadores = [];
  List<Jugador> visitanteJugadores = [];
  List<Gol> goles = [];
  List<Tarjeta> tarjetas = [];

  @override
  void initState() {
    super.initState();
    cargarPartido();
  }

  @override
  void dispose() {
    golesLocalCtrl.dispose();
    golesVisitanteCtrl.dispose();
    fechaCtrl.dispose();
    horaCtrl.dispose();
    observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarPartido() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final PartidoDetalle detalle = await _partidosService.getPartidoById(
        widget.partidoId,
        token: widget.token,
      );

      final partido = detalle.partido;
      localEquipoId = partido.equipoLocalId ?? 0;
      visitanteEquipoId = partido.equipoVisitanteId ?? 0;
      equipoLocal = partido.equipoLocalNombre;
      equipoVisitante = partido.equipoVisitanteNombre;
      observacionesCtrl.text = partido.observaciones ?? '';

      if (partido.fechaHora != null && partido.fechaHora!.isNotEmpty) {
        final dt = DateTime.tryParse(partido.fechaHora!);
        if (dt != null) {
          fechaCtrl.text =
              '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          horaCtrl.text =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }
      }

      final results = await Future.wait([
        if (localEquipoId > 0)
          _equiposService.getJugadoresEquipo(localEquipoId, token: widget.token)
        else
          Future.value(<Jugador>[]),
        if (visitanteEquipoId > 0)
          _equiposService.getJugadoresEquipo(visitanteEquipoId, token: widget.token)
        else
          Future.value(<Jugador>[]),
        _golesService.getGolesPartido(widget.partidoId, token: widget.token),
        _tarjetasService.getTarjetasPartido(widget.partidoId, token: widget.token),
      ]);

      final jLocal = results[0] as List<Jugador>;
      final jVisitante = results[1] as List<Jugador>;
      final gList = results[2] as List<Gol>;
      final tList = results[3] as List<Tarjeta>;

      if (mounted) {
        setState(() {
          localJugadores = jLocal;
          visitanteJugadores = jVisitante;
          goles = gList;
          tarjetas = tList;

          final countLocalGoles = goles.where((g) {
            if (localEquipoId > 0 && g.equipoId != null) {
              return g.equipoId == localEquipoId;
            }
            return g.equipoNombre.toUpperCase() == equipoLocal.toUpperCase();
          }).length;

          final countVisitanteGoles = goles.where((g) {
            if (visitanteEquipoId > 0 && g.equipoId != null) {
              return g.equipoId == visitanteEquipoId;
            }
            return g.equipoNombre.toUpperCase() == equipoVisitante.toUpperCase();
          }).length;

          if (goles.isNotEmpty) {
            golesLocalCtrl.text = countLocalGoles.toString();
            golesVisitanteCtrl.text = countVisitanteGoles.toString();
          } else {
            golesLocalCtrl.text = partido.golesLocal != null ? partido.golesLocal.toString() : '0';
            golesVisitanteCtrl.text = partido.golesVisitante != null ? partido.golesVisitante.toString() : '0';
          }
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

  Future<void> _mostrarDialogoAgregarGol(bool esLocal) async {
    final jugadoresEquipo = esLocal ? localJugadores : visitanteJugadores;
    final nombreEquipo = esLocal ? equipoLocal : equipoVisitante;

    if (jugadoresEquipo.isEmpty) {
      UiHelpers.showError(context, 'No hay jugadores registrados en el plantel de $nombreEquipo.');
      return;
    }

    int? jugadorSeleccionadoId = jugadoresEquipo.first.id;
    final minutoLocalCtrl = TextEditingController();
    final obsLocalCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.sports_soccer, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Añadir Gol • $nombreEquipo',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: jugadorSeleccionadoId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Jugador anotador',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  items: jugadoresEquipo.map((j) {
                    final num = j.numeroCamiseta != null ? '#${j.numeroCamiseta} ' : '';
                    return DropdownMenuItem<int>(
                      value: j.id,
                      child: Text('$num${j.nombreCompleto}', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => jugadorSeleccionadoId = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: minutoLocalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minuto del gol (opcional)',
                    prefixIcon: Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'Ej. 23',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: obsLocalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Observación (opcional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'Ej. Tiro libre, penal...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add),
              label: const Text('REGISTRAR GOL'),
              onPressed: () async {
                if (jugadorSeleccionadoId == null) return;
                int? min;
                if (minutoLocalCtrl.text.trim().isNotEmpty) {
                  min = int.tryParse(minutoLocalCtrl.text.trim());
                  if (min == null || min < 0 || min > 300) {
                    UiHelpers.showError(ctx, 'Minuto no válido.');
                    return;
                  }
                }
                Navigator.pop(ctx);
                if (!mounted) return;
                setState(() => cargando = true);
                try {
                  await _golesService.registrarGol(
                    {
                      'partidoId': widget.partidoId,
                      'jugadorId': jugadorSeleccionadoId,
                      'minuto': min,
                      'observacion': obsLocalCtrl.text.trim().isEmpty ? null : obsLocalCtrl.text.trim(),
                    },
                    token: widget.token,
                  );
                  if (!mounted) return;
                  UiHelpers.showSuccess(context, 'Gol registrado correctamente.');
                  await cargarPartido();
                } catch (e) {
                  if (!mounted) return;
                  setState(() => cargando = false);
                  UiHelpers.showError(context, 'Error al registrar el gol: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarGol(int golId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Gol'),
        content: const Text('¿Desea quitar este gol registrado del encuentro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;

    setState(() => cargando = true);
    try {
      await _golesService.eliminarGol(golId, token: widget.token);
      if (!mounted) return;
      UiHelpers.showSuccess(context, 'Gol eliminado.');
      await cargarPartido();
    } catch (e) {
      if (!mounted) return;
      setState(() => cargando = false);
      UiHelpers.showError(context, 'Error al eliminar el gol.');
    }
  }

  Future<void> _mostrarDialogoAgregarTarjeta(bool esLocal) async {
    final jugadoresEquipo = esLocal ? localJugadores : visitanteJugadores;
    final nombreEquipo = esLocal ? equipoLocal : equipoVisitante;

    if (jugadoresEquipo.isEmpty) {
      UiHelpers.showError(context, 'No hay jugadores registrados en el plantel de $nombreEquipo.');
      return;
    }

    int? jugadorSeleccionadoId = jugadoresEquipo.first.id;
    String tipoSeleccionado = 'AMARILLA';
    final minutoLocalCtrl = TextEditingController();
    final motivoLocalCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.style, color: Color(0xFFFBC02D)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Añadir Tarjeta • $nombreEquipo',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: jugadorSeleccionadoId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Jugador sancionado',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  items: jugadoresEquipo.map((j) {
                    final num = j.numeroCamiseta != null ? '#${j.numeroCamiseta} ' : '';
                    return DropdownMenuItem<int>(
                      value: j.id,
                      child: Text('$num${j.nombreCompleto}', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => jugadorSeleccionadoId = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Tarjeta',
                    prefixIcon: Icon(Icons.style_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'AMARILLA', child: Text('🟨 Tarjeta Amarilla')),
                    DropdownMenuItem(value: 'ROJA', child: Text('🟥 Tarjeta Roja')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => tipoSeleccionado = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: minutoLocalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minuto (opcional)',
                    prefixIcon: Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'Ej. 42',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: motivoLocalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motivo / Observación (opcional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'Ej. Falta táctica, conducta...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: tipoSeleccionado == 'ROJA' ? const Color(0xFFD32F2F) : const Color(0xFFFBC02D),
                foregroundColor: tipoSeleccionado == 'ROJA' ? Colors.white : Colors.black87,
              ),
              icon: const Icon(Icons.add),
              label: const Text('REGISTRAR TARJETA'),
              onPressed: () async {
                if (jugadorSeleccionadoId == null) return;
                int? min;
                if (minutoLocalCtrl.text.trim().isNotEmpty) {
                  min = int.tryParse(minutoLocalCtrl.text.trim());
                  if (min == null || min < 0 || min > 300) {
                    UiHelpers.showError(ctx, 'Minuto no válido.');
                    return;
                  }
                }
                Navigator.pop(ctx);
                if (!mounted) return;
                setState(() => cargando = true);
                try {
                  await _tarjetasService.registrarTarjeta(
                    {
                      'partidoId': widget.partidoId,
                      'jugadorId': jugadorSeleccionadoId,
                      'tipo': tipoSeleccionado,
                      'minuto': min,
                      'observacion': motivoLocalCtrl.text.trim().isEmpty ? null : motivoLocalCtrl.text.trim(),
                    },
                    token: widget.token,
                  );
                  if (!mounted) return;
                  UiHelpers.showSuccess(context, 'Tarjeta registrada correctamente.');
                  await cargarPartido();
                } catch (e) {
                  if (!mounted) return;
                  setState(() => cargando = false);
                  UiHelpers.showError(context, 'Error al registrar la tarjeta: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarTarjeta(int tarjetaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Tarjeta'),
        content: const Text('¿Desea quitar esta tarjeta registrada del encuentro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;

    setState(() => cargando = true);
    try {
      await _tarjetasService.eliminarTarjeta(tarjetaId, token: widget.token);
      if (!mounted) return;
      UiHelpers.showSuccess(context, 'Tarjeta eliminada.');
      await cargarPartido();
    } catch (e) {
      if (!mounted) return;
      setState(() => cargando = false);
      UiHelpers.showError(context, 'Error al eliminar la tarjeta.');
    }
  }

  Future<void> seleccionarFecha() async {
    DateTime fechaInicial = DateTime.now();
    final fechaActual = DateTime.tryParse(fechaCtrl.text.trim());
    if (fechaActual != null) {
      fechaInicial = fechaActual;
    }

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (seleccionada == null) return;

    final anio = seleccionada.year.toString().padLeft(4, '0');
    final mes = seleccionada.month.toString().padLeft(2, '0');
    final dia = seleccionada.day.toString().padLeft(2, '0');

    setState(() {
      fechaCtrl.text = '$anio-$mes-$dia';
    });
  }

  Future<void> seleccionarHora() async {
    TimeOfDay horaInicial = TimeOfDay.now();
    final partes = horaCtrl.text.split(':');
    if (partes.length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        horaInicial = TimeOfDay(hour: h, minute: m);
      }
    }

    final seleccionada = await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );

    if (seleccionada == null) return;

    final h = seleccionada.hour.toString().padLeft(2, '0');
    final m = seleccionada.minute.toString().padLeft(2, '0');

    setState(() {
      horaCtrl.text = '$h:$m';
    });
  }

  Future<void> guardarResultado() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final golesLocal = int.tryParse(golesLocalCtrl.text.trim());
    final golesVisitante = int.tryParse(golesVisitanteCtrl.text.trim());

    if (golesLocal == null || golesVisitante == null) {
      UiHelpers.showError(context, 'Los goles deben ser valores numéricos.');
      return;
    }

    if (golesLocal < 0 || golesVisitante < 0) {
      UiHelpers.showError(context, 'Los goles no pueden ser negativos.');
      return;
    }

    String? fechaHora;
    if (fechaCtrl.text.trim().isNotEmpty && horaCtrl.text.trim().isNotEmpty) {
      final fechaTexto = '${fechaCtrl.text.trim()} ${horaCtrl.text.trim()}:00';
      final parsed = DateTime.tryParse(fechaTexto);
      if (parsed == null) {
        UiHelpers.showError(context, 'La fecha y hora no son válidas.');
        return;
      }
      fechaHora = parsed.toIso8601String();
    }

    final body = <String, dynamic>{
      'golesLocal': golesLocal,
      'golesVisitante': golesVisitante,
      'fechaHora': fechaHora,
      'observaciones': observacionesCtrl.text.trim().isEmpty ? null : observacionesCtrl.text.trim(),
    };

    setState(() => guardando = true);

    try {
      await _partidosService.registrarResultado(
        widget.partidoId,
        body,
        token: widget.token,
      );

      if (!mounted) return;
      UiHelpers.showSuccess(context, 'Resultado registrado y finalizado correctamente.');
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AppException catch (e) {
      if (!mounted) return;
      UiHelpers.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      UiHelpers.showError(context, 'Error al registrar el resultado.');
    } finally {
      if (mounted) setState(() => guardando = false);
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
            const Text('Registrar resultado e incidencias'),
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
              onRetry: cargarPartido,
            );
          }

          final golesLocal = goles.where((g) {
            if (localEquipoId > 0 && g.equipoId != null) {
              return g.equipoId == localEquipoId;
            }
            return g.equipoNombre.toUpperCase() == equipoLocal.toUpperCase();
          }).toList();

          final golesVisitante = goles.where((g) {
            if (visitanteEquipoId > 0 && g.equipoId != null) {
              return g.equipoId == visitanteEquipoId;
            }
            return g.equipoNombre.toUpperCase() == equipoVisitante.toUpperCase();
          }).toList();

          final tarjetasLocal = tarjetas.where((t) {
            if (localEquipoId > 0 && t.equipoId != null) {
              return t.equipoId == localEquipoId;
            }
            return t.equipoNombre.toUpperCase() == equipoLocal.toUpperCase();
          }).toList();

          final tarjetasVisitante = tarjetas.where((t) {
            if (visitanteEquipoId > 0 && t.equipoId != null) {
              return t.equipoId == visitanteEquipoId;
            }
            return t.equipoNombre.toUpperCase() == equipoVisitante.toUpperCase();
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // TARJETA DE MARCADOR
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                'Marcador final',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          equipoLocal,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: golesLocalCtrl,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'Goles',
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (v) =>
                                              v == null || v.trim().isEmpty ? 'Ingrese goles' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '-',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          equipoVisitante,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: golesVisitanteCtrl,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'Goles',
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (v) =>
                                              v == null || v.trim().isEmpty ? 'Ingrese goles' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // GESTIÓN DE GOLES INDIVIDUALES
                      Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.sports_soccer, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Anotadores de Goles (Top 10 Goleadores)',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Los goles individuales registrados aquí alimentan automáticamente la Tabla de Goleadores.',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Local
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          ),
                                          onPressed: () => _mostrarDialogoAgregarGol(true),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: Text('+ Gol $equipoLocal', maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(height: 8),
                                        if (golesLocal.isEmpty)
                                          const Text(
                                            'Sin goles',
                                            style: TextStyle(color: Colors.black38, fontSize: 12.5, fontStyle: FontStyle.italic),
                                          )
                                        else
                                          ...golesLocal.map((g) => Card(
                                                color: const Color(0xFFF8FAFC),
                                                margin: const EdgeInsets.only(bottom: 6),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.sports_soccer, size: 14),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          '${g.nombreJugador}${g.minuto != null ? " (${g.minuto}')" : ""}',
                                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                        visualDensity: VisualDensity.compact,
                                                        onPressed: () => _eliminarGol(g.id),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Visitante
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          ),
                                          onPressed: () => _mostrarDialogoAgregarGol(false),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: Text('+ Gol $equipoVisitante', maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(height: 8),
                                        if (golesVisitante.isEmpty)
                                          const Text(
                                            'Sin goles',
                                            style: TextStyle(color: Colors.black38, fontSize: 12.5, fontStyle: FontStyle.italic),
                                          )
                                        else
                                          ...golesVisitante.map((g) => Card(
                                                color: const Color(0xFFF8FAFC),
                                                margin: const EdgeInsets.only(bottom: 6),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.sports_soccer, size: 14),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          '${g.nombreJugador}${g.minuto != null ? " (${g.minuto}')" : ""}',
                                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                        visualDensity: VisualDensity.compact,
                                                        onPressed: () => _eliminarGol(g.id),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // GESTIÓN DE TARJETAS
                      Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.style, color: Color(0xFFFBC02D)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tarjetas y Sanciones Disciplinarias',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Registre amonestaciones (amarillas) y expulsiones (rojas) para el control del torneo.',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Local
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          ),
                                          onPressed: () => _mostrarDialogoAgregarTarjeta(true),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: Text('+ Tarjeta $equipoLocal', maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(height: 8),
                                        if (tarjetasLocal.isEmpty)
                                          const Text(
                                            'Sin tarjetas',
                                            style: TextStyle(color: Colors.black38, fontSize: 12.5, fontStyle: FontStyle.italic),
                                          )
                                        else
                                          ...tarjetasLocal.map((t) => Card(
                                                color: t.esRoja ? const Color(0xFFD32F2F) : const Color(0xFFFBC02D),
                                                margin: const EdgeInsets.only(bottom: 6),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          '${t.esRoja ? "🟥" : "🟨"} ${t.nombreJugador}${t.minuto != null ? " (${t.minuto}')" : ""}',
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.w800,
                                                            color: t.esRoja ? Colors.white : Colors.black87,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.close, size: 14, color: t.esRoja ? Colors.white : Colors.black87),
                                                        visualDensity: VisualDensity.compact,
                                                        onPressed: () => _eliminarTarjeta(t.id),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Visitante
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          ),
                                          onPressed: () => _mostrarDialogoAgregarTarjeta(false),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: Text('+ Tarjeta $equipoVisitante', maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(height: 8),
                                        if (tarjetasVisitante.isEmpty)
                                          const Text(
                                            'Sin tarjetas',
                                            style: TextStyle(color: Colors.black38, fontSize: 12.5, fontStyle: FontStyle.italic),
                                          )
                                        else
                                          ...tarjetasVisitante.map((t) => Card(
                                                color: t.esRoja ? const Color(0xFFD32F2F) : const Color(0xFFFBC02D),
                                                margin: const EdgeInsets.only(bottom: 6),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          '${t.esRoja ? "🟥" : "🟨"} ${t.nombreJugador}${t.minuto != null ? " (${t.minuto}')" : ""}',
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.w800,
                                                            color: t.esRoja ? Colors.white : Colors.black87,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.close, size: 14, color: t.esRoja ? Colors.white : Colors.black87),
                                                        visualDensity: VisualDensity.compact,
                                                        onPressed: () => _eliminarTarjeta(t.id),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // FECHA, HORA Y OBSERVACIONES
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: fechaCtrl,
                              readOnly: true,
                              onTap: seleccionarFecha,
                              decoration: const InputDecoration(
                                labelText: 'Fecha',
                                prefixIcon: Icon(Icons.calendar_today),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: horaCtrl,
                              readOnly: true,
                              onTap: seleccionarHora,
                              decoration: const InputDecoration(
                                labelText: 'Hora',
                                prefixIcon: Icon(Icons.access_time),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: observacionesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones del resultado',
                          prefixIcon: Icon(Icons.note_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: guardando ? null : guardarResultado,
                          icon: guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            guardando ? 'GUARDANDO...' : 'GUARDAR Y FINALIZAR',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
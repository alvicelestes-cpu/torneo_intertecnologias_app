import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/utils/ui_helpers.dart';
import 'models/partido_detalle.dart';
import 'services/partidos_service.dart';
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
      if (mounted) {
        setState(() {
          equipoLocal = partido.equipoLocalNombre;
          equipoVisitante = partido.equipoVisitanteNombre;
          golesLocalCtrl.text = partido.golesLocal != null ? partido.golesLocal.toString() : '';
          golesVisitanteCtrl.text =
              partido.golesVisitante != null ? partido.golesVisitante.toString() : '';
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
      UiHelpers.showSuccess(context, 'Resultado registrado correctamente.');
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
        title: const Text('Registrar resultado'),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                      const SizedBox(height: 20),
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
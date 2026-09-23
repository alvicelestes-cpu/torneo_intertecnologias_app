import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/ui_helpers.dart';
import 'models/partido_detalle.dart';
import 'services/partidos_service.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';

class EditarPartidoPage extends StatefulWidget {
  final int partidoId;
  final String token;

  const EditarPartidoPage({
    super.key,
    required this.partidoId,
    required this.token,
  });

  @override
  State<EditarPartidoPage> createState() => _EditarPartidoPageState();
}

class _EditarPartidoPageState extends State<EditarPartidoPage> {
  final _formKey = GlobalKey<FormState>();
  final PartidosService _partidosService = PartidosService();

  final faseCtrl = TextEditingController();
  final llaveCtrl = TextEditingController();
  final jornadaCtrl = TextEditingController();
  final equipoLocalIdCtrl = TextEditingController();
  final equipoVisitanteIdCtrl = TextEditingController();
  final canchaCtrl = TextEditingController();
  final fechaCtrl = TextEditingController();
  final horaCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();

  bool cargando = true;
  bool guardando = false;
  String? error;

  String equipoLocalNombre = '';
  String equipoVisitanteNombre = '';
  String estado = 'PROGRAMADO';

  @override
  void initState() {
    super.initState();
    cargarPartido();
  }

  @override
  void dispose() {
    faseCtrl.dispose();
    llaveCtrl.dispose();
    jornadaCtrl.dispose();
    equipoLocalIdCtrl.dispose();
    equipoVisitanteIdCtrl.dispose();
    canchaCtrl.dispose();
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
          faseCtrl.text = partido.fase ?? '';
          llaveCtrl.text = partido.llave ?? '';
          jornadaCtrl.text = partido.jornada != null ? partido.jornada.toString() : '';

          if (partido.equipoLocalId != null) {
            equipoLocalIdCtrl.text = partido.equipoLocalId.toString();
          }
          equipoLocalNombre = partido.equipoLocalNombre;

          if (partido.equipoVisitanteId != null) {
            equipoVisitanteIdCtrl.text = partido.equipoVisitanteId.toString();
          }
          equipoVisitanteNombre = partido.equipoVisitanteNombre;

          canchaCtrl.text = partido.cancha ?? '';

          if (partido.fechaHora != null && partido.fechaHora!.isNotEmpty) {
            final dt = DateTime.tryParse(partido.fechaHora!);
            if (dt != null) {
              final anio = dt.year.toString();
              final mes = dt.month.toString().padLeft(2, '0');
              final dia = dt.day.toString().padLeft(2, '0');
              final hora = dt.hour.toString().padLeft(2, '0');
              final minuto = dt.minute.toString().padLeft(2, '0');

              fechaCtrl.text = '$anio-$mes-$dia';
              horaCtrl.text = '$hora:$minuto';
            }
          }

          estado = partido.estado.isNotEmpty ? partido.estado : 'PROGRAMADO';
          observacionesCtrl.text = partido.observaciones ?? '';
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

    final anio = seleccionada.year.toString();
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

  Future<void> guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final jornada = int.tryParse(jornadaCtrl.text.trim());
    final equipoLocalId = int.tryParse(equipoLocalIdCtrl.text.trim());
    final equipoVisitanteId = int.tryParse(equipoVisitanteIdCtrl.text.trim());

    if (equipoLocalId == null || equipoVisitanteId == null) {
      UiHelpers.showError(context, 'Los IDs de los equipos deben ser numéricos.');
      return;
    }

    if (equipoLocalId == equipoVisitanteId) {
      UiHelpers.showError(context, 'El equipo local y visitante no pueden ser el mismo.');
      return;
    }

    String? fechaHora;
    if (fechaCtrl.text.trim().isNotEmpty && horaCtrl.text.trim().isNotEmpty) {
      final fechaTexto = '${fechaCtrl.text.trim()} ${horaCtrl.text.trim()}:00';
      final parsed = DateTime.tryParse(fechaTexto);
      if (parsed == null) {
        UiHelpers.showError(context, 'La combinación de fecha y hora no es válida.');
        return;
      }
      fechaHora = parsed.toIso8601String();
    }

    final body = <String, dynamic>{
      'cancha': canchaCtrl.text.trim().isEmpty ? null : canchaCtrl.text.trim(),
      'fase': faseCtrl.text.trim().isEmpty ? null : faseCtrl.text.trim(),
      'llave': llaveCtrl.text.trim().isEmpty ? null : llaveCtrl.text.trim(),
      'jornada': jornada,
      'equipoLocalId': equipoLocalId,
      'equipoVisitanteId': equipoVisitanteId,
      'fechaHora': fechaHora,
      'estado': estado,
      'observaciones': observacionesCtrl.text.trim().isEmpty ? null : observacionesCtrl.text.trim(),
    };

    setState(() => guardando = true);

    try {
      await _partidosService.updatePartido(
        widget.partidoId,
        body,
        token: widget.token,
      );

      if (!mounted) return;
      UiHelpers.showSuccess(context, 'Partido actualizado correctamente.');
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AppException catch (e) {
      if (!mounted) return;
      UiHelpers.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      UiHelpers.showError(context, 'Error al actualizar el partido.');
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
            const Text('Editar partido'),
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
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  equipoLocalNombre.isNotEmpty ? equipoLocalNombre : 'Equipo local',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                              Expanded(
                                child: Text(
                                  equipoVisitanteNombre.isNotEmpty ? equipoVisitanteNombre : 'Equipo visitante',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: faseCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fase',
                          prefixIcon: Icon(Icons.flag_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: llaveCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Llave',
                          prefixIcon: Icon(Icons.account_tree_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: jornadaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jornada',
                          prefixIcon: Icon(Icons.calendar_month),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: equipoLocalIdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'ID Equipo Local ($equipoLocalNombre)',
                          prefixIcon: const Icon(Icons.shield),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese ID del equipo local.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: equipoVisitanteIdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'ID Equipo Visitante ($equipoVisitanteNombre)',
                          prefixIcon: const Icon(Icons.shield_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese ID del equipo visitante.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: canchaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cancha',
                          prefixIcon: Icon(Icons.stadium_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                      DropdownButtonFormField<String>(
                        initialValue: estado.isEmpty ? 'PROGRAMADO' : estado,
                        decoration: const InputDecoration(
                          labelText: 'Estado del partido',
                          prefixIcon: Icon(Icons.verified),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'PROGRAMADO', child: Text('PROGRAMADO')),
                          DropdownMenuItem(value: 'EN_CURSO', child: Text('EN_CURSO')),
                          DropdownMenuItem(value: 'FINALIZADO', child: Text('FINALIZADO')),
                          DropdownMenuItem(value: 'CANCELADO', child: Text('CANCELADO')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => estado = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: observacionesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
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
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: guardando ? null : guardarCambios,
                          icon: guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            guardando ? 'GUARDANDO...' : 'GUARDAR CAMBIOS',
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
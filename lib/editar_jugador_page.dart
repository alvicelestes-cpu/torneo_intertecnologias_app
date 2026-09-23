import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/ui_helpers.dart';
import 'models/jugador.dart';
import 'services/jugadores_service.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/player_avatar.dart';

class EditarJugadorPage extends StatefulWidget {
  final int jugadorId;
  final String token;

  const EditarJugadorPage({
    super.key,
    required this.jugadorId,
    required this.token,
  });

  @override
  State<EditarJugadorPage> createState() => _EditarJugadorPageState();
}

class _EditarJugadorPageState extends State<EditarJugadorPage> {
  final _formKey = GlobalKey<FormState>();
  final JugadoresService _jugadoresService = JugadoresService();

  final nombresCtrl = TextEditingController();
  final apellidosCtrl = TextEditingController();
  final numeroCamisetaCtrl = TextEditingController();
  final documentoCtrl = TextEditingController();
  final fechaNacimientoCtrl = TextEditingController();
  final posicionCtrl = TextEditingController();
  final observacionCtrl = TextEditingController();

  bool cargando = true;
  bool guardando = false;
  String? error;

  int? equipoId;
  String equipoNombre = '';
  String? fotoJugador;
  String estado = 'PENDIENTE';

  @override
  void initState() {
    super.initState();
    cargarJugador();
  }

  @override
  void dispose() {
    nombresCtrl.dispose();
    apellidosCtrl.dispose();
    numeroCamisetaCtrl.dispose();
    documentoCtrl.dispose();
    fechaNacimientoCtrl.dispose();
    posicionCtrl.dispose();
    observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarJugador() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final Jugador jugador = await _jugadoresService.getJugadorById(
        widget.jugadorId,
        token: widget.token,
      );

      if (mounted) {
        setState(() {
          equipoId = jugador.equipoId > 0 ? jugador.equipoId : null;
          equipoNombre = jugador.equipoNombre ?? '';
          nombresCtrl.text = jugador.nombres;
          apellidosCtrl.text = jugador.apellidos;
          numeroCamisetaCtrl.text =
              jugador.numeroCamiseta != null ? jugador.numeroCamiseta.toString() : '';
          documentoCtrl.text = jugador.documento ?? '';
          fechaNacimientoCtrl.text = AppDateUtils.formatDate(
            jugador.fechaNacimiento,
            defaultText: '',
          );
          posicionCtrl.text = jugador.posicion ?? '';
          fotoJugador = jugador.fotoJugador;
          estado = jugador.estado.isNotEmpty ? jugador.estado : 'PENDIENTE';
          observacionCtrl.text = jugador.observacionAdmin ?? '';
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
    final actual = DateTime.tryParse(fechaNacimientoCtrl.text.trim());
    if (actual != null) {
      fechaInicial = actual;
    }

    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (fechaSeleccionada == null) return;

    final anio = fechaSeleccionada.year.toString();
    final mes = fechaSeleccionada.month.toString().padLeft(2, '0');
    final dia = fechaSeleccionada.day.toString().padLeft(2, '0');

    setState(() {
      fechaNacimientoCtrl.text = '$anio-$mes-$dia';
    });
  }

  Future<void> guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (equipoId == null) {
      UiHelpers.showError(context, 'El jugador no tiene un equipo válido.');
      return;
    }

    int? numeroCamiseta;
    if (numeroCamisetaCtrl.text.trim().isNotEmpty) {
      numeroCamiseta = int.tryParse(numeroCamisetaCtrl.text.trim());
      if (numeroCamiseta == null) {
        UiHelpers.showError(context, 'El número de camiseta debe ser numérico.');
        return;
      }
    }

    String? fechaNacimiento;
    if (fechaNacimientoCtrl.text.trim().isNotEmpty) {
      final fecha = DateTime.tryParse(fechaNacimientoCtrl.text.trim());
      if (fecha == null) {
        UiHelpers.showError(context, 'La fecha de nacimiento no es válida.');
        return;
      }
      fechaNacimiento = fecha.toIso8601String();
    }

    final body = <String, dynamic>{
      'equipoId': equipoId,
      'nombres': nombresCtrl.text.trim(),
      'apellidos': apellidosCtrl.text.trim(),
      'numeroCamiseta': numeroCamiseta,
      'documento': documentoCtrl.text.trim().isEmpty ? null : documentoCtrl.text.trim(),
      'fechaNacimiento': fechaNacimiento,
      'posicion': posicionCtrl.text.trim().isEmpty ? null : posicionCtrl.text.trim(),
      'fotoJugador': fotoJugador != null && fotoJugador!.trim().isNotEmpty ? fotoJugador!.trim() : null,
      'estado': estado,
      'observacionAdmin': observacionCtrl.text.trim().isEmpty ? null : observacionCtrl.text.trim(),
    };

    setState(() {
      guardando = true;
    });

    try {
      await _jugadoresService.updateJugador(
        widget.jugadorId,
        body,
        token: widget.token,
      );

      if (!mounted) return;
      UiHelpers.showSuccess(context, 'Jugador actualizado correctamente.');
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AppException catch (e) {
      if (!mounted) return;
      UiHelpers.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      UiHelpers.showError(context, 'Error al actualizar el jugador.');
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
            const Text('Editar jugador'),
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
              onRetry: cargarJugador,
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
                      PlayerAvatar(
                        photoUrl: fotoJugador,
                        playerName: '${nombresCtrl.text} ${apellidosCtrl.text}',
                        radius: 65,
                      ),
                      const SizedBox(height: 16),
                      if (equipoNombre.isNotEmpty)
                        Text(
                          equipoNombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nombresCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombres',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Ingrese los nombres.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: apellidosCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Ingrese los apellidos.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: numeroCamisetaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Número de camiseta',
                          prefixIcon: Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: documentoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Documento',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: fechaNacimientoCtrl,
                        readOnly: true,
                        onTap: seleccionarFecha,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento (AAAA-MM-DD)',
                          prefixIcon: Icon(Icons.calendar_today),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: posicionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Posición',
                          prefixIcon: Icon(Icons.sports_soccer),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: estado.isEmpty ? 'PENDIENTE' : estado,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          prefixIcon: Icon(Icons.verified),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'PENDIENTE', child: Text('PENDIENTE')),
                          DropdownMenuItem(value: 'VALIDADO', child: Text('VALIDADO')),
                          DropdownMenuItem(value: 'ACTIVO', child: Text('ACTIVO')),
                          DropdownMenuItem(value: 'RECHAZADO', child: Text('RECHAZADO')),
                          DropdownMenuItem(value: 'INACTIVO', child: Text('INACTIVO')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => estado = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: observacionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observación administrativa',
                          prefixIcon: Icon(Icons.note),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: guardando ? null : guardarCambios,
                          icon: guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
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
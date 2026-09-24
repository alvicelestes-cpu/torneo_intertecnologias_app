import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/mobile_image_picker.dart';
import 'core/utils/ui_helpers.dart';
import 'models/equipo.dart';
import 'models/jugador.dart';
import 'services/equipos_service.dart';
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
  final EquiposService _equiposService = EquiposService();

  final nombresCtrl = TextEditingController();
  final apellidosCtrl = TextEditingController();
  final numeroCamisetaCtrl = TextEditingController();
  final documentoCtrl = TextEditingController();
  final fechaNacimientoCtrl = TextEditingController();
  final posicionCtrl = TextEditingController();
  final observacionCtrl = TextEditingController();

  bool cargando = true;
  bool guardando = false;
  bool procesandoFoto = false;
  String? error;

  List<Equipo> equipos = [];
  int? equipoId;
  String equipoNombre = '';
  String? equipoSigla;
  String? fotoJugador;
  String estado = 'PENDIENTE';

  Uint8List? _nuevaFotoBytes;
  String? _nuevaFotoBase64;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAccesoAdmin();
    });
    cargarDatos();
  }

  void _verificarAccesoAdmin() {
    final session = SessionManager();
    final tieneAcceso = (widget.token.isNotEmpty && session.isAuthenticated) ||
        session.hasAdminAccess;
    if (!tieneAcceso && mounted) {
      UiHelpers.showError(
        context,
        'Acceso restringido: Se requieren permisos de administrador.',
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
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

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultados = await Future.wait([
        _jugadoresService.getJugadorById(widget.jugadorId, token: widget.token),
        _equiposService.getEquipos(token: widget.token).catchError((_) => <Equipo>[]),
      ]);

      final Jugador jugador = resultados[0] as Jugador;
      final List<Equipo> listaEquipos = resultados[1] as List<Equipo>;

      if (mounted) {
        setState(() {
          equipos = listaEquipos;
          equipoId = jugador.equipoId > 0 ? jugador.equipoId : null;
          equipoNombre = jugador.equipoNombre ?? '';
          equipoSigla = jugador.equipoSigla;
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

  Future<void> _seleccionarFoto() async {
    setState(() => procesandoFoto = true);
    UiHelpers.showInfo(context, 'Abriendo selector de imágenes...');

    try {
      final AppPickedImage? picked = await MobileImagePicker.pickImage();

      if (!mounted) return;

      if (picked == null) {
        setState(() => procesandoFoto = false);
        return;
      }

      setState(() {
        _nuevaFotoBytes = picked.bytes;
        _nuevaFotoBase64 = picked.dataUri;
        procesandoFoto = false;
      });

      if (mounted) {
        UiHelpers.showSuccess(context, 'Fotografía cargada correctamente.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => procesandoFoto = false);
        UiHelpers.showError(context, 'No se pudo seleccionar la fotografía: $e');
      }
    }
  }

  void _deshacerFoto() {
    setState(() {
      _nuevaFotoBytes = null;
      _nuevaFotoBase64 = null;
    });
  }

  String get _equipoBadgeText {
    if (equipoId != null) {
      final eq = equipos.where((e) => e.id == equipoId).firstOrNull;
      if (eq != null) {
        return '${eq.nombre} (${eq.sigla})';
      }
    }
    if (equipoNombre.isNotEmpty) {
      if (equipoSigla != null &&
          equipoSigla!.isNotEmpty &&
          !equipoNombre.contains(equipoSigla!)) {
        return '$equipoNombre ($equipoSigla)';
      }
      return equipoNombre;
    }
    return 'Sin equipo asignado';
  }

  Future<void> seleccionarFecha() async {
    DateTime fechaInicial = DateTime(2000, 1, 1);
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
      UiHelpers.showError(context, 'El jugador debe tener un equipo asignado.');
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
      'fotoJugador': _nuevaFotoBase64 ??
          (fotoJugador != null && fotoJugador!.trim().isNotEmpty
              ? fotoJugador!.trim()
              : null),
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
              onRetry: cargarDatos,
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
                      // Avatar interactivo con vista previa y selección de fotografía
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: _seleccionarFoto,
                            child: _nuevaFotoBytes != null
                                ? Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primary, width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.memory(
                                        _nuevaFotoBytes!,
                                        width: 130,
                                        height: 130,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary.withAlpha(90),
                                        width: 2.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: PlayerAvatar(
                                      photoUrl: fotoJugador,
                                      playerName:
                                          '${nombresCtrl.text} ${apellidosCtrl.text}',
                                      radius: 65,
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Material(
                              color: AppColors.primary,
                              shape: const CircleBorder(),
                              elevation: 4,
                              child: InkWell(
                                onTap: _seleccionarFoto,
                                customBorder: const CircleBorder(),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (procesandoFoto)
                            Container(
                              width: 130,
                              height: 130,
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _seleccionarFoto,
                            icon: const Icon(Icons.photo_camera, size: 18),
                            label: const Text('Cambiar fotografía'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          if (_nuevaFotoBytes != null)
                            TextButton.icon(
                              onPressed: _deshacerFoto,
                              icon: const Icon(Icons.undo, size: 18, color: Colors.red),
                              label: const Text(
                                'Deshacer cambio',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Badge compacto y limpio del equipo
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(70),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _equipoBadgeText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Selector de Equipo para reasignación
                      DropdownButtonFormField<int>(
                        initialValue: (equipoId != null && equipos.any((e) => e.id == equipoId))
                            ? equipoId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Equipo asignado',
                          prefixIcon: Icon(Icons.shield_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: equipos.map((e) {
                          return DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(
                              '${e.nombre} (${e.sigla})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final selected =
                                equipos.where((e) => e.id == val).firstOrNull;
                            setState(() {
                              equipoId = val;
                              if (selected != null) {
                                equipoNombre = selected.nombre;
                                equipoSigla = selected.sigla;
                              }
                            });
                          }
                        },
                        validator: (v) => v == null ? 'Seleccione un equipo.' : null,
                      ),
                      const SizedBox(height: 14),

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
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Seleccione la fecha de nacimiento.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: posicionCtrl.text.trim().isNotEmpty
                            ? (const [
                                'Portero',
                                'Defensa',
                                'Mediocampista',
                                'Delantero'
                              ].contains(posicionCtrl.text.trim())
                                ? posicionCtrl.text.trim()
                                : null)
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Posición de juego',
                          prefixIcon: Icon(Icons.sports_soccer),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Portero', child: Text('Portero')),
                          DropdownMenuItem(value: 'Defensa', child: Text('Defensa')),
                          DropdownMenuItem(
                              value: 'Mediocampista', child: Text('Mediocampista')),
                          DropdownMenuItem(
                              value: 'Delantero', child: Text('Delantero')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => posicionCtrl.text = val);
                          }
                        },
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
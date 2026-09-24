import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/ui_helpers.dart';
import 'models/equipo.dart';
import 'models/jugador.dart';
import 'services/equipos_service.dart';
import 'services/jugadores_service.dart';
import 'widgets/app_error_view.dart';
import 'widgets/app_loading_indicator.dart';

class CrearJugadorPage extends StatefulWidget {
  final int? equipoIdInicial;
  final String? equipoNombreInicial;
  final String? token;

  const CrearJugadorPage({
    super.key,
    this.equipoIdInicial,
    this.equipoNombreInicial,
    this.token,
  });

  @override
  State<CrearJugadorPage> createState() => _CrearJugadorPageState();
}

class _CrearJugadorPageState extends State<CrearJugadorPage> {
  final _formKey = GlobalKey<FormState>();
  final JugadoresService _jugadoresService = JugadoresService();
  final EquiposService _equiposService = EquiposService();
  final ImagePicker _picker = ImagePicker();

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
  Map<int, int> conteoPorEquipo = {};
  int? equipoIdSeleccionado;
  String estado = 'ACTIVO';

  Uint8List? _nuevaFotoBytes;
  String? _nuevaFotoBase64;

  static const int kMaxJugadoresPorEquipo = 23;

  @override
  void initState() {
    super.initState();
    equipoIdSeleccionado = widget.equipoIdInicial;
    cargarDatos();
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

  String get _effectiveToken =>
      (widget.token != null && widget.token!.isNotEmpty)
          ? widget.token!
          : SessionManager().token;

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultados = await Future.wait([
        _equiposService.getEquipos(token: _effectiveToken),
        _jugadoresService.getJugadores(token: _effectiveToken).catchError((_) => <Jugador>[]),
      ]);

      final listaEquipos = resultados[0] as List<Equipo>;
      final listaJugadores = resultados[1] as List<Jugador>;

      final mapConteo = <int, int>{};
      for (final j in listaJugadores) {
        if (j.estado.toUpperCase() != 'RECHAZADO') {
          mapConteo[j.equipoId] = (mapConteo[j.equipoId] ?? 0) + 1;
        }
      }

      listaEquipos.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      if (mounted) {
        setState(() {
          equipos = listaEquipos;
          conteoPorEquipo = mapConteo;

          if (equipoIdSeleccionado == null && listaEquipos.isNotEmpty) {
            final disponible = listaEquipos
                .where((e) => (mapConteo[e.id] ?? e.cantidadJugadores) < kMaxJugadoresPorEquipo)
                .firstOrNull;
            equipoIdSeleccionado = disponible?.id ?? listaEquipos.first.id;
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

  Future<void> _seleccionarFoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => procesandoFoto = true);
      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        setState(() => procesandoFoto = false);
        return;
      }

      final mime = pickedFile.mimeType ?? 'image/jpeg';
      final base64String = base64Encode(bytes);
      final dataUri = 'data:$mime;base64,$base64String';

      setState(() {
        _nuevaFotoBytes = bytes;
        _nuevaFotoBase64 = dataUri;
        procesandoFoto = false;
      });
    } catch (e) {
      setState(() => procesandoFoto = false);
      if (mounted) {
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

  Future<void> _seleccionarFecha() async {
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

  int _conteoActualDelEquipo(int eqId) {
    if (conteoPorEquipo.containsKey(eqId)) {
      return conteoPorEquipo[eqId]!;
    }
    final eq = equipos.where((e) => e.id == eqId).firstOrNull;
    return eq?.cantidadJugadores ?? 0;
  }

  bool _equipoEstaLleno(int eqId) {
    return _conteoActualDelEquipo(eqId) >= kMaxJugadoresPorEquipo;
  }

  Future<void> registrarJugador() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (equipoIdSeleccionado == null) {
      UiHelpers.showError(context, 'Seleccione un equipo de destino.');
      return;
    }

    if (_equipoEstaLleno(equipoIdSeleccionado!)) {
      UiHelpers.showError(
        context,
        'El equipo seleccionado ya tiene el límite reglamentario de $kMaxJugadoresPorEquipo jugadores.',
      );
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

    final fecha = DateTime.tryParse(fechaNacimientoCtrl.text.trim());
    if (fecha == null) {
      UiHelpers.showError(context, 'La fecha de nacimiento no es válida.');
      return;
    }

    final body = <String, dynamic>{
      'equipoId': equipoIdSeleccionado,
      'nombres': nombresCtrl.text.trim(),
      'apellidos': apellidosCtrl.text.trim(),
      'numeroCamiseta': numeroCamiseta,
      'documento': documentoCtrl.text.trim().isEmpty ? null : documentoCtrl.text.trim(),
      'fechaNacimiento': fecha.toIso8601String(),
      'posicion': posicionCtrl.text.trim().isEmpty ? null : posicionCtrl.text.trim(),
      'fotoJugador': _nuevaFotoBase64,
      'estado': estado,
      'observacionAdmin': observacionCtrl.text.trim().isEmpty ? null : observacionCtrl.text.trim(),
    };

    setState(() => guardando = true);

    try {
      await _jugadoresService.createJugador(body, token: _effectiveToken);

      if (!mounted) return;
      UiHelpers.showSuccess(context, '¡Jugador inscrito correctamente en el plantel!');
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AppException catch (e) {
      if (!mounted) return;
      UiHelpers.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      UiHelpers.showError(context, 'Error al inscribir el nuevo jugador.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool equipoLleno =
        equipoIdSeleccionado != null && _equipoEstaLleno(equipoIdSeleccionado!);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Inscribir Jugador'),
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
                      // Avatar interactivo con preview y selección de fotografía
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
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary.withAlpha(25),
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
                                    child: const Center(
                                      child: Icon(
                                        Icons.person_add_alt_1,
                                        size: 60,
                                        color: AppColors.primary,
                                      ),
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
                            label: Text(
                              _nuevaFotoBytes != null
                                  ? 'Cambiar fotografía'
                                  : 'Seleccionar fotografía',
                            ),
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
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              label: const Text(
                                'Quitar foto',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Alerta si el equipo seleccionado ya tiene 23 inscritos
                      if (equipoLleno)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade800),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Este equipo ha alcanzado el límite reglamentario máximo de $kMaxJugadoresPorEquipo jugadores inscritos.',
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Selector de Equipo de destino
                      DropdownButtonFormField<int>(
                        initialValue: equipoIdSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Equipo de destino *',
                          prefixIcon: Icon(Icons.shield_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: equipos.map((e) {
                          final cant = _conteoActualDelEquipo(e.id);
                          final lleno = cant >= kMaxJugadoresPorEquipo;

                          return DropdownMenuItem<int>(
                            value: e.id,
                            enabled: !lleno,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${e.nombre} (${e.sigla})',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: lleno ? Colors.grey : Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: lleno
                                        ? Colors.red.withAlpha(30)
                                        : Colors.green.withAlpha(30),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    lleno ? 'LLENO (23/23)' : '$cant/23',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: lleno ? Colors.red.shade700 : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => equipoIdSeleccionado = val);
                          }
                        },
                        validator: (v) {
                          if (v == null) return 'Seleccione el equipo de destino.';
                          if (_equipoEstaLleno(v)) {
                            return 'El equipo ya tiene 23 jugadores inscritos.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: nombresCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombres *',
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
                          labelText: 'Apellidos *',
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
                          labelText: 'Documento de identidad',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: fechaNacimientoCtrl,
                        readOnly: true,
                        onTap: _seleccionarFecha,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento (AAAA-MM-DD) *',
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
                        initialValue: estado,
                        decoration: const InputDecoration(
                          labelText: 'Estado de inscripción',
                          prefixIcon: Icon(Icons.verified),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ACTIVO', child: Text('ACTIVO')),
                          DropdownMenuItem(value: 'VALIDADO', child: Text('VALIDADO')),
                          DropdownMenuItem(value: 'PENDIENTE', child: Text('PENDIENTE')),
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
                            backgroundColor:
                                equipoLleno ? Colors.grey : AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: (guardando || equipoLleno) ? null : registrarJugador,
                          icon: guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.person_add),
                          label: Text(
                            guardando ? 'INSCRIBIENDO...' : 'INSCRIBIR JUGADOR',
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

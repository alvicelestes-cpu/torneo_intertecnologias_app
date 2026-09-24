import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/errors/app_exception.dart';
import 'core/session/session_manager.dart';
import 'core/utils/mobile_image_picker.dart';
import 'core/utils/ui_helpers.dart';
import 'models/equipo.dart';
import 'services/equipos_service.dart';
import 'widgets/team_logo_avatar.dart';

class EditarEquipoPage extends StatefulWidget {
  final Equipo equipo;
  final String? token;

  const EditarEquipoPage({
    super.key,
    required this.equipo,
    this.token,
  });

  @override
  State<EditarEquipoPage> createState() => _EditarEquipoPageState();
}

class _EditarEquipoPageState extends State<EditarEquipoPage> {
  final _formKey = GlobalKey<FormState>();
  final EquiposService _equiposService = EquiposService();

  late TextEditingController nombreCtrl;
  late TextEditingController siglaCtrl;
  late TextEditingController colorCtrl;

  bool cargando = false;
  bool guardando = false;
  bool procesandoEscudo = false;

  Uint8List? _nuevoLogoBytes;
  String? _nuevoLogoBase64;
  String? _currentLogo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAccesoAdmin();
    });

    nombreCtrl = TextEditingController(text: widget.equipo.nombre);
    siglaCtrl = TextEditingController(text: widget.equipo.sigla);
    colorCtrl = TextEditingController(text: widget.equipo.colorPrincipal ?? '#0D47A1');
    _currentLogo = widget.equipo.logo;
  }

  void _verificarAccesoAdmin() {
    final session = SessionManager();
    final tieneAcceso = ((widget.token != null && widget.token!.isNotEmpty) && session.isAuthenticated) ||
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
    nombreCtrl.dispose();
    siglaCtrl.dispose();
    colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarEscudo() async {
    setState(() => procesandoEscudo = true);
    UiHelpers.showInfo(context, 'Abriendo selector de imágenes para el escudo...');

    try {
      final AppPickedImage? picked = await MobileImagePicker.pickImage();

      if (!mounted) return;

      if (picked == null) {
        setState(() => procesandoEscudo = false);
        return;
      }

      setState(() {
        _nuevoLogoBytes = picked.bytes;
        _nuevoLogoBase64 = picked.dataUri;
        procesandoEscudo = false;
      });

      if (mounted) {
        UiHelpers.showSuccess(context, 'Escudo seleccionado correctamente. Previsualización activa.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => procesandoEscudo = false);
        UiHelpers.showError(context, 'No se pudo seleccionar el archivo de escudo: $e');
      }
    }
  }

  void _deshacerEscudo() {
    setState(() {
      _nuevoLogoBytes = null;
      _nuevoLogoBase64 = null;
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => guardando = true);

    final effectiveLogo = _nuevoLogoBase64 ?? _currentLogo;

    final body = <String, dynamic>{
      'id': widget.equipo.id,
      'nombre': nombreCtrl.text.trim(),
      'sigla': siglaCtrl.text.trim().toUpperCase(),
      'colorPrincipal': colorCtrl.text.trim(),
      if (effectiveLogo != null && effectiveLogo.isNotEmpty) 'logo': effectiveLogo,
    };

    final effectiveToken = widget.token ?? SessionManager().token;

    try {
      await _equiposService.updateEquipo(
        widget.equipo.id,
        body,
        token: effectiveToken,
      );

      if (!mounted) return;
      UiHelpers.showSuccess(context, 'Equipo y escudo actualizados correctamente.');
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) {
        UiHelpers.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showError(context, 'Error al guardar los cambios del equipo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamColor = widget.equipo.color;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Editar Club y Escudo'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta principal con el Escudo Interactivo
                  Card(
                    elevation: 2.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        children: [
                          const Text(
                            'ESCUDO OFICIAL DEL CLUB',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Avatar / Escudo interactivo con preview
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: teamColor,
                                      width: 3.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: teamColor.withAlpha(40),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  padding: const EdgeInsets.all(10),
                                  child: Center(
                                    child: _nuevoLogoBytes != null
                                        ? Image.memory(
                                            _nuevoLogoBytes!,
                                            fit: BoxFit.contain,
                                          )
                                        : TeamLogoAvatar(
                                            logoUrl: _currentLogo,
                                            teamName: nombreCtrl.text.isNotEmpty
                                                ? nombreCtrl.text
                                                : widget.equipo.nombre,
                                            sigla: siglaCtrl.text.isNotEmpty
                                                ? siglaCtrl.text
                                                : widget.equipo.sigla,
                                            teamColor: teamColor,
                                            size: 100,
                                            isCircle: true,
                                          ),
                                  ),
                                ),
                                // Botón flotante para seleccionar escudo
                                Material(
                                  color: AppColors.primary,
                                  shape: const CircleBorder(),
                                  elevation: 4,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: procesandoEscudo ? null : _seleccionarEscudo,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: procesandoEscudo
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Botones de acción del escudo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: procesandoEscudo ? null : _seleccionarEscudo,
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text(
                                  'Subir / Cambiar Escudo',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (_nuevoLogoBytes != null) ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    side: BorderSide(color: Colors.red.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                  onPressed: _deshacerEscudo,
                                  icon: const Icon(Icons.undo, size: 16),
                                  label: const Text('Restaurar'),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Formatos admitidos: PNG, JPG, JPEG o Base64',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Formulario de datos del club
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INFORMACIÓN DEL CLUB',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nombre del equipo
                          TextFormField(
                            controller: nombreCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nombre del equipo',
                              prefixIcon: const Icon(Icons.shield),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'El nombre del equipo es obligatorio.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Sigla del equipo
                          TextFormField(
                            controller: siglaCtrl,
                            decoration: InputDecoration(
                              labelText: 'Sigla del equipo (ej. TRF, INP)',
                              prefixIcon: const Icon(Icons.short_text),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'La sigla es obligatoria.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Color principal
                          TextFormField(
                            controller: colorCtrl,
                            decoration: InputDecoration(
                              labelText: 'Color principal (Hexadecimal, ej: #0D47A1)',
                              prefixIcon: const Icon(Icons.palette),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón Guardar Cambios
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: guardando ? null : _guardarCambios,
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
                        guardando ? 'Guardando cambios...' : 'Guardar y Actualizar Escudo',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

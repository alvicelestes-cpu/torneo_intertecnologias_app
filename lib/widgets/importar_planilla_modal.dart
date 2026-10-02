import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core/session/session_manager.dart';
import '../models/resumen_importacion.dart';
import '../services/equipos_service.dart';
import 'importar_planilla_historial_view.dart';

class ImportarPlanillaModal extends StatefulWidget {
  final String? token;
  final EquiposService? equiposService;
  final int? torneoId;
  final String? torneoNombre;
  final int initialTabIndex;

  const ImportarPlanillaModal({
    super.key,
    this.token,
    this.equiposService,
    this.torneoId,
    this.torneoNombre,
    this.initialTabIndex = 0,
  });

  /// Extrae el ID de la hoja de cálculo de Google Sheets.
  /// Soporta URLs completas (https://docs.google.com/spreadsheets/d/ID/...)
  /// y también IDs directos pegados por el usuario.
  static String? extraerGoogleSheetId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 1. Si el usuario ingresó directamente el ID de la hoja
    final idRegex = RegExp(r'^[a-zA-Z0-9_-]{20,100}$');
    if (idRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    // 2. Si es una URL completa de Google Sheets
    final sheetUrlRegex = RegExp(
      r'docs\.google\.com/spreadsheets(?:/u/\d+)?/d/([a-zA-Z0-9_-]+)',
      caseSensitive: false,
    );
    final match = sheetUrlRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      if (id != null && id.length >= 15) {
        return id;
      }
    }

    // 3. Si es un enlace de Google Drive
    final driveUrlRegex = RegExp(
      r'drive\.google\.com/(?:file/d/|open\?id=|uc\?(?:export=[^&]+&)?id=)([a-zA-Z0-9_-]+)',
      caseSensitive: false,
    );
    final driveMatch = driveUrlRegex.firstMatch(trimmed);
    if (driveMatch != null && driveMatch.groupCount >= 1) {
      final id = driveMatch.group(1);
      if (id != null && id.length >= 15) {
        return id;
      }
    }

    return null;
  }

  @override
  State<ImportarPlanillaModal> createState() => _ImportarPlanillaModalState();
}

class _ImportarPlanillaModalState extends State<ImportarPlanillaModal> {
  late final EquiposService _equiposService;
  late int _activeTab;

  int _opcionSeleccionada = 0; // 0: Archivo Local, 1: Enlace Google Drive / Sheets
  Uint8List? _archivoBytes;
  String? _nombreArchivo;

  final TextEditingController _driveUrlController = TextEditingController();
  bool _procesando = false;
  bool _descargandoPlantilla = false;
  String? _errorMensaje;
  ResumenImportacion? _resumenFinal;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
    _equiposService = widget.equiposService ?? EquiposService();
  }

  @override
  void dispose() {
    _driveUrlController.dispose();
    super.dispose();
  }

  int get _resolvedTorneoId =>
      widget.torneoId ?? SessionManager().selectedCampeonatoId;

  String get _resolvedTorneoNombre =>
      widget.torneoNombre ?? SessionManager().selectedCampeonatoNombre;

  Future<void> _seleccionarArchivo() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv', 'xls'],
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _archivoBytes = bytes;
          _nombreArchivo = file.name;
          _errorMensaje = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMensaje = 'Error al seleccionar archivo: $e';
      });
    }
  }

  Future<void> _descargarPlantilla() async {
    setState(() {
      _descargandoPlantilla = true;
    });

    try {
      final bytes = await _equiposService.descargarPlantillaPlanilla(
        token: widget.token,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Plantilla_Planilla_Equipos_Jugadores.xlsx',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plantilla modelo descargada exitosamente.'),
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo descargar la plantilla: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _descargandoPlantilla = false;
        });
      }
    }
  }

  Future<void> _ejecutarImportacion() async {
    setState(() {
      _procesando = true;
      _errorMensaje = null;
    });

    try {
      String? urlParaImportar;

      if (_opcionSeleccionada == 0) {
        if (_archivoBytes == null || _archivoBytes!.isEmpty) {
          setState(() {
            _errorMensaje = 'Por favor selecciona un archivo Excel (.xlsx) o CSV antes de continuar.';
            _procesando = false;
          });
          return;
        }
      } else {
        final rawInput = _driveUrlController.text.trim();
        if (rawInput.isEmpty) {
          setState(() {
            _errorMensaje = 'Por favor ingresa el enlace compartido de Google Drive o Sheets.';
            _procesando = false;
          });
          return;
        }

        final sheetId = ImportarPlanillaModal.extraerGoogleSheetId(rawInput);
        if (sheetId == null) {
          setState(() {
            _errorMensaje = 'El enlace ingresado no es válido. Asegúrate de incluir la URL completa de Google Sheets';
            _procesando = false;
          });
          return;
        }

        // Construir URL canónica de Google Sheets
        urlParaImportar = 'https://docs.google.com/spreadsheets/d/$sheetId/edit';
      }

      final resumen = await _equiposService.importarPlanilla(
        archivoBytes: _opcionSeleccionada == 0 ? _archivoBytes : null,
        nombreArchivo: _opcionSeleccionada == 0 ? _nombreArchivo : null,
        urlGoogleDrive: _opcionSeleccionada == 1 ? urlParaImportar : null,
        campeonatoId: _resolvedTorneoId,
        torneoId: _resolvedTorneoId,
        token: widget.token,
      );

      if (mounted) {
        setState(() {
          _procesando = false;
          if (resumen.exito) {
            _resumenFinal = resumen;
          } else {
            _errorMensaje = resumen.mensaje.isNotEmpty
                ? resumen.mensaje
                : 'Error al procesar la planilla.';
            if (resumen.alertas.isNotEmpty) {
              _resumenFinal = resumen;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        String errorUser = 'Error al procesar la importación: $e';
        if (errStr.contains('401') || errStr.contains('403') || errStr.contains('500') || errStr.contains('permiso')) {
          errorUser = "No se pudo acceder a la hoja. Verifica que tenga permisos de lectura públicos ('Cualquier persona con el enlace')";
        }
        setState(() {
          _procesando = false;
          _errorMensaje = errorUser;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _activeTab == 1 ? 750 : 620,
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _construirEncabezado(context),
              const SizedBox(height: 8),
              _construirTabSelector(),
              const SizedBox(height: 10),
              if (_activeTab == 1)
                ImportarPlanillaHistorialView(
                  torneoId: _resolvedTorneoId,
                  torneoNombre: _resolvedTorneoNombre,
                  token: widget.token,
                  equiposService: _equiposService,
                )
              else if (_resumenFinal != null && _resumenFinal!.exito)
                _construirVistaExito(context)
              else
                _construirFormularioImportacion(context, theme, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirEncabezado(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            color: Color(0xFF0F766E),
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Importar Planilla Masiva',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Torneo: $_resolvedTorneoNombre',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
          onPressed: _procesando ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _construirTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: const Key('tab_importar_planilla'),
              onTap: _procesando ? null : () => setState(() => _activeTab = 0),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _activeTab == 0
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 16,
                      color: _activeTab == 0 ? const Color(0xFF0F766E) : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Importar Planilla',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _activeTab == 0 ? const Color(0xFF0F766E) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              key: const Key('tab_historial_importaciones'),
              onTap: _procesando ? null : () => setState(() => _activeTab = 1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _activeTab == 1
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: _activeTab == 1 ? const Color(0xFF0F766E) : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Historial',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _activeTab == 1 ? const Color(0xFF0F766E) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFormularioImportacion(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // ==================== DESCARGA PLANTILLA MODELO ====================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.table_chart_outlined, color: Color(0xFF15803D), size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '¿No tienes el formato oficial de columnas?',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('btn_descargar_plantilla_modelo'),
                onPressed: _descargandoPlantilla ? null : _descargarPlantilla,
                icon: _descargandoPlantilla
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF15803D)),
                      )
                    : const Icon(Icons.download, size: 16, color: Color(0xFF15803D)),
                label: const Text(
                  'Descargar Modelo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ==================== SELECTOR DE MÉTODO ====================
        Row(
          children: [
            Expanded(
              child: _construirPillOpcion(
                titulo: 'Archivo (.xlsx / .csv)',
                icono: Icons.description_outlined,
                index: 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _construirPillOpcion(
                titulo: 'Google Drive / Sheets',
                icono: Icons.link,
                index: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ==================== CUERPO SEGÚN MÉTODO ====================
        if (_opcionSeleccionada == 0) ...[
          // Opción A: Archivo local
          InkWell(
            onTap: _procesando ? null : _seleccionarArchivo,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _archivoBytes != null
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFCBD5E1),
                  width: _archivoBytes != null ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _archivoBytes != null
                        ? Icons.check_circle_outline
                        : Icons.upload_file_outlined,
                    size: 38,
                    color: _archivoBytes != null
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 10),
                  if (_archivoBytes != null) ...[
                    Text(
                      _nombreArchivo ?? 'Archivo seleccionado',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F766E),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_archivoBytes!.length / 1024).toStringAsFixed(1)} KB listos para importar',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _procesando ? null : _seleccionarArchivo,
                      child: const Text('Cambiar archivo'),
                    ),
                  ] else ...[
                    const Text(
                      'Haz clic para seleccionar tu archivo Excel o CSV',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: Color(0xFF334155),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Formatos admitidos: .xlsx, .csv, .xls',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ] else ...[
          // Opción B: Enlace de Google Drive / Sheets
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enlace público de Google Sheets o Google Drive',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('input_enlace_google_drive'),
                controller: _driveUrlController,
                enabled: !_procesando,
                decoration: InputDecoration(
                  hintText: 'https://docs.google.com/spreadsheets/d/...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.link, color: Color(0xFF0F766E)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'El enlace debe tener permisos de acceso público ("Cualquier persona con el enlace puede ver").',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],

        // ==================== MENSAJE DE ERROR ====================
        if (_errorMensaje != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMensaje!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ==================== BARRA DE PROGRESO ====================
        if (_procesando) ...[
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Procesando planilla en el servidor...',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  color: Color(0xFF0F766E),
                  backgroundColor: Color(0xFFE2E8F0),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Creando equipos no existentes, validando edades y vinculando al torneo.',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],

        const SizedBox(height: 12),

        // ==================== BOTONES DE ACCIÓN ====================
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _procesando ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              key: const Key('btn_ejecutar_importacion'),
              onPressed: _procesando ? null : _ejecutarImportacion,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text(_procesando ? 'Importando...' : 'Comenzar Importación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _construirPillOpcion({
    required String titulo,
    required IconData icono,
    required int index,
  }) {
    final activa = _opcionSeleccionada == index;
    return InkWell(
      onTap: _procesando ? null : () => setState(() => _opcionSeleccionada = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: activa ? const Color(0xFF0F766E).withAlpha(20) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: activa ? const Color(0xFF0F766E) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 18,
              color: activa ? const Color(0xFF0F766E) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: activa ? FontWeight.bold : FontWeight.w500,
                  color: activa ? const Color(0xFF0F766E) : const Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirVistaExito(BuildContext context) {
    final resumen = _resumenFinal!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF16A34A),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '¡Importación Completada!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          resumen.mensaje,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Métricas resumidas
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _construirMetrica(
                titulo: 'Equipos Nuevos',
                valor: resumen.equiposCreados.toString(),
                icono: Icons.groups_outlined,
                color: const Color(0xFF0D57AA),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              _construirMetrica(
                titulo: 'Jugadores Inscritos',
                valor: resumen.jugadoresRegistrados.toString(),
                icono: Icons.person_add_alt,
                color: const Color(0xFF0F766E),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              _construirMetrica(
                titulo: 'Filas Totales',
                valor: resumen.filasProcesadas.toString(),
                icono: Icons.list_alt,
                color: const Color(0xFF64748B),
              ),
            ],
          ),
        ),

        // Alertas u omisiones si existen
        if (resumen.alertas.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Observaciones / Filas Omitidas (${resumen.alertas.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: resumen.alertas.length,
                    itemBuilder: (context, idx) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${resumen.alertas[idx]}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('btn_ver_historial_exito'),
                onPressed: () {
                  setState(() {
                    _resumenFinal = null;
                    _activeTab = 1;
                  });
                },
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Ver en Historial'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                key: const Key('btn_cerrar_resumen_importacion'),
                onPressed: () => Navigator.of(context).pop(true), // Retorna true para recargar equipos
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Aceptar y Ver Equipos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _construirMetrica({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

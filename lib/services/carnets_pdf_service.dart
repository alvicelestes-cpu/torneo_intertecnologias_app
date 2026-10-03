import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/app_colors.dart';
import '../core/session/session_manager.dart';
import '../core/theme/tournament_theme.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/player_sort_utils.dart';
import '../models/equipo.dart';
import '../models/jugador.dart';
import 'torneo_config_service.dart';

/// Servicio especializado en la generación, descarga e impresión en formato PDF
/// de los Carnets Oficiales de Jugadores por Equipo.
class CarnetsPdfService {
  CarnetsPdfService._();

  /// Obtiene el color reglamentario del carnet según la edad del jugador:
  /// - Edad >= 40 años: Verde (#226C2A / Mayores de 40 años)
  /// - Edad >= 35 y Edad <= 39 años: Naranja / Terracota (#B84500 / Entre 35 y 39 años)
  /// - Edad < 35 años (18 a 34 años): Azul (#0D57AA / De 18 a 34 años)
  /// - Edad no disponible / null: Neutro (#546E7A o color del equipo)
  static PdfColor obtenerColorPorEdad(int? edad, {PdfColor? fallbackColor}) {
    if (edad == null) {
      return fallbackColor ?? PdfColor.fromInt(AppColors.carnetNeutro.toARGB32());
    }
    if (edad >= 40) {
      return PdfColor.fromHex('#226C2A');
    }
    if (edad >= 35 && edad <= 39) {
      return PdfColor.fromHex('#B84500');
    }
    return PdfColor.fromHex('#0D57AA');
  }

  /// Genera el nombre de archivo estandarizado para el PDF del equipo.
  /// Ejemplo: Carnets_GREMIO_HFC.pdf
  static String getFilename(String equipoNombre) {
    final clean = equipoNombre
        .trim()
        .replaceAll(RegExp(r'[^\w\s\u00C0-\u017F-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toUpperCase();
    return 'Carnets_${clean.isEmpty ? "EQUIPO" : clean}.pdf';
  }

  /// Construye el documento PDF con todos los carnets del equipo,
  /// respetando la disposición de 2 columnas x 4 filas (máximo 8 por página).
  static Future<Uint8List> generarCarnetsPdf({
    required Equipo equipo,
    required List<Jugador> jugadores,
    String? torneoNombre,
    int? torneoId,
    TournamentTheme? tournamentTheme,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    // 1. Resolver nombre del torneo activo y tema correspondiente
    final torneo = (torneoNombre != null && torneoNombre.trim().isNotEmpty)
        ? torneoNombre.trim()
        : (SessionManager().selectedCampeonatoNombre.isNotEmpty
            ? SessionManager().selectedCampeonatoNombre
            : TorneoConfigService().nombreTorneo);

    final resolvedTheme = tournamentTheme ??
        TournamentTheme.fromIdOrSlug(
          id: torneoId ??
              (equipo.campeonatoId != 0
                  ? equipo.campeonatoId
                  : (SessionManager().selectedCampeonatoId != 0
                      ? SessionManager().selectedCampeonatoId
                      : null)),
          nombre: torneo,
        );

    // 2. Filtrar y ordenar jugadores activos por edad descendente
    List<Jugador> jugadoresProcesados = jugadores
        .where((j) => j.estado.trim().toUpperCase() != 'INACTIVO')
        .toList();
    if (jugadoresProcesados.isEmpty && jugadores.isNotEmpty) {
      jugadoresProcesados = List<Jugador>.from(jugadores);
    }
    jugadoresProcesados.sort(compareJugadoresPorEdad);

    // 3. Cargar fuentes con soporte para acentos y fallback seguro
    pw.Font? ttfRegular;
    pw.Font? ttfBold;
    try {
      ttfRegular = await PdfGoogleFonts.latoRegular();
      ttfBold = await PdfGoogleFonts.latoBold();
    } catch (_) {
      ttfRegular = pw.Font.helvetica();
      ttfBold = pw.Font.helveticaBold();
    }

    final theme = pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
    );

    // 4. Cargar recursos gráficos (escudo y fotos de jugadores)
    final logoImage = await _cargarEscudoEquipo(equipo);
    final fotosJugadores = await _cargarFotosJugadores(jugadoresProcesados);

    // 5. Color base del club
    final teamColor = PdfColor.fromInt(equipo.color.toARGB32());

    // 6. Construir documento y paginar en grupos de 8 carnets
    final doc = pw.Document(theme: theme);

    if (jugadoresProcesados.isEmpty) {
      // Página vacía informativa si no hay jugadores
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(34.0),
          build: (context) {
            return pw.Center(
              child: pw.Text(
                'No hay jugadores registrados para el equipo ${equipo.nombre}.',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#4B5563'),
                ),
              ),
            );
          },
        ),
      );
    } else {
      final chunks = <List<Jugador>>[];
      for (var i = 0; i < jugadoresProcesados.length; i += 8) {
        chunks.add(
          jugadoresProcesados.sublist(
            i,
            min(i + 8, jugadoresProcesados.length),
          ),
        );
      }

      for (final chunk in chunks) {
        doc.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: const pw.EdgeInsets.symmetric(horizontal: 34.0, vertical: 34.0),
            build: (context) {
              return pw.GridView(
                crossAxisCount: 2,
                childAspectRatio: 257.8 / 172.9,
                crossAxisSpacing: 11.6,
                mainAxisSpacing: 11.3,
                children: chunk.map((j) {
                  return _construirTarjetaCarnet(
                    equipo: equipo,
                    jugador: j,
                    torneoNombre: torneo,
                    teamColor: teamColor,
                    logoImage: logoImage,
                    playerPhoto: fotosJugadores[j.id],
                    theme: resolvedTheme,
                  );
                }).toList(),
              );
            },
          ),
        );
      }
    }

    return doc.save();
  }

  /// Construye individualmente la tarjeta de carnet
  static pw.Widget _construirTarjetaCarnet({
    required Equipo equipo,
    required Jugador jugador,
    required String torneoNombre,
    required PdfColor teamColor,
    required pw.MemoryImage? logoImage,
    required pw.MemoryImage? playerPhoto,
    TournamentTheme? theme,
  }) {
    final activeTheme = theme ?? TournamentTheme.fromIdOrSlug(nombre: torneoNombre);
    final isBanquita = activeTheme.isBanquita;
    final edad = jugador.edad;

    // Para Banquita ID 2: Identidad verde profesional con gradiente y acentos dorados
    // Para Intertecnologías ID 1: Colores reglamentarios oficiales por edad
    final carnetColor = isBanquita
        ? PdfColor.fromHex('#064E3B')
        : obtenerColorPorEdad(edad, fallbackColor: teamColor);

    final borderColor = isBanquita
        ? PdfColor.fromHex('#047857')
        : carnetColor;

    final dorsalBadgeColor = isBanquita
        ? PdfColor.fromHex('#F59E0B')
        : PdfColor.fromInt(0x42000000);

    final pillBgColor = isBanquita
        ? PdfColor.fromHex('#ECFDF5')
        : _calcularColorPastel(carnetColor);

    final fechaNac = AppDateUtils.formatDate(
      jugador.fechaNacimiento,
      defaultText: 'Sin fecha',
    );
    final edadTxt = edad != null ? '$edad años' : '--';

    return pw.Container(
      width: 257.8,
      height: 172.9,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderColor, width: 1.0),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 6,
        verticalRadius: 6,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ==================== ENCABEZADO ====================
            pw.Container(
              height: 58,
              decoration: isBanquita
                  ? pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [
                          PdfColor.fromHex('#064E3B'),
                          PdfColor.fromHex('#047857'),
                        ],
                        begin: pw.Alignment.topLeft,
                        end: pw.Alignment.bottomRight,
                      ),
                    )
                  : pw.BoxDecoration(
                      color: carnetColor,
                    ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Escudo / Sigla del club
                  pw.Container(
                    width: 38,
                    height: 38,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Center(
                      child: logoImage != null
                          ? pw.Padding(
                              padding: const pw.EdgeInsets.all(2),
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            )
                          : pw.Text(
                              equipo.sigla.isNotEmpty
                                  ? equipo.sigla.toUpperCase()
                                  : equipo.iniciales.toUpperCase(),
                              style: pw.TextStyle(
                                color: isBanquita ? PdfColor.fromHex('#064E3B') : carnetColor,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  // Nombre del club y Nombre del jugador
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          equipo.nombre.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          jugador.nombreCompleto.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  if (jugador.numeroCamiseta != null) ...[
                    pw.SizedBox(width: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                      decoration: pw.BoxDecoration(
                        color: dorsalBadgeColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        '#${jugador.numeroCamiseta}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ==================== CUERPO ====================
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Izquierda: Foto del jugador (o silueta por defecto)
                  pw.Container(
                    width: 88,
                    color: PdfColor.fromHex('#F3F4F6'),
                    child: playerPhoto != null
                        ? pw.Image(playerPhoto, fit: pw.BoxFit.cover)
                        : _construirSiluetaAvatar(),
                  ),

                  // Derecha: Datos de nacimiento, edad, torneo y leyenda
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: 6,
                        bottom: 6,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          // Pastilla con Nacimiento y Edad
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: pillBgColor,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4),
                              ),
                            ),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'NACIMIENTO',
                                      style: pw.TextStyle(
                                        color: PdfColor.fromHex('#6B7280'),
                                        fontSize: 6,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.SizedBox(height: 1),
                                    pw.Text(
                                      fechaNac,
                                      style: pw.TextStyle(
                                        color: PdfColors.black,
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.Text(
                                      'EDAD',
                                      style: pw.TextStyle(
                                        color: isBanquita
                                            ? PdfColor.fromHex('#064E3B')
                                            : PdfColor.fromHex('#6B7280'),
                                        fontSize: 6,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.SizedBox(height: 1),
                                    pw.Text(
                                      edadTxt,
                                      style: pw.TextStyle(
                                        color: isBanquita
                                            ? PdfColor.fromHex('#064E3B')
                                            : PdfColors.black,
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Línea divisoria sutil
                          pw.Container(
                            height: 0.5,
                            color: PdfColor.fromHex('#E5E7EB'),
                          ),

                          // Nombre del torneo activo dinámico
                          pw.Text(
                            torneoNombre.toUpperCase(),
                            style: pw.TextStyle(
                              color: isBanquita ? PdfColor.fromHex('#064E3B') : carnetColor,
                              fontSize: 6.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            maxLines: 2,
                          ),

                          // Leyenda institucional sutil
                          pw.Text(
                            'Jugador autorizado',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#6B7280'),
                              fontSize: 7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Silueta de avatar vectorial cuando no hay foto disponible
  static pw.Widget _construirSiluetaAvatar() {
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            width: 28,
            height: 28,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#CBD5E1'),
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: 46,
            height: 20,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#CBD5E1'),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(14),
                topRight: pw.Radius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula un color pastel opaco derivado del color principal del equipo
  static PdfColor _calcularColorPastel(PdfColor baseColor) {
    final r = baseColor.red + (1.0 - baseColor.red) * 0.86;
    final g = baseColor.green + (1.0 - baseColor.green) * 0.86;
    final b = baseColor.blue + (1.0 - baseColor.blue) * 0.86;
    return PdfColor(r.clamp(0.0, 1.0), g.clamp(0.0, 1.0), b.clamp(0.0, 1.0));
  }

  /// Carga el escudo del club desde Asset, Base64 o URL remota
  static Future<pw.MemoryImage?> _cargarEscudoEquipo(Equipo equipo) async {
    final logoResolved = ImageUtils.resolveTeamLogo(
      equipo.logo,
      teamName: equipo.nombre,
      sigla: equipo.sigla,
    );

    if (logoResolved == null || logoResolved.isEmpty) return null;

    final bytes = await _obtenerBytesImagen(logoResolved);
    if (bytes != null && bytes.isNotEmpty) {
      try {
        return pw.MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Carga de forma concurrente las fotos de todos los jugadores
  static Future<Map<int, pw.MemoryImage>> _cargarFotosJugadores(
    List<Jugador> jugadores,
  ) async {
    final result = <int, pw.MemoryImage>{};

    final tareas = jugadores.map((j) async {
      final foto = j.fotoJugador?.trim();
      if (foto != null && foto.isNotEmpty) {
        final bytes = await _obtenerBytesImagen(foto);
        if (bytes != null && bytes.isNotEmpty) {
          try {
            final img = pw.MemoryImage(bytes);
            return MapEntry<int, pw.MemoryImage>(j.id, img);
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    });

    final cargadas = await Future.wait(tareas);
    for (final entry in cargadas) {
      if (entry != null) {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  /// Obtiene los bytes de una imagen desde Base64, Asset o HTTP
  static Future<Uint8List?> _obtenerBytesImagen(String uriOPath) async {
    try {
      final str = uriOPath.trim();
      if (str.isEmpty || str == 'null' || str == 'string') return null;

      // 1. Base64 data URI
      if (str.startsWith('data:image')) {
        final commaIdx = str.indexOf(',');
        if (commaIdx != -1) {
          final b64 = str.substring(commaIdx + 1);
          return base64Decode(b64);
        }
      }

      // 2. Asset bundle
      if (str.startsWith('assets/')) {
        final byteData = await rootBundle.load(str);
        return byteData.buffer.asUint8List();
      }

      // 3. URL remota
      final url = ImageUtils.resolveUrl(str);
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 4),
        );
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      }
    } catch (_) {
      // Ignorar fallo de carga de imagen individual
    }
    return null;
  }

  /// Comprueba si el usuario autenticado tiene permisos de administración
  /// (ADMIN, SUPERADMIN o ADMINISTRADOR) para generar, descargar o imprimir carnets.
  static bool tienePermisoAdministrador({SessionManager? sessionManager}) {
    final session = sessionManager ?? SessionManager();
    return session.hasAdminAccess;
  }

  /// Flujo interactivo: Genera y descarga el documento de carnets en el dispositivo / navegador.
  /// Muestra un modal de carga durante el proceso y notifica con un SnackBar al finalizar.
  static Future<void> descargarCarnetsConFeedback({
    required BuildContext context,
    required Equipo equipo,
    required List<Jugador> jugadores,
    String? torneoNombre,
    int? torneoId,
    TournamentTheme? tournamentTheme,
    bool verificarPermisos = true,
  }) async {
    // 0. Comprobación de seguridad: Solo administradores autorizados
    if (verificarPermisos && !tienePermisoAdministrador()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso restringido: Solo administradores autorizados pueden descargar carnets.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 1. Mostrar diálogo de progreso
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generando carnets...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      equipo.nombre,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final pdfBytes = await generarCarnetsPdf(
        equipo: equipo,
        jugadores: jugadores,
        torneoNombre: torneoNombre,
        torneoId: torneoId,
        tournamentTheme: tournamentTheme ?? (context.mounted ? TournamentTheme.of(context) : null),
      );

      final filename = getFilename(equipo.nombre);

      // Cerrar diálogo de progreso
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Descargar directamente vía Printing.sharePdf
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Carnets de ${equipo.nombre} generados exitosamente ($filename)',
            ),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Imprimir',
              textColor: Colors.white,
              onPressed: () {
                Printing.layoutPdf(
                  onLayout: (_) async => pdfBytes,
                  name: filename,
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar carnets: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Abre la vista previa o diálogo de impresión del navegador/sistema operativo
  static Future<void> imprimirCarnetsConFeedback({
    required BuildContext context,
    required Equipo equipo,
    required List<Jugador> jugadores,
    String? torneoNombre,
    int? torneoId,
    TournamentTheme? tournamentTheme,
    bool verificarPermisos = true,
  }) async {
    // 0. Comprobación de seguridad: Solo administradores autorizados
    if (verificarPermisos && !tienePermisoAdministrador()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso restringido: Solo administradores autorizados pueden imprimir carnets.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final filename = getFilename(equipo.nombre);

    await Printing.layoutPdf(
      onLayout: (format) => generarCarnetsPdf(
        equipo: equipo,
        jugadores: jugadores,
        torneoNombre: torneoNombre,
        torneoId: torneoId,
        tournamentTheme: tournamentTheme ?? (context.mounted ? TournamentTheme.of(context) : null),
        pageFormat: format,
      ),
      name: filename,
    );
  }
}

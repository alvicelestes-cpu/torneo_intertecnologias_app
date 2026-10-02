import 'dart:convert';
import 'resumen_importacion.dart';

class ImportacionHistorialItem {
  final int id;
  final int torneoId;
  final int campeonatoId;
  final DateTime fechaImportacion;
  final String nombreArchivo;
  final int? usuarioId;
  final String? usuarioNombre;
  final int filasProcesadas;
  final int jugadoresRegistrados;
  final int jugadoresOmitidos;
  final int equiposCreados;
  final int equiposExistentes;
  final int duplicadosDocumento;
  final int conflictosDorsal;
  final int alertasCantidad;
  final int erroresCantidad;
  final bool exito;
  final String mensaje;
  final String? resumenJson;
  final List<String> alertas;
  final List<DetalleEquipoImportado> equiposDetalle;
  final DateTime? createdAt;

  const ImportacionHistorialItem({
    required this.id,
    required this.torneoId,
    required this.campeonatoId,
    required this.fechaImportacion,
    required this.nombreArchivo,
    this.usuarioId,
    this.usuarioNombre,
    this.filasProcesadas = 0,
    this.jugadoresRegistrados = 0,
    this.jugadoresOmitidos = 0,
    this.equiposCreados = 0,
    this.equiposExistentes = 0,
    this.duplicadosDocumento = 0,
    this.conflictosDorsal = 0,
    this.alertasCantidad = 0,
    this.erroresCantidad = 0,
    required this.exito,
    this.mensaje = '',
    this.resumenJson,
    this.alertas = const [],
    this.equiposDetalle = const [],
    this.createdAt,
  });

  /// Determina el estado semántico de la importación para presentación visual
  String get estadoVisual {
    if (!exito) return 'Error';
    if (alertasCantidad > 0 || duplicadosDocumento > 0 || conflictosDorsal > 0) {
      return 'Éxito con alertas';
    }
    return 'Éxito';
  }

  factory ImportacionHistorialItem.fromJson(Map<String, dynamic> json) {
    DateTime fecha = DateTime.now();
    if (json['fechaImportacion'] != null) {
      try {
        fecha = DateTime.parse(json['fechaImportacion'].toString());
      } catch (_) {}
    }

    DateTime? created;
    if (json['createdAt'] != null) {
      try {
        created = DateTime.parse(json['createdAt'].toString());
      } catch (_) {}
    }

    List<String> parsedAlertas = [];
    List<DetalleEquipoImportado> parsedEquipos = [];

    final rawJson = json['resumenJson']?.toString();
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          if (decoded['alertas'] is List) {
            parsedAlertas = (decoded['alertas'] as List)
                .map((a) => a.toString())
                .toList();
          }
          if (decoded['equiposDetalle'] is List) {
            parsedEquipos = (decoded['equiposDetalle'] as List)
                .map((e) => DetalleEquipoImportado.fromJson(
                      e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
                    ))
                .toList();
          }
        }
      } catch (_) {}
    }

    return ImportacionHistorialItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      torneoId: (json['torneoId'] as num?)?.toInt() ?? 0,
      campeonatoId: (json['campeonatoId'] as num?)?.toInt() ?? 0,
      fechaImportacion: fecha,
      nombreArchivo: json['nombreArchivo']?.toString() ?? 'Planilla',
      usuarioId: (json['usuarioId'] as num?)?.toInt(),
      usuarioNombre: json['usuarioNombre']?.toString(),
      filasProcesadas: (json['filasProcesadas'] as num?)?.toInt() ?? 0,
      jugadoresRegistrados: (json['jugadoresRegistrados'] as num?)?.toInt() ?? 0,
      jugadoresOmitidos: (json['jugadoresOmitidos'] as num?)?.toInt() ?? 0,
      equiposCreados: (json['equiposCreados'] as num?)?.toInt() ?? 0,
      equiposExistentes: (json['equiposExistentes'] as num?)?.toInt() ?? 0,
      duplicadosDocumento: (json['duplicadosDocumento'] as num?)?.toInt() ?? 0,
      conflictosDorsal: (json['conflictosDorsal'] as num?)?.toInt() ?? 0,
      alertasCantidad: (json['alertasCantidad'] as num?)?.toInt() ?? 0,
      erroresCantidad: (json['erroresCantidad'] as num?)?.toInt() ?? 0,
      exito: json['exito'] == true,
      mensaje: json['mensaje']?.toString() ?? '',
      resumenJson: rawJson,
      alertas: parsedAlertas,
      equiposDetalle: parsedEquipos,
      createdAt: created,
    );
  }
}

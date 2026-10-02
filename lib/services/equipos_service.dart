import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../models/equipo.dart';
import '../models/importacion_historial_item.dart';
import '../models/jugador.dart';
import '../models/resumen_importacion.dart';

class EquiposService {
  final ApiClient _apiClient;
  EquiposService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Equipo>> getEquipos({
    String? token,
    int? campeonatoId,
    int? torneoId,
  }) async {
    final resolvedId = torneoId ?? campeonatoId ?? SessionManager().selectedCampeonatoId;
    final query = resolvedId > 0 ? '?campeonatoId=$resolvedId' : '';
    final response = await _apiClient.get(
      '${ApiConstants.equipos}$query',
      token: token,
      headers: resolvedId > 0
          ? {
              'X-Campeonato-Id': resolvedId.toString(),
              'X-Torneo-Id': resolvedId.toString(),
            }
          : null,
    );

    if (response is List) {
      return response
          .map((item) => Equipo.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw const AppException('La respuesta del servidor no tiene el formato esperado.');
  }

  Future<List<Jugador>> getJugadoresEquipo(
    int equipoId, {
    String? token,
    int? campeonatoId,
    int? torneoId,
  }) async {
    final resolvedId = torneoId ?? campeonatoId ?? SessionManager().selectedCampeonatoId;
    final query = resolvedId > 0 ? '?campeonatoId=$resolvedId' : '';
    final response = await _apiClient.get(
      '${ApiConstants.equipoJugadores(equipoId)}$query',
      token: token,
      headers: resolvedId > 0
          ? {
              'X-Campeonato-Id': resolvedId.toString(),
              'X-Torneo-Id': resolvedId.toString(),
            }
          : null,
    );

    if (response is List) {
      return response
          .map((item) => Jugador.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    if (response is Map<String, dynamic> && response['jugadores'] is List) {
      return (response['jugadores'] as List)
          .map((item) => Jugador.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw const AppException('La respuesta no contiene una lista válida de jugadores.');
  }

  Future<Equipo> getEquipoById(int id, {String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.equipoDetalle(id),
      token: token,
    );

    if (response is Map<String, dynamic>) {
      if (response['equipo'] is Map) {
        return Equipo.fromJson(Map<String, dynamic>.from(response['equipo'] as Map));
      }
      return Equipo.fromJson(response);
    }

    throw const AppException('No se pudo obtener la información del equipo.');
  }

  Future<void> updateEquipo(int id, Map<String, dynamic> data, {String? token}) async {
    await _apiClient.put(
      ApiConstants.equipoDetalle(id),
      body: data,
      token: token,
    );
  }

  /// Elimina un equipo y opcionalmente pasa contexto de torneo/campeonato (Requiere Admin)
  Future<void> eliminarEquipo(
    int id, {
    String? token,
    int? campeonatoId,
    int? torneoId,
  }) async {
    final session = SessionManager();
    final effectiveToken = (token != null && token.isNotEmpty)
        ? token
        : session.token;

    final bool esAdmin = (token != null && token.isNotEmpty && session.currentUser == null)
        ? true
        : session.hasAdminAccess;

    if (effectiveToken.isEmpty || !esAdmin) {
      throw const AuthException(
        'Acceso restringido: Se requiere una sesión activa con permisos de Administrador para eliminar equipos.',
      );
    }

    final resolvedId = torneoId ?? campeonatoId ?? session.selectedCampeonatoId;
    final query = resolvedId > 0 ? '?campeonatoId=$resolvedId' : '';
    await _apiClient.delete(
      '${ApiConstants.equipoDetalle(id)}$query',
      token: effectiveToken,
      headers: resolvedId > 0
          ? {
              'X-Campeonato-Id': resolvedId.toString(),
              'X-Torneo-Id': resolvedId.toString(),
            }
          : null,
    );
  }

  Future<void> deleteEquipo(
    int id, {
    String? token,
    int? campeonatoId,
    int? torneoId,
  }) =>
      eliminarEquipo(id, token: token, campeonatoId: campeonatoId, torneoId: torneoId);



  /// Crea un nuevo equipo asociado al torneo activo
  Future<Equipo> crearEquipo({
    required String nombre,
    String? sigla,
    String? colorPrincipal,
    String? logo,
    int? campeonatoId,
    int? torneoId,
    String? token,
  }) async {
    final session = SessionManager();
    final resolvedTorneoId = torneoId ?? campeonatoId ?? session.selectedCampeonatoId;

    final payload = <String, dynamic>{
      'nombre': nombre.trim(),
      if (sigla != null && sigla.trim().isNotEmpty) 'sigla': sigla.trim(),
      'colorPrincipal': (colorPrincipal != null && colorPrincipal.trim().isNotEmpty)
          ? colorPrincipal.trim()
          : '#0d6efd',
      if (logo != null && logo.trim().isNotEmpty) 'logo': logo.trim(),
      'campeonatoId': resolvedTorneoId,
      'torneoId': resolvedTorneoId,
    };

    final response = await _apiClient.post(
      ApiConstants.equipos,
      body: payload,
      token: token ?? (session.token.isNotEmpty ? session.token : null),
    );

    if (response is Map<String, dynamic>) {
      if (response['equipo'] is Map) {
        return Equipo.fromJson(Map<String, dynamic>.from(response['equipo'] as Map));
      }
      return Equipo.fromJson(response);
    }

    throw const AppException('Respuesta inesperada al crear el equipo.');
  }

  /// Importa masivamente una planilla de equipos y jugadores vía POST /api/equipos/importar-planilla
  Future<ResumenImportacion> importarPlanilla({
    Uint8List? archivoBytes,
    String? nombreArchivo,
    String? urlGoogleDrive,
    int? campeonatoId,
    int? torneoId,
    String? token,
  }) async {
    final session = SessionManager();
    final effectiveToken = (token != null && token.isNotEmpty)
        ? token
        : session.token;
    final resolvedTorneoId = torneoId ?? campeonatoId ?? session.selectedCampeonatoId;

    final uri = Uri.parse(ApiConstants.importarPlanilla).replace(
      queryParameters: resolvedTorneoId > 0
          ? {'campeonatoId': resolvedTorneoId.toString()}
          : null,
    );

    final request = http.MultipartRequest('POST', uri);

    final headers = ApiConstants.defaultHeaders(
      token: effectiveToken,
      campeonatoId: resolvedTorneoId,
      torneoId: resolvedTorneoId,
      torneoSlug: session.selectedCampeonatoSlug,
    );
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    if (resolvedTorneoId > 0) {
      request.fields['campeonatoId'] = resolvedTorneoId.toString();
      request.fields['torneoId'] = resolvedTorneoId.toString();
    }

    if (urlGoogleDrive != null && urlGoogleDrive.trim().isNotEmpty) {
      request.fields['urlGoogleDrive'] = urlGoogleDrive.trim();
      request.fields['enlaceDrive'] = urlGoogleDrive.trim();
    }

    if (archivoBytes != null && archivoBytes.isNotEmpty) {
      final filename = (nombreArchivo != null && nombreArchivo.trim().isNotEmpty)
          ? nombreArchivo.trim()
          : 'planilla.xlsx';
      final multipartFile = http.MultipartFile.fromBytes(
        'archivo',
        archivoBytes,
        filename: filename,
      );
      request.files.add(multipartFile);
    }

    try {
      final streamedResponse = await _apiClient.client.send(request).timeout(const Duration(seconds: 45));
      final responseBody = await streamedResponse.stream.bytesToString();
      final statusCode = streamedResponse.statusCode;

      dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {
        decoded = null;
      }

      if (statusCode >= 200 && statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return ResumenImportacion.fromJson(decoded);
        }
        return ResumenImportacion(
          exito: true,
          mensaje: 'Planilla procesada exitosamente.',
          torneoId: resolvedTorneoId,
        );
      }

      String errorMsg = 'Error al procesar la planilla (Código $statusCode).';
      if (decoded is Map && decoded['mensaje'] != null && decoded['mensaje'].toString().trim().isNotEmpty) {
        final serverMsg = decoded['mensaje'].toString().trim();
        if (statusCode == 500 || serverMsg.toLowerCase().contains('internal server error') || serverMsg.toLowerCase().contains('error interno')) {
          errorMsg = "No se pudo acceder a la hoja. Verifica que tenga permisos de lectura públicos ('Cualquier persona con el enlace')";
        } else {
          errorMsg = serverMsg;
        }
      } else if (statusCode == 401 || statusCode == 403 || statusCode == 500) {
        errorMsg = "No se pudo acceder a la hoja. Verifica que tenga permisos de lectura públicos ('Cualquier persona con el enlace')";
      }
      final alertas = decoded is Map && decoded['alertas'] is List
          ? (decoded['alertas'] as List).map((e) => e.toString()).toList()
          : <String>[];

      return ResumenImportacion(
        exito: false,
        mensaje: errorMsg,
        torneoId: resolvedTorneoId,
        alertas: alertas,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Error de conexión al importar la planilla: $e');
    }
  }

  /// Descarga la plantilla oficial en formato bytes (.xlsx o .csv)
  Future<Uint8List> descargarPlantillaPlanilla({String? token}) async {
    try {
      final bytes = await _apiClient.getBytes(
        ApiConstants.plantillaPlanilla,
        token: token,
      );
      return bytes;
    } catch (_) {
      // Fallback CSV modelo con codificación UTF-8 BOM para abrir directamente en Excel
      const csvHeader =
          'Nombre del Equipo,Nombre Completo,Documento / Identificación,Fecha de Nacimiento (YYYY-MM-DD),Dorsal,URL Foto (Google Drive o Web)\n'
          'Los Galácticos,Juan Carlos Pérez Gómez,1045678901,1990-05-14,10,https://drive.google.com/file/d/1EjemploGoogleDriveFotoA/view?usp=sharing\n'
          'Los Galácticos,Andrés Felipe Gómez Meza,1045678902,1984-11-20,7,\n'
          'Atlético San Juan,Carlos Eduardo Rivera Ruiz,1045678903,1998-03-08,1,https://images.unsplash.com/photo-1534528741775-53994a69daeb\n';
      final bom = [0xEF, 0xBB, 0xBF];
      final utf8Bytes = utf8.encode(csvHeader);
      return Uint8List.fromList([...bom, ...utf8Bytes]);
    }
  }

  /// Obtiene el historial de importaciones del torneo activo vía GET /api/equipos/importaciones
  Future<List<ImportacionHistorialItem>> obtenerHistorialImportaciones({
    int? campeonatoId,
    int? torneoId,
    String? token,
    int pagina = 1,
    int limite = 50,
  }) async {
    final session = SessionManager();
    final effectiveToken = (token != null && token.isNotEmpty) ? token : session.token;
    final resolvedTorneoId = torneoId ?? campeonatoId ?? session.selectedCampeonatoId;

    final queryParams = <String, String>{
      'pagina': pagina.toString(),
      'limite': limite.toString(),
    };
    if (resolvedTorneoId > 0) {
      queryParams['campeonatoId'] = resolvedTorneoId.toString();
    }

    final uri = Uri.parse(ApiConstants.importacionesHistorial).replace(
      queryParameters: queryParams,
    );

    final headers = ApiConstants.defaultHeaders(
      token: effectiveToken,
      campeonatoId: resolvedTorneoId,
      torneoId: resolvedTorneoId,
      torneoSlug: session.selectedCampeonatoSlug,
    );

    try {
      final response = await _apiClient.get(
        uri.toString(),
        token: effectiveToken,
        headers: headers,
      );

      if (response is Map<String, dynamic> && response['items'] is List) {
        return (response['items'] as List)
            .map((item) => ImportacionHistorialItem.fromJson(
                  item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
                ))
            .toList();
      } else if (response is List) {
        return response
            .map((item) => ImportacionHistorialItem.fromJson(
                  item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
                ))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Obtiene el detalle completo de una importación vía GET /api/equipos/importaciones/{id}
  Future<ImportacionHistorialItem?> obtenerDetalleImportacion({
    required int id,
    int? campeonatoId,
    int? torneoId,
    String? token,
  }) async {
    final session = SessionManager();
    final effectiveToken = (token != null && token.isNotEmpty) ? token : session.token;
    final resolvedTorneoId = torneoId ?? campeonatoId ?? session.selectedCampeonatoId;

    final queryParams = <String, String>{};
    if (resolvedTorneoId > 0) {
      queryParams['campeonatoId'] = resolvedTorneoId.toString();
    }

    final uri = Uri.parse(ApiConstants.importacionDetalle(id)).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final headers = ApiConstants.defaultHeaders(
      token: effectiveToken,
      campeonatoId: resolvedTorneoId,
      torneoId: resolvedTorneoId,
      torneoSlug: session.selectedCampeonatoSlug,
    );

    try {
      final response = await _apiClient.get(
        uri.toString(),
        token: effectiveToken,
        headers: headers,
      );

      if (response is Map<String, dynamic>) {
        return ImportacionHistorialItem.fromJson(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

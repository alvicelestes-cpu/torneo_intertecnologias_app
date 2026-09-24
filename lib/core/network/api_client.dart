import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../errors/app_exception.dart';
import '../session/session_manager.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient({http.Client? client}) {
    if (client != null) {
      return ApiClient._withClient(client);
    }
    return _instance;
  }

  final http.Client _client;
  ApiClient._internal() : _client = http.Client();
  ApiClient._withClient(this._client);

  static const Duration timeout = Duration(seconds: 25);

  bool _shouldAppendCampeonato(String path) {
    final lowerPath = path.toLowerCase();

    // Endpoints globales explícitamente excluidos
    if (lowerPath.startsWith('/api/auth') ||
        lowerPath.startsWith('/api/campeonatos')) {
      return false;
    }

    // Endpoints que requieren contexto de campeonato
    return lowerPath.startsWith('/api/equipos') ||
        lowerPath.startsWith('/api/jugadores') ||
        lowerPath.startsWith('/api/partidos') ||
        lowerPath.startsWith('/api/jornadas') ||
        lowerPath.startsWith('/api/posiciones') ||
        lowerPath.startsWith('/api/estadisticas') ||
        lowerPath.startsWith('/api/goles') ||
        lowerPath.startsWith('/api/tarjetas') ||
        lowerPath.startsWith('/api/goleadores') ||
        lowerPath.startsWith('/api/fases') ||
        lowerPath.startsWith('/api/torneo');
  }

  Uri _buildUri(String rawUrl) {
    final uri = Uri.parse(rawUrl);

    if (!_shouldAppendCampeonato(uri.path)) {
      return uri;
    }

    final campeonatoId = SessionManager().selectedCampeonatoId;
    if (campeonatoId <= 0) {
      return uri;
    }

    // Si la URL ya contiene campeonatoId, no duplicarlo
    if (uri.queryParameters.containsKey('campeonatoId')) {
      return uri;
    }

    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['campeonatoId'] = campeonatoId.toString();

    return uri.replace(queryParameters: queryParams);
  }

  Map<String, String> _buildHeaders({String? token, Map<String, String>? extraHeaders}) {
    final effectiveToken = (token != null && token.isNotEmpty)
        ? token
        : SessionManager().token;

    final headers = ApiConstants.defaultHeaders(
      token: effectiveToken,
      campeonatoId: SessionManager().selectedCampeonatoId,
    );
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Future<dynamic> get(
    String url, {
    String? token,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(url);
      final response = await _client
          .get(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: headers),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No hay conexión con el servidor. Verifique su red.');
    } on TimeoutException {
      throw const NetworkException('El servidor tardó demasiado en responder.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error de conexión: $e');
    }
  }

  Future<dynamic> post(
    String url, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(url);
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No hay conexión con el servidor. Verifique su red.');
    } on TimeoutException {
      throw const NetworkException('El servidor tardó demasiado en responder.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error de conexión: $e');
    }
  }

  Future<dynamic> put(
    String url, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(url);
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No hay conexión con el servidor. Verifique su red.');
    } on TimeoutException {
      throw const NetworkException('El servidor tardó demasiado en responder.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error de conexión: $e');
    }
  }

  Future<dynamic> delete(
    String url, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(url);
      final response = await _client
          .delete(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No hay conexión con el servidor. Verifique su red.');
    } on TimeoutException {
      throw const NetworkException('El servidor tardó demasiado en responder.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error de conexión: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded;
      } catch (_) {
        return response.body;
      }
    }

    String errorMsg = 'Error en la petición (Código $statusCode)';
    dynamic errorDetails;

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          errorMsg = decoded['mensaje']?.toString() ??
              decoded['message']?.toString() ??
              decoded['error']?.toString() ??
              errorMsg;
          errorDetails = decoded;
        }
      } catch (_) {
        errorMsg = response.body;
      }
    }

    if (statusCode == 401) {
      throw AuthException(errorMsg.isNotEmpty ? errorMsg : 'Sesión no autorizada o token vencido.');
    }

    if (statusCode == 404) {
      throw NotFoundException(errorMsg.isNotEmpty ? errorMsg : 'Recurso no encontrado.');
    }

    throw AppException(errorMsg, statusCode: statusCode, details: errorDetails);
  }
}

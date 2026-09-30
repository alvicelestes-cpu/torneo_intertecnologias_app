import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../models/jugador.dart';

class JugadoresService {
  final ApiClient _apiClient;
  JugadoresService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Jugador>> getJugadores({
    String? token,
    int? campeonatoId,
    int? torneoId,
  }) async {
    final resolvedId = torneoId ?? campeonatoId ?? SessionManager().selectedCampeonatoId;
    final query = resolvedId > 0 ? '?campeonatoId=$resolvedId' : '';
    final response = await _apiClient.get(
      '${ApiConstants.jugadores}$query',
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

  Future<Jugador> getJugadorById(int id, {String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.jugadorDetalle(id),
      token: token,
    );

    if (response is Map<String, dynamic>) {
      if (response['jugador'] is Map) {
        final jMap = Map<String, dynamic>.from(response['jugador'] as Map);
        if (response['estadisticas'] is Map) {
          final stats = response['estadisticas'] as Map;
          jMap['goles'] = stats['totalGoles'];
          jMap['amarillas'] = stats['amarillas'];
          jMap['rojas'] = stats['rojas'];
        }
        return Jugador.fromJson(jMap);
      }
      return Jugador.fromJson(response);
    }

    throw const AppException('La respuesta no tiene el formato esperado para el jugador.');
  }

  Future<void> updateJugador(int id, Map<String, dynamic> data, {String? token}) async {
    await _apiClient.put(
      ApiConstants.jugadorDetalle(id),
      body: data,
      token: token,
    );
  }

  Future<Jugador> createJugador(Map<String, dynamic> data, {String? token}) async {
    final response = await _apiClient.post(
      ApiConstants.jugadores,
      body: data,
      token: token,
    );

    if (response is Map<String, dynamic>) {
      if (response['jugador'] is Map) {
        return Jugador.fromJson(Map<String, dynamic>.from(response['jugador'] as Map));
      }
      return Jugador.fromJson(response);
    }

    throw const AppException('No se pudo crear el jugador.');
  }

  /// Elimina un jugador del sistema y del torneo activo (Requiere Admin)
  Future<void> eliminarJugador(
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
        'Acceso restringido: Se requiere una sesión activa con permisos de Administrador para eliminar jugadores.',
      );
    }

    final resolvedId = torneoId ?? campeonatoId ?? session.selectedCampeonatoId;
    final query = resolvedId > 0 ? '?campeonatoId=$resolvedId' : '';
    await _apiClient.delete(
      '${ApiConstants.jugadorDetalle(id)}$query',
      token: effectiveToken,
      headers: resolvedId > 0
          ? {
              'X-Campeonato-Id': resolvedId.toString(),
              'X-Torneo-Id': resolvedId.toString(),
            }
          : null,
    );
  }

  Future<void> deleteJugador(
    int id, {
    String? token,
    int? campeonatoId,
    int? torneoId,
  }) =>
      eliminarJugador(id, token: token, campeonatoId: campeonatoId, torneoId: torneoId);
}



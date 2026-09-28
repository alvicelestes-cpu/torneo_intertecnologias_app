import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../models/equipo.dart';
import '../models/jugador.dart';

class EquiposService {
  final ApiClient _apiClient;
  EquiposService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Equipo>> getEquipos({String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.equipos,
      token: token,
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

  Future<List<Jugador>> getJugadoresEquipo(int equipoId, {String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.equipoJugadores(equipoId),
      token: token,
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
}

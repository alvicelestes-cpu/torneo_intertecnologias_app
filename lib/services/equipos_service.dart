import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
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
}

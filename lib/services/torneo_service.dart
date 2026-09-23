import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/estadisticas.dart';
import '../models/goleador.dart';
import '../models/posicion.dart';
import 'jugadores_service.dart';

class TorneoService {
  final ApiClient _apiClient;
  final JugadoresService _jugadoresService;

  TorneoService({ApiClient? apiClient, JugadoresService? jugadoresService})
      : _apiClient = apiClient ?? ApiClient(),
        _jugadoresService = jugadoresService ?? JugadoresService(apiClient: apiClient);

  Future<List<Posicion>> getPosiciones({String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.posiciones,
      token: token,
    );

    if (response is List) {
      return response
          .map((item) => Posicion.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw const AppException('La respuesta de posiciones no tiene el formato esperado.');
  }

  Future<List<Goleador>> getGoleadores({String? token, bool cargarFotos = true}) async {
    final response = await _apiClient.get(
      ApiConstants.goleadores,
      token: token,
    );

    if (response is! List) {
      throw const AppException('La respuesta de goleadores no tiene el formato esperado.');
    }

    final goleadores = response
        .map((item) => Goleador.fromJson(
              item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
            ))
        .toList();

    if (!cargarFotos) return goleadores;

    // Cargar fotos concurrentemente para los que no tienen foto
    final resultados = await Future.wait(
      goleadores.map((g) async {
        if (g.fotoJugador != null && g.fotoJugador!.isNotEmpty) {
          return g;
        }
        if (g.jugadorId <= 0) return g;

        try {
          final jugador = await _jugadoresService.getJugadorById(g.jugadorId, token: token);
          if (jugador.fotoJugador != null && jugador.fotoJugador!.isNotEmpty) {
            return g.copyWith(fotoJugador: jugador.fotoJugador);
          }
        } catch (_) {
          // Ignorar error al buscar foto individual
        }
        return g;
      }),
    );

    return resultados;
  }

  Future<EstadisticasTorneo> getEstadisticas({String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.estadisticas,
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return EstadisticasTorneo.fromJson(response);
    }

    throw const AppException('La respuesta de estadísticas no tiene el formato esperado.');
  }
}

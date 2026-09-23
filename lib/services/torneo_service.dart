import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/campeonato.dart';
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

  /// Obtiene la lista de todos los campeonatos activos (multitorneo)
  Future<List<Campeonato>> getCampeonatos({String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.campeonatos,
      token: token,
    );

    if (response is List) {
      return response
          .map((item) => Campeonato.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw const AppException('La respuesta de campeonatos no tiene el formato esperado.');
  }

  /// Obtiene el detalle de un campeonato específico
  Future<Campeonato> getCampeonatoById(int id, {String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.campeonatoDetalle(id),
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return Campeonato.fromJson(response);
    }

    throw const AppException('No se pudo obtener el detalle del campeonato.');
  }

  String _buildUrl(String endpoint, int? campeonatoId) {
    if (campeonatoId == null) return endpoint;
    final uri = Uri.parse(endpoint);
    return uri.replace(queryParameters: {'campeonatoId': campeonatoId.toString()}).toString();
  }

  /// Obtiene el resumen general del torneo activo
  Future<Map<String, dynamic>> getResumenTorneo({String? token, int? campeonatoId}) async {
    final response = await _apiClient.get(
      _buildUrl(ApiConstants.torneoResumen, campeonatoId),
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw const AppException('La respuesta del resumen de torneo no tiene el formato esperado.');
  }

  Future<List<Posicion>> getPosiciones({String? token, int? campeonatoId}) async {
    final response = await _apiClient.get(
      _buildUrl(ApiConstants.posiciones, campeonatoId),
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

  Future<List<Goleador>> getGoleadores({String? token, bool cargarFotos = true, int? campeonatoId}) async {
    final response = await _apiClient.get(
      _buildUrl(ApiConstants.goleadores, campeonatoId),
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

  Future<EstadisticasTorneo> getEstadisticas({String? token, int? campeonatoId}) async {
    final response = await _apiClient.get(
      _buildUrl(ApiConstants.estadisticas, campeonatoId),
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return EstadisticasTorneo.fromJson(response);
    }

    throw const AppException('La respuesta de estadísticas no tiene el formato esperado.');
  }
}

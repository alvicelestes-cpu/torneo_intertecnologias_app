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

  /// Obtiene la lista de todos los torneos activos (multitorneo) con conteos de equipos y partidos
  Future<List<Campeonato>> getCampeonatos({String? token}) async {
    try {
      final responseListar = await _apiClient.get(
        ApiConstants.torneoListar,
        token: token,
      );

      if (responseListar is List && responseListar.isNotEmpty) {
        return responseListar
            .map((item) => Campeonato.fromJson(
                  item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
                ))
            .toList();
      }
    } catch (_) {
      // Fallback a campeonatos legacy si el endpoint listar no responde
    }

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

  /// Obtiene la lista directa de torneos activos desde /api/torneo/listar
  Future<List<Campeonato>> getTorneosActivos({String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.torneoListar,
      token: token,
    );

    if (response is List) {
      return response
          .map((item) => Campeonato.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw const AppException('La respuesta de torneos no tiene el formato esperado.');
  }

  /// Registra un nuevo torneo en el backend protegido para SUPERADMIN (/api/torneo/crear)
  Future<Map<String, dynamic>> crearTorneo({
    required String nombre,
    String? slug,
    int? organizacionId,
    int limiteJugadores = 14,
    bool tienePuntoInvisible = true,
    int topGoleadoresMax = 10,
    String? token,
  }) async {
    final payload = <String, dynamic>{
      'nombre': nombre.trim(),
      if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
      if (organizacionId != null && organizacionId > 0) 'organizacionId': organizacionId,
      'limiteJugadores': limiteJugadores,
      'tienePuntoInvisible': tienePuntoInvisible,
      'topGoleadoresMax': topGoleadoresMax,
    };

    final response = await _apiClient.post(
      ApiConstants.torneoCrear,
      body: payload,
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw const AppException('Respuesta inesperada al crear el nuevo torneo.');
  }

  /// Obtiene la configuración/detalle de un torneo por su slug
  Future<Map<String, dynamic>> getTorneoPorSlug(String slug, {String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.torneoPorSlug(slug),
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw const AppException('La respuesta del torneo por slug no tiene el formato esperado.');
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

  /// Desactiva (elimina lógicamente) un campeonato por su ID (protegido para SUPERADMIN)
  Future<dynamic> desactivarCampeonato(int id, {String? token}) async {
    if (id == 1) {
      throw const AppException('El campeonato principal ID 1 no puede ser desactivado.');
    }
    return await _apiClient.delete(
      ApiConstants.campeonatoDetalle(id),
      token: token,
    );
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

  /// Ejecuta la migración de aislamiento y reparación de datos cruzados entre torneos (ADMIN/SUPERADMIN)
  Future<Map<String, dynamic>> repararAislamientoTorneos({String? token}) async {
    final response = await _apiClient.post(
      ApiConstants.torneoRepararDatos,
      body: {},
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw const AppException('Respuesta inesperada al reparar el aislamiento de torneos.');
  }
}

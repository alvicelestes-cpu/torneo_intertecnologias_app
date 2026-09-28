import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../models/partido.dart';
import '../models/partido_detalle.dart';

class PartidosService {
  final ApiClient _apiClient;
  PartidosService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Partido>> getPartidos({String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.partidos,
      token: token,
    );

    if (response is List) {
      return response
          .map((item) => Partido.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    if (response is Map<String, dynamic> && response['partidos'] is List) {
      return (response['partidos'] as List)
          .map((item) => Partido.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw const AppException('La respuesta del servidor no contiene una lista válida de partidos.');
  }

  Future<PartidoDetalle> getPartidoById(int id, {String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.partidoDetalle(id),
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return PartidoDetalle.fromJson(response);
    }

    throw const AppException('La respuesta del servidor no tiene el formato esperado.');
  }

  Future<void> updatePartido(int id, Map<String, dynamic> data, {String? token}) async {
    await _apiClient.put(
      ApiConstants.partidoDetalle(id),
      body: data,
      token: token,
    );
  }

  Future<void> registrarResultado(int id, Map<String, dynamic> data, {String? token}) async {
    await _apiClient.put(
      ApiConstants.partidoResultado(id),
      body: data,
      token: token,
    );
  }

  Future<void> reabrirPartido(int id, {String? token}) async {
    await _apiClient.put(
      ApiConstants.partidoReabrir(id),
      token: token,
    );
  }

  /// Genera o previsualiza el fixture de una fase (Primera Fase, Cuadrangulares, Cuartos, Semifinal, Final)
  Future<Map<String, dynamic>> generarFixture({
    required String fase,
    DateTime? fechaInicio,
    String modalidad = 'Ida',
    bool soloVistaPrevia = false,
    bool sobrescribirFase = false,
    int? torneoId,
    int? campeonatoId,
    int intervaloDiasEntreJornadas = 7,
    String? token,
  }) async {
    final session = SessionManager();
    final resolvedTorneoId = torneoId ?? campeonatoId ?? session.selectedCampeonatoId;

    final body = <String, dynamic>{
      'torneoId': resolvedTorneoId,
      'campeonatoId': resolvedTorneoId,
      'fase': fase,
      if (fechaInicio != null) 'fechaInicio': fechaInicio.toIso8601String(),
      'modalidad': modalidad,
      'soloVistaPrevia': soloVistaPrevia,
      'sobrescribirFase': sobrescribirFase,
      'intervaloDiasEntreJornadas': intervaloDiasEntreJornadas,
    };

    final response = await _apiClient.post(
      ApiConstants.partidosGenerarFixture,
      body: body,
      token: token ?? (session.token.isNotEmpty ? session.token : null),
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw const AppException('La respuesta del servidor no tiene el formato esperado al generar el fixture.');
  }
}

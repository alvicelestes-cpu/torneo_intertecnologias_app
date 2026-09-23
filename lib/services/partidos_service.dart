import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
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
}

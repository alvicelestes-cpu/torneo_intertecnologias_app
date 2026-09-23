import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/gol.dart';

class GolesService {
  final ApiClient _apiClient;
  GolesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Gol>> getGolesPartido(int partidoId, {String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.golesPartido(partidoId),
      token: token,
    );

    if (response is Map<String, dynamic> && response['goles'] is List) {
      return (response['goles'] as List)
          .map((item) => Gol.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    if (response is List) {
      return response
          .map((item) => Gol.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw const AppException('No fue posible obtener los goles del partido.');
  }

  Future<void> registrarGol(Map<String, dynamic> data, {String? token}) async {
    await _apiClient.post(
      ApiConstants.goles,
      body: data,
      token: token,
    );
  }

  Future<void> eliminarGol(int golId, {String? token}) async {
    await _apiClient.delete(
      ApiConstants.golDetalle(golId),
      token: token,
    );
  }
}

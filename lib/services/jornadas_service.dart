import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/jornada.dart';

class JornadasService {
  final ApiClient _apiClient;
  JornadasService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<JornadasResponse> getJornadas({String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.jornadas,
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return JornadasResponse.fromJson(response);
    }

    if (response is List) {
      return JornadasResponse(
        cantidadJornadas: response.length,
        jornadas: response
            .map((j) => Jornada.fromJson(
                  j is Map<String, dynamic> ? j : Map<String, dynamic>.from(j),
                ))
            .toList(),
      );
    }

    throw const AppException('La respuesta no contiene datos válidos de jornadas.');
  }

  Future<Jornada> getJornadaDetalle(int numeroJornada, {String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.jornadaDetalle(numeroJornada),
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return Jornada.fromJson(response);
    }

    throw const AppException('La jornada no fue encontrada o el formato es incorrecto.');
  }
}

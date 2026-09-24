import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';

class FasesService {
  final ApiClient _apiClient;

  FasesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Obtiene el estado de avance y generación de todas las fases del torneo
  Future<Map<String, dynamic>> getEstadoFases({String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.fasesEstado,
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const AppException('La respuesta del estado de fases no tiene el formato esperado.');
  }

  /// Genera los Cuadrangulares Semifinales (Grupos A y B) en backend
  Future<Map<String, dynamic>> generarSegundaRonda({String? token}) async {
    final response = await _apiClient.post(
      ApiConstants.generarSegundaRonda,
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const AppException('No se pudo generar la Segunda Ronda.');
  }

  /// Genera los Cuartos de Final (Llaves 1 a 4) en backend
  Future<Map<String, dynamic>> generarCuartos({String? token}) async {
    final response = await _apiClient.post(
      ApiConstants.generarCuartos,
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const AppException('No se pudieron generar los Cuartos de Final.');
  }

  /// Genera las Semifinales en backend
  Future<Map<String, dynamic>> generarSemifinales({String? token}) async {
    final response = await _apiClient.post(
      ApiConstants.generarSemifinales,
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const AppException('No se pudieron generar las Semifinales.');
  }

  /// Genera la Gran Final y Tercer Puesto en backend
  Future<Map<String, dynamic>> generarFinal({String? token}) async {
    final response = await _apiClient.post(
      ApiConstants.generarFinal,
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const AppException('No se pudo generar la Gran Final.');
  }
}

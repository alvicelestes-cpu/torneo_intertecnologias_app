import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/tarjeta.dart';

class TarjetasService {
  final ApiClient _apiClient;
  TarjetasService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Tarjeta>> getTarjetasPartido(int partidoId, {String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.tarjetasPartido(partidoId),
      token: token,
    );

    if (response is Map<String, dynamic> && response['tarjetas'] is List) {
      return (response['tarjetas'] as List)
          .map((item) => Tarjeta.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    if (response is List) {
      return response
          .map((item) => Tarjeta.fromJson(
                item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw const AppException('No fue posible obtener las tarjetas del partido.');
  }

  Future<void> registrarTarjeta(Map<String, dynamic> data, {String? token}) async {
    await _apiClient.post(
      ApiConstants.tarjetas,
      body: data,
      token: token,
    );
  }

  Future<void> eliminarTarjeta(int tarjetaId, {String? token}) async {
    await _apiClient.delete(
      ApiConstants.tarjetaDetalle(tarjetaId),
      token: token,
    );
  }
}

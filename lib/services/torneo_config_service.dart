import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/torneo_model.dart';

class TorneoConfigService extends ChangeNotifier {
  static final TorneoConfigService _instance = TorneoConfigService._internal();
  factory TorneoConfigService() => _instance;
  TorneoConfigService._internal({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  TorneoModel _config = TorneoModel.defaults();
  bool _cargando = false;
  String? _ultimoError;

  TorneoModel get config => _config;
  TorneoModel get torneo => _config;
  int get limiteJugadores => _config.limiteJugadores;
  bool get tienePuntoInvisible => _config.tienePuntoInvisible;
  int get topGoleadoresMax => _config.topGoleadoresMax;
  String get nombreTorneo => _config.nombre;
  bool get cargando => _cargando;
  String? get ultimoError => _ultimoError;

  void setLocalConfig(TorneoModel nuevaConfig) {
    _config = nuevaConfig;
    notifyListeners();
  }

  /// Carga la configuración del torneo actual desde el backend.
  /// Si falla o no hay conexión, mantiene de forma segura los valores por defecto (14 jugadores, Top 10, Punto invisible activo).
  Future<TorneoModel> cargarConfiguracion({String? token, int? torneoId}) async {
    _cargando = true;
    _ultimoError = null;

    final queryParams = <String, String>{};
    if (torneoId != null && torneoId > 0) {
      queryParams['torneoId'] = torneoId.toString();
    }

    final uri = Uri.parse(ApiConstants.torneoActual).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      final response = await _apiClient.get(
        uri.toString(),
        headers: ApiConstants.defaultHeaders(
          token: token,
          torneoId: torneoId,
        ),
      );

      if (response is Map<String, dynamic>) {
        _config = TorneoModel.fromJson(response);
        notifyListeners();
        return _config;
      }
    } catch (e) {
      _ultimoError = e.toString();
      // Silenciosamente asegura los valores predeterminados seguros si el backend no responde
      if (kDebugMode) {
        debugPrint('TorneoConfigService: Fallback a valores por defecto ($e)');
      }
    } finally {
      _cargando = false;
      notifyListeners();
    }

    return _config;
  }

  /// Actualiza los parámetros reglamentarios en el backend (Endpoint protegido de Administrador)
  Future<TorneoModel> actualizarConfiguracion({
    required String token,
    String? nombre,
    int? limiteJugadores,
    bool? tienePuntoInvisible,
    int? topGoleadoresMax,
    int? torneoId,
  }) async {
    _cargando = true;
    _ultimoError = null;
    notifyListeners();

    final queryParams = <String, String>{};
    if (torneoId != null && torneoId > 0) {
      queryParams['torneoId'] = torneoId.toString();
    }

    final uri = Uri.parse(ApiConstants.torneoConfig).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final payload = <String, dynamic>{};
    if (nombre != null && nombre.trim().isNotEmpty) {
      payload['nombre'] = nombre.trim();
    }
    if (limiteJugadores != null) {
      payload['limiteJugadores'] = limiteJugadores;
    }
    if (tienePuntoInvisible != null) {
      payload['tienePuntoInvisible'] = tienePuntoInvisible;
    }
    if (topGoleadoresMax != null) {
      payload['topGoleadoresMax'] = topGoleadoresMax;
    }

    try {
      final response = await _apiClient.put(
        uri.toString(),
        headers: ApiConstants.defaultHeaders(
          token: token,
          torneoId: torneoId,
        ),
        body: jsonEncode(payload),
      );

      if (response is Map<String, dynamic>) {
        if (response.containsKey('torneo') && response['torneo'] is Map<String, dynamic>) {
          _config = TorneoModel.fromJson(response['torneo'] as Map<String, dynamic>);
        } else {
          _config = TorneoModel.fromJson(response);
        }
        notifyListeners();
        return _config;
      }

      throw const AppException('Respuesta inesperada al actualizar configuración del torneo.');
    } catch (e) {
      _ultimoError = e.toString();
      rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}

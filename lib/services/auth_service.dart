import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../models/auth_user.dart';

class AuthService {
  final ApiClient _apiClient;
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<AuthUser> login({
    required String usuario,
    required String contrasena,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      body: {
        'usuario': usuario.trim(),
        'contrasena': contrasena,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw const AppException('La respuesta del servidor no tiene un formato válido.');
    }

    final token = response['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw const AppException('El servidor no devolvió el token de acceso.');
    }

    final authUser = AuthUser.fromJson(response);
    SessionManager().setSession(authUser);
    return authUser;
  }

  void logout() {
    SessionManager().clearSession();
  }
}

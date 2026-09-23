import 'package:flutter/foundation.dart';
import '../../models/auth_user.dart';

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _currentUser!.token.isNotEmpty;
  String get token => _currentUser?.token ?? '';
  String get usuario => _currentUser?.usuario ?? '';
  String get rol => _currentUser?.rol ?? 'Administrador';

  void setSession(AuthUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateToken(String token, {String? usuario, String? rol}) {
    _currentUser = AuthUser(
      token: token,
      usuario: usuario ?? _currentUser?.usuario ?? '',
      rol: rol ?? _currentUser?.rol ?? 'Administrador',
    );
    notifyListeners();
  }

  void clearSession() {
    _currentUser = null;
    notifyListeners();
  }
}

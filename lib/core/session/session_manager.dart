import 'package:flutter/foundation.dart';
import '../../models/auth_user.dart';
import '../../models/campeonato.dart';

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  AuthUser? _currentUser;
  Campeonato? _selectedCampeonato;
  List<Campeonato> _campeonatos = [];

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _currentUser!.token.isNotEmpty;
  String get token => _currentUser?.token ?? '';
  String get usuario => _currentUser?.usuario ?? '';
  String get rol => _currentUser?.rol ?? 'Administrador';

  // Multitorneo
  Campeonato? get selectedCampeonato => _selectedCampeonato;
  List<Campeonato> get campeonatos => List.unmodifiable(_campeonatos);

  int get selectedCampeonatoId =>
      _selectedCampeonato?.id ?? _currentUser?.campeonatoId ?? 1;

  String get selectedCampeonatoNombre =>
      _selectedCampeonato?.nombre ?? _currentUser?.campeonato ?? 'Torneo Intertecnologías';

  void setSession(AuthUser user) {
    _currentUser = user;
    if (user.campeonatoId != null && _campeonatos.isNotEmpty) {
      final match = _campeonatos.cast<Campeonato?>().firstWhere(
            (c) => c?.id == user.campeonatoId,
            orElse: () => null,
          );
      if (match != null) {
        _selectedCampeonato = match;
      }
    }
    notifyListeners();
  }

  void setCampeonatos(List<Campeonato> list) {
    _campeonatos = list;
    if (list.isNotEmpty) {
      final currentTargetId = _selectedCampeonato?.id ?? _currentUser?.campeonatoId ?? 1;
      final match = list.cast<Campeonato?>().firstWhere(
            (c) => c?.id == currentTargetId,
            orElse: () => list.first,
          );
      _selectedCampeonato = match;
    }
    notifyListeners();
  }

  void selectCampeonato(Campeonato campeonato) {
    if (_selectedCampeonato?.id == campeonato.id) return;
    _selectedCampeonato = campeonato;
    notifyListeners();
  }

  void selectCampeonatoById(int id) {
    if (_selectedCampeonato?.id == id) return;
    final match = _campeonatos.cast<Campeonato?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => null,
        );
    if (match != null) {
      _selectedCampeonato = match;
    } else {
      _selectedCampeonato = Campeonato(
        id: id,
        nombre: 'Campeonato #$id',
        slug: 'campeonato-$id',
      );
    }
    notifyListeners();
  }

  void updateToken(String token, {String? usuario, String? rol, int? campeonatoId, String? campeonato}) {
    _currentUser = AuthUser(
      token: token,
      usuario: usuario ?? _currentUser?.usuario ?? '',
      rol: rol ?? _currentUser?.rol ?? 'Administrador',
      campeonatoId: campeonatoId ?? _currentUser?.campeonatoId,
      campeonato: campeonato ?? _currentUser?.campeonato,
    );
    notifyListeners();
  }

  void clearSession() {
    _currentUser = null;
    _selectedCampeonato = null;
    notifyListeners();
  }
}

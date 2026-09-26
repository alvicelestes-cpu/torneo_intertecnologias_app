import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/auth_user.dart';
import '../../models/campeonato.dart';
import '../../services/torneo_config_service.dart';

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const String _keySelectedCampeonatoId = 'selected_campeonato_id';

  AuthUser? _currentUser;
  Campeonato? _selectedCampeonato;
  List<Campeonato> _campeonatos = [];
  int? _persistedCampeonatoId;

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _currentUser!.token.isNotEmpty;
  String get token => _currentUser?.token ?? '';
  String get usuario => _currentUser?.usuario ?? '';
  String get rol => _currentUser?.rol ?? 'Administrador';

  // Control de roles
  bool get isSuperAdmin =>
      _currentUser != null &&
      _currentUser!.rol.trim().toUpperCase() == 'SUPERADMIN';

  bool get isAdmin =>
      _currentUser != null &&
      (_currentUser!.rol.trim().toUpperCase() == 'ADMIN' ||
       _currentUser!.rol.trim().toUpperCase() == 'ADMINISTRADOR');

  /// Determina si el usuario tiene una sesión activa válida con permisos de administración
  bool get hasAdminAccess =>
      isAuthenticated && (isAdmin || isSuperAdmin);

  /// SUPERADMIN puede cambiar libremente de torneo; ADMIN está restringido a su propio torneo
  bool get canChangeCampeonato => _currentUser == null || isSuperAdmin;

  // Multitorneo
  Campeonato? get selectedCampeonato => _selectedCampeonato;
  List<Campeonato> get campeonatos => List.unmodifiable(_campeonatos);

  int get selectedCampeonatoId =>
      _selectedCampeonato?.id ??
      _persistedCampeonatoId ??
      _currentUser?.campeonatoId ??
      1;

  String get selectedCampeonatoNombre =>
      _selectedCampeonato?.nombre ??
      _currentUser?.campeonato ??
      'Torneo Intertecnologías';

  /// Inicializa la sesión cargando el campeonatoId previamente guardado
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getInt(_keySelectedCampeonatoId);
      if (savedId != null && savedId > 0) {
        _persistedCampeonatoId = savedId;
        _selectedCampeonato ??= Campeonato(
          id: savedId,
          nombre: 'Torneo #$savedId',
          slug: 'campeonato-$savedId',
        );
      }
    } catch (_) {
      // Ignorar fallo al leer SharedPreferences para no bloquear inicio
    }
    TorneoConfigService().cargarConfiguracion(torneoId: selectedCampeonatoId);
  }

  void _persistCampeonatoId(int id) {
    _persistedCampeonatoId = id;
    TorneoConfigService().cargarConfiguracion(torneoId: id, token: token);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_keySelectedCampeonatoId, id);
    }).catchError((_) {});
  }

  void setSession(AuthUser user) {
    _currentUser = user;

    final isUserSuperAdmin = user.rol.trim().toUpperCase() == 'SUPERADMIN';

    if (!isUserSuperAdmin && user.campeonatoId != null && user.campeonatoId! > 0) {
      // ADMIN: Forzar que trabaje únicamente con su propio campeonato asignado
      final assignedId = user.campeonatoId!;
      final match = _campeonatos.cast<Campeonato?>().firstWhere(
            (c) => c?.id == assignedId,
            orElse: () => null,
          );
      _selectedCampeonato = match ??
          Campeonato(
            id: assignedId,
            nombre: user.campeonato?.isNotEmpty == true
                ? user.campeonato!
                : 'Campeonato #$assignedId',
            slug: 'campeonato-$assignedId',
          );
      _persistCampeonatoId(assignedId);
    } else if (isUserSuperAdmin) {
      // SUPERADMIN: conservar el campeonato seleccionado o guardado válido si existe
      final targetId = _selectedCampeonato?.id ??
          _persistedCampeonatoId ??
          user.campeonatoId;

      if (targetId != null && _campeonatos.isNotEmpty) {
        final match = _campeonatos.cast<Campeonato?>().firstWhere(
              (c) => c?.id == targetId && c?.estaActivo == true,
              orElse: () => null,
            );
        if (match != null) {
          _selectedCampeonato = match;
          _persistCampeonatoId(match.id);
        }
      }
    }

    notifyListeners();
  }

  void setCampeonatos(List<Campeonato> list) {
    _campeonatos = list;

    if (list.isEmpty) {
      notifyListeners();
      return;
    }

    final activos = list.where((c) => c.estaActivo).toList();
    final publicados = list.where((c) => c.estaPublicado).toList();
    final disponibles = (!isAuthenticated && publicados.isNotEmpty)
        ? publicados
        : (activos.isNotEmpty ? activos : list);

    if (_currentUser != null && !isSuperAdmin && _currentUser!.campeonatoId != null) {
      // ADMIN: estrictamente bloqueado a su propio campeonato asignado
      final assignedId = _currentUser!.campeonatoId!;
      final match = list.cast<Campeonato?>().firstWhere(
            (c) => c?.id == assignedId,
            orElse: () => null,
          );
      _selectedCampeonato = match ??
          Campeonato(
            id: assignedId,
            nombre: _currentUser!.campeonato?.isNotEmpty == true
                ? _currentUser!.campeonato!
                : 'Campeonato #$assignedId',
            slug: 'campeonato-$assignedId',
          );
      _persistCampeonatoId(assignedId);
    } else if (isSuperAdmin) {
      // SUPERADMIN: validar si el campeonato guardado/seleccionado existe y está activo
      final targetId = _selectedCampeonato?.id ??
          _persistedCampeonatoId ??
          _currentUser?.campeonatoId ??
          1;

      final match = disponibles.cast<Campeonato?>().firstWhere(
            (c) => c?.id == targetId,
            orElse: () => null,
          );

      if (match != null) {
        _selectedCampeonato = match;
        _persistCampeonatoId(match.id);
      } else {
        _selectedCampeonato = disponibles.first;
        _persistCampeonatoId(disponibles.first.id);
      }
    } else {
      // VISITANTE ANÓNIMO (Portal Público):
      // Seleccionar únicamente entre campeonatos publicados
      final targetId = _selectedCampeonato?.id ?? _persistedCampeonatoId;
      final match = disponibles.cast<Campeonato?>().firstWhere(
            (c) => c?.id == targetId && c?.estaPublicado == true,
            orElse: () => null,
          );

      if (match != null) {
        _selectedCampeonato = match;
        _persistCampeonatoId(match.id);
      } else {
        _selectedCampeonato = disponibles.first;
        _persistCampeonatoId(disponibles.first.id);
      }
    }

    notifyListeners();
  }

  void selectCampeonato(Campeonato campeonato) {
    if (!canChangeCampeonato) return;
    if (_selectedCampeonato?.id == campeonato.id) return;
    _selectedCampeonato = campeonato;
    _persistCampeonatoId(campeonato.id);
    notifyListeners();
  }

  void selectCampeonatoById(int id) {
    if (!canChangeCampeonato) return;
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
    _persistCampeonatoId(id);
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
    _campeonatos = [];
    notifyListeners();
  }
}

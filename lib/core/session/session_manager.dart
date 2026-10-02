import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/auth_user.dart';
import '../../models/campeonato.dart';
import '../../models/torneo_model.dart';
import '../../services/torneo_config_service.dart';
import '../../services/torneo_service.dart';
import '../utils/player_sort_utils.dart';

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

  String get selectedCampeonatoNombre {
    if (_selectedCampeonato != null && _selectedCampeonato!.nombre.trim().isNotEmpty) {
      return _selectedCampeonato!.nombre.trim();
    }
    final configNombre = TorneoConfigService().nombreTorneo.trim();
    if (configNombre.isNotEmpty && configNombre.toLowerCase() != 'torneo') {
      return configNombre;
    }
    if (_currentUser?.campeonato != null && _currentUser!.campeonato!.trim().isNotEmpty) {
      return _currentUser!.campeonato!.trim();
    }
    return configNombre.isNotEmpty ? configNombre : 'Torneo Intertecnologías';
  }

  String get selectedCampeonatoSlug =>
      _selectedCampeonato?.slug.isNotEmpty == true
          ? _selectedCampeonato!.slug
          : 'campeonato-$selectedCampeonatoId';

  /// Determina si el torneo actualmente seleccionado maneja categorías visuales de edad.
  /// Para Torneo Banquita Los Altos (ID 2), retorna false.
  /// Para Torneo Intertecnologías (ID 1) y otros torneos estándar, retorna true.
  bool get tieneCategoriasEdad => torneoTieneCategoriasEdad(
        id: selectedCampeonatoId,
        slug: selectedCampeonatoSlug,
        nombre: selectedCampeonatoNombre,
      );

  /// Extrae el slug de una URI con soporte para rutas web amigables y con hash (#)
  static String? extractSlugFromUri(Uri uri) {
    // 1. Path directo: /t/:slug o /t/:slug/...
    final pathMatch = RegExp(r'^/t/([^/]+)').firstMatch(uri.path);
    if (pathMatch != null) {
      return pathMatch.group(1);
    }

    // 2. Hash fragment (Flutter Web hash URL strategy: #/t/:slug)
    if (uri.fragment.isNotEmpty) {
      final cleanFragment = uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
      final fragmentMatch = RegExp(r'^/t/([^/]+)').firstMatch(cleanFragment);
      if (fragmentMatch != null) {
        return fragmentMatch.group(1);
      }
    }

    return null;
  }

  /// Inicializa la sesión cargando el campeonatoId previamente guardado o resolviendo el slug de la URL
  Future<void> init({Uri? currentUri, TorneoService? torneoService}) async {
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

    // Intentar resolver slug desde la URL del navegador si aplica
    final uri = currentUri ?? Uri.base;
    final slugFromUrl = extractSlugFromUri(uri);
    if (slugFromUrl != null && slugFromUrl.isNotEmpty) {
      final exito = await selectCampeonatoBySlug(slugFromUrl, torneoService: torneoService);
      if (exito) return;
    }

    TorneoConfigService().cargarConfiguracion(torneoId: selectedCampeonatoId);
  }

  /// Selecciona y sincroniza el torneo activo a partir de su Slug
  Future<bool> selectCampeonatoBySlug(String slug, {TorneoService? torneoService}) async {
    final cleanSlug = slug.trim().toLowerCase();
    if (cleanSlug.isEmpty) return false;

    // Si ya coincide con el seleccionado actualmente
    if (_selectedCampeonato?.slug.trim().toLowerCase() == cleanSlug) {
      return true;
    }

    // Si ya existe en la lista de torneos en memoria
    final match = _campeonatos.cast<Campeonato?>().firstWhere(
          (c) => c?.slug.trim().toLowerCase() == cleanSlug,
          orElse: () => null,
        );
    if (match != null) {
      selectCampeonato(match);
      return true;
    }

    // Consultar backend vía /api/torneo/por-slug/{slug}
    try {
      final service = torneoService ?? TorneoService();
      final data = await service.getTorneoPorSlug(cleanSlug, token: token);
      final rawTorneo = (data.containsKey('torneo') && data['torneo'] is Map<String, dynamic>)
          ? data['torneo'] as Map<String, dynamic>
          : data;

      final resolvedId = (rawTorneo['id'] as num?)?.toInt() ?? 1;
      final resolvedNombre = rawTorneo['nombre']?.toString() ?? 'Torneo $cleanSlug';
      final resolvedSlug = rawTorneo['slug']?.toString() ?? cleanSlug;
      final totalEquipos = (rawTorneo['totalEquipos'] as num?)?.toInt() ?? 0;
      final totalPartidos = (rawTorneo['totalPartidos'] as num?)?.toInt() ?? 0;
      final estaActivo = rawTorneo['activo'] == true || rawTorneo['estaActivo'] == true;
      final estaPublicado = rawTorneo['publicado'] == true || rawTorneo['estaPublicado'] == true;

      final torneoModel = TorneoModel.fromJson(rawTorneo);
      TorneoConfigService().setLocalConfig(torneoModel);

      final nuevoCampeonato = Campeonato(
        id: resolvedId,
        nombre: resolvedNombre,
        slug: resolvedSlug,
        activo: estaActivo,
        publicado: estaPublicado,
        totalEquipos: totalEquipos,
        totalPartidos: totalPartidos,
      );

      registrarNuevoTorneo(nuevoCampeonato);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SessionManager: Error al resolver torneo por slug "$slug": $e');
      }
      return false;
    }
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
        final c1 = disponibles.cast<Campeonato?>().firstWhere(
              (c) => c?.id == 1,
              orElse: () => null,
            );
        final defaultTarget = c1 ?? disponibles.first;
        _selectedCampeonato = defaultTarget;
        _persistCampeonatoId(defaultTarget.id);
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
        final c1 = disponibles.cast<Campeonato?>().firstWhere(
              (c) => c?.id == 1 && c?.estaPublicado == true,
              orElse: () => null,
            );
        final defaultTarget = c1 ?? disponibles.first;
        _selectedCampeonato = defaultTarget;
        _persistCampeonatoId(defaultTarget.id);
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

  /// Registra un nuevo torneo en la lista y lo selecciona automáticamente como activo
  void registrarNuevoTorneo(Campeonato nuevo) {
    final list = List<Campeonato>.from(_campeonatos);
    final idx = list.indexWhere((c) => c.id == nuevo.id);
    if (idx >= 0) {
      list[idx] = nuevo;
    } else {
      list.add(nuevo);
    }
    _campeonatos = list;
    _selectedCampeonato = nuevo;
    _persistCampeonatoId(nuevo.id);
    notifyListeners();
  }

  /// Elimina/desactiva un campeonato de la lista en memoria (solo aplicable a torneos != 1)
  void removerCampeonato(int id) {
    if (id == 1) return; // NUNCA eliminar o desactivar torneo ID 1
    _campeonatos = _campeonatos.where((c) => c.id != id).toList();
    if (_selectedCampeonato?.id == id) {
      final campeonatoPrincipal = _campeonatos.cast<Campeonato?>().firstWhere(
            (c) => c?.id == 1,
            orElse: () => null,
          );
      if (campeonatoPrincipal != null) {
        selectCampeonato(campeonatoPrincipal);
      } else {
        selectCampeonatoById(1);
      }
    } else {
      notifyListeners();
    }
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
    _selectedCampeonato = null;
    _persistedCampeonatoId = null;
    _campeonatos = [];
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/auth_user.dart';
import '../../models/campeonato.dart';
import '../../models/torneo_model.dart';
import '../../services/torneo_config_service.dart';
import '../../services/torneo_service.dart';
import '../utils/player_sort_utils.dart';
import '../utils/web_url_helper.dart';

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

  // Control de roles RBAC
  bool get isSuperAdmin =>
      _currentUser != null && _currentUser!.isSuperAdmin;

  bool get isAdmin =>
      _currentUser != null && _currentUser!.isTournamentAdmin;

  /// Determina si el usuario tiene una sesión activa válida con permisos de administración
  bool get isAuthenticatedAdmin => isAuthenticated && (isAdmin || isSuperAdmin);

  /// SUPERADMIN puede cambiar libremente de torneo; ADMIN está restringido a su propio torneo
  bool get canChangeCampeonato => _currentUser == null || isSuperAdmin;

  /// Valida si el usuario tiene permisos de edición/escritura sobre el torneo especificado.
  /// Si no se especifica torneoId, evalúa sobre el torneo activo (selectedCampeonatoId).
  bool canWriteTournament([int? torneoId]) {
    if (!isAuthenticated) return false;
    if (isSuperAdmin) return true;
    if (!isAdmin) return false;
    final targetId = torneoId ?? selectedCampeonatoId;
    return _currentUser?.canWriteTournament(targetId) ?? false;
  }

  /// Permiso de edición en el torneo activo actualmente
  bool get hasWriteAccess => canWriteTournament(selectedCampeonatoId);

  /// Para compatibilidad y seguridad RBAC por torneo, hasAdminAccess valida los permisos
  /// sobre el torneo activo actualmente seleccionado.
  bool get hasAdminAccess => canWriteTournament(selectedCampeonatoId);

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

  /// Determina si una cadena representa un identificador o slug del Torneo Banquita Los Altos
  static bool isBanquitaIdentifier(String? val) {
    if (val == null) return false;
    final clean = val.trim().toLowerCase().replaceAll('-', '_');
    if (clean == '2' || clean == '3') return true;
    if (clean.contains('banquita')) return true;
    if (clean == 'torneo_demo') return true;
    return false;
  }

  /// Determina si una cadena representa un identificador del Torneo Intertecnologías
  static bool isIntertecnologiasIdentifier(String? val) {
    if (val == null) return false;
    final clean = val.trim().toLowerCase().replaceAll('-', '_');
    if (clean == '1') return true;
    if (clean.contains('intertecnologia') || clean.contains('inter_tecnologia')) return true;
    return false;
  }

  /// Extrae el slug o identificador de torneo de una URI con soporte para:
  /// 1. Query parameters directos (?torneo=..., ?t=..., ?slug=..., ?campeonato=..., ?id=...)
  /// 2. Query parameters dentro del fragment de Flutter Web (#/?torneo=... o #?torneo=...)
  /// 3. Rutas directas: /t/:slug, /torneo/:slug
  /// 4. Rutas en hash fragment: #/t/:slug, #/torneo/:slug
  static String? extractSlugFromUri(Uri uri) {
    // 1. Query parameters directos (?torneo=..., ?t=..., etc.)
    final qDirect = uri.queryParameters['torneo'] ??
        uri.queryParameters['t'] ??
        uri.queryParameters['slug'] ??
        uri.queryParameters['campeonato'] ??
        uri.queryParameters['id'];
    if (qDirect != null && qDirect.trim().isNotEmpty) {
      return qDirect.trim();
    }

    // 2. Query parameters o rutas dentro del fragment (#) en Flutter Web
    if (uri.fragment.isNotEmpty) {
      final cleanFragment = uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
      final fragUri = Uri.tryParse(cleanFragment);
      if (fragUri != null) {
        final qFrag = fragUri.queryParameters['torneo'] ??
            fragUri.queryParameters['t'] ??
            fragUri.queryParameters['slug'] ??
            fragUri.queryParameters['campeonato'] ??
            fragUri.queryParameters['id'];
        if (qFrag != null && qFrag.trim().isNotEmpty) {
          return qFrag.trim();
        }

        // Rutas dentro de hash: #/t/:slug o #/torneo/:slug
        final fragMatch = RegExp(r'^/(?:t|torneo)/([^/?#]+)').firstMatch(fragUri.path);
        if (fragMatch != null) {
          return fragMatch.group(1);
        }
      }
    }

    // 3. Path directo: /t/:slug o /torneo/:slug
    final pathMatch = RegExp(r'^/(?:t|torneo)/([^/?#]+)').firstMatch(uri.path);
    if (pathMatch != null) {
      return pathMatch.group(1);
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

    // Obtener la URI actual del navegador si estamos en entorno web
    Uri uri = currentUri ?? Uri.base;
    final browserHref = getBrowserUrl();
    if (currentUri == null && browserHref.isNotEmpty) {
      final parsed = Uri.tryParse(browserHref);
      if (parsed != null) {
        uri = parsed;
      }
    }

    // Intentar resolver torneo desde la URL del navegador si se especificó
    final slugFromUrl = extractSlugFromUri(uri);
    if (slugFromUrl != null && slugFromUrl.isNotEmpty) {
      final exito = await selectCampeonatoBySlug(slugFromUrl, torneoService: torneoService);
      if (exito) return;
    } else {
      // Si no viene ningún parámetro en la URL y el usuario no está autenticado,
      // asegurar que el torneo activo sea el torneo principal por defecto (Torneo Intertecnologías)
      if (!isAuthenticated) {
        final principal = Campeonato(
          id: 1,
          nombre: 'Torneo Intertecnologías 2026',
          slug: 'torneo-intertecnologias-2026',
          activo: true,
          publicado: true,
        );
        _selectedCampeonato = principal;
        _persistedCampeonatoId = 1;
      }
    }

    TorneoConfigService().cargarConfiguracion(torneoId: selectedCampeonatoId);
  }

  /// Selecciona y sincroniza el torneo activo a partir de su Slug o identificador
  Future<bool> selectCampeonatoBySlug(String slug, {TorneoService? torneoService}) async {
    final cleanSlug = slug.trim().toLowerCase();
    if (cleanSlug.isEmpty) return false;

    final isBanquita = isBanquitaIdentifier(cleanSlug);
    final isInter = isIntertecnologiasIdentifier(cleanSlug);

    // Si ya coincide con el seleccionado actualmente
    if (_selectedCampeonato != null) {
      if (_selectedCampeonato!.slug.trim().toLowerCase() == cleanSlug) {
        return true;
      }
      if (isBanquita && (_selectedCampeonato!.id == 2 || _selectedCampeonato!.id == 3 || _selectedCampeonato!.nombre.toLowerCase().contains('banquita'))) {
        return true;
      }
      if (isInter && (_selectedCampeonato!.id == 1 || _selectedCampeonato!.nombre.toLowerCase().contains('intertecnologia'))) {
        return true;
      }
    }

    // Si ya existe en la lista de torneos en memoria
    final match = _campeonatos.cast<Campeonato?>().firstWhere(
          (c) {
            if (c == null) return false;
            final cSlug = c.slug.trim().toLowerCase().replaceAll('-', '_');
            if (cSlug == cleanSlug.replaceAll('-', '_')) return true;
            if (cleanSlug == c.id.toString()) return true;
            if (isBanquita && (c.id == 2 || c.id == 3 || c.nombre.toLowerCase().contains('banquita'))) {
              return true;
            }
            if (isInter && (c.id == 1 || c.nombre.toLowerCase().contains('intertecnologia'))) {
              return true;
            }
            return false;
          },
          orElse: () => null,
        );
    if (match != null) {
      selectCampeonato(match);
      return true;
    }

    // Si la lista de torneos aún no se ha cargado en memoria, intentar cargarla del backend
    if (_campeonatos.isEmpty) {
      try {
        final service = torneoService ?? TorneoService();
        final list = await service.getCampeonatos(token: token);
        if (list.isNotEmpty) {
          _campeonatos = list;
          final matchFromBackend = _campeonatos.cast<Campeonato?>().firstWhere(
                (c) {
                  if (c == null) return false;
                  final cSlug = c.slug.trim().toLowerCase().replaceAll('-', '_');
                  if (cSlug == cleanSlug.replaceAll('-', '_')) return true;
                  if (cleanSlug == c.id.toString()) return true;
                  if (isBanquita && (c.id == 2 || c.id == 3 || c.nombre.toLowerCase().contains('banquita'))) {
                    return true;
                  }
                  if (isInter && (c.id == 1 || c.nombre.toLowerCase().contains('intertecnologia'))) {
                    return true;
                  }
                  return false;
                },
                orElse: () => null,
              );
          if (matchFromBackend != null) {
            selectCampeonato(matchFromBackend);
            return true;
          }
        }
      } catch (_) {
        // Fallback síncrono si el endpoint no responde
      }
    }

    // Fast-path síncrono para torneos base si aún no están cargados en memoria
    if (isBanquita) {
      final banquita = Campeonato(
        id: (cleanSlug == 'torneo-demo' || cleanSlug == '2') ? 2 : 3,
        nombre: 'Torneo Banquita Los Altos',
        slug: cleanSlug == 'torneo-demo' ? 'torneo-demo' : 'torneo-banquitas-los-altos-2026',
        activo: true,
        publicado: true,
      );
      selectCampeonato(banquita);
      return true;
    } else if (isInter) {
      final inter = Campeonato(
        id: 1,
        nombre: 'Torneo Intertecnologías 2026',
        slug: 'intertecnologias',
        activo: true,
        publicado: true,
      );
      selectCampeonato(inter);
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

    final isUserSuperAdmin = user.isSuperAdmin;

    if (!isUserSuperAdmin && (user.campeonatoId != null && user.campeonatoId! > 0 || user.torneoIds.isNotEmpty)) {
      // ADMIN DE TORNEO: Forzar que trabaje únicamente con su propio campeonato asignado
      final assignedId = user.campeonatoId ?? user.torneoIds.first;
      final isBanquita = isBanquitaIdentifier(assignedId.toString()) ||
          isBanquitaIdentifier(user.campeonato);

      final match = _campeonatos.cast<Campeonato?>().firstWhere(
            (c) {
              if (c == null) return false;
              if (c.id == assignedId) return true;
              if (isBanquita && (c.id == 2 || c.id == 3 || isBanquitaIdentifier(c.nombre) || isBanquitaIdentifier(c.slug))) {
                return true;
              }
              return false;
            },
            orElse: () => null,
          );

      final banquitaNombre = (user.campeonato != null && user.campeonato!.trim().isNotEmpty)
          ? user.campeonato!.trim()
          : 'Torneo Banquita Los Altos';

      _selectedCampeonato = match ??
          Campeonato(
            id: assignedId,
            nombre: isBanquita
                ? banquitaNombre
                : (user.campeonato?.isNotEmpty == true ? user.campeonato! : 'Campeonato #$assignedId'),
            slug: isBanquita ? 'torneo-banquitas-los-altos-2026' : 'campeonato-$assignedId',
            activo: true,
            publicado: true,
          );
      _persistCampeonatoId(_selectedCampeonato!.id);
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

  /// Restaura el torneo activo al torneo asignado al usuario administrador
  void restaurarTorneoAsignado() {
    if (_currentUser == null || isSuperAdmin) return;
    final assignedId = _currentUser!.campeonatoId ??
        (_currentUser!.torneoIds.isNotEmpty ? _currentUser!.torneoIds.first : null);
    if (assignedId == null) return;

    final isBanquita = isBanquitaIdentifier(assignedId.toString()) ||
        isBanquitaIdentifier(_currentUser!.campeonato);

    final match = _campeonatos.cast<Campeonato?>().firstWhere(
          (c) {
            if (c == null) return false;
            if (c.id == assignedId) return true;
            if (isBanquita && (c.id == 2 || c.id == 3 || isBanquitaIdentifier(c.nombre) || isBanquitaIdentifier(c.slug))) {
              return true;
            }
            return false;
          },
          orElse: () => null,
        );

    final banquitaNombre = (_currentUser!.campeonato != null && _currentUser!.campeonato!.trim().isNotEmpty)
        ? _currentUser!.campeonato!.trim()
        : 'Torneo Banquita Los Altos';

    _selectedCampeonato = match ??
        Campeonato(
          id: assignedId,
          nombre: isBanquita
              ? banquitaNombre
              : (_currentUser!.campeonato?.isNotEmpty == true ? _currentUser!.campeonato! : 'Campeonato #$assignedId'),
          slug: isBanquita ? 'torneo-banquitas-los-altos-2026' : 'campeonato-$assignedId',
          activo: true,
          publicado: true,
        );
    _persistCampeonatoId(_selectedCampeonato!.id);
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

    if (_currentUser != null && !isSuperAdmin && (_currentUser!.campeonatoId != null || _currentUser!.torneoIds.isNotEmpty)) {
      // ADMIN: estrictamente bloqueado y fijado a su propio campeonato asignado
      final assignedId = _currentUser!.campeonatoId ?? _currentUser!.torneoIds.first;
      final isBanquita = isBanquitaIdentifier(assignedId.toString()) ||
          isBanquitaIdentifier(_currentUser!.campeonato);

      final match = list.cast<Campeonato?>().firstWhere(
            (c) {
              if (c == null) return false;
              if (c.id == assignedId) return true;
              if (isBanquita && (c.id == 2 || c.id == 3 || isBanquitaIdentifier(c.nombre) || isBanquitaIdentifier(c.slug))) {
                return true;
              }
              return false;
            },
            orElse: () => null,
          );

      final banquitaNombre = (_currentUser!.campeonato != null && _currentUser!.campeonato!.trim().isNotEmpty)
          ? _currentUser!.campeonato!.trim()
          : 'Torneo Banquita Los Altos';

      _selectedCampeonato = match ??
          Campeonato(
            id: assignedId,
            nombre: isBanquita
                ? banquitaNombre
                : (_currentUser!.campeonato?.isNotEmpty == true ? _currentUser!.campeonato! : 'Campeonato #$assignedId'),
            slug: isBanquita ? 'torneo-banquitas-los-altos-2026' : 'campeonato-$assignedId',
            activo: true,
            publicado: true,
          );
      _persistCampeonatoId(_selectedCampeonato!.id);
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

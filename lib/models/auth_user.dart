import '../core/utils/text_utils.dart';

class AuthUser {
  final String token;
  final String usuario;
  final String rol;
  final int? campeonatoId;
  final String? campeonato;
  final List<int> torneoIds;
  final Map<int, List<String>> permisosPorTorneo;

  const AuthUser({
    required this.token,
    required this.usuario,
    required this.rol,
    this.campeonatoId,
    this.campeonato,
    this.torneoIds = const [],
    this.permisosPorTorneo = const {},
  });

  /// Alias de campeonatoId para compatibilidad semántica con torneos
  int? get torneoId => campeonatoId;

  /// Alias de rol
  String get role => rol;

  /// Superadministrador global con control irrestricto sobre todos los torneos
  bool get isSuperAdmin {
    final r = rol.trim().toUpperCase();
    return r == 'SUPERADMIN';
  }

  /// Administrador asignado a torneo (restringido a sus torneos asignados)
  bool get isTournamentAdmin {
    final r = rol.trim().toUpperCase();
    return r == 'ADMIN' ||
        r == 'ADMINISTRADOR' ||
        r == 'ADMIN_TORNEO' ||
        r == 'ADMINTORNEO';
  }

  /// Determina si un id o nombre/slug corresponde al Torneo Banquita Los Altos
  static bool isBanquitaTorneo(int? id, [String? nombreOrSlug]) {
    if (id == 2 || id == 3) return true;
    if (nombreOrSlug != null) {
      final clean = nombreOrSlug.toLowerCase();
      if (clean.contains('banquita') || clean == 'torneo_demo' || clean == 'torneo-demo') {
        return true;
      }
    }
    return false;
  }

  /// Indica si el usuario tiene una asignación específica a uno o más torneos.
  bool get hasTorneoAsignado =>
      campeonatoId != null ||
      torneoIds.isNotEmpty ||
      permisosPorTorneo.isNotEmpty;

  /// Valida si el usuario tiene permisos de escritura/edición en el torneo especificado.
  /// - SUPERADMIN: tiene permisos en cualquier torneo.
  /// - ADMIN general (sin torneo asignado): tiene permisos en cualquier torneo por compatibilidad.
  /// - ADMIN / ADMIN_TORNEO asignado: tiene permisos estrictamente en sus torneos asignados.
  ///   Para el administrador de "Torneo Banquita Los Altos", solo autoriza IDs 2 y 3.
  bool canWriteTournament(int targetTorneoId) {
    if (isSuperAdmin) return true;
    if (!isTournamentAdmin) return false;

    // Si es un admin general sin restricción de torneo específico ni rol admin_torneo
    final isSpecificRole = rol.trim().toUpperCase() == 'ADMIN_TORNEO' ||
        rol.trim().toUpperCase() == 'ADMINTORNEO';
    if (!hasTorneoAsignado && !isSpecificRole) {
      return true;
    }

    // 1. Permisos explícitos por torneo
    if (permisosPorTorneo.containsKey(targetTorneoId)) {
      final pList = permisosPorTorneo[targetTorneoId]!;
      if (pList.contains('write') ||
          pList.contains('escritura') ||
          pList.contains('admin') ||
          pList.isEmpty) {
        return true;
      }
    }

    // 2. Lista explícita de torneoIds asignados
    if (torneoIds.contains(targetTorneoId)) {
      return true;
    }

    // 3. ID de campeonato asignado directo
    if (campeonatoId != null && campeonatoId == targetTorneoId) {
      return true;
    }

    // 4. Equivalencia y alias para Torneo Banquita Los Altos (IDs 2 y 3)
    final assignedIsBanquita = isBanquitaTorneo(campeonatoId, campeonato) ||
        torneoIds.any((id) => isBanquitaTorneo(id));
    final targetIsBanquita = isBanquitaTorneo(targetTorneoId);

    if (assignedIsBanquita && targetIsBanquita) {
      return true;
    }

    return false;
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawTorneoId = json['campeonatoId'] ??
        json['campeonato_id'] ??
        json['torneoId'] ??
        json['torneo_id'];
    final parsedId = rawTorneoId != null ? TextUtils.toInt(rawTorneoId) : null;

    final rawIds = json['torneoIds'] ??
        json['torneo_ids'] ??
        json['campeonatoIds'] ??
        json['campeonatos_ids'];
    List<int> parsedIds = [];
    if (rawIds is List) {
      parsedIds = rawIds.map((e) => TextUtils.toInt(e)).where((e) => e > 0).toList();
    } else if (parsedId != null && parsedId > 0) {
      parsedIds = [parsedId];
    }

    final Map<int, List<String>> permisosMap = {};
    if (json['permisosPorTorneo'] is Map) {
      final pMap = json['permisosPorTorneo'] as Map;
      pMap.forEach((k, v) {
        final tId = TextUtils.toInt(k);
        if (tId > 0 && v is List) {
          permisosMap[tId] = v.map((e) => e.toString()).toList();
        }
      });
    }

    final rawRol = json['rol'] ?? json['role'] ?? json['rol_nombre'] ?? 'Administrador';

    return AuthUser(
      token: json['token']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? json['username']?.toString() ?? '',
      rol: rawRol.toString(),
      campeonatoId: parsedId,
      campeonato: json['campeonato']?.toString().trim() ?? json['torneo']?.toString().trim(),
      torneoIds: parsedIds,
      permisosPorTorneo: permisosMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'usuario': usuario,
      'rol': rol,
      'role': rol,
      if (campeonatoId != null) 'campeonatoId': campeonatoId,
      if (campeonatoId != null) 'torneo_id': campeonatoId,
      if (campeonato != null) 'campeonato': campeonato,
      if (torneoIds.isNotEmpty) 'torneoIds': torneoIds,
      if (permisosPorTorneo.isNotEmpty)
        'permisosPorTorneo': permisosPorTorneo.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
    };
  }

  AuthUser copyWith({
    String? token,
    String? usuario,
    String? rol,
    int? campeonatoId,
    String? campeonato,
    List<int>? torneoIds,
    Map<int, List<String>>? permisosPorTorneo,
  }) {
    return AuthUser(
      token: token ?? this.token,
      usuario: usuario ?? this.usuario,
      rol: rol ?? this.rol,
      campeonatoId: campeonatoId ?? this.campeonatoId,
      campeonato: campeonato ?? this.campeonato,
      torneoIds: torneoIds ?? this.torneoIds,
      permisosPorTorneo: permisosPorTorneo ?? this.permisosPorTorneo,
    );
  }
}


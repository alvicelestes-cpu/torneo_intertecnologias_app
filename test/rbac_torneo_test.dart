import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/models/auth_user.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';

void main() {
  group('RBAC por Torneo - AuthUser Model', () {
    test('SUPERADMIN tiene permisos de escritura en todos los torneos', () {
      const superAdmin = AuthUser(
        token: 'token-super',
        usuario: 'superadmin',
        rol: 'SUPERADMIN',
      );

      expect(superAdmin.isSuperAdmin, isTrue);
      expect(superAdmin.isTournamentAdmin, isFalse);
      expect(superAdmin.canWriteTournament(1), isTrue);
      expect(superAdmin.canWriteTournament(2), isTrue);
      expect(superAdmin.canWriteTournament(3), isTrue);
      expect(superAdmin.canWriteTournament(999), isTrue);
    });

    test('ADMIN general sin torneo asignado mantiene compatibilidad global', () {
      const generalAdmin = AuthUser(
        token: 'token-admin',
        usuario: 'admin_global',
        rol: 'ADMIN',
      );

      expect(generalAdmin.isSuperAdmin, isFalse);
      expect(generalAdmin.isTournamentAdmin, isTrue);
      expect(generalAdmin.hasTorneoAsignado, isFalse);
      expect(generalAdmin.canWriteTournament(1), isTrue);
      expect(generalAdmin.canWriteTournament(3), isTrue);
    });

    test('ADMIN asignado a Banquitas (campeonatoId: 3) solo puede editar Banquitas (IDs 2 y 3)', () {
      const banquitaAdmin = AuthUser(
        token: 'token-banquitas',
        usuario: 'admin.banquitas@losaltos.com',
        rol: 'ADMIN',
        campeonatoId: 3,
        campeonato: 'Torneo Banquita Los Altos 2026',
      );

      expect(banquitaAdmin.isTournamentAdmin, isTrue);
      expect(banquitaAdmin.hasTorneoAsignado, isTrue);
      // Escritura permitida en Banquitas (ID 3 y alias ID 2)
      expect(banquitaAdmin.canWriteTournament(3), isTrue);
      expect(banquitaAdmin.canWriteTournament(2), isTrue);
      // Bloqueo estricto de escritura en Torneo Intertecnologías (ID 1) y otros
      expect(banquitaAdmin.canWriteTournament(1), isFalse);
      expect(banquitaAdmin.canWriteTournament(4), isFalse);
      expect(banquitaAdmin.canWriteTournament(100), isFalse);
    });

    test('Rol ADMIN_TORNEO asignado a Banquitas respeta frontera de torneo', () {
      const torneoAdmin = AuthUser(
        token: 'token-banquitas-2',
        usuario: 'admin.banquitas',
        rol: 'admin_torneo',
        campeonatoId: 3,
      );

      expect(torneoAdmin.isTournamentAdmin, isTrue);
      expect(torneoAdmin.canWriteTournament(3), isTrue);
      expect(torneoAdmin.canWriteTournament(1), isFalse);
    });

    test('Permisos explícitos por torneo en permisosPorTorneo', () {
      final user = AuthUser.fromJson({
        'token': 'tok-123',
        'usuario': 'gestor.mixto',
        'rol': 'ADMIN_TORNEO',
        'permisosPorTorneo': {
          '3': ['write'],
          '1': ['read'],
        },
      });

      expect(user.canWriteTournament(3), isTrue);
      expect(user.canWriteTournament(1), isFalse);
    });

    test('Usuario regular (JUGADOR) no tiene permisos de escritura en ningún torneo', () {
      const jugador = AuthUser(
        token: 'tok-jugador',
        usuario: 'jugador.estrella',
        rol: 'JUGADOR',
        campeonatoId: 3,
      );

      expect(jugador.isTournamentAdmin, isFalse);
      expect(jugador.canWriteTournament(3), isFalse);
      expect(jugador.canWriteTournament(1), isFalse);
    });

    test('Deserialización fromJson soporta alias torneoId, torneoIds y campeonato_id', () {
      final user = AuthUser.fromJson({
        'token': 'tok-xyz',
        'usuario': 'admin.banquitas@losaltos.com',
        'rol': 'ADMIN',
        'torneo_id': 3,
        'torneo_ids': [2, 3],
      });

      expect(user.torneoId, equals(3));
      expect(user.torneoIds, containsAll([2, 3]));
      expect(user.canWriteTournament(3), isTrue);
      expect(user.canWriteTournament(2), isTrue);
      expect(user.canWriteTournament(1), isFalse);
    });
  });

  group('RBAC por Torneo - SessionManager Lifecycle y Aislamiento', () {
    late SessionManager session;

    setUp(() {
      session = SessionManager();
      session.clearSession();
      session.setCampeonatos(const [
        Campeonato(
          id: 1,
          nombre: 'Torneo Intertecnologías 2026',
          slug: 'intertecnologias-2026',
          activo: true,
        ),
        Campeonato(
          id: 3,
          nombre: 'Torneo Banquita Los Altos 2026',
          slug: 'torneo-banquitas-los-altos-2026',
          activo: true,
        ),
      ]);
    });

    test('Login con admin Banquitas fija automáticamente torneo activo a Banquitas', () {
      session.setSession(const AuthUser(
        token: 'token-banquitas-jwt',
        usuario: 'admin.banquitas@losaltos.com',
        rol: 'ADMIN',
        campeonatoId: 3,
        campeonato: 'Torneo Banquita Los Altos 2026',
      ));

      expect(session.isAuthenticated, isTrue);
      expect(session.selectedCampeonatoId, equals(3));
      expect(session.hasWriteAccess, isTrue);
      expect(session.hasAdminAccess, isTrue);
      // Admin de torneo no tiene permiso para cambiar libremente de torneo
      expect(session.canChangeCampeonato, isFalse);
    });

    test('Admin Banquitas tiene selector bloqueado (canChangeCampeonato == false) y canWriteTournament(1) es falso', () {
      session.setSession(const AuthUser(
        token: 'token-banquitas-jwt',
        usuario: 'admin.banquitas@losaltos.com',
        rol: 'ADMIN',
        campeonatoId: 3,
      ));

      expect(session.selectedCampeonatoId, equals(3));
      expect(session.canChangeCampeonato, isFalse);

      // Intento de cambiar al Torneo Intertecnologías es bloqueado por canChangeCampeonato
      final torneo1 = session.campeonatos.firstWhere((c) => c.id == 1);
      session.selectCampeonato(torneo1);
      // Sigue bloqueado en torneo 3
      expect(session.selectedCampeonatoId, equals(3));
      expect(session.hasWriteAccess, isTrue);

      // Si se consulta explícitamente permisos sobre torneo 1:
      expect(session.canWriteTournament(1), isFalse);

      // Si restaurarTorneoAsignado() se invoca, asegura torneo 3
      session.restaurarTorneoAsignado();
      expect(session.selectedCampeonatoId, equals(3));
      expect(session.hasWriteAccess, isTrue);
      expect(session.hasAdminAccess, isTrue);
    });

    test('SUPERADMIN puede cambiar de torneo y mantiene acceso de escritura en todos', () {
      session.setSession(const AuthUser(
        token: 'token-superadmin',
        usuario: 'admin',
        rol: 'SUPERADMIN',
      ));

      expect(session.canChangeCampeonato, isTrue);

      // En torneo 1
      session.selectCampeonato(session.campeonatos.firstWhere((c) => c.id == 1));
      expect(session.selectedCampeonatoId, equals(1));
      expect(session.hasWriteAccess, isTrue);
      expect(session.hasAdminAccess, isTrue);

      // En torneo 3
      session.selectCampeonato(session.campeonatos.firstWhere((c) => c.id == 3));
      expect(session.selectedCampeonatoId, equals(3));
      expect(session.hasWriteAccess, isTrue);
      expect(session.hasAdminAccess, isTrue);
    });

    test('Administrador original Intertecnologías (SUPERADMIN con campeonatoId 1) tiene acceso total e inicio en Torneo 1', () {
      session.setSession(const AuthUser(
        token: 'token-admin-inter',
        usuario: 'admin',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
        campeonato: 'Torneo Intertecnologías 2026',
      ));

      expect(session.isAuthenticated, isTrue);
      expect(session.isSuperAdmin, isTrue);
      expect(session.selectedCampeonatoId, equals(1));
      expect(session.hasWriteAccess, isTrue);
      expect(session.hasAdminAccess, isTrue);
      expect(session.canChangeCampeonato, isTrue);
      expect(session.canWriteTournament(1), isTrue);
      expect(session.canWriteTournament(3), isTrue);
    });

    test('Administrador asignado a Intertecnologías (ADMIN con campeonatoId 1) tiene acceso en Torneo 1 pero bloqueado en Banquitas (Torneo 3)', () {
      session.setSession(const AuthUser(
        token: 'token-admin-inter-especifico',
        usuario: 'admin.intertecnologias',
        rol: 'ADMIN',
        campeonatoId: 1,
        campeonato: 'Torneo Intertecnologías 2026',
      ));

      expect(session.isAuthenticated, isTrue);
      expect(session.isSuperAdmin, isFalse);
      expect(session.isAdmin, isTrue);
      expect(session.selectedCampeonatoId, equals(1));
      expect(session.hasWriteAccess, isTrue);
      expect(session.canWriteTournament(1), isTrue);
      // Aislamiento: bloqueado para escribir en Banquitas
      expect(session.canWriteTournament(3), isFalse);
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/core/utils/fixture_utils.dart';
import 'package:torneo_intertecnologias_app/core/utils/image_utils.dart';
import 'package:torneo_intertecnologias_app/core/utils/mobile_image_picker.dart';
import 'package:torneo_intertecnologias_app/crear_jugador_page.dart';
import 'package:torneo_intertecnologias_app/main.dart';
import 'package:torneo_intertecnologias_app/models/auth_user.dart';
import 'package:torneo_intertecnologias_app/models/equipo.dart';
import 'package:torneo_intertecnologias_app/models/jugador.dart';
import 'package:torneo_intertecnologias_app/models/partido.dart';
import 'package:torneo_intertecnologias_app/models/posicion.dart';
import 'package:torneo_intertecnologias_app/services/jugadores_service.dart';
import 'package:torneo_intertecnologias_app/widgets/public_team_card.dart';

void main() {
  group('Jugador Model - Corrección Visual de Equipo y Mapa', () {
    test('Parsea correctamente equipo anidado como Map sin imprimir mapa crudo', () {
      final json = {
        'id': 165,
        'nombres': 'Carlos',
        'apellidos': 'Valderrama',
        'equipoId': 5,
        'equipo': {
          'id': 5,
          'nombre': 'TIENDA RACING FC',
          'sigla': 'TRF',
          'colorPrincipal': '#003366',
        },
        'fechaNacimiento': '1985-05-10',
        'estado': 'ACTIVO',
      };

      final jugador = Jugador.fromJson(json);

      expect(jugador.id, 165);
      expect(jugador.equipoId, 5);
      expect(jugador.equipoNombre, 'TIENDA RACING FC');
      expect(jugador.equipoSigla, 'TRF');
      expect(jugador.equipoColor, '#003366');
      expect(jugador.equipoNombre!.contains('{'), isFalse);
    });

    test('Descarta equipoNombre si es un mapa serializado como texto', () {
      final json = {
        'id': 166,
        'nombres': 'James',
        'apellidos': 'Rodriguez',
        'equipoId': 3,
        'equipoNombre': '{id: 3, nombre: DEPORTIVO ELITE, sigla: DEL}',
        'fechaNacimiento': '1991-07-12',
      };

      final jugador = Jugador.fromJson(json);

      expect(jugador.equipoNombre, isNull);
    });

    test('Parsea equipo plano cuando equipoNombre viene como texto limpio', () {
      final json = {
        'id': 167,
        'nombres': 'Radamel',
        'apellidos': 'Falcao',
        'equipoId': 2,
        'equipoNombre': 'CEMENTEROS FC',
        'equipoSigla': 'CEM',
        'fechaNacimiento': '1986-02-10',
      };

      final jugador = Jugador.fromJson(json);

      expect(jugador.equipoNombre, 'CEMENTEROS FC');
      expect(jugador.equipoSigla, 'CEM');
    });
  });

  group('ImageUtils - Soporte de Data URI Base64 y Blob', () {
    test('Preserva data URI en Base64 sin anteponer baseUrl', () {
      const dataUri = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...';
      final resolved = ImageUtils.resolveUrl(dataUri);
      expect(resolved, dataUri);
    });

    test('Preserva URLs blob sin anteponer baseUrl', () {
      const blobUrl = 'blob:http://localhost:5000/guid-1234';
      final resolved = ImageUtils.resolveUrl(blobUrl);
      expect(resolved, blobUrl);
    });

    test('Resuelve rutas relativas con baseUrl', () {
      const relative = '/uploads/jugadores/foto.jpg';
      final resolved = ImageUtils.resolveUrl(relative);
      expect(resolved, startsWith('http'));
      expect(resolved, endsWith(relative));
    });
  });

  group('JugadoresService - createJugador', () {
    test('createJugador envía POST y retorna Jugador creado', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.contains('/api/jugadores')) {
          final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          expect(requestBody['nombres'], 'Juan');
          expect(requestBody['apellidos'], 'Perez');
          expect(requestBody['equipoId'], 4);

          return http.Response(
            jsonEncode({
              'mensaje': 'Jugador creado correctamente.',
              'jugador': {
                'id': 200,
                'equipoId': 4,
                'equipo': 'LOS MISMOS FC',
                'nombres': 'Juan',
                'apellidos': 'Perez',
                'numeroCamiseta': 10,
                'fechaNacimiento': '1995-04-12',
                'estado': 'ACTIVO',
                'fotoJugador': '/uploads/jugadores/new.jpg',
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final service = JugadoresService(apiClient: apiClient);

      final nuevoJugador = await service.createJugador({
        'equipoId': 4,
        'nombres': 'Juan',
        'apellidos': 'Perez',
        'numeroCamiseta': 10,
        'fechaNacimiento': '1995-04-12',
      });

      expect(nuevoJugador.id, 200);
      expect(nuevoJugador.nombres, 'Juan');
      expect(nuevoJugador.apellidos, 'Perez');
      expect(nuevoJugador.numeroCamiseta, 10);
      expect(nuevoJugador.fotoJugador, '/uploads/jugadores/new.jpg');
    });
  });

  group('Control de Acceso de Administrador - SessionManager', () {
    final session = SessionManager();

    setUp(() {
      session.clearSession();
    });

    test('Usuario no autenticado / anónimo NO tiene acceso de administrador', () {
      expect(session.isAuthenticated, isFalse);
      expect(session.isAdmin, isFalse);
      expect(session.isSuperAdmin, isFalse);
      expect(session.hasAdminAccess, isFalse);
    });

    test('Usuario con rol regular (no admin) NO tiene acceso de administrador', () {
      session.setSession(const AuthUser(
        token: 'token-valido',
        usuario: 'jugador1',
        rol: 'JUGADOR',
      ));

      expect(session.isAuthenticated, isTrue);
      expect(session.isAdmin, isFalse);
      expect(session.isSuperAdmin, isFalse);
      expect(session.hasAdminAccess, isFalse);
    });

    test('Usuario con rol ADMIN tiene acceso de administrador', () {
      session.setSession(const AuthUser(
        token: 'token-valido',
        usuario: 'admin1',
        rol: 'ADMIN',
      ));

      expect(session.isAuthenticated, isTrue);
      expect(session.isAdmin, isTrue);
      expect(session.hasAdminAccess, isTrue);
    });

    test('Usuario con rol SUPERADMIN tiene acceso de administrador', () {
      session.setSession(const AuthUser(
        token: 'token-valido',
        usuario: 'superadmin1',
        rol: 'SUPERADMIN',
      ));

      expect(session.isAuthenticated, isTrue);
      expect(session.isSuperAdmin, isTrue);
      expect(session.hasAdminAccess, isTrue);
    });
  });

  group('MobileImagePicker - AppPickedImage', () {
    test('Genera data URI Base64 válido con mimeType correcto', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final picked = AppPickedImage(
        bytes: bytes,
        mimeType: 'image/jpeg',
        name: 'foto.jpg',
      );

      final dataUri = picked.dataUri;
      expect(dataUri, startsWith('data:image/jpeg;base64,'));
      expect(dataUri, contains(base64Encode(bytes)));
    });
  });

  group('Protección de Rutas - /crear-jugador', () {
    setUp(() {
      SessionManager().clearSession();
    });

    testWidgets('Visitante anónimo es redirigido a LoginPage al intentar acceder a /crear-jugador', (WidgetTester tester) async {
      await tester.pumpWidget(const TorneoApp());
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed('/crear-jugador');
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    });
  });

  group('Ajuste Reglamentario - Cupo Máximo 14 Jugadores', () {
    test('Límite reglamentario kMaxJugadoresPorEquipo y maxPlantilla es 14', () {
      expect(CrearJugadorPage.kMaxJugadoresPorEquipo, equals(14));
      expect(PublicTeamCard.maxPlantilla, equals(14));
    });

    testWidgets('PublicTeamCard muestra etiqueta "14/14 jugadores"', (WidgetTester tester) async {
      const equipoLleno = Equipo(
        id: 1,
        nombre: 'INPEC FC',
        sigla: 'INP',
        cantidadJugadores: 14,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PublicTeamCard(equipo: equipoLleno),
          ),
        ),
      );

      expect(find.text('14/14 jugadores'), findsOneWidget);
    });

    testWidgets('PublicTeamCard muestra etiqueta "12/14 jugadores" para equipo incompleto', (WidgetTester tester) async {
      const equipoIncompleto = Equipo(
        id: 2,
        nombre: 'TIENDA RACING FC',
        sigla: 'TRF',
        cantidadJugadores: 12,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PublicTeamCard(equipo: equipoIncompleto),
          ),
        ),
      );

      expect(find.text('12/14 jugadores'), findsOneWidget);
    });
  });

  group('Fixture y Fases Posteriores (FixtureUtils)', () {
    test('Construye las 5 fases reglamentarias del torneo incluso sin partidos jugados', () {
      final sections = FixtureUtils.buildTournamentSections(partidos: []);

      // 7 Jornadas de Primera Fase + Cuadrangular Grupo A + Cuadrangular Grupo B + Cuartos de Final + Semifinal + Gran Final = 12 secciones
      expect(sections.length, equals(12));

      // 1. Primera Fase: Jornadas 1 a 7
      for (int j = 1; j <= 7; j++) {
        final sec = sections.firstWhere((s) => s.id == 'jornada_$j');
        expect(sec.numeroJornada, equals(j));
        expect(sec.fase, equals(TournamentPhase.primeraFase));
        expect(sec.titulo, equals('Jornada $j'));
      }

      // 2. Segunda Ronda: Cuadrangulares Grupo A y Grupo B
      final grupoA = sections.firstWhere((s) => s.id == 'cuadrangular_grupo_a');
      expect(grupoA.fase, equals(TournamentPhase.segundaRonda));
      expect(grupoA.titulo, contains('Grupo A'));
      expect(grupoA.subtitulo, contains('1°, 3°, 5° y 7°'));
      expect(grupoA.subtitulo, contains('Punto Invisible'));
      expect(grupoA.esPendiente, isTrue);
      expect(grupoA.mensajePendiente, contains('Punto Invisible'));
      expect(grupoA.partidos.length, equals(6));

      final grupoB = sections.firstWhere((s) => s.id == 'cuadrangular_grupo_b');
      expect(grupoB.fase, equals(TournamentPhase.segundaRonda));
      expect(grupoB.titulo, contains('Grupo B'));
      expect(grupoB.subtitulo, contains('2°, 4°, 6° y 8°'));
      expect(grupoB.subtitulo, contains('Punto Invisible'));
      expect(grupoB.esPendiente, isTrue);
      expect(grupoB.mensajePendiente, contains('Punto Invisible'));
      expect(grupoB.partidos.length, equals(6));

      // 3. Tercera Ronda: Cuartos de Final (4 llaves)
      final cuartos = sections.firstWhere((s) => s.id == 'cuartos_de_final');
      expect(cuartos.fase, equals(TournamentPhase.terceraRonda));
      expect(cuartos.titulo, contains('Cuartos de Final'));
      expect(cuartos.esPendiente, isTrue);
      expect(cuartos.partidos.length, equals(4));
      expect(cuartos.partidos[0].equipoLocalNombre, contains('1° Grupo A'));
      expect(cuartos.partidos[0].equipoVisitanteNombre, contains('4° Grupo B'));
      expect(cuartos.partidos[1].equipoLocalNombre, contains('2° Grupo A'));
      expect(cuartos.partidos[1].equipoVisitanteNombre, contains('3° Grupo B'));
      expect(cuartos.partidos[2].equipoLocalNombre, contains('1° Grupo B'));
      expect(cuartos.partidos[2].equipoVisitanteNombre, contains('4° Grupo A'));
      expect(cuartos.partidos[3].equipoLocalNombre, contains('2° Grupo B'));
      expect(cuartos.partidos[3].equipoVisitanteNombre, contains('3° Grupo A'));

      // 4. Cuarta Ronda: Semifinal (2 llaves)
      final semifinal = sections.firstWhere((s) => s.id == 'semifinal');
      expect(semifinal.fase, equals(TournamentPhase.cuartaRonda));
      expect(semifinal.titulo, contains('Semifinales'));
      expect(semifinal.esPendiente, isTrue);
      expect(semifinal.partidos.length, equals(2));
      expect(semifinal.partidos[0].equipoLocalNombre, contains('Ganador Llave 1'));
      expect(semifinal.partidos[0].equipoVisitanteNombre, contains('Ganador Llave 4'));
      expect(semifinal.partidos[1].equipoLocalNombre, contains('Ganador Llave 3'));
      expect(semifinal.partidos[1].equipoVisitanteNombre, contains('Ganador Llave 2'));

      // 5. Quinta Ronda: Gran Final y Tercer Puesto
      final granFinal = sections.firstWhere((s) => s.id == 'gran_final');
      expect(granFinal.fase, equals(TournamentPhase.quintaRonda));
      expect(granFinal.titulo, contains('Gran Final'));
      expect(granFinal.esPendiente, isTrue);
      expect(granFinal.partidos.length, equals(2));
      expect(granFinal.partidos[0].equipoLocalNombre, contains('Ganador Semifinal 1'));
      expect(granFinal.partidos[1].equipoLocalNombre, contains('Perdedor Semifinal 1'));
    });

    test('Siembra equipos reales en Cuadrangulares cuando se provee la tabla de posiciones', () {
      Posicion crearPos({
        required int pos,
        required int equipoId,
        required String nombre,
        required String sigla,
        required int pts,
      }) {
        return Posicion(
          posicion: pos,
          equipoId: equipoId,
          equipo: nombre,
          sigla: sigla,
          pj: 5,
          pg: 3,
          pe: 1,
          pp: 1,
          gf: 10,
          gc: 5,
          dg: 5,
          pts: pts,
        );
      }

      final mockPosiciones = [
        crearPos(pos: 1, equipoId: 1, nombre: 'DEP ELITE', sigla: 'ELI', pts: 15),
        crearPos(pos: 2, equipoId: 2, nombre: 'CEMENTEROS', sigla: 'CEM', pts: 12),
        crearPos(pos: 3, equipoId: 3, nombre: 'CONEXIÓN DIGITAL', sigla: 'CDI', pts: 10),
        crearPos(pos: 4, equipoId: 4, nombre: 'TIENDA RACING FC', sigla: 'TRF', pts: 9),
        crearPos(pos: 5, equipoId: 5, nombre: 'TELEMATIK', sigla: 'TEL', pts: 7),
        crearPos(pos: 6, equipoId: 6, nombre: 'GREMIO HFC', sigla: 'GRE', pts: 6),
        crearPos(pos: 7, equipoId: 7, nombre: 'INPEC', sigla: 'INP', pts: 4),
        crearPos(pos: 8, equipoId: 8, nombre: 'TIGO CITY', sigla: 'TIG', pts: 1),
      ];

      final sections = FixtureUtils.buildTournamentSections(
        partidos: [],
        posiciones: mockPosiciones,
      );

      final grupoA = sections.firstWhere((s) => s.id == 'cuadrangular_grupo_a');
      final nombresEquiposA = grupoA.partidos
          .expand((p) => [p.equipoLocalNombre, p.equipoVisitanteNombre])
          .toSet();
      expect(nombresEquiposA.any((n) => n.contains('DEP ELITE')), isTrue);
      expect(nombresEquiposA.any((n) => n.contains('CONEXIÓN DIGITAL')), isTrue);
      expect(nombresEquiposA.any((n) => n.contains('TELEMATIK')), isTrue);
      expect(nombresEquiposA.any((n) => n.contains('INPEC')), isTrue);
      expect(nombresEquiposA.any((n) => n.contains('CEMENTEROS')), isFalse);

      final grupoB = sections.firstWhere((s) => s.id == 'cuadrangular_grupo_b');
      final nombresEquiposB = grupoB.partidos
          .expand((p) => [p.equipoLocalNombre, p.equipoVisitanteNombre])
          .toSet();
      expect(nombresEquiposB.any((n) => n.contains('CEMENTEROS')), isTrue);
      expect(nombresEquiposB.any((n) => n.contains('TIENDA RACING FC')), isTrue);
      expect(nombresEquiposB.any((n) => n.contains('GREMIO HFC')), isTrue);
      expect(nombresEquiposB.any((n) => n.contains('TIGO CITY')), isTrue);
      expect(nombresEquiposB.any((n) => n.contains('DEP ELITE')), isFalse);
    });

    test('Carga automáticamente partidos reales de cuadrangular cuando el backend los provee', () {
      const matchEliminatoria = Partido(
        id: 162,
        jornada: 8,
        fase: 'SEGUNDA_RONDA',
        llave: 'GRUPO A',
        equipoLocalNombre: 'INPEC FC',
        equipoVisitanteNombre: 'DEP ELITE',
        estado: 'PROGRAMADO',
      );

      final sections = FixtureUtils.buildTournamentSections(partidos: [matchEliminatoria]);
      final grupoA = sections.firstWhere((s) => s.id == 'cuadrangular_grupo_a' || s.id == 'segunda_ronda');

      expect(grupoA.esPendiente, isFalse);
      expect(grupoA.partidos.length, equals(1));
      expect(grupoA.partidos.first.id, equals(162));
      expect(grupoA.partidos.first.equipoLocalNombre, equals('INPEC FC'));
    });
  });

  group('Desactivación Prompt de Instalación PWA (web/index.html)', () {
    test('web/index.html cancela beforeinstallprompt y desvincula manifest', () {
      final indexHtmlFile = File('web/index.html');
      expect(indexHtmlFile.existsSync(), isTrue);

      final content = indexHtmlFile.readAsStringSync();

      // Debe capturar beforeinstallprompt y prevenir la instalación
      expect(content.contains("window.addEventListener('beforeinstallprompt'"), isTrue);
      expect(content.contains("e.preventDefault()"), isTrue);

      // La etiqueta manifest debe estar comentada o ausente de etiquetas link activas
      final manifestCommented = content.contains('<!-- <link rel="manifest"') ||
          !content.contains('<link rel="manifest"');
      expect(manifestCommented, isTrue, reason: 'manifest.json debe estar desvinculado o comentado');
    });
  });
}

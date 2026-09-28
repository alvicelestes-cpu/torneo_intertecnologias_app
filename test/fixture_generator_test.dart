import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/jornadas_page.dart';
import 'package:torneo_intertecnologias_app/models/auth_user.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';
import 'package:torneo_intertecnologias_app/services/jornadas_service.dart';
import 'package:torneo_intertecnologias_app/services/partidos_service.dart';
import 'package:torneo_intertecnologias_app/services/torneo_service.dart';

class MockFixtureHttpClient extends http.BaseClient {
  Uri? lastUri;
  String? lastMethod;
  String? lastBody;
  Map<String, String>? lastHeaders;

  List<Map<String, dynamic>> partidosDb = [
    {
      'id': 1,
      'fase': 'PRIMERA_FASE',
      'jornada': 1,
      'equipoLocalId': 1,
      'equipoLocal': 'Sistemas FC',
      'equipoVisitanteId': 2,
      'equipoVisitante': 'Electrónica United',
      'fechaHora': '2026-10-03T14:00:00Z',
      'golesLocal': 2,
      'golesVisitante': 1,
      'estado': 'FINALIZADO',
      'observaciones': 'Primera Fase - Jornada 1',
    },
    {
      'id': 2,
      'fase': 'PRIMERA_FASE',
      'jornada': 1,
      'equipoLocalId': 3,
      'equipoLocal': 'Redes CF',
      'equipoVisitanteId': 4,
      'equipoVisitante': 'Mecatrónica SC',
      'fechaHora': '2026-10-03T16:00:00Z',
      'golesLocal': 0,
      'golesVisitante': 0,
      'estado': 'FINALIZADO',
      'observaciones': 'Primera Fase - Jornada 1',
    },
  ];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastMethod = request.method;
    lastHeaders = request.headers;
    if (request is http.Request) {
      lastBody = request.body;
    }

    // POST /api/partidos/generar-fixture
    if (request.method == 'POST' && request.url.path.contains('/generar-fixture')) {
      final payload = jsonDecode(lastBody ?? '{}');
      final fase = payload['fase'] ?? 'PRIMERA_FASE';
      final modalidad = payload['modalidad'] ?? 'Ida';
      final soloVistaPrevia = payload['soloVistaPrevia'] == true;

      final previewPartidos = [
        {
          'numero': 1,
          'fase': fase,
          'llave': 'LLAVE_1',
          'jornada': 9,
          'equipoLocalId': 1,
          'equipoLocal': 'Sistemas FC',
          'equipoVisitanteId': 8,
          'equipoVisitante': 'Telecomunicaciones',
          'fechaHora': '2026-10-10T14:00:00Z',
          'observaciones': 'Cuartos - Llave 1 • Ventaja Deportiva (Punto Invisible): Sistemas FC',
          'estado': 'PROGRAMADO',
        },
        {
          'numero': 2,
          'fase': fase,
          'llave': 'LLAVE_2',
          'jornada': 9,
          'equipoLocalId': 2,
          'equipoLocal': 'Electrónica United',
          'equipoVisitanteId': 7,
          'equipoVisitante': 'Bioingeniería FC',
          'fechaHora': '2026-10-10T16:00:00Z',
          'observaciones': 'Cuartos - Llave 2 • Ventaja Deportiva: Electrónica United',
          'estado': 'PROGRAMADO',
        }
      ];

      if (!soloVistaPrevia) {
        for (final p in previewPartidos) {
          partidosDb.add({
            'id': partidosDb.length + 1,
            'fase': p['fase'],
            'llave': p['llave'],
            'jornada': p['jornada'],
            'equipoLocalId': p['equipoLocalId'],
            'equipoLocal': p['equipoLocal'],
            'equipoVisitanteId': p['equipoVisitanteId'],
            'equipoVisitante': p['equipoVisitante'],
            'fechaHora': p['fechaHora'],
            'golesLocal': null,
            'golesVisitante': null,
            'estado': 'PROGRAMADO',
            'observaciones': p['observaciones'],
          });
        }
      }

      final responseData = {
        'mensaje': soloVistaPrevia
            ? 'Vista previa del fixture calculada exitosamente.'
            : 'Fixture de $fase ($modalidad) generado exitosamente con ${previewPartidos.length} partidos.',
        'fase': fase,
        'modalidad': modalidad,
        'totalPartidos': previewPartidos.length,
        'partidos': previewPartidos,
      };

      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(responseData))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // GET /api/jornadas
    if (request.method == 'GET' && request.url.path.contains('/jornadas')) {
      final data = {
        'cantidadJornadas': 7,
        'jornadas': [
          {'id': 1, 'numero': 1, 'nombre': 'Jornada 1', 'activo': true},
          {'id': 2, 'numero': 2, 'nombre': 'Jornada 2', 'activo': true},
        ]
      };
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(data))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // GET /api/partidos
    if (request.method == 'GET' && request.url.path.endsWith('/partidos')) {
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(partidosDb))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // GET /api/posiciones
    if (request.method == 'GET' && request.url.path.contains('/posiciones')) {
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode([]))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode('[]')),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockFixtureHttpClient mockClient;
  late ApiClient apiClient;
  late JornadasService jornadasService;
  late PartidosService partidosService;
  late TorneoService torneoService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockClient = MockFixtureHttpClient();
    apiClient = ApiClient(client: mockClient);
    jornadasService = JornadasService(apiClient: apiClient);
    partidosService = PartidosService(apiClient: apiClient);
    torneoService = TorneoService(apiClient: apiClient);

    final session = SessionManager();
    session.clearSession();
    session.setCampeonatos([
      const Campeonato(
        id: 1,
        nombre: 'Torneo Intertecnologías 2026',
        slug: 'intertecnologias-2026',
        activo: true,
        publicado: true,
      ),
    ]);
  });

  tearDown(() {
    SessionManager().clearSession();
  });

  group('1. PartidosService - Generación de Fixture', () {
    test('generarFixture envía POST con payload correcto para vista previa y guardado', () async {
      final res = await partidosService.generarFixture(
        fase: 'CUARTOS',
        fechaInicio: DateTime.parse('2026-10-10T14:00:00Z'),
        modalidad: 'IdaYVuelta',
        soloVistaPrevia: false,
        sobrescribirFase: true,
        campeonatoId: 1,
        torneoId: 1,
        token: 'fake-jwt-token',
      );

      expect(mockClient.lastMethod, 'POST');
      expect(mockClient.lastUri?.path, contains('/generar-fixture'));
      expect(mockClient.lastHeaders?['authorization'], 'Bearer fake-jwt-token');

      final payload = jsonDecode(mockClient.lastBody!);
      expect(payload['fase'], 'CUARTOS');
      expect(payload['modalidad'], 'IdaYVuelta');
      expect(payload['soloVistaPrevia'], false);
      expect(payload['sobrescribirFase'], true);
      expect(payload['campeonatoId'], 1);
      expect(payload['torneoId'], 1);

      expect(res['fase'], 'CUARTOS');
      expect(res['totalPartidos'], 2);
    });
  });

  group('2. JornadasPage - Filtrado reactivo por fase', () {
    testWidgets('Filtra reactivamente los partidos al pulsar chips de fase', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        home: JornadasPage(
          jornadasService: jornadasService,
          partidosService: partidosService,
          torneoService: torneoService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Partidos por jornada'), findsOneWidget);
      expect(find.text('Todas las Fases'), findsOneWidget);
      expect(find.text('1. Primera Fase'), findsOneWidget);
      expect(find.text('2. Cuadrangulares'), findsOneWidget);
      expect(find.text('3. Cuartos'), findsOneWidget);
      expect(find.text('4. Semifinales'), findsOneWidget);
      expect(find.text('5. Gran Final'), findsOneWidget);

      // Pulsar chip "3. Cuartos"
      await tester.tap(find.text('3. Cuartos'));
      await tester.pumpAndSettle();

      // No hay partidos registrados en cuartos aún
      expect(find.text('Tercera Ronda (Cuartos de Final)'), findsOneWidget);
      // Usuario público no ve botón de generación
      expect(find.byKey(const Key('btn_generar_fixture_banner')), findsNothing);
    });

    testWidgets('Usuario ADMIN visualiza botón rápido para fase vacía y botón en banner', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'admin-token',
        usuario: 'admin_user',
        rol: 'ADMIN',
        campeonatoId: 1,
      ));

      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        home: JornadasPage(
          token: 'admin-token',
          jornadasService: jornadasService,
          partidosService: partidosService,
          torneoService: torneoService,
        ),
      ));
      await tester.pumpAndSettle();

      // En banner para admin se encuentra el botón "+ Generar Fixture"
      expect(find.byKey(const Key('btn_generar_fixture_banner')), findsOneWidget);

      // Filtrar a Cuartos
      await tester.tap(find.text('3. Cuartos'));
      await tester.pumpAndSettle();

      // Debe aparecer la tarjeta de acción rápida "+ Generar Cruces de Cuartos de Final"
      expect(find.textContaining('Fase sin partidos: Cuartos de Final'), findsOneWidget);
      expect(find.text('+ Generar Cruces de Cuartos de Final'), findsOneWidget);
    });
  });

  group('3. Modal Interactivo de Generación de Fixture', () {
    testWidgets('Abre modal, previsualiza cruces y genera exitosamente el fixture', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'superadmin-token',
        usuario: 'superadmin_user',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
      ));

      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        home: JornadasPage(
          token: 'superadmin-token',
          jornadasService: jornadasService,
          partidosService: partidosService,
          torneoService: torneoService,
        ),
      ));
      await tester.pumpAndSettle();

      // Abrir modal desde el botón de banner
      await tester.tap(find.byKey(const Key('btn_generar_fixture_banner')));
      await tester.pumpAndSettle();

      // Verificar que el modal se abrió con todos los controles
      expect(find.text('Generador de Fixture'), findsOneWidget);
      expect(find.byKey(const Key('dropdown_fase_fixture')), findsOneWidget);
      expect(find.byKey(const Key('btn_seleccionar_fecha_fixture')), findsOneWidget);
      expect(find.byKey(const Key('chip_modalidad_ida')), findsOneWidget);
      expect(find.byKey(const Key('chip_modalidad_ida_vuelta')), findsOneWidget);
      expect(find.byKey(const Key('switch_sobrescribir_fixture')), findsOneWidget);
      expect(find.byKey(const Key('btn_vista_previa_fixture')), findsOneWidget);
      expect(find.byKey(const Key('btn_confirmar_generar_fixture')), findsOneWidget);

      // Seleccionar modalidad "Ida y Vuelta"
      await tester.tap(find.byKey(const Key('chip_modalidad_ida_vuelta')));
      await tester.pumpAndSettle();

      // Pulsar "Ver Vista Previa de Cruces"
      await tester.tap(find.byKey(const Key('btn_vista_previa_fixture')));
      await tester.pumpAndSettle();

      // Verificar que se renderizó la vista previa de cruces proyectados
      expect(find.textContaining('Cruces proyectados'), findsOneWidget);
      expect(find.textContaining('Sistemas FC vs Telecomunicaciones'), findsOneWidget);
      expect(find.textContaining('⭐ Ventaja'), findsWidgets);

      // Confirmar y generar el fixture
      await tester.tap(find.byKey(const Key('btn_confirmar_generar_fixture')));
      await tester.pumpAndSettle();

      // El diálogo debe cerrarse y mostrar el SnackBar de confirmación
      expect(find.text('Generador de Fixture'), findsNothing);
      expect(find.textContaining('generado exitosamente'), findsOneWidget);
    });
  });
}

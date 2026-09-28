import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/equipos_page.dart';
import 'package:torneo_intertecnologias_app/models/auth_user.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';
import 'package:torneo_intertecnologias_app/services/equipos_service.dart';
import 'package:torneo_intertecnologias_app/services/jugadores_service.dart';

class MockEquiposHttpClient extends http.BaseClient {
  Uri? lastUri;
  String? lastMethod;
  String? lastBody;
  Map<String, String>? lastHeaders;

  List<Map<String, dynamic>> equiposDb = [
    {
      'id': 1,
      'nombre': 'Sistemas FC',
      'sigla': 'SIS',
      'colorPrincipal': '#1D4F7A',
      'logo': null,
      'campeonatoId': 1,
      'torneoId': 1,
      'activo': true,
      'puntos': 15,
      'partidosJugados': 5,
    },
    {
      'id': 2,
      'nombre': 'Electrónica United',
      'sigla': 'ELE',
      'colorPrincipal': '#D32F2F',
      'logo': null,
      'campeonatoId': 1,
      'torneoId': 1,
      'activo': true,
      'puntos': 12,
      'partidosJugados': 5,
    }
  ];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastMethod = request.method;
    lastHeaders = request.headers;
    if (request is http.Request) {
      lastBody = request.body;
    }

    // GET /api/equipos
    if (request.method == 'GET' && request.url.path.endsWith('/equipos')) {
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(equiposDb))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // POST /api/equipos
    if (request.method == 'POST' && request.url.path.endsWith('/equipos')) {
      final payload = jsonDecode(lastBody ?? '{}');
      final newEquipo = {
        'id': equiposDb.length + 1,
        'nombre': payload['nombre'] ?? 'Nuevo Equipo',
        'sigla': payload['sigla'] ?? 'NEQ',
        'colorPrincipal': payload['colorPrincipal'] ?? '#1D4F7A',
        'logo': payload['logo'],
        'campeonatoId': payload['campeonatoId'] ?? 1,
        'torneoId': payload['torneoId'] ?? payload['campeonatoId'] ?? 1,
        'activo': true,
        'puntos': 0,
        'partidosJugados': 0,
      };
      equiposDb.add(newEquipo);

      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({
          'mensaje': 'Equipo registrado exitosamente.',
          'equipo': newEquipo,
        }))),
        201,
        headers: {'content-type': 'application/json'},
      );
    }

    // Default fallback
    return http.StreamedResponse(
      Stream.value(utf8.encode('[]')),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockEquiposHttpClient mockClient;
  late ApiClient apiClient;
  late EquiposService equiposService;
  late JugadoresService jugadoresService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockClient = MockEquiposHttpClient();
    apiClient = ApiClient(client: mockClient);
    equiposService = EquiposService(apiClient: apiClient);
    jugadoresService = JugadoresService(apiClient: apiClient);

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

  group('1. EquiposService - Creación de Equipos', () {
    test('crearEquipo envía POST con los campos correctos y retorna el equipo', () async {
      final equipo = await equiposService.crearEquipo(
        nombre: 'Ciberseguridad CF',
        sigla: 'CSCF',
        colorPrincipal: '#0D9488',
        logo: 'https://example.com/logo.png',
        campeonatoId: 1,
        torneoId: 1,
        token: 'fake-jwt-token',
      );

      expect(mockClient.lastMethod, 'POST');
      expect(mockClient.lastUri?.path, contains('/equipos'));
      expect(mockClient.lastHeaders?['authorization'], 'Bearer fake-jwt-token');

      final payload = jsonDecode(mockClient.lastBody!);
      expect(payload['nombre'], 'Ciberseguridad CF');
      expect(payload['sigla'], 'CSCF');
      expect(payload['colorPrincipal'], '#0D9488');
      expect(payload['logo'], 'https://example.com/logo.png');
      expect(payload['campeonatoId'], 1);
      expect(payload['torneoId'], 1);

      expect(equipo.nombre, 'Ciberseguridad CF');
      expect(equipo.sigla, 'CSCF');
      expect(equipo.colorPrincipal, '#0D9488');
    });
  });

  group('2. EquiposPage - Controles según rol de usuario', () {
    testWidgets('Usuario no autenticado (público) NO visualiza botones de creación ni FAB de admin', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        home: EquiposPage(
          equiposService: equiposService,
          jugadoresService: jugadoresService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Equipos participantes'), findsOneWidget);
      expect(find.byKey(const Key('btn_crear_equipo_banner')), findsNothing);
      expect(find.byKey(const Key('btn_crear_equipo_fab')), findsNothing);
      expect(find.byKey(const Key('btn_inscribir_jugador_fab')), findsNothing);
    });

    testWidgets('Usuario ADMIN visualiza botón "+ Crear Equipo" en banner y en FloatingActionButton', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'fake-token-admin',
        usuario: 'admin_user',
        rol: 'ADMIN',
        campeonatoId: 1,
      ));

      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        home: EquiposPage(
          token: 'fake-token-admin',
          equiposService: equiposService,
          jugadoresService: jugadoresService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Equipos participantes'), findsOneWidget);
      expect(find.byKey(const Key('btn_crear_equipo_banner')), findsOneWidget);
      expect(find.byKey(const Key('btn_crear_equipo_fab')), findsOneWidget);
      expect(find.byKey(const Key('btn_inscribir_jugador_fab')), findsOneWidget);
    });
  });

  group('3. Diálogo de Creación de Equipo', () {
    testWidgets('Abre diálogo con todos los campos requeridos y realiza validaciones', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'fake-token-super',
        usuario: 'superadmin_user',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
      ));

      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        home: EquiposPage(
          token: 'fake-token-super',
          equiposService: equiposService,
          jugadoresService: jugadoresService,
        ),
      ));
      await tester.pumpAndSettle();

      // Pulsar botón de crear equipo
      await tester.tap(find.byKey(const Key('btn_crear_equipo_banner')));
      await tester.pumpAndSettle();

      // Verificar que el diálogo se abre
      expect(find.text('Nuevo Equipo'), findsOneWidget);
      expect(find.text('Torneo: Torneo Intertecnologías 2026'), findsOneWidget);
      expect(find.byKey(const Key('input_nombre_equipo')), findsOneWidget);
      expect(find.byKey(const Key('input_sigla_equipo')), findsOneWidget);
      expect(find.byKey(const Key('btn_subir_escudo_equipo')), findsOneWidget);
      expect(find.byKey(const Key('btn_guardar_nuevo_equipo')), findsOneWidget);

      // Intentar guardar con campos vacíos -> muestra error de validación
      await tester.tap(find.byKey(const Key('btn_guardar_nuevo_equipo')));
      await tester.pumpAndSettle();
      expect(find.text('El nombre del equipo es obligatorio'), findsOneWidget);

      // Escribir nombre del equipo
      await tester.enterText(find.byKey(const Key('input_nombre_equipo')), 'Inteligencia Artificial');
      await tester.pumpAndSettle();

      // Verificar que la sigla se genera automáticamente si está vacía
      final siglaField = tester.widget<TextFormField>(find.byKey(const Key('input_sigla_equipo')));
      expect(siglaField.controller?.text, 'IA');

      // Seleccionar un color de la paleta
      final colorOption = find.byKey(const Key('color_picker_#0D9488'));
      if (colorOption.evaluate().isNotEmpty) {
        await tester.tap(colorOption);
        await tester.pumpAndSettle();
      }

      // Guardar equipo exitosamente
      await tester.tap(find.byKey(const Key('btn_guardar_nuevo_equipo')));
      await tester.pumpAndSettle();

      // El diálogo debe cerrarse y el nuevo equipo debe figurar en la lista
      expect(find.text('Nuevo Equipo'), findsNothing);
      expect(find.text('Inteligencia Artificial'), findsOneWidget);
      expect(find.text('IA'), findsWidgets);
      expect(find.textContaining('creado exitosamente'), findsOneWidget);
    });

    testWidgets('Empty view muestra botón de crear primer equipo para admin', (tester) async {
      mockClient.equiposDb.clear(); // Vaciar equipos

      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'fake-token-admin',
        usuario: 'admin_user',
        rol: 'ADMIN',
        campeonatoId: 1,
      ));

      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        home: EquiposPage(
          token: 'fake-token-admin',
          equiposService: equiposService,
          jugadoresService: jugadoresService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No hay equipos registrados en este torneo.'), findsOneWidget);
      expect(find.byKey(const Key('btn_crear_primer_equipo')), findsOneWidget);

      // Pulsar botón de crear primer equipo
      await tester.tap(find.byKey(const Key('btn_crear_primer_equipo')));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Equipo'), findsOneWidget);
    });
  });
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/models/auth_user.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';
import 'package:torneo_intertecnologias_app/services/torneo_service.dart';
import 'package:torneo_intertecnologias_app/widgets/campeonato_selector_bar.dart';

class MockTorneoHttpClient extends http.BaseClient {
  Uri? lastUri;
  String? lastMethod;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastMethod = request.method;
    if (request is http.Request) {
      lastBody = request.body;
    }

    // Respuesta para GET /api/torneo/listar o /api/campeonatos
    if (request.url.path.endsWith('/listar') || request.url.path.endsWith('/campeonatos')) {
      final list = [
        {
          'id': 1,
          'nombre': 'Torneo Intertecnologías 2026',
          'slug': 'intertecnologias',
          'activo': true,
          'publicado': true,
          'totalEquipos': 8,
          'totalPartidos': 12,
        }
      ];
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(list))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // Respuesta para POST /api/torneo/crear
    if (request.url.path.endsWith('/crear')) {
      final payload = jsonDecode(lastBody ?? '{}');
      final resp = {
        'mensaje': 'Torneo registrado exitosamente.',
        'torneo': {
          'id': 2,
          'organizacionId': 1,
          'organizacionNombre': 'CUN / Intertecnologías',
          'nombre': payload['nombre'] ?? 'Nuevo Torneo 2026',
          'slug': 'nuevo-torneo-2026',
          'limiteJugadores': payload['limiteJugadores'] ?? 14,
          'tienePuntoInvisible': payload['tienePuntoInvisible'] ?? true,
          'topGoleadoresMax': payload['topGoleadoresMax'] ?? 10,
          'activo': true,
          'totalEquipos': 0,
          'totalPartidos': 0,
        }
      };
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(resp))),
        201,
        headers: {'content-type': 'application/json'},
      );
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode('{}')),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockTorneoHttpClient mockClient;
  late TorneoService mockTorneoService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockClient = MockTorneoHttpClient();
    final apiClient = ApiClient(client: mockClient);
    mockTorneoService = TorneoService(apiClient: apiClient);
    SessionManager().clearSession();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: CampeonatoSelectorBar(torneoService: mockTorneoService),
        ),
      ),
    );
  }

  group('Modal Seleccionar Torneo - Visibilidad del botón de creación', () {
    testWidgets('Visitante anónimo NO ve el botón "+ Crear Nuevo Torneo"', (tester) async {
      final session = SessionManager();
      session.clearSession();
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias', activo: true, publicado: true),
      ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Abrir modal haciendo tap en la barra
      await tester.tap(find.byType(CampeonatoSelectorBar));
      await tester.pumpAndSettle();

      expect(find.text('Seleccionar Torneo'), findsOneWidget);
      expect(find.byKey(const Key('btn_crear_nuevo_torneo')), findsNothing);
    });

    testWidgets('ADMIN regular NO ve el botón "+ Crear Nuevo Torneo"', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'admin-token',
        usuario: 'admin_user',
        rol: 'ADMIN',
        campeonatoId: 1,
      ));
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias', activo: true, publicado: true),
      ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // ADMIN regular no puede cambiar campeonato, por tanto no abre modal
      expect(session.canChangeCampeonato, isFalse);
    });

    testWidgets('SUPERADMIN SÍ ve el botón "+ Crear Nuevo Torneo"', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'super-token',
        usuario: 'superadmin_user',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
      ));
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias', activo: true, publicado: true),
      ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Abrir selector
      await tester.tap(find.byType(CampeonatoSelectorBar));
      await tester.pumpAndSettle();

      expect(find.text('Seleccionar Torneo'), findsOneWidget);
      expect(find.byKey(const Key('btn_crear_nuevo_torneo')), findsOneWidget);
      expect(find.text('+ Crear Nuevo Torneo'), findsOneWidget);
    });
  });

  group('Formulario de Creación de Torneo - Validaciones y Controles', () {
    testWidgets('Muestra todos los campos requeridos en el diálogo', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'super-token',
        usuario: 'superadmin_user',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
      ));
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias', activo: true, publicado: true),
      ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Abrir modal
      await tester.tap(find.byType(CampeonatoSelectorBar));
      await tester.pumpAndSettle();

      // Tocar en "+ Crear Nuevo Torneo"
      await tester.tap(find.byKey(const Key('btn_crear_nuevo_torneo')));
      await tester.pumpAndSettle();

      // Verificar diálogo
      expect(find.text('Nuevo Torneo'), findsOneWidget);
      expect(find.byKey(const Key('input_nombre_torneo')), findsOneWidget);
      expect(find.byKey(const Key('slider_cupo_jugadores')), findsOneWidget);
      expect(find.byKey(const Key('segmented_top_goleadores')), findsOneWidget);
      expect(find.byKey(const Key('switch_punto_invisible')), findsOneWidget);
      expect(find.byKey(const Key('btn_cancelar_creacion_torneo')), findsOneWidget);
      expect(find.byKey(const Key('btn_guardar_torneo')), findsOneWidget);
    });

    testWidgets('Valida que el nombre del torneo sea obligatorio', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'super-token',
        usuario: 'superadmin_user',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
      ));
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias', activo: true, publicado: true),
      ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CampeonatoSelectorBar));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_crear_nuevo_torneo')));
      await tester.pumpAndSettle();

      // Intentar guardar con campo vacío
      await tester.tap(find.byKey(const Key('btn_guardar_torneo')));
      await tester.pumpAndSettle();

      expect(find.text('El nombre del torneo es obligatorio'), findsOneWidget);
      expect(mockClient.lastMethod, isNot(equals('POST')));
    });

    testWidgets('Crea y selecciona automáticamente el nuevo torneo como activo', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'super-token',
        usuario: 'superadmin_user',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
      ));
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias', activo: true, publicado: true),
      ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CampeonatoSelectorBar));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_crear_nuevo_torneo')));
      await tester.pumpAndSettle();

      // Ingresar nombre válido
      await tester.enterText(find.byKey(const Key('input_nombre_torneo')), 'Copa Campeones 2026');
      await tester.pumpAndSettle();

      // Tocar guardar
      await tester.tap(find.byKey(const Key('btn_guardar_torneo')));
      await tester.pumpAndSettle();

      // Verificar que se envió POST a /api/torneo/crear
      expect(mockClient.lastUri?.path, endsWith('/api/torneo/crear'));
      expect(mockClient.lastMethod, equals('POST'));

      // Verificar que el nuevo torneo quedó seleccionado en SessionManager
      expect(session.selectedCampeonatoId, equals(2));
      expect(session.selectedCampeonatoNombre, equals('Copa Campeones 2026'));
      expect(session.campeonatos.any((c) => c.id == 2), isTrue);
    });
  });
}

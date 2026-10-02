import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_intertecnologias_app/core/errors/app_exception.dart';
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
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
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

  group('Eliminación / Desactivación de Torneos en el Selector', () {
    testWidgets('Visitante anónimo NO ve la papelera roja de eliminación', (tester) async {
      final session = SessionManager();
      session.clearSession();
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias', activo: true, publicado: true),
        const Campeonato(id: 2, nombre: 'Torneo Secundario 2026', slug: 'torneo-secundario', activo: true, publicado: true),
      ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CampeonatoSelectorBar));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_eliminar_torneo_1')), findsNothing);
      expect(find.byKey(const Key('btn_eliminar_torneo_2')), findsNothing);
    });

    testWidgets('SUPERADMIN NO ve botón eliminar para campeonato ID 1 pero SÍ para campeonato ID 2', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'super-token',
        usuario: 'superadmin_user',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
      ));
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias', activo: true, publicado: true),
        const Campeonato(id: 2, nombre: 'Torneo Secundario 2026', slug: 'torneo-secundario', activo: true, publicado: true),
      ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CampeonatoSelectorBar));
      await tester.pumpAndSettle();

      // Torneo ID 1 NUNCA muestra botón eliminar
      expect(find.byKey(const Key('btn_eliminar_torneo_1')), findsNothing);

      // Torneo ID 2 SÍ muestra botón eliminar con papelera
      expect(find.byKey(const Key('btn_eliminar_torneo_2')), findsOneWidget);
    });

    testWidgets('Diálogo de confirmación muestra nombre y cancela sin llamar DELETE', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'super-token',
        usuario: 'superadmin_user',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
      ));
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias', activo: true, publicado: true),
        const Campeonato(id: 2, nombre: 'Torneo Secundario 2026', slug: 'torneo-secundario', activo: true, publicado: true),
      ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CampeonatoSelectorBar));
      await tester.pumpAndSettle();

      // Tocar papelera de torneo 2
      await tester.tap(find.byKey(const Key('btn_eliminar_torneo_2')));
      await tester.pumpAndSettle();

      // Verificar diálogo de confirmación con nombre claro
      expect(find.text('Eliminar Torneo'), findsOneWidget);
      expect(
        find.text('¿Estás seguro de que deseas eliminar el torneo "Torneo Secundario 2026"?'),
        findsOneWidget,
      );

      // Tocar Cancelar
      await tester.tap(find.byKey(const Key('btn_cancelar_eliminar_torneo')));
      await tester.pumpAndSettle();

      // No debe haberse llamado DELETE
      expect(mockClient.requests.any((r) => r.method == 'DELETE'), isFalse);
      expect(session.campeonatos.any((c) => c.id == 2), isTrue);
    });

    testWidgets('Confirmar eliminación llama DELETE /api/torneo/2, NO llama /api/campeonatos, desaparece del selector y selecciona de forma segura torneo ID 1', (tester) async {
      final session = SessionManager();
      session.setSession(const AuthUser(
        token: 'super-token',
        usuario: 'superadmin_user',
        rol: 'SUPERADMIN',
        campeonatoId: 1,
      ));
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias', activo: true, publicado: true),
        const Campeonato(id: 2, nombre: 'Torneo Secundario 2026', slug: 'torneo-secundario', activo: true, publicado: true),
      ]);

      // Seleccionar torneo 2 para verificar regla 15
      session.selectCampeonatoById(2);
      expect(session.selectedCampeonatoId, equals(2));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CampeonatoSelectorBar));
      await tester.pumpAndSettle();

      // Tocar papelera de torneo 2
      await tester.tap(find.byKey(const Key('btn_eliminar_torneo_2')));
      await tester.pumpAndSettle();

      // Confirmar eliminación
      await tester.tap(find.byKey(const Key('btn_confirmar_eliminar_torneo_2')));
      await tester.pumpAndSettle();

      // 1. Confirmar que DELETE /api/torneo/2 se ejecuta
      expect(
        mockClient.requests.any((r) => r.method == 'DELETE' && r.url.path.endsWith('/api/torneo/2')),
        isTrue,
      );

      // 2. Confirmar que ya NO se llama DELETE /api/campeonatos/2
      expect(
        mockClient.requests.any((r) => r.method == 'DELETE' && r.url.path.contains('/api/campeonatos')),
        isFalse,
      );

      // 3. Torneo 2 desaparece del selector tras refrescar /api/torneo/listar
      expect(session.campeonatos.any((c) => c.id == 2), isFalse);
      expect(find.text('Torneo Secundario 2026'), findsNothing);

      // 4. El torneo ID 1 queda seleccionado de forma segura
      expect(session.selectedCampeonatoId, equals(1));
      expect(session.selectedCampeonatoNombre, equals('Torneo Intertecnologías 2026'));

      // 5. El slug del ID 1 permanece exactamente igual
      expect(session.selectedCampeonatoSlug, equals('intertecnologias'));

      // Verificar SnackBar de éxito
      expect(find.text('Torneo "Torneo Secundario 2026" eliminado exitosamente.'), findsOneWidget);
    });

    test('TorneoService.desactivarCampeonato llama DELETE /api/torneo/{id} y rechaza ID 1', () async {
      // Intentar desactivar ID 1 debe fallar antes de hacer cualquier petición HTTP
      expect(
        () => mockTorneoService.desactivarCampeonato(1, token: 'super-token'),
        throwsA(isA<AppException>()),
      );
      expect(mockClient.requests.where((r) => r.method == 'DELETE'), isEmpty);

      // Desactivar ID 2 debe llamar DELETE /api/torneo/2
      await mockTorneoService.desactivarCampeonato(2, token: 'super-token');
      expect(
        mockClient.requests.any((r) => r.method == 'DELETE' && r.url.path.endsWith('/api/torneo/2')),
        isTrue,
      );
      expect(
        mockClient.requests.any((r) => r.method == 'DELETE' && r.url.path.contains('/api/campeonatos')),
        isFalse,
      );
    });

    test('removerCampeonato(1) no hace absolutamente nada y conserva el torneo principal', () {
      final session = SessionManager();
      const slugReal = 'torneo-intertecnologias-2026-backend-oficial';
      const c1 = Campeonato(
        id: 1,
        nombre: 'Torneo Intertecnologías 2026',
        slug: slugReal,
        activo: true,
        publicado: true,
      );
      session.setCampeonatos([c1]);
      session.selectCampeonato(c1);

      session.removerCampeonato(1);

      expect(session.campeonatos.length, equals(1));
      expect(session.campeonatos.first.id, equals(1));
      expect(session.selectedCampeonatoId, equals(1));
      expect(session.selectedCampeonatoSlug, equals(slugReal));
      expect(session.selectedCampeonato, equals(c1));
    });

    test('Al eliminar el torneo seleccionado se conserva exactamente el slug real del backend para ID 1 sin valores hardcodeados', () {
      final session = SessionManager();
      const slugRealBackend = 'mi-slug-unico-del-backend-torneo-1';
      const c1 = Campeonato(
        id: 1,
        nombre: 'Torneo Principal Oficial',
        slug: slugRealBackend,
        activo: true,
        publicado: true,
      );
      const c2 = Campeonato(
        id: 2,
        nombre: 'Torneo Secundario 2026',
        slug: 'torneo-secundario',
        activo: true,
        publicado: true,
      );
      session.setCampeonatos([c1, c2]);
      session.selectCampeonato(c2);
      expect(session.selectedCampeonatoId, equals(2));

      // Eliminar torneo 2
      session.removerCampeonato(2);

      // Debe haber vuelto al objeto real ID 1 existente en _campeonatos cargado desde backend
      expect(session.selectedCampeonatoId, equals(1));
      expect(session.selectedCampeonato, equals(c1));
      expect(session.selectedCampeonatoNombre, equals('Torneo Principal Oficial'));
      expect(session.selectedCampeonatoSlug, equals(slugRealBackend));
      expect(session.selectedCampeonatoSlug, isNot(equals('intertecnologias')));
      expect(session.selectedCampeonatoSlug, isNot(equals('campeonato-1')));
    });
  });
}

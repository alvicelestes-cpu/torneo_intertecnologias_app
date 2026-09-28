import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_intertecnologias_app/core/constants/api_constants.dart';
import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/equipos_page.dart';
import 'package:torneo_intertecnologias_app/estadisticas_page.dart';
import 'package:torneo_intertecnologias_app/goleadores_page.dart';
import 'package:torneo_intertecnologias_app/jornadas_page.dart';
import 'package:torneo_intertecnologias_app/jugadores_page.dart';
import 'package:torneo_intertecnologias_app/main.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';
import 'package:torneo_intertecnologias_app/partidos_page.dart';
import 'package:torneo_intertecnologias_app/portal_publico_page.dart';
import 'package:torneo_intertecnologias_app/posiciones_page.dart';
import 'package:torneo_intertecnologias_app/services/torneo_service.dart';
import 'package:torneo_intertecnologias_app/widgets/campeonato_selector_bar.dart';

class MockSlugHttpClient extends http.BaseClient {
  Uri? lastUri;
  String? lastMethod;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastMethod = request.method;

    // GET /api/torneo/por-slug/{slug}
    if (request.url.path.contains('/por-slug/')) {
      final slug = request.url.pathSegments.last;
      final responseBody = {
        'id': 7,
        'organizacionId': 1,
        'organizacionNombre': 'CUN / Intertecnologías',
        'nombre': 'Torneo Demo $slug',
        'slug': slug,
        'limiteJugadores': 18,
        'tienePuntoInvisible': false,
        'topGoleadoresMax': 5,
        'activo': true,
        'publicado': true,
        'totalEquipos': 6,
        'totalPartidos': 15,
      };

      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(responseBody))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // GET /api/torneo/listar
    if (request.url.path.endsWith('/listar') || request.url.path.endsWith('/campeonatos')) {
      final list = [
        {
          'id': 1,
          'nombre': 'Torneo Intertecnologías 2026',
          'slug': 'intertecnologias-2026',
          'activo': true,
          'publicado': true,
          'totalEquipos': 8,
          'totalPartidos': 12,
        },
        {
          'id': 2,
          'nombre': 'Torneo Clausura',
          'slug': 'torneo-clausura',
          'activo': true,
          'publicado': true,
          'totalEquipos': 6,
          'totalPartidos': 10,
        }
      ];
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(list))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // Default fallback vacío para evitar timeouts en tests
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode([]))),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionManager().clearSession();
  });

  group('1. ApiConstants & Headers por Slug', () {
    test('Genera URL correcta para resolución por slug', () {
      final url = ApiConstants.torneoPorSlug('intertecnologias-2026');
      expect(url, contains('/api/torneo/por-slug/intertecnologias-2026'));
    });

    test('defaultHeaders incluye X-Torneo-Slug si se provee', () {
      final headers = ApiConstants.defaultHeaders(
        token: 'token-abc',
        torneoId: 3,
        torneoSlug: 'copa-verano',
      );

      expect(headers['Authorization'], 'Bearer token-abc');
      expect(headers['X-Torneo-Id'], '3');
      expect(headers['X-Torneo-Slug'], 'copa-verano');
    });
  });

  group('2. SessionManager Slug Parsing & Resolution', () {
    test('extractSlugFromUri resuelve rutas directas y con subrutas', () {
      expect(
        SessionManager.extractSlugFromUri(Uri.parse('https://app.com/t/intertecnologias-2026')),
        'intertecnologias-2026',
      );

      expect(
        SessionManager.extractSlugFromUri(Uri.parse('https://app.com/t/copa-2026/posiciones')),
        'copa-2026',
      );

      expect(
        SessionManager.extractSlugFromUri(Uri.parse('https://app.com/t/liga-elite/equipos')),
        'liga-elite',
      );
    });

    test('extractSlugFromUri resuelve rutas con hash strategy (#)', () {
      expect(
        SessionManager.extractSlugFromUri(Uri.parse('https://app.com/#/t/torneo-primavera')),
        'torneo-primavera',
      );

      expect(
        SessionManager.extractSlugFromUri(Uri.parse('https://app.com/#/t/torneo-primavera/goleadores')),
        'torneo-primavera',
      );
    });

    test('extractSlugFromUri retorna null en rutas estándar sin slug', () {
      expect(SessionManager.extractSlugFromUri(Uri.parse('https://app.com/')), isNull);
      expect(SessionManager.extractSlugFromUri(Uri.parse('https://app.com/equipos')), isNull);
      expect(SessionManager.extractSlugFromUri(Uri.parse('https://app.com/login')), isNull);
    });

    test('selectCampeonatoBySlug resuelve de lista en memoria y backend', () async {
      final session = SessionManager();
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo 1', slug: 'torneo-uno'),
        const Campeonato(id: 2, nombre: 'Torneo 2', slug: 'torneo-dos'),
      ]);

      // Resuelve de memoria
      final ok1 = await session.selectCampeonatoBySlug('torneo-dos');
      expect(ok1, isTrue);
      expect(session.selectedCampeonatoId, 2);
      expect(session.selectedCampeonatoSlug, 'torneo-dos');

      // Resuelve consultando mock TorneoService
      final mockClient = MockSlugHttpClient();
      final mockService = TorneoService(apiClient: ApiClient(client: mockClient));

      final ok2 = await session.selectCampeonatoBySlug('torneo-remoto', torneoService: mockService);
      expect(ok2, isTrue);
      expect(session.selectedCampeonatoId, 7);
      expect(session.selectedCampeonatoSlug, 'torneo-remoto');
      expect(session.selectedCampeonatoNombre, 'Torneo Demo torneo-remoto');
    });
  });

  group('3. Enrutamiento Web Amigable en TorneoApp', () {
    testWidgets('Ruta /t/intertecnologias-2026 carga PortalPublicoPage', (tester) async {
      await tester.pumpWidget(const TorneoApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PortalPublicoPage));
      Navigator.pushNamed(context, '/t/intertecnologias-2026');
      await tester.pumpAndSettle();

      expect(find.byType(PortalPublicoPage), findsOneWidget);
    });

    testWidgets('Ruta /t/intertecnologias-2026/posiciones carga PosicionesPage', (tester) async {
      await tester.pumpWidget(const TorneoApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PortalPublicoPage));
      Navigator.pushNamed(context, '/t/intertecnologias-2026/posiciones');
      await tester.pumpAndSettle();

      expect(find.byType(PosicionesPage), findsOneWidget);
    });

    testWidgets('Ruta /t/intertecnologias-2026/equipos carga EquiposPage', (tester) async {
      await tester.pumpWidget(const TorneoApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PortalPublicoPage));
      Navigator.pushNamed(context, '/t/intertecnologias-2026/equipos');
      await tester.pumpAndSettle();

      expect(find.byType(EquiposPage), findsOneWidget);
    });

    testWidgets('Ruta /t/intertecnologias-2026/partidos carga PartidosPage', (tester) async {
      await tester.pumpWidget(const TorneoApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PortalPublicoPage));
      Navigator.pushNamed(context, '/t/intertecnologias-2026/partidos');
      await tester.pumpAndSettle();

      expect(find.byType(PartidosPage), findsOneWidget);
    });

    testWidgets('Ruta /t/intertecnologias-2026/jornadas carga JornadasPage', (tester) async {
      await tester.pumpWidget(const TorneoApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PortalPublicoPage));
      Navigator.pushNamed(context, '/t/intertecnologias-2026/jornadas');
      await tester.pumpAndSettle();

      expect(find.byType(JornadasPage), findsOneWidget);
    });

    testWidgets('Ruta /t/intertecnologias-2026/goleadores carga GoleadoresPage', (tester) async {
      await tester.pumpWidget(const TorneoApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PortalPublicoPage));
      Navigator.pushNamed(context, '/t/intertecnologias-2026/goleadores');
      await tester.pumpAndSettle();

      expect(find.byType(GoleadoresPage), findsOneWidget);
    });

    testWidgets('Ruta /t/intertecnologias-2026/estadisticas carga EstadisticasPage', (tester) async {
      await tester.pumpWidget(const TorneoApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PortalPublicoPage));
      Navigator.pushNamed(context, '/t/intertecnologias-2026/estadisticas');
      await tester.pumpAndSettle();

      expect(find.byType(EstadisticasPage), findsOneWidget);
    });

    testWidgets('Ruta /t/intertecnologias-2026/jugadores carga JugadoresPage', (tester) async {
      await tester.pumpWidget(const TorneoApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PortalPublicoPage));
      Navigator.pushNamed(context, '/t/intertecnologias-2026/jugadores');
      await tester.pumpAndSettle();

      expect(find.byType(JugadoresPage), findsOneWidget);
    });
  });

  group('4. CampeonatoSelectorBar & Copiar Enlace', () {
    testWidgets('Muestra botón de copiar enlace en la barra y abre modal con opciones', (tester) async {
      final session = SessionManager();
      session.setCampeonatos([
        const Campeonato(id: 1, nombre: 'Torneo Intertecnologías 2026', slug: 'intertecnologias-2026', totalEquipos: 8, totalPartidos: 12),
        const Campeonato(id: 2, nombre: 'Torneo Clausura', slug: 'torneo-clausura', totalEquipos: 6, totalPartidos: 10),
      ]);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CampeonatoSelectorBar(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica botón en la barra superior
      final btnCopiarBar = find.byKey(const Key('btn_copiar_enlace_torneo_bar'));
      expect(btnCopiarBar, findsOneWidget);

      // Toca el botón para copiar enlace
      await tester.tap(btnCopiarBar);
      await tester.pump();

      // Abre el modal selector
      await tester.tap(find.text('Torneo Intertecnologías 2026'));
      await tester.pumpAndSettle();

      // Verifica botón de copiar enlace en el encabezado del modal
      expect(find.byKey(const Key('btn_copiar_enlace_modal_header')), findsOneWidget);

      // Selecciona el segundo torneo
      await tester.tap(find.text('Torneo Clausura'));
      await tester.pumpAndSettle();

      expect(session.selectedCampeonatoId, 2);
      expect(session.selectedCampeonatoSlug, 'torneo-clausura');
    });
  });
}

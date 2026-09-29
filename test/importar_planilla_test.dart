import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/equipos_page.dart';
import 'package:torneo_intertecnologias_app/models/auth_user.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';
import 'package:torneo_intertecnologias_app/models/equipo.dart';
import 'package:torneo_intertecnologias_app/models/jugador.dart';
import 'package:torneo_intertecnologias_app/models/resumen_importacion.dart';
import 'package:torneo_intertecnologias_app/services/carnets_pdf_service.dart';
import 'package:torneo_intertecnologias_app/services/equipos_service.dart';
import 'package:torneo_intertecnologias_app/services/jugadores_service.dart';
import 'package:torneo_intertecnologias_app/widgets/importar_planilla_modal.dart';

class MockImportHttpClient extends http.BaseClient {
  Uri? lastUri;
  String? lastMethod;
  Map<String, String>? lastHeaders;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastMethod = request.method;
    lastHeaders = request.headers;

    if (request.url.path.contains('/api/equipos/importar-planilla')) {
      final jsonResponse = jsonEncode({
        'exito': true,
        'mensaje': 'Planilla procesada con éxito.',
        'torneoId': 2,
        'torneoNombre': 'Torneo Secundario 2026',
        'equiposCreados': 2,
        'equiposExistentes': 1,
        'jugadoresRegistrados': 10,
        'filasProcesadas': 12,
        'alertas': [
          'Fila 4: El jugador Carlos ya está registrado en este torneo.',
          'Fila 8: Fecha de nacimiento ausente.',
        ],
        'equiposDetalle': [
          {
            'id': 10,
            'nombre': 'Halcones FC',
            'fueCreado': true,
            'jugadoresAgregados': 5,
          },
          {
            'id': 11,
            'nombre': 'Tiburones',
            'fueCreado': true,
            'jugadoresAgregados': 5,
          }
        ]
      });

      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonResponse)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    if (request.url.path.contains('/api/equipos/plantilla-planilla')) {
      return http.StreamedResponse(
        Stream.value(Uint8List.fromList([0x50, 0x4B, 0x03, 0x04])), // PK zip header
        200,
        headers: {'content-type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'},
      );
    }

    if (request.url.path.endsWith('/equipos')) {
      final dummyEquipos = [
        {
          'id': 1,
          'nombre': 'Halcones FC',
          'sigla': 'HAL',
          'colorPrincipal': '#0D47A1',
          'campeonatoId': 2,
          'torneoId': 2,
          'activo': true,
        }
      ];
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(dummyEquipos))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (request.url.path.contains('/jugadores')) {
      return http.StreamedResponse(
        Stream.value(utf8.encode('[]')),
        200,
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionManager().clearSession();
  });

  group('1. ResumenImportacion Model & Deserialization Tests', () {
    test('Parsea JSON completo de importación masiva exitosa', () {
      final json = {
        'exito': true,
        'mensaje': 'Planilla importada.',
        'torneoId': 5,
        'torneoNombre': 'Copa Primavera',
        'equiposCreados': 3,
        'equiposExistentes': 2,
        'jugadoresRegistrados': 14,
        'filasProcesadas': 16,
        'alertas': ['Fila 2: Documento duplicado'],
        'equiposDetalle': [
          {'id': 101, 'nombre': 'Alpha', 'fueCreado': true, 'jugadoresAgregados': 7},
          {'id': 102, 'nombre': 'Beta', 'fueCreado': false, 'jugadoresAgregados': 7},
        ],
      };

      final resumen = ResumenImportacion.fromJson(json);

      expect(resumen.exito, isTrue);
      expect(resumen.torneoId, 5);
      expect(resumen.torneoNombre, 'Copa Primavera');
      expect(resumen.equiposCreados, 3);
      expect(resumen.equiposExistentes, 2);
      expect(resumen.jugadoresRegistrados, 14);
      expect(resumen.filasProcesadas, 16);
      expect(resumen.alertas.length, 1);
      expect(resumen.alertas.first, 'Fila 2: Documento duplicado');
      expect(resumen.equiposDetalle.length, 2);
      expect(resumen.equiposDetalle.first.nombre, 'Alpha');
      expect(resumen.equiposDetalle.first.fueCreado, isTrue);
    });

    test('Maneja valores nulos o ausentes de forma segura', () {
      final resumen = ResumenImportacion.fromJson({});

      expect(resumen.exito, isFalse);
      expect(resumen.mensaje, '');
      expect(resumen.torneoId, 0);
      expect(resumen.equiposCreados, 0);
      expect(resumen.jugadoresRegistrados, 0);
      expect(resumen.alertas, isEmpty);
      expect(resumen.equiposDetalle, isEmpty);
    });
  });

  group('2. Carnets Multi-Tenant - Leyenda dinámica del torneo activo', () {
    test('SessionManager resuelve selectedCampeonatoNombre dinámicamente', () {
      final session = SessionManager();

      // Por defecto
      expect(session.selectedCampeonatoNombre, isNotEmpty);

      // Asignar un torneo secundario
      session.selectCampeonato(
        Campeonato(
          id: 42,
          nombre: 'Torneo Clausura Intertecnologías 2026',
          slug: 'clausura-2026',
        ),
      );

      expect(session.selectedCampeonatoId, 42);
      expect(session.selectedCampeonatoNombre, 'Torneo Clausura Intertecnologías 2026');
    });

    test('generarCarnetsPdf genera PDF con leyenda del torneo secundario activo', () async {
      final session = SessionManager();
      session.selectCampeonato(
        Campeonato(
          id: 99,
          nombre: 'Supercopa Élite 2026',
          slug: 'supercopa-2026',
        ),
      );

      final equipo = Equipo(
        id: 1,
        nombre: 'Los Titanes',
        sigla: 'TIT',
        colorPrincipal: '#0D47A1',
      );

      final jugador = Jugador(
        id: 1,
        equipoId: 1,
        nombres: 'Roberto',
        apellidos: 'Carlos',
        fechaNacimiento: '1982-04-10', // 40+ años
        estado: 'ACTIVO',
      );

      final pdfBytes = await CarnetsPdfService.generarCarnetsPdf(
        equipo: equipo,
        jugadores: [jugador],
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
      // Verifica cabecera estándar PDF
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });
  });

  group('3. EquiposPage - Botón de Importar Planilla por Rol', () {
    testWidgets('Oculta botón "+ Importar Planilla" si el usuario NO es admin', (tester) async {
      final mockClient = MockImportHttpClient();
      final apiClient = ApiClient(client: mockClient);
      final equiposService = EquiposService(apiClient: apiClient);
      final jugadoresService = JugadoresService(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: EquiposPage(
            equiposService: equiposService,
            jugadoresService: jugadoresService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_importar_planilla_banner')), findsNothing);
      expect(find.byKey(const Key('btn_importar_planilla_fab')), findsNothing);
    });

    testWidgets('Muestra botón "+ Importar Planilla" para usuario ADMIN autenticado', (tester) async {
      final session = SessionManager();
      session.setSession(
        AuthUser(
          token: 'jwt_admin_token',
          usuario: 'admin_test',
          rol: 'ADMIN',
          campeonatoId: 1,
        ),
      );

      final mockClient = MockImportHttpClient();
      final apiClient = ApiClient(client: mockClient);
      final equiposService = EquiposService(apiClient: apiClient);
      final jugadoresService = JugadoresService(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: EquiposPage(
            token: 'jwt_admin_token',
            equiposService: equiposService,
            jugadoresService: jugadoresService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_importar_planilla_banner')), findsOneWidget);
      expect(find.byKey(const Key('btn_importar_planilla_fab')), findsOneWidget);
    });

    testWidgets('Tocar "+ Importar Planilla" abre modal de importación', (tester) async {
      final session = SessionManager();
      session.setSession(
        AuthUser(
          token: 'jwt_admin_token',
          usuario: 'admin_test',
          rol: 'ADMIN',
          campeonatoId: 1,
        ),
      );

      final mockClient = MockImportHttpClient();
      final apiClient = ApiClient(client: mockClient);
      final equiposService = EquiposService(apiClient: apiClient);
      final jugadoresService = JugadoresService(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: EquiposPage(
            token: 'jwt_admin_token',
            equiposService: equiposService,
            jugadoresService: jugadoresService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_importar_planilla_banner')));
      await tester.pumpAndSettle();

      expect(find.text('Importar Planilla Masiva'), findsOneWidget);
      expect(find.text('Archivo (.xlsx / .csv)'), findsOneWidget);
      expect(find.text('Google Drive / Sheets'), findsOneWidget);
      expect(find.byKey(const Key('btn_descargar_plantilla_modelo')), findsOneWidget);
      expect(find.byKey(const Key('btn_ejecutar_importacion')), findsOneWidget);
    });
  });

  group('4. ImportarPlanillaModal - Widget Tests & Validaciones', () {
    testWidgets('Alterna entre opción Archivo y opción Google Drive', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaModal(
              torneoId: 2,
              torneoNombre: 'Torneo Clausura',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Opción 0 (Archivo local) por defecto
      expect(find.text('Haz clic para seleccionar tu archivo Excel o CSV'), findsOneWidget);
      expect(find.byKey(const Key('input_enlace_google_drive')), findsNothing);

      // Cambiar a opción 1 (Google Drive)
      await tester.tap(find.text('Google Drive / Sheets'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_enlace_google_drive')), findsOneWidget);
    });

    testWidgets('Muestra error si se intenta importar sin seleccionar archivo ni ingresar URL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaModal(
              torneoId: 2,
              torneoNombre: 'Torneo Clausura',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_ejecutar_importacion')));
      await tester.pumpAndSettle();

      expect(find.text('Por favor selecciona un archivo Excel (.xlsx) o CSV antes de continuar.'), findsOneWidget);

      // Cambiar a opción Google Drive y validar campo vacío
      await tester.tap(find.text('Google Drive / Sheets'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_ejecutar_importacion')));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa el enlace compartido de Google Drive o Sheets.'), findsOneWidget);
    });

    testWidgets('Importa con enlace Google Drive y muestra vista de resumen exitoso', (tester) async {
      final mockClient = MockImportHttpClient();
      final apiClient = ApiClient(client: mockClient);
      final equiposService = EquiposService(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaModal(
              torneoId: 2,
              torneoNombre: 'Torneo Secundario 2026',
              equiposService: equiposService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Seleccionar opción Google Drive
      await tester.tap(find.text('Google Drive / Sheets'));
      await tester.pumpAndSettle();

      // Ingresar enlace válido de Google Drive
      await tester.enterText(
        find.byKey(const Key('input_enlace_google_drive')),
        'https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit',
      );
      await tester.pumpAndSettle();

      // Ejecutar importación
      await tester.tap(find.byKey(const Key('btn_ejecutar_importacion')));
      await tester.pumpAndSettle();

      // Verificar pantalla de éxito
      expect(find.text('¡Importación Completada!'), findsOneWidget);
      expect(find.text('Equipos Nuevos'), findsOneWidget);
      expect(find.text('Jugadores Inscritos'), findsOneWidget);
      expect(find.text('Observaciones / Filas Omitidas (2)'), findsOneWidget);
      expect(find.byKey(const Key('btn_cerrar_resumen_importacion')), findsOneWidget);
    });
  });
}

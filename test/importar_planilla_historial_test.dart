import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/models/importacion_historial_item.dart';
import 'package:torneo_intertecnologias_app/services/equipos_service.dart';
import 'package:torneo_intertecnologias_app/widgets/importacion_detalle_modal.dart';
import 'package:torneo_intertecnologias_app/widgets/importar_planilla_historial_view.dart';
import 'package:torneo_intertecnologias_app/widgets/importar_planilla_modal.dart';

class MockHistorialHttpClient extends http.BaseClient {
  Uri? lastUri;
  String? lastMethod;
  Map<String, String>? lastHeaders;
  int statusCode;
  List<Map<String, dynamic>> itemsToReturn;

  MockHistorialHttpClient({
    this.statusCode = 200,
    this.itemsToReturn = const [],
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastMethod = request.method;
    lastHeaders = request.headers;

    if (request.url.path.contains('/api/equipos/importaciones')) {
      final jsonResponse = jsonEncode(itemsToReturn);
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonResponse)),
        statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode('[]')),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

void main() {
  final sampleExito = {
    'id': 1,
    'torneoId': 2,
    'campeonatoId': 2,
    'fechaImportacion': '2026-10-02T15:30:00.000Z',
    'nombreArchivo': 'Plantilla_Banquita_Final.xlsx',
    'usuarioId': 5,
    'usuarioNombre': 'Admin Principal',
    'filasProcesadas': 14,
    'jugadoresRegistrados': 14,
    'jugadoresOmitidos': 0,
    'equiposCreados': 1,
    'equiposExistentes': 1,
    'duplicadosDocumento': 0,
    'conflictosDorsal': 0,
    'alertasCantidad': 0,
    'erroresCantidad': 0,
    'exito': true,
    'mensaje': 'Importación completada con éxito.',
    'resumenJson': jsonEncode({
      'alertas': [],
      'equiposDetalle': [
        {'id': 31, 'nombre': 'Amigos del fútbol', 'fueCreado': false, 'jugadoresAgregados': 7},
        {'id': 32, 'nombre': 'Real Puerta Roja', 'fueCreado': true, 'jugadoresAgregados': 7},
      ],
    }),
  };

  final sampleConAlertas = {
    'id': 2,
    'torneoId': 2,
    'campeonatoId': 2,
    'fechaImportacion': '2026-10-02T16:00:00.000Z',
    'nombreArchivo': 'Google Sheets Formulario',
    'usuarioId': 5,
    'usuarioNombre': 'Admin Principal',
    'filasProcesadas': 8,
    'jugadoresRegistrados': 6,
    'jugadoresOmitidos': 2,
    'equiposCreados': 0,
    'equiposExistentes': 1,
    'duplicadosDocumento': 1,
    'conflictosDorsal': 1,
    'alertasCantidad': 2,
    'erroresCantidad': 0,
    'exito': true,
    'mensaje': 'Se importaron jugadores con 2 advertencias.',
    'resumenJson': jsonEncode({
      'alertas': [
        'Fila 3: Jugador ya existe por documento 1102862856.',
        'Fila 7: Dorsal 14 ya ocupado en Real Puerta Roja.',
      ],
      'equiposDetalle': [
        {'id': 32, 'nombre': 'Real Puerta Roja', 'fueCreado': false, 'jugadoresAgregados': 6},
      ],
    }),
  };

  final sampleError = {
    'id': 3,
    'torneoId': 2,
    'campeonatoId': 2,
    'fechaImportacion': '2026-10-02T14:00:00.000Z',
    'nombreArchivo': 'Archivo_Invalido.csv',
    'usuarioId': null,
    'usuarioNombre': null,
    'filasProcesadas': 0,
    'jugadoresRegistrados': 0,
    'jugadoresOmitidos': 0,
    'equiposCreados': 0,
    'equiposExistentes': 0,
    'duplicadosDocumento': 0,
    'conflictosDorsal': 0,
    'alertasCantidad': 0,
    'erroresCantidad': 1,
    'exito': false,
    'mensaje': 'El formato de columnas no corresponde a la plantilla oficial.',
    'resumenJson': null,
  };

  group('1. ImportacionHistorialItem Model Tests', () {
    test('Parsea correctamente JSON completo con resumenJson', () {
      final item = ImportacionHistorialItem.fromJson(sampleConAlertas);

      expect(item.id, 2);
      expect(item.torneoId, 2);
      expect(item.nombreArchivo, 'Google Sheets Formulario');
      expect(item.usuarioNombre, 'Admin Principal');
      expect(item.filasProcesadas, 8);
      expect(item.jugadoresRegistrados, 6);
      expect(item.duplicadosDocumento, 1);
      expect(item.conflictosDorsal, 1);
      expect(item.alertasCantidad, 2);
      expect(item.exito, true);
      expect(item.estadoVisual, 'Éxito con alertas');
      expect(item.alertas.length, 2);
      expect(item.equiposDetalle.length, 1);
      expect(item.equiposDetalle.first.nombre, 'Real Puerta Roja');
    });

    test('Determina estados visuales adecuadamente (Éxito, Con Alertas, Error)', () {
      final exitoItem = ImportacionHistorialItem.fromJson(sampleExito);
      expect(exitoItem.estadoVisual, 'Éxito');

      final alertaItem = ImportacionHistorialItem.fromJson(sampleConAlertas);
      expect(alertaItem.estadoVisual, 'Éxito con alertas');

      final errorItem = ImportacionHistorialItem.fromJson(sampleError);
      expect(errorItem.estadoVisual, 'Error');
    });

    test('Maneja campos nulos o faltantes de forma segura', () {
      final item = ImportacionHistorialItem.fromJson({
        'id': 99,
        'fechaImportacion': '2026-10-02T12:00:00.000Z',
      });

      expect(item.id, 99);
      expect(item.nombreArchivo, 'Planilla');
      expect(item.usuarioNombre, isNull);
      expect(item.filasProcesadas, 0);
      expect(item.jugadoresRegistrados, 0);
      expect(item.alertas, isEmpty);
      expect(item.equiposDetalle, isEmpty);
    });
  });

  group('2. EquiposService Historial API Tests', () {
    test('obtenerHistorialImportaciones envía parámetros multi-tenant y token', () async {
      final mock = MockHistorialHttpClient(itemsToReturn: [sampleExito]);
      final client = ApiClient(client: mock);
      final service = EquiposService(apiClient: client);

      final resultado = await service.obtenerHistorialImportaciones(
        campeonatoId: 2,
        token: 'fake-jwt-token',
        pagina: 1,
        limite: 20,
      );

      expect(mock.lastMethod, 'GET');
      expect(mock.lastUri?.path, contains('/api/equipos/importaciones'));
      expect(mock.lastUri?.queryParameters['campeonatoId'], '2');
      expect(mock.lastUri?.queryParameters['pagina'], '1');
      expect(mock.lastUri?.queryParameters['limite'], '20');
      expect(mock.lastHeaders?['authorization'], 'Bearer fake-jwt-token');
      expect(resultado.length, 1);
      expect(resultado.first.nombreArchivo, 'Plantilla_Banquita_Final.xlsx');
    });
  });

  group('3. ImportarPlanillaHistorialView Widget Tests', () {
    testWidgets('Test 11: Renderiza estado vacío cuando no hay importaciones', (tester) async {
      final mock = MockHistorialHttpClient(itemsToReturn: []);
      final client = ApiClient(client: mock);
      final service = EquiposService(apiClient: client);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaHistorialView(
              torneoId: 2,
              torneoNombre: 'Torneo Banquita Los Altos',
              token: 'test-token',
              equiposService: service,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No hay importaciones registradas para este torneo.'), findsOneWidget);
    });

    testWidgets('Test 12: Renderiza múltiples importaciones con sus datos', (tester) async {
      final mock = MockHistorialHttpClient(itemsToReturn: [sampleExito, sampleConAlertas]);
      final client = ApiClient(client: mock);
      final service = EquiposService(apiClient: client);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaHistorialView(
              torneoId: 2,
              torneoNombre: 'Torneo Banquita Los Altos',
              token: 'test-token',
              equiposService: service,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Plantilla_Banquita_Final.xlsx'), findsOneWidget);
      expect(find.text('Google Sheets Formulario'), findsOneWidget);
      expect(find.text('2 importaciones registradas'), findsOneWidget);
    });

    testWidgets('Test 13: Muestra badge Éxito para importación sin alertas', (tester) async {
      final mock = MockHistorialHttpClient(itemsToReturn: [sampleExito]);
      final client = ApiClient(client: mock);
      final service = EquiposService(apiClient: client);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaHistorialView(
              torneoId: 2,
              torneoNombre: 'Torneo Banquita Los Altos',
              token: 'test-token',
              equiposService: service,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Éxito'), findsOneWidget);
      expect(find.text('Plantilla_Banquita_Final.xlsx'), findsOneWidget);
    });

    testWidgets('Test 14: Muestra badge Éxito con alertas', (tester) async {
      final mock = MockHistorialHttpClient(itemsToReturn: [sampleConAlertas]);
      final client = ApiClient(client: mock);
      final service = EquiposService(apiClient: client);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaHistorialView(
              torneoId: 2,
              torneoNombre: 'Torneo Banquita Los Altos',
              token: 'test-token',
              equiposService: service,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Éxito con alertas'), findsOneWidget);
      expect(find.text('Google Sheets Formulario'), findsOneWidget);
    });

    testWidgets('Test 15: Abre modal de detalle al presionar un elemento del historial', (tester) async {
      final mock = MockHistorialHttpClient(itemsToReturn: [sampleConAlertas]);
      final client = ApiClient(client: mock);
      final service = EquiposService(apiClient: client);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaHistorialView(
              torneoId: 2,
              torneoNombre: 'Torneo Banquita Los Altos',
              token: 'test-token',
              equiposService: service,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pulsar la tarjeta de importación
      await tester.tap(find.text('Google Sheets Formulario'));
      await tester.pumpAndSettle();

      // Verificar que el diálogo de detalle se abrió con sus secciones
      expect(find.text('Detalle de Importación'), findsOneWidget);
      expect(find.text('Fila 3: Jugador ya existe por documento 1102862856.'), findsOneWidget);
      expect(find.text('Fila 7: Dorsal 14 ya ocupado en Real Puerta Roja.'), findsOneWidget);
      expect(find.text('Equipos Procesados'), findsOneWidget);
      expect(find.text('Real Puerta Roja'), findsOneWidget);
    });

    testWidgets('Test 16: Responsive móvil y escritorio renderizan correctamente', (tester) async {
      final mock = MockHistorialHttpClient(itemsToReturn: [sampleExito]);
      final client = ApiClient(client: mock);
      final service = EquiposService(apiClient: client);

      // Simulación móvil (ancho 400px)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaHistorialView(
              torneoId: 2,
              torneoNombre: 'Torneo Banquita Los Altos',
              token: 'test-token',
              equiposService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Plantilla_Banquita_Final.xlsx'), findsOneWidget);

      // Simulación escritorio (ancho 1200px)
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaHistorialView(
              torneoId: 2,
              torneoNombre: 'Torneo Banquita Los Altos',
              token: 'test-token',
              equiposService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Plantilla_Banquita_Final.xlsx'), findsOneWidget);
    });

    testWidgets('Test 17: Botón de recarga actualiza la lista del historial', (tester) async {
      final mock = MockHistorialHttpClient(itemsToReturn: [sampleExito]);
      final client = ApiClient(client: mock);
      final service = EquiposService(apiClient: client);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaHistorialView(
              torneoId: 2,
              torneoNombre: 'Torneo Banquita Los Altos',
              token: 'test-token',
              equiposService: service,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('1 importación registrada'), findsOneWidget);

      // Actualizar datos del mock
      mock.itemsToReturn = [sampleExito, sampleConAlertas];

      // Pulsar botón de refrescar
      await tester.tap(find.byKey(const Key('btn_refrescar_historial')));
      await tester.pumpAndSettle();

      expect(find.text('2 importaciones registradas'), findsOneWidget);
    });
  });

  group('4. ImportarPlanillaModal Tab Navigation Tests', () {
    testWidgets('Test 18: Cambiar entre pestaña Importar e Historial dentro del modal', (tester) async {
      final mock = MockHistorialHttpClient(itemsToReturn: [sampleExito]);
      final client = ApiClient(client: mock);
      final service = EquiposService(apiClient: client);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaModal(
              torneoId: 2,
              torneoNombre: 'Torneo Banquita Los Altos',
              token: 'test-token',
              equiposService: service,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Inicialmente en pestaña Importar Planilla
      expect(find.text('Comenzar Importación'), findsOneWidget);

      // Cambiar a la pestaña de Historial
      await tester.tap(find.byKey(const Key('tab_historial_importaciones')));
      await tester.pumpAndSettle();

      // Debe mostrar la lista de historial
      expect(find.text('Plantilla_Banquita_Final.xlsx'), findsOneWidget);
      expect(find.text('Comenzar Importación'), findsNothing);

      // Regresar a la pestaña de Importar
      await tester.tap(find.byKey(const Key('tab_importar_planilla')));
      await tester.pumpAndSettle();

      expect(find.text('Comenzar Importación'), findsOneWidget);
    });

    testWidgets('Test 19: Modal abre directamente en Historial si initialTabIndex = 1', (tester) async {
      final mock = MockHistorialHttpClient(itemsToReturn: [sampleExito]);
      final client = ApiClient(client: mock);
      final service = EquiposService(apiClient: client);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarPlanillaModal(
              torneoId: 2,
              torneoNombre: 'Torneo Banquita Los Altos',
              token: 'test-token',
              equiposService: service,
              initialTabIndex: 1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Directamente en historial
      expect(find.text('Plantilla_Banquita_Final.xlsx'), findsOneWidget);
      expect(find.text('Comenzar Importación'), findsNothing);
    });
  });

  group('5. ImportacionDetalleModal Unit & Dialog Tests', () {
    testWidgets('Muestra todas las secciones de métricas y desglose de equipos', (tester) async {
      final item = ImportacionHistorialItem.fromJson(sampleConAlertas);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ImportacionDetalleModal.show(
                  ctx,
                  item: item,
                  torneoNombre: 'Torneo Banquita Los Altos',
                ),
                child: const Text('Abrir Detalle'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Detalle'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle de Importación'), findsOneWidget);
      expect(find.text('Google Sheets Formulario'), findsOneWidget);
      expect(find.text('Filas Leídas'), findsOneWidget);
      expect(find.text('Inscritos'), findsOneWidget);
      expect(find.text('Cédulas Duplicadas'), findsOneWidget);
      expect(find.text('Conflictos Dorsal'), findsOneWidget);
      expect(find.text('Alertas Registradas (2)'), findsOneWidget);
      expect(find.text('Equipos Procesados'), findsOneWidget);
      expect(find.text('Real Puerta Roja'), findsOneWidget);
    });
  });
}

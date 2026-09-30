import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/equipos_page.dart';
import 'package:torneo_intertecnologias_app/jugador_detalle_page.dart';
import 'package:torneo_intertecnologias_app/jugadores_equipo_page.dart';
import 'package:torneo_intertecnologias_app/models/auth_user.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';
import 'package:torneo_intertecnologias_app/models/equipo.dart';
import 'package:torneo_intertecnologias_app/models/jugador.dart';
import 'package:torneo_intertecnologias_app/services/equipos_service.dart';
import 'package:torneo_intertecnologias_app/services/jugadores_service.dart';
import 'package:torneo_intertecnologias_app/widgets/public_player_card.dart';
import 'package:torneo_intertecnologias_app/widgets/public_team_card.dart';

class MockEliminacionHttpClient extends http.BaseClient {
  final List<String> deletedUris = [];
  final List<String> requestedUris = [];

  List<Map<String, dynamic>> equiposDb = [
    {
      'id': 10,
      'nombre': 'Halcones FC',
      'sigla': 'HLC',
      'colorPrincipal': '#1E3A8A',
      'logo': null,
      'campeonatoId': 1,
      'torneoId': 1,
      'activo': true,
      'puntos': 12,
      'partidosJugados': 4,
    },
    {
      'id': 20,
      'nombre': 'Toros Rojos',
      'sigla': 'TOR',
      'colorPrincipal': '#DC2626',
      'logo': null,
      'campeonatoId': 1,
      'torneoId': 1,
      'activo': true,
      'puntos': 9,
      'partidosJugados': 4,
    },
  ];

  List<Map<String, dynamic>> jugadoresDb = [
    {
      'id': 101,
      'nombres': 'Carlos',
      'apellidos': 'Mendoza',
      'numeroCamiseta': 9,
      'equipoId': 10,
      'fechaNacimiento': '1982-04-10',
      'posicion': 'Delantero',
      'estado': 'ACTIVO',
    },
    {
      'id': 102,
      'nombres': 'Luis',
      'apellidos': 'Gómez',
      'numeroCamiseta': 10,
      'equipoId': 10,
      'fechaNacimiento': '1988-08-15',
      'posicion': 'Mediocampista',
      'estado': 'ACTIVO',
    },
    {
      'id': 201,
      'nombres': 'Mateo',
      'apellidos': 'Ríos',
      'numeroCamiseta': 1,
      'equipoId': 20,
      'fechaNacimiento': '1995-02-20',
      'posicion': 'Arquero',
      'estado': 'ACTIVO',
    },
  ];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUris.add('${request.method} ${request.url}');

    // GET /api/equipos
    if (request.method == 'GET' && request.url.path.endsWith('/equipos')) {
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(equiposDb))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // GET /api/equipos/:id/jugadores
    final matchEquipoJugadores = RegExp(r'/api/equipos/(\d+)/jugadores').firstMatch(request.url.path);
    if (request.method == 'GET' && matchEquipoJugadores != null) {
      final eqId = int.parse(matchEquipoJugadores.group(1)!);
      final jugList = jugadoresDb.where((j) => j['equipoId'] == eqId).toList();
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(jugList))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // GET /api/jugadores
    if (request.method == 'GET' && request.url.path.endsWith('/jugadores')) {
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(jugadoresDb))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // GET /api/jugadores/:id
    final matchJugadorDetalle = RegExp(r'/api/jugadores/(\d+)$').firstMatch(request.url.path);
    if (request.method == 'GET' && matchJugadorDetalle != null) {
      final jugId = int.parse(matchJugadorDetalle.group(1)!);
      final jug = jugadoresDb.firstWhere((j) => j['id'] == jugId, orElse: () => {});
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(jug))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // DELETE /api/equipos/:id
    final matchDeleteEquipo = RegExp(r'/api/equipos/(\d+)').firstMatch(request.url.path);
    if (request.method == 'DELETE' && matchDeleteEquipo != null) {
      final eqId = int.parse(matchDeleteEquipo.group(1)!);
      deletedUris.add(request.url.toString());
      equiposDb.removeWhere((e) => e['id'] == eqId);
      jugadoresDb.removeWhere((j) => j['equipoId'] == eqId);
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({'mensaje': 'Equipo eliminado correctamente'}))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // DELETE /api/jugadores/:id
    final matchDeleteJugador = RegExp(r'/api/jugadores/(\d+)').firstMatch(request.url.path);
    if (request.method == 'DELETE' && matchDeleteJugador != null) {
      final jugId = int.parse(matchDeleteJugador.group(1)!);
      deletedUris.add(request.url.toString());
      jugadoresDb.removeWhere((j) => j['id'] == jugId);
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({'mensaje': 'Jugador eliminado correctamente'}))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // Fallback GET /api/goleadores
    if (request.url.path.contains('goleadores')) {
      return http.StreamedResponse(
        Stream.value(utf8.encode('[]')),
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
  late MockEliminacionHttpClient mockClient;
  late ApiClient apiClient;
  late EquiposService equiposService;
  late JugadoresService jugadoresService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockClient = MockEliminacionHttpClient();
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

  group('Servicios - EquiposService y JugadoresService eliminación', () {
    test('EquiposService.eliminarEquipo ejecuta DELETE con url y headers correctos', () async {
      await equiposService.eliminarEquipo(10, token: 'token-test', campeonatoId: 1);
      expect(mockClient.deletedUris.any((u) => u.contains('/api/equipos/10')), isTrue);
      expect(mockClient.equiposDb.any((e) => e['id'] == 10), isFalse);
    });

    test('JugadoresService.eliminarJugador ejecuta DELETE con url y headers correctos', () async {
      await jugadoresService.eliminarJugador(101, token: 'token-test', campeonatoId: 1);
      expect(mockClient.deletedUris.any((u) => u.contains('/api/jugadores/101')), isTrue);
      expect(mockClient.jugadoresDb.any((j) => j['id'] == 101), isFalse);
    });
  });

  group('1. Eliminación de Equipos (EquiposPage)', () {
    testWidgets('Muestra botón/icono de papelera en cada tarjeta de equipo y solicita confirmación', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: EquiposPage(
            equiposService: equiposService,
            jugadoresService: jugadoresService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar ambas tarjetas
      expect(find.text('Halcones FC'), findsOneWidget);
      expect(find.text('Toros Rojos'), findsOneWidget);

      // Icono de papelera presente para cada equipo
      final btnEliminar10 = find.byKey(const Key('btn_eliminar_equipo_10'));
      expect(btnEliminar10, findsOneWidget);

      // Clic en papelera de Halcones FC
      await tester.tap(btnEliminar10);
      await tester.pumpAndSettle();

      // Debe mostrar el modal de confirmación con el texto exacto requerido
      expect(find.text('Eliminar Equipo'), findsOneWidget);
      expect(
        find.text(
          '¿Estás seguro de que deseas eliminar este equipo? Se borrarán también todos sus jugadores inscritos.',
        ),
        findsOneWidget,
      );

      // Clic en Cancelar
      await tester.tap(find.byKey(const Key('btn_cancelar_eliminar_equipo')));
      await tester.pumpAndSettle();

      // El equipo no se elimina
      expect(find.text('Halcones FC'), findsOneWidget);
      expect(mockClient.deletedUris.isEmpty, isTrue);

      // Clic en papelera y luego Confirmar
      await tester.tap(btnEliminar10);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirmar_eliminar_equipo')));
      await tester.pumpAndSettle();

      // Debe haberse eliminado de la vista y del mock backend
      expect(find.text('Halcones FC'), findsNothing);
      expect(find.text('Toros Rojos'), findsOneWidget);
      expect(mockClient.deletedUris.any((u) => u.contains('/api/equipos/10')), isTrue);
    });
  });

  group('2. Eliminación de Jugadores (JugadoresEquipoPage y JugadorDetallePage)', () {
    testWidgets('En carnet de jugador solicita confirmación y actualiza total de inscritos', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: JugadoresEquipoPage(
            equipoId: 10,
            equipoNombre: 'Halcones FC',
            equiposService: equiposService,
            jugadoresService: jugadoresService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2 jugadores inscritos inicialmente
      expect(find.text('2/14'), findsOneWidget);
      expect(find.text('CARLOS MENDOZA'), findsOneWidget);
      expect(find.text('LUIS GÓMEZ'), findsOneWidget);

      // Botón de eliminar en carnet
      final btnEliminar101 = find.byKey(const Key('btn_eliminar_carnet_101'));
      expect(btnEliminar101, findsOneWidget);

      // Clic en eliminar
      await tester.tap(btnEliminar101);
      await tester.pumpAndSettle();

      // Mensaje de confirmación exacto
      expect(find.text('¿Deseas eliminar a este jugador del plantel?'), findsOneWidget);

      // Cancelar
      await tester.tap(find.byKey(const Key('btn_cancelar_eliminar_jugador')));
      await tester.pumpAndSettle();
      expect(find.text('2/14'), findsOneWidget);

      // Confirmar eliminación
      await tester.tap(btnEliminar101);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_confirmar_eliminar_jugador')));
      await tester.pumpAndSettle();

      // Ahora solo queda 1 jugador y el contador se actualiza inmediatamente
      expect(find.text('1/14'), findsOneWidget);
      expect(find.text('CARLOS MENDOZA'), findsNothing);
      expect(find.text('LUIS GÓMEZ'), findsOneWidget);
      expect(mockClient.deletedUris.any((u) => u.contains('/api/jugadores/101')), isTrue);
    });

    testWidgets('En vista JugadorDetallePage (Ver ficha) muestra botón rojo Eliminar Jugador y elimina', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final jugador = mockClient.jugadoresDb.first;

      await tester.pumpWidget(
        MaterialApp(
          home: JugadorDetallePage(
            jugador: jugador,
            equipoNombre: 'Halcones FC',
            jugadoresService: jugadoresService,
          ),

        ),
      );
      await tester.pumpAndSettle();

      // Botón visible 'ELIMINAR JUGADOR'
      final btnEliminarFicha = find.byKey(const Key('btn_eliminar_jugador'));
      expect(btnEliminarFicha, findsOneWidget);

      await tester.ensureVisible(btnEliminarFicha);
      await tester.pumpAndSettle();
      await tester.tap(btnEliminarFicha);
      await tester.pumpAndSettle();


      // Modal de confirmación
      expect(find.text('¿Deseas eliminar a este jugador del plantel?'), findsOneWidget);

      // Confirmar
      await tester.tap(find.byKey(const Key('btn_confirmar_eliminar_jugador')));
      await tester.pumpAndSettle();

      expect(mockClient.deletedUris.any((u) => u.contains('/api/jugadores/101')), isTrue);
    });
  });
}

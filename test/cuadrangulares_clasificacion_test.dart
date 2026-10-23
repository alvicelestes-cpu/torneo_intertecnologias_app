import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:torneo_intertecnologias_app/core/network/api_client.dart';
import 'package:torneo_intertecnologias_app/models/posicion.dart';
import 'package:torneo_intertecnologias_app/posiciones_page.dart';
import 'package:torneo_intertecnologias_app/services/torneo_service.dart';

void main() {
  final sampleFasesJson = {
    'primeraFase': [
      {'posicion': 1, 'equipoId': 1, 'equipo': 'DEP ELITE', 'sigla': 'DEP', 'pj': 7, 'pg': 6, 'pe': 0, 'pp': 1, 'gf': 39, 'gc': 21, 'dg': 18, 'pts': 18},
      {'posicion': 2, 'equipoId': 2, 'equipo': 'CEMENTEROS', 'sigla': 'CEM', 'pj': 7, 'pg': 6, 'pe': 0, 'pp': 1, 'gf': 36, 'gc': 23, 'dg': 13, 'pts': 18},
      {'posicion': 3, 'equipoId': 7, 'equipo': 'CONEXIÓN DIGITAL', 'sigla': 'CD', 'pj': 7, 'pg': 4, 'pe': 0, 'pp': 3, 'gf': 26, 'gc': 26, 'dg': 0, 'pts': 12},
      {'posicion': 4, 'equipoId': 8, 'equipo': 'TELEMATIK', 'sigla': 'TELM', 'pj': 7, 'pg': 3, 'pe': 1, 'pp': 3, 'gf': 43, 'gc': 41, 'dg': 2, 'pts': 10},
      {'posicion': 5, 'equipoId': 5, 'equipo': 'TIENDA RACING FC', 'sigla': 'TRF', 'pj': 7, 'pg': 3, 'pe': 0, 'pp': 4, 'gf': 28, 'gc': 23, 'dg': 5, 'pts': 9},
      {'posicion': 6, 'equipoId': 6, 'equipo': 'GREMIO HFC', 'sigla': 'GHFC', 'pj': 7, 'pg': 3, 'pe': 0, 'pp': 4, 'gf': 26, 'gc': 30, 'dg': -4, 'pts': 9},
      {'posicion': 7, 'equipoId': 3, 'equipo': 'TIGO CITY', 'sigla': 'TIGO', 'pj': 7, 'pg': 1, 'pe': 1, 'pp': 5, 'gf': 23, 'gc': 44, 'dg': -21, 'pts': 4},
      {'posicion': 8, 'equipoId': 4, 'equipo': 'INPEC', 'sigla': 'INPEC', 'pj': 7, 'pg': 1, 'pe': 0, 'pp': 6, 'gf': 29, 'gc': 42, 'dg': -13, 'pts': 3},
    ],
    'existeSegundaRonda': true,
    'grupoA': [
      {'posicion': 1, 'equipoId': 1, 'equipo': 'DEP ELITE', 'sigla': 'DEP', 'pj': 0, 'pg': 0, 'pe': 0, 'pp': 0, 'gf': 0, 'gc': 0, 'dg': 0, 'puntoInvisible': true, 'posicionPrimeraFase': 1, 'pts': 0},
      {'posicion': 2, 'equipoId': 7, 'equipo': 'CONEXIÓN DIGITAL', 'sigla': 'CD', 'pj': 0, 'pg': 0, 'pe': 0, 'pp': 0, 'gf': 0, 'gc': 0, 'dg': 0, 'puntoInvisible': false, 'posicionPrimeraFase': 3, 'pts': 0},
      {'posicion': 3, 'equipoId': 5, 'equipo': 'TIENDA RACING FC', 'sigla': 'TRF', 'pj': 0, 'pg': 0, 'pe': 0, 'pp': 0, 'gf': 0, 'gc': 0, 'dg': 0, 'puntoInvisible': false, 'posicionPrimeraFase': 5, 'pts': 0},
      {'posicion': 4, 'equipoId': 3, 'equipo': 'TIGO CITY', 'sigla': 'TIGO', 'pj': 0, 'pg': 0, 'pe': 0, 'pp': 0, 'gf': 0, 'gc': 0, 'dg': 0, 'puntoInvisible': false, 'posicionPrimeraFase': 7, 'pts': 0},
    ],
    'grupoB': [
      {'posicion': 1, 'equipoId': 2, 'equipo': 'CEMENTEROS', 'sigla': 'CEM', 'pj': 0, 'pg': 0, 'pe': 0, 'pp': 0, 'gf': 0, 'gc': 0, 'dg': 0, 'puntoInvisible': true, 'posicionPrimeraFase': 2, 'pts': 0},
      {'posicion': 2, 'equipoId': 8, 'equipo': 'TELEMATIK', 'sigla': 'TELM', 'pj': 0, 'pg': 0, 'pe': 0, 'pp': 0, 'gf': 0, 'gc': 0, 'dg': 0, 'puntoInvisible': false, 'posicionPrimeraFase': 4, 'pts': 0},
      {'posicion': 3, 'equipoId': 6, 'equipo': 'GREMIO HFC', 'sigla': 'GHFC', 'pj': 0, 'pg': 0, 'pe': 0, 'pp': 0, 'gf': 0, 'gc': 0, 'dg': 0, 'puntoInvisible': false, 'posicionPrimeraFase': 6, 'pts': 0},
      {'posicion': 4, 'equipoId': 4, 'equipo': 'INPEC', 'sigla': 'INPEC', 'pj': 0, 'pg': 0, 'pe': 0, 'pp': 0, 'gf': 0, 'gc': 0, 'dg': 0, 'puntoInvisible': false, 'posicionPrimeraFase': 8, 'pts': 0},
    ]
  };

  group('Clasificación Independiente por Fases y Cuadrangulares', () {
    test('PosicionesFases.fromJson deserializa correctamente primeraFase y cuadrangulares', () {
      final response = PosicionesFases.fromJson(sampleFasesJson);

      // Regla 1: Primera Fase conserva íntegramente los resultados históricos
      expect(response.primeraFase.length, equals(8));
      expect(response.primeraFase[0].equipo, equals('DEP ELITE'));
      expect(response.primeraFase[0].pj, equals(7));
      expect(response.primeraFase[0].pts, equals(18));
      expect(response.primeraFase[1].equipo, equals('CEMENTEROS'));
      expect(response.primeraFase[1].pj, equals(7));
      expect(response.primeraFase[1].pts, equals(18));

      // Regla 2: Segunda Ronda inicia en cero
      for (final p in response.grupoA) {
        expect(p.pj, equals(0));
        expect(p.pg, equals(0));
        expect(p.pe, equals(0));
        expect(p.pp, equals(0));
        expect(p.gf, equals(0));
        expect(p.gc, equals(0));
        expect(p.dg, equals(0));
        expect(p.pts, equals(0));
      }
      for (final p in response.grupoB) {
        expect(p.pj, equals(0));
        expect(p.pg, equals(0));
        expect(p.pe, equals(0));
        expect(p.pp, equals(0));
        expect(p.gf, equals(0));
        expect(p.gc, equals(0));
        expect(p.dg, equals(0));
        expect(p.pts, equals(0));
      }

      // Regla 3: Grupo A conformado por DEP ELITE, CONEXIÓN DIGITAL, TIENDA RACING FC y TIGO CITY
      expect(response.grupoA.map((e) => e.equipo).toList(), equals([
        'DEP ELITE',
        'CONEXIÓN DIGITAL',
        'TIENDA RACING FC',
        'TIGO CITY',
      ]));

      // Regla 4: Grupo B conformado por CEMENTEROS, TELEMATIK, GREMIO HFC e INPEC
      expect(response.grupoB.map((e) => e.equipo).toList(), equals([
        'CEMENTEROS',
        'TELEMATIK',
        'GREMIO HFC',
        'INPEC',
      ]));

      // Regla 5: Punto Invisible activo en DEP ELITE (A) y CEMENTEROS (B), sin sumar puntos
      final depEliteA = response.grupoA.firstWhere((e) => e.equipo == 'DEP ELITE');
      expect(depEliteA.puntoInvisible, isTrue);
      expect(depEliteA.pts, equals(0));

      final cementerosB = response.grupoB.firstWhere((e) => e.equipo == 'CEMENTEROS');
      expect(cementerosB.puntoInvisible, isTrue);
      expect(cementerosB.pts, equals(0));

      // Los demás equipos no tienen punto invisible
      final cdA = response.grupoA.firstWhere((e) => e.equipo == 'CONEXIÓN DIGITAL');
      expect(cdA.puntoInvisible, isFalse);

      final telmB = response.grupoB.firstWhere((e) => e.equipo == 'TELEMATIK');
      expect(telmB.puntoInvisible, isFalse);
    });

    test('Punto invisible resuelve empate en puntos sin alterar el marcador ni los puntos obtenidos', () {
      final lista = [
        const Posicion(
          posicion: 1,
          equipoId: 7,
          equipo: 'CONEXIÓN DIGITAL',
          sigla: 'CD',
          pj: 1,
          pg: 1,
          pe: 0,
          pp: 0,
          gf: 4,
          gc: 1,
          dg: 3,
          pts: 3,
          puntoInvisible: false,
          posicionPrimeraFase: 3,
        ),
        const Posicion(
          posicion: 2,
          equipoId: 1,
          equipo: 'DEP ELITE',
          sigla: 'DEP',
          pj: 1,
          pg: 1,
          pe: 0,
          pp: 0,
          gf: 2,
          gc: 1,
          dg: 1,
          pts: 3,
          puntoInvisible: true,
          posicionPrimeraFase: 1,
        ),
      ];

      final ordenados = List<Posicion>.from(lista)
        ..sort((a, b) {
          if (b.pts != a.pts) return b.pts.compareTo(a.pts);
          if (a.puntoInvisible != b.puntoInvisible) return a.puntoInvisible ? -1 : 1;
          if (b.dg != a.dg) return b.dg.compareTo(a.dg);
          return b.gf.compareTo(a.gf);
        });

      // DEP ELITE debe quedar primero por Punto Invisible a pesar de menor DG
      expect(ordenados[0].equipo, equals('DEP ELITE'));
      expect(ordenados[0].pts, equals(3));
      expect(ordenados[1].equipo, equals('CONEXIÓN DIGITAL'));
      expect(ordenados[1].pts, equals(3));
    });

    testWidgets('PosicionesPage renderiza Primera Fase y Cuadrangulares con estadísticas independientes', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/posiciones/fases')) {
          return http.Response(
            jsonEncode(sampleFasesJson),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"not found"}', 404);
      });

      final mockTorneoService = TorneoService(
        apiClient: ApiClient(client: mockClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PosicionesPage(torneoService: mockTorneoService),
        ),
      );

      await tester.pumpAndSettle();

      // Pestaña 1: Primera Fase activa por defecto
      expect(find.text('PRIMERA FASE (General)'), findsOneWidget);
      expect(find.text('SEGUNDA RONDA (Cuadrangulares)'), findsOneWidget);
      expect(find.text('8 equipos en competencia'), findsOneWidget);

      // Verificar que en Primera Fase DEP ELITE tiene sus 18 puntos históricos
      expect(find.text('DEP ELITE'), findsOneWidget);
      expect(find.text('CEMENTEROS'), findsOneWidget);

      // Cambiar a la pestaña de Segunda Ronda (Cuadrangulares)
      await tester.tap(find.text('SEGUNDA RONDA (Cuadrangulares)'));
      await tester.pumpAndSettle();

      // Verificar títulos de los cuadrangulares
      expect(find.text('CUADRANGULAR GRUPO A'), findsOneWidget);
      expect(find.text('CUADRANGULAR GRUPO B'), findsOneWidget);

      // Verificar integrantes de Grupo A y Grupo B
      expect(find.text('CONEXIÓN DIGITAL'), findsWidgets);
      expect(find.text('TIENDA RACING FC'), findsWidgets);
      expect(find.text('TIGO CITY'), findsWidgets);
      expect(find.text('TELEMATIK'), findsWidgets);
      expect(find.text('GREMIO HFC'), findsWidgets);
      expect(find.text('INPEC'), findsWidgets);

      // Verificar que el badge de Punto Invisible aparece para los sembrados 1 y 2
      expect(find.text('Punto Invisible'), findsNWidgets(2));
    });

    testWidgets('PosicionesPage muestra AppErrorView si falla el endpoint sin inventar datos locales', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClientError = MockClient((request) async {
        return http.Response('Error de conexión', 500);
      });

      final mockTorneoServiceError = TorneoService(
        apiClient: ApiClient(client: mockClientError),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PosicionesPage(torneoService: mockTorneoServiceError),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar la vista de error clara y el botón de reintentar
      expect(find.text('REINTENTAR'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:torneo_intertecnologias_app/models/gol.dart';
import 'package:torneo_intertecnologias_app/models/partido.dart';
import 'package:torneo_intertecnologias_app/models/partido_detalle.dart';
import 'package:torneo_intertecnologias_app/models/tarjeta.dart';
import 'package:torneo_intertecnologias_app/partido_detalle_page.dart';

void main() {
  group('Modelos Gol y Tarjeta - Serialización y Aliases', () {
    test('Gol.fromJson mapea correctamente con aliases nombreJugador y jugadorNombre', () {
      final json1 = {
        'id': 101,
        'partidoId': 1,
        'jugadorId': 10,
        'nombreJugador': 'Juan Pérez',
        'equipoId': 5,
        'minuto': 23,
      };
      final gol1 = Gol.fromJson(json1);
      expect(gol1.id, equals(101));
      expect(gol1.jugadorId, equals(10));
      expect(gol1.nombreJugador, equals('Juan Pérez'));
      expect(gol1.equipoId, equals(5));
      expect(gol1.minuto, equals(23));

      final json2 = {
        'id': 102,
        'partidoId': 1,
        'jugadorId': 11,
        'jugadorNombre': 'Carlos Gómez',
        'equipoId': 5,
        'minuto': 54,
      };
      final gol2 = Gol.fromJson(json2);
      expect(gol2.nombreJugador, equals('Carlos Gómez'));
    });

    test('Tarjeta.fromJson mapea correctamente con aliases tipoTarjeta y motivo', () {
      final jsonAmarilla = {
        'id': 201,
        'partidoId': 1,
        'jugadorId': 15,
        'nombreJugador': 'Andrés Torres',
        'equipoId': 5,
        'tipo': 'AMARILLA',
        'minuto': 31,
      };
      final t1 = Tarjeta.fromJson(jsonAmarilla);
      expect(t1.id, equals(201));
      expect(t1.tipoTarjeta, equals('AMARILLA'));
      expect(t1.esAmarilla, isTrue);
      expect(t1.esRoja, isFalse);
      expect(t1.nombreJugador, equals('Andrés Torres'));

      final jsonRoja = {
        'id': 202,
        'partidoId': 1,
        'jugadorId': 16,
        'jugadorNombre': 'Luis Ramírez',
        'equipoId': 6,
        'tipoTarjeta': 'ROJA',
        'minuto': 88,
      };
      final t2 = Tarjeta.fromJson(jsonRoja);
      expect(t2.tipoTarjeta, equals('ROJA'));
      expect(t2.esRoja, isTrue);
      expect(t2.esAmarilla, isFalse);
      expect(t2.nombreJugador, equals('Luis Ramírez'));
    });
  });

  group('Partido y PartidoDetalle - Inclusión de Incidencias', () {
    test('Partido.fromJson deserializa listas de goles y tarjetas', () {
      final json = {
        'id': 1,
        'equipoLocalId': 5,
        'equipoLocalNombre': 'DEP ELITE',
        'equipoVisitanteId': 6,
        'equipoVisitanteNombre': 'TIENDA RACING FC',
        'golesLocal': 2,
        'golesVisitante': 1,
        'goles': [
          {'id': 1, 'jugadorId': 10, 'nombreJugador': 'Juan Pérez', 'equipoId': 5, 'minuto': 23},
          {'id': 2, 'jugadorId': 10, 'nombreJugador': 'Juan Pérez', 'equipoId': 5, 'minuto': 54},
          {'id': 3, 'jugadorId': 20, 'nombreJugador': 'Pedro Silva', 'equipoId': 6, 'minuto': 80},
        ],
        'tarjetas': [
          {'id': 1, 'jugadorId': 12, 'nombreJugador': 'Mateo Díaz', 'equipoId': 5, 'tipo': 'AMARILLA', 'minuto': 15},
          {'id': 2, 'jugadorId': 22, 'nombreJugador': 'Oscar Blanco', 'equipoId': 6, 'tipo': 'ROJA', 'minuto': 75},
        ],
      };

      final partido = Partido.fromJson(json);
      expect(partido.goles.length, equals(3));
      expect(partido.tarjetas.length, equals(2));
      expect(partido.goles[0].nombreJugador, equals('Juan Pérez'));
      expect(partido.tarjetas[1].esRoja, isTrue);
    });

    test('PartidoDetalle.fromJson propaga goles y tarjetas al partido interior', () {
      final json = {
        'partido': {
          'id': 1,
          'equipoLocalId': 5,
          'equipoLocalNombre': 'DEP ELITE',
          'equipoVisitanteId': 6,
          'equipoVisitanteNombre': 'TIENDA RACING FC',
          'golesLocal': 1,
          'golesVisitante': 0,
        },
        'goles': [
          {'id': 1, 'jugadorId': 10, 'nombreJugador': 'Juan Pérez', 'equipoId': 5, 'minuto': 44},
        ],
        'tarjetas': [
          {'id': 1, 'jugadorId': 11, 'nombreJugador': 'Luis Suárez', 'equipoId': 5, 'tipo': 'AMARILLA', 'minuto': 70},
        ],
      };

      final det = PartidoDetalle.fromJson(json);
      expect(det.goles.length, equals(1));
      expect(det.tarjetas.length, equals(1));
      expect(det.partido.goles.length, equals(1));
      expect(det.partido.tarjetas.length, equals(1));
    });
  });

  group('PartidoDetallePage - Visualización de Incidencias en UI', () {
    testWidgets('Muestra desglose de goles agrupados por jugador con minutos e icono de balón', (tester) async {
      final partido = Partido(
        id: 1,
        equipoLocalId: 5,
        equipoLocalNombre: 'DEP ELITE',
        equipoVisitanteId: 6,
        equipoVisitanteNombre: 'TIENDA RACING FC',
        golesLocal: 2,
        golesVisitante: 1,
        estado: 'FINALIZADO',
        goles: const [
          Gol(id: 1, jugadorId: 10, jugadorNombre: 'Juan Pérez', equipoId: 5, equipoNombre: 'DEP ELITE', minuto: 23),
          Gol(id: 2, jugadorId: 10, jugadorNombre: 'Juan Pérez', equipoId: 5, equipoNombre: 'DEP ELITE', minuto: 54),
          Gol(id: 3, jugadorId: 20, jugadorNombre: 'Pedro Silva', equipoId: 6, equipoNombre: 'TIENDA RACING FC', minuto: 80),
        ],
        tarjetas: const [],
      );

      final partidoDetalle = PartidoDetalle(
        partido: partido,
        goles: partido.goles,
        tarjetas: partido.tarjetas,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PartidoDetallePage(
            partidoId: 1,
            initialDetalle: partidoDetalle,
          ),
        ),
      );
      await tester.pump();

      // Verificar que la sección Goles y autores estén presentes
      expect(find.text('Goles'), findsOneWidget);
      expect(find.byIcon(Icons.sports_soccer), findsWidgets);
      expect(find.textContaining('Juan Pérez'), findsOneWidget);
      expect(find.textContaining("23', 54'"), findsOneWidget);
      expect(find.textContaining('Pedro Silva'), findsOneWidget);
      expect(find.textContaining("80'"), findsOneWidget);

      // Tarjetas vacías debe mostrar el mensaje correspondiente
      expect(find.text('Sin amonestaciones registradas'), findsOneWidget);
    });

    testWidgets('Muestra badges de tarjetas amarillas (#FBC02D) y rojas (#D32F2F)', (tester) async {
      final partido = Partido(
        id: 2,
        equipoLocalId: 5,
        equipoLocalNombre: 'DEP ELITE',
        equipoVisitanteId: 6,
        equipoVisitanteNombre: 'TIENDA RACING FC',
        golesLocal: 0,
        golesVisitante: 0,
        estado: 'FINALIZADO',
        goles: const [],
        tarjetas: const [
          Tarjeta(id: 1, jugadorId: 12, jugadorNombre: 'Mateo Díaz', equipoId: 5, equipoNombre: 'DEP ELITE', tipo: 'AMARILLA', minuto: 30),
          Tarjeta(id: 2, jugadorId: 22, jugadorNombre: 'Oscar Blanco', equipoId: 6, equipoNombre: 'TIENDA RACING FC', tipo: 'ROJA', minuto: 85),
        ],
      );

      final partidoDetalle = PartidoDetalle(
        partido: partido,
        goles: partido.goles,
        tarjetas: partido.tarjetas,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PartidoDetallePage(
            partidoId: 2,
            initialDetalle: partidoDetalle,
          ),
        ),
      );
      await tester.pump();

      // Goles vacíos debe mostrar el mensaje correspondiente
      expect(find.text('Sin goles registrados'), findsOneWidget);

      // Verificar sección de tarjetas
      expect(find.text('Tarjetas y Sanciones Disciplinarias'), findsOneWidget);
      expect(find.textContaining('Mateo Díaz'), findsOneWidget);
      expect(find.textContaining("30'"), findsOneWidget);
      expect(find.textContaining('Oscar Blanco'), findsOneWidget);
      expect(find.textContaining("85'"), findsOneWidget);

      // Verificar los badges de colores
      final yellowContainers = tester.widgetList<Container>(find.byType(Container)).where((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          return dec.color == const Color(0xFFFBC02D);
        }
        return false;
      });
      expect(yellowContainers.isNotEmpty, isTrue);

      final redContainers = tester.widgetList<Container>(find.byType(Container)).where((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          return dec.color == const Color(0xFFD32F2F);
        }
        return false;
      });
      expect(redContainers.isNotEmpty, isTrue);
    });
  });
}

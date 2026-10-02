import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_intertecnologias_app/core/utils/fixture_utils.dart';
import 'package:torneo_intertecnologias_app/models/partido.dart';

void main() {
  group('Soporte dinámico para Torneo Banquita Los Altos (12 equipos, 11 jornadas)', () {
    test('66 partidos en 11 jornadas de Primera Fase se agrupan en 11 jornadas sin fases eliminatorias vacías', () {
      final partidos = <Partido>[];
      int partidoId = 1;

      // 12 equipos juegan 11 jornadas de 6 partidos cada una = 66 partidos
      for (int j = 1; j <= 11; j++) {
        for (int p = 1; p <= 6; p++) {
          partidos.add(Partido(
            id: partidoId++,
            equipoLocalNombre: 'Equipo L$p',
            equipoVisitanteNombre: 'Equipo V$p',
            jornada: j,
            fase: 'PRIMERA_FASE',
            estado: 'PROGRAMADO',
          ));
        }
      }

      expect(partidos.length, equals(66));

      // Construir secciones para Banquita Los Altos
      final secciones = FixtureUtils.buildTournamentSections(
        partidos: partidos,
        torneoSlug: 'torneo-demo',
      );

      // Debe haber exactamente 11 secciones, todas de Primera Fase (Jornadas 1 a 11)
      expect(secciones.length, equals(11));

      for (int i = 0; i < 11; i++) {
        final sec = secciones[i];
        expect(sec.numeroJornada, equals(i + 1));
        expect(sec.fase, equals(TournamentPhase.primeraFase));
        expect(sec.titulo, equals('Jornada ${i + 1}'));
        expect(sec.partidos.length, equals(6));
        expect(sec.esPendiente, isFalse);
      }

      // Verificar que jornadas 8, 9, 10 y 11 NO se clasifican como eliminatorias
      final j8 = secciones.firstWhere((s) => s.numeroJornada == 8);
      expect(j8.fase, equals(TournamentPhase.primeraFase));
      expect(j8.titulo, equals('Jornada 8'));

      final j11 = secciones.firstWhere((s) => s.numeroJornada == 11);
      expect(j11.fase, equals(TournamentPhase.primeraFase));
      expect(j11.titulo, equals('Jornada 11'));

      // Verificar que no se generaron secciones vacías de Cuartos, Semifinal o Final
      final tieneEliminatorias = secciones.any((s) =>
          s.fase == TournamentPhase.segundaRonda ||
          s.fase == TournamentPhase.terceraRonda ||
          s.fase == TournamentPhase.cuartaRonda ||
          s.fase == TournamentPhase.quintaRonda);
      expect(tieneEliminatorias, isFalse);
    });

    test('Clasificación estricta por fase del partido sin depender del número de jornada', () {
      final partidos = [
        // Jornada 8 en Primera Fase vs Jornada 8 en Segunda Ronda
        const Partido(
          id: 101,
          equipoLocalNombre: 'Equipo A',
          equipoVisitanteNombre: 'Equipo B',
          jornada: 8,
          fase: 'PRIMERA_FASE',
        ),
        const Partido(
          id: 102,
          equipoLocalNombre: 'Equipo C',
          equipoVisitanteNombre: 'Equipo D',
          jornada: 8,
          fase: 'SEGUNDA_RONDA',
        ),
        // Fases eliminatorias explícitas
        const Partido(
          id: 103,
          equipoLocalNombre: 'Equipo E',
          equipoVisitanteNombre: 'Equipo F',
          jornada: 9,
          fase: 'CUARTOS',
        ),
        const Partido(
          id: 104,
          equipoLocalNombre: 'Equipo G',
          equipoVisitanteNombre: 'Equipo H',
          jornada: 10,
          fase: 'SEMIFINAL',
        ),
        const Partido(
          id: 105,
          equipoLocalNombre: 'Equipo I',
          equipoVisitanteNombre: 'Equipo J',
          jornada: 11,
          fase: 'FINAL',
        ),
      ];

      final secciones = FixtureUtils.buildTournamentSections(
        partidos: partidos,
        torneoSlug: 'torneo-demo',
      );

      // Debe haber secciones para: Jornada 8 (Primera Fase), Cuadrangulares, Cuartos, Semifinales, Final
      final secPF = secciones.where((s) => s.fase == TournamentPhase.primeraFase).toList();
      expect(secPF.length, equals(1));
      expect(secPF.first.numeroJornada, equals(8));
      expect(secPF.first.partidos.first.id, equals(101));

      final secSR = secciones.firstWhere((s) => s.fase == TournamentPhase.segundaRonda);
      expect(secSR.partidos.first.id, equals(102));

      final secCuartos = secciones.firstWhere((s) => s.fase == TournamentPhase.terceraRonda);
      expect(secCuartos.partidos.first.id, equals(103));

      final secSemis = secciones.firstWhere((s) => s.fase == TournamentPhase.cuartaRonda);
      expect(secSemis.partidos.first.id, equals(104));

      final secFinal = secciones.firstWhere((s) => s.fase == TournamentPhase.quintaRonda);
      expect(secFinal.partidos.first.id, equals(105));
    });
  });

  group('Preservación íntegra de Torneo Intertecnologías (ID 1, 7 jornadas + 4 fases pendientes)', () {
    test('28 partidos en 7 jornadas de Primera Fase generan 7 jornadas + 4 secciones eliminatorias pendientes', () {
      final partidos = <Partido>[];
      int partidoId = 1;

      // 8 equipos juegan 7 jornadas de 4 partidos cada una = 28 partidos
      for (int j = 1; j <= 7; j++) {
        for (int p = 1; p <= 4; p++) {
          partidos.add(Partido(
            id: partidoId++,
            equipoLocalNombre: 'Ingeniería',
            equipoVisitanteNombre: 'Sistemas',
            jornada: j,
            fase: 'PRIMERA_FASE',
            estado: 'FINALIZADO',
          ));
        }
      }

      expect(partidos.length, equals(28));

      // Construir secciones para Intertecnologías
      final secciones = FixtureUtils.buildTournamentSections(
        partidos: partidos,
        torneoSlug: 'intertecnologias',
      );

      // Debe haber 7 jornadas + 4 fases eliminatorias pendientes = 11 secciones
      expect(secciones.length, equals(11));

      // Primeras 7 secciones corresponden a Jornadas 1 a 7
      for (int i = 0; i < 7; i++) {
        final sec = secciones[i];
        expect(sec.numeroJornada, equals(i + 1));
        expect(sec.fase, equals(TournamentPhase.primeraFase));
        expect(sec.partidos.length, equals(4));
        expect(sec.esPendiente, isFalse);
      }

      // Las siguientes 4 secciones corresponden a las fases reglamentarias pendientes
      final secCuadrangulares = secciones[7];
      expect(secCuadrangulares.fase, equals(TournamentPhase.segundaRonda));
      expect(secCuadrangulares.esPendiente, isTrue);

      final secCuartos = secciones[8];
      expect(secCuartos.fase, equals(TournamentPhase.terceraRonda));
      expect(secCuartos.esPendiente, isTrue);

      final secSemis = secciones[9];
      expect(secSemis.fase, equals(TournamentPhase.cuartaRonda));
      expect(secSemis.esPendiente, isTrue);

      final secFinal = secciones[10];
      expect(secFinal.fase, equals(TournamentPhase.quintaRonda));
      expect(secFinal.esPendiente, isTrue);
    });

    test('Fallback por defecto mantiene comportamiento histórico cuando no se especifica torneoSlug', () {
      final secciones = FixtureUtils.buildTournamentSections(
        partidos: const [],
      );

      // 7 jornadas vacías + 4 eliminatorias pendientes = 11 secciones
      expect(secciones.length, equals(11));
      for (int i = 1; i <= 7; i++) {
        expect(secciones.any((s) => s.numeroJornada == i && s.fase == TournamentPhase.primeraFase), isTrue);
      }
      expect(secciones.any((s) => s.fase == TournamentPhase.segundaRonda), isTrue);
      expect(secciones.any((s) => s.fase == TournamentPhase.terceraRonda), isTrue);
      expect(secciones.any((s) => s.fase == TournamentPhase.cuartaRonda), isTrue);
      expect(secciones.any((s) => s.fase == TournamentPhase.quintaRonda), isTrue);
    });
  });
}

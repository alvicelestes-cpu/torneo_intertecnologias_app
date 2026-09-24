import '../../models/jornada.dart';
import '../../models/partido.dart';

class FixtureSection {
  final String id;
  final String fase;
  final String titulo;
  final int numeroJornada;
  final String? fecha;
  final List<Partido> partidos;
  final bool esPendiente;
  final String? mensajePendiente;

  const FixtureSection({
    required this.id,
    required this.fase,
    required this.titulo,
    required this.numeroJornada,
    this.fecha,
    required this.partidos,
    this.esPendiente = false,
    this.mensajePendiente,
  });

  int get cantidadPartidos => partidos.length;
}

class FixtureUtils {
  FixtureUtils._();

  /// Construye todas las fases del torneo garantizando la visualización de:
  /// 1. PRIMERA FASE (Jornadas 1 a 7)
  /// 2. SEGUNDA RONDA / FASE ELIMINATORIA
  /// 3. SEMIFINAL
  /// 4. GRAN FINAL / TERCER PUESTO
  ///
  /// Si la Primera Fase aún no ha concluido y el fixture no ha determinado los
  /// clasificados, estas fases no se ocultan; se muestran con sus respectivos
  /// acordeones, badges y estado visual "Pendiente de definición".
  /// Cuando el backend resuelva las llaves, la información real se carga automáticamente.
  static List<FixtureSection> buildTournamentSections({
    required List<Partido> partidos,
    List<Jornada> jornadas = const [],
  }) {
    final sections = <FixtureSection>[];

    // 1. PRIMERA FASE: Jornadas 1 a 7
    final Map<int, List<Partido>> partidosPrimeraFase = {};
    for (final p in partidos) {
      final f = p.fase?.toUpperCase().trim() ?? '';
      final isFaseEliminatoria = f.contains('SEGUNDA') ||
          f.contains('ELIMINATORIA') ||
          f.contains('CUARTO') ||
          f.contains('SEMI') ||
          f.contains('FINAL') ||
          f.contains('TERCER') ||
          (p.jornada != null && p.jornada! > 7);

      if (!isFaseEliminatoria) {
        final j = (p.jornada != null && p.jornada! > 0) ? p.jornada! : 1;
        partidosPrimeraFase.putIfAbsent(j, () => []).add(p);
      }
    }

    final Set<int> numJornadas = {
      1, 2, 3, 4, 5, 6, 7,
      ...jornadas.where((j) => j.numero > 0 && j.numero <= 7).map((j) => j.numero),
      ...partidosPrimeraFase.keys.where((j) => j <= 7),
    };
    final sortedJornadas = numJornadas.toList()..sort();

    for (final numJ in sortedJornadas) {
      final matches = partidosPrimeraFase[numJ] ?? [];
      sections.add(FixtureSection(
        id: 'jornada_$numJ',
        fase: 'PRIMERA FASE',
        titulo: 'Jornada $numJ',
        numeroJornada: numJ,
        partidos: matches,
        esPendiente: false,
      ));
    }

    // 2. SEGUNDA RONDA / FASE ELIMINATORIA
    final matchesSegundaRonda = partidos.where((p) {
      final f = p.fase?.toUpperCase().trim() ?? '';
      return f.contains('SEGUNDA') ||
          f.contains('ELIMINATORIA') ||
          f.contains('CUARTO') ||
          (p.jornada == 8 || p.jornada == 99 && !f.contains('SEMI') && !f.contains('FINAL'));
    }).toList();

    if (matchesSegundaRonda.isNotEmpty) {
      sections.add(FixtureSection(
        id: 'segunda_ronda',
        fase: 'SEGUNDA RONDA',
        titulo: 'Segunda Ronda (Fase Eliminatoria)',
        numeroJornada: 8,
        partidos: matchesSegundaRonda,
        esPendiente: false,
      ));
    } else {
      sections.add(FixtureSection(
        id: 'segunda_ronda',
        fase: 'SEGUNDA RONDA',
        titulo: 'Segunda Ronda (Fase Eliminatoria)',
        numeroJornada: 8,
        esPendiente: true,
        mensajePendiente:
            'Pendiente de definición: Los cruces se confirmarán al concluir la Jornada 7 de la Primera Fase.',
        partidos: _generarPartidosProvisoriosSegundaRonda(),
      ));
    }

    // 3. SEMIFINAL
    final matchesSemifinal = partidos.where((p) {
      final f = p.fase?.toUpperCase().trim() ?? '';
      return f.contains('SEMI');
    }).toList();

    if (matchesSemifinal.isNotEmpty) {
      sections.add(FixtureSection(
        id: 'semifinal',
        fase: 'SEMIFINAL',
        titulo: 'Semifinales',
        numeroJornada: 9,
        partidos: matchesSemifinal,
        esPendiente: false,
      ));
    } else {
      sections.add(FixtureSection(
        id: 'semifinal',
        fase: 'SEMIFINAL',
        titulo: 'Semifinales',
        numeroJornada: 9,
        esPendiente: true,
        mensajePendiente:
            'Pendiente de definición: Clasificados de Segunda Ronda.',
        partidos: _generarPartidosProvisoriosSemifinal(),
      ));
    }

    // 4. GRAN FINAL / TERCER PUESTO
    final matchesFinal = partidos.where((p) {
      final f = p.fase?.toUpperCase().trim() ?? '';
      return (f.contains('FINAL') || f.contains('TERCER')) && !f.contains('SEMI');
    }).toList();

    if (matchesFinal.isNotEmpty) {
      sections.add(FixtureSection(
        id: 'gran_final',
        fase: 'GRAN FINAL',
        titulo: 'Gran Final y Tercer Puesto',
        numeroJornada: 10,
        partidos: matchesFinal,
        esPendiente: false,
      ));
    } else {
      sections.add(FixtureSection(
        id: 'gran_final',
        fase: 'GRAN FINAL',
        titulo: 'Gran Final y Tercer Puesto',
        numeroJornada: 10,
        esPendiente: true,
        mensajePendiente:
            'Pendiente de definición: Finalistas del torneo y disputa del 3° puesto.',
        partidos: _generarPartidosProvisoriosFinal(),
      ));
    }

    return sections;
  }

  static List<Partido> _generarPartidosProvisoriosSegundaRonda() {
    return const [
      Partido(
        id: 0,
        equipoLocalNombre: '1° Clasificado (Primera Fase)',
        equipoLocalSigla: '1°',
        equipoVisitanteNombre: '8° Clasificado (Primera Fase)',
        equipoVisitanteSigla: '8°',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Llave 1',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: '2° Clasificado (Primera Fase)',
        equipoLocalSigla: '2°',
        equipoVisitanteNombre: '7° Clasificado (Primera Fase)',
        equipoVisitanteSigla: '7°',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Llave 2',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: '3° Clasificado (Primera Fase)',
        equipoLocalSigla: '3°',
        equipoVisitanteNombre: '6° Clasificado (Primera Fase)',
        equipoVisitanteSigla: '6°',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Llave 3',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: '4° Clasificado (Primera Fase)',
        equipoLocalSigla: '4°',
        equipoVisitanteNombre: '5° Clasificado (Primera Fase)',
        equipoVisitanteSigla: '5°',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Llave 4',
      ),
    ];
  }

  static List<Partido> _generarPartidosProvisoriosSemifinal() {
    return const [
      Partido(
        id: 0,
        equipoLocalNombre: 'Ganador Llave 1',
        equipoLocalSigla: 'G1',
        equipoVisitanteNombre: 'Ganador Llave 4',
        equipoVisitanteSigla: 'G4',
        estado: 'POR DEFINIR',
        fase: 'SEMIFINAL',
        cancha: 'Cancha Principal',
        llave: 'Semifinal 1',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: 'Ganador Llave 2',
        equipoLocalSigla: 'G2',
        equipoVisitanteNombre: 'Ganador Llave 3',
        equipoVisitanteSigla: 'G3',
        estado: 'POR DEFINIR',
        fase: 'SEMIFINAL',
        cancha: 'Cancha Principal',
        llave: 'Semifinal 2',
      ),
    ];
  }

  static List<Partido> _generarPartidosProvisoriosFinal() {
    return const [
      Partido(
        id: 0,
        equipoLocalNombre: 'Ganador Semifinal 1',
        equipoLocalSigla: 'F1',
        equipoVisitanteNombre: 'Ganador Semifinal 2',
        equipoVisitanteSigla: 'F2',
        estado: 'POR DEFINIR',
        fase: 'GRAN_FINAL',
        cancha: 'Cancha Principal',
        llave: 'Gran Final',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: 'Perdedor Semifinal 1',
        equipoLocalSigla: 'P1',
        equipoVisitanteNombre: 'Perdedor Semifinal 2',
        equipoVisitanteSigla: 'P2',
        estado: 'POR DEFINIR',
        fase: 'TERCER_PUESTO',
        cancha: 'Cancha Principal',
        llave: 'Tercer Puesto',
      ),
    ];
  }
}

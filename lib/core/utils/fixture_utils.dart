import '../../models/jornada.dart';
import '../../models/partido.dart';
import '../../models/posicion.dart';

class TournamentPhase {
  static const String primeraFase = 'PRIMERA FASE';
  static const String segundaRonda = 'SEGUNDA RONDA';
  static const String terceraRonda = 'TERCERA RONDA';
  static const String cuartaRonda = 'CUARTA RONDA';
  static const String quintaRonda = 'QUINTA RONDA';

  static const List<String> allPhases = [
    primeraFase,
    segundaRonda,
    terceraRonda,
    cuartaRonda,
    quintaRonda,
  ];
}

class FixtureSection {
  final String id;
  final String fase;
  final String titulo;
  final String? subtitulo;
  final int numeroJornada;
  final String? fecha;
  final List<Partido> partidos;
  final bool esPendiente;
  final String? mensajePendiente;

  const FixtureSection({
    required this.id,
    required this.fase,
    required this.titulo,
    this.subtitulo,
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

  /// Construye la estructura reglamentaria completa del Torneo Intertecnologías (5 Fases):
  /// 1. PRIMERA FASE: Jornadas 1 a 7 (conservando íntegros los datos de fechas 1 a 5 y programando 6 y 7).
  /// 2. SEGUNDA RONDA (Cuadrangulares):
  ///    - Grupo A: 1°, 3°, 5° y 7° de la Primera Fase (1° con Punto Invisible / Ventaja Deportiva).
  ///    - Grupo B: 2°, 4°, 6° y 8° de la Primera Fase (2° con Punto Invisible / Ventaja Deportiva).
  /// 3. TERCERA RONDA (Cuartos de Final):
  ///    - Llave 1: 1° Grupo A vs 4° Grupo B
  ///    - Llave 2: 2° Grupo A vs 3° Grupo B
  ///    - Llave 3: 1° Grupo B vs 4° Grupo A
  ///    - Llave 4: 2° Grupo B vs 3° Grupo A
  /// 4. CUARTA RONDA (Semifinales):
  ///    - Partido 1: Ganador Llave 1 vs Ganador Llave 4
  ///    - Partido 2: Ganador Llave 3 vs Ganador Llave 2
  /// 5. QUINTA RONDA (Gran Final y 3° Puesto):
  ///    - Gran Final: Ganador Partido 1 vs Ganador Partido 2
  ///    - Tercer Puesto: Perdedor Partido 1 vs Perdedor Partido 2
  ///
  /// Mientras una fase previa no haya concluido o la fase posterior no se haya generado,
  /// se muestra en estado limpio y pendiente sin partidos tentativos ficticios.
  static List<FixtureSection> buildTournamentSections({
    required List<Partido> partidos,
    List<Jornada> jornadas = const [],
    List<Posicion> posiciones = const [],
  }) {
    final sections = <FixtureSection>[];

    // 1. PRIMERA FASE: Jornadas 1 a 7
    final Map<int, List<Partido>> partidosPrimeraFase = {};
    for (final p in partidos) {
      final f = p.fase?.toUpperCase().trim() ?? '';
      final isFaseEliminatoria = f.contains('SEGUNDA') ||
          f.contains('CUADRANGULAR') ||
          f.contains('TERCERA') ||
          f.contains('CUARTO') ||
          f.contains('CUARTA') ||
          f.contains('SEMI') ||
          f.contains('QUINTA') ||
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
        fase: TournamentPhase.primeraFase,
        titulo: 'Jornada $numJ',
        subtitulo: 'Primera Fase • Regular',
        numeroJornada: numJ,
        partidos: matches,
        esPendiente: false,
      ));
    }

    // 2. SEGUNDA RONDA (Cuadrangulares)
    final matchesSegundaRonda = partidos.where((p) {
      final f = p.fase?.toUpperCase().trim() ?? '';
      return f.contains('SEGUNDA') ||
          f.contains('CUADRANGULAR') ||
          (p.jornada == 8 || p.jornada == 99 && !f.contains('TERCERA') && !f.contains('CUARTO') && !f.contains('SEMI') && !f.contains('FINAL'));
    }).toList();

    if (matchesSegundaRonda.isNotEmpty) {
      // Si el backend ya guardó partidos reales de Cuadrangulares
      final matchesGrupoA = matchesSegundaRonda.where((p) {
        final ll = p.llave?.toUpperCase().trim() ?? '';
        return ll.contains('A') || !ll.contains('B');
      }).toList();
      final matchesGrupoB = matchesSegundaRonda.where((p) {
        final ll = p.llave?.toUpperCase().trim() ?? '';
        return ll.contains('B');
      }).toList();

      if (matchesGrupoB.isNotEmpty) {
        sections.add(FixtureSection(
          id: 'cuadrangular_grupo_a',
          fase: TournamentPhase.segundaRonda,
          titulo: 'Cuadrangular Semifinal - Grupo A',
          subtitulo: '1°, 3°, 5° y 7° de Primera Fase (1° con Ventaja Deportiva)',
          numeroJornada: 8,
          partidos: matchesGrupoA,
          esPendiente: false,
        ));
        sections.add(FixtureSection(
          id: 'cuadrangular_grupo_b',
          fase: TournamentPhase.segundaRonda,
          titulo: 'Cuadrangular Semifinal - Grupo B',
          subtitulo: '2°, 4°, 6° y 8° de Primera Fase (2° con Ventaja Deportiva)',
          numeroJornada: 8,
          partidos: matchesGrupoB,
          esPendiente: false,
        ));
      } else {
        sections.add(FixtureSection(
          id: 'segunda_ronda',
          fase: TournamentPhase.segundaRonda,
          titulo: 'Segunda Ronda (Cuadrangulares Semifinales)',
          subtitulo: 'Grupos A y B • Ventaja Deportiva para 1° y 2°',
          numeroJornada: 8,
          partidos: matchesSegundaRonda,
          esPendiente: false,
        ));
      }
    } else {
      sections.add(const FixtureSection(
        id: 'segunda_ronda',
        fase: TournamentPhase.segundaRonda,
        titulo: 'Segunda Ronda (Cuadrangulares Semifinales)',
        subtitulo: 'Grupos A y B • Ventaja Deportiva para 1° y 2°',
        numeroJornada: 8,
        esPendiente: true,
        mensajePendiente:
            'Fase pendiente de inicio. Los cruces se habilitarán una vez concluyan los encuentros de la fase anterior.',
        partidos: [],
      ));
    }

    // 3. TERCERA RONDA (Cuartos de Final)
    final matchesTerceraRonda = partidos.where((p) {
      final f = p.fase?.toUpperCase().trim() ?? '';
      return f.contains('TERCERA') ||
          (f.contains('CUARTO') && !f.contains('SEMI') && !f.contains('FINAL'));
    }).toList();

    if (matchesTerceraRonda.isNotEmpty) {
      sections.add(FixtureSection(
        id: 'cuartos_de_final',
        fase: TournamentPhase.terceraRonda,
        titulo: 'Tercera Ronda (Cuartos de Final)',
        subtitulo: 'Cruces directos: 1A vs 4B, 2A vs 3B, 1B vs 4A, 2B vs 3A',
        numeroJornada: 9,
        partidos: matchesTerceraRonda,
        esPendiente: false,
      ));
    } else {
      sections.add(const FixtureSection(
        id: 'cuartos_de_final',
        fase: TournamentPhase.terceraRonda,
        titulo: 'Tercera Ronda (Cuartos de Final)',
        subtitulo: 'Cruces directos entre clasificados de Grupos A y B',
        numeroJornada: 9,
        esPendiente: true,
        mensajePendiente:
            'Fase pendiente de inicio. Los cruces se habilitarán una vez concluyan los encuentros de la fase anterior.',
        partidos: [],
      ));
    }

    // 4. CUARTA RONDA (Semifinales)
    final matchesCuartaRonda = partidos.where((p) {
      final f = p.fase?.toUpperCase().trim() ?? '';
      return f.contains('CUARTA') || (f.contains('SEMI') && !f.contains('FINAL'));
    }).toList();

    if (matchesCuartaRonda.isNotEmpty) {
      sections.add(FixtureSection(
        id: 'semifinal',
        fase: TournamentPhase.cuartaRonda,
        titulo: 'Cuarta Ronda (Semifinales)',
        subtitulo: 'Ganador Llave 1 vs Llave 4 | Ganador Llave 3 vs Llave 2',
        numeroJornada: 10,
        partidos: matchesCuartaRonda,
        esPendiente: false,
      ));
    } else {
      sections.add(const FixtureSection(
        id: 'semifinal',
        fase: TournamentPhase.cuartaRonda,
        titulo: 'Cuarta Ronda (Semifinales)',
        subtitulo: 'Ganador Llave 1 vs Llave 4 | Ganador Llave 3 vs Llave 2',
        numeroJornada: 10,
        esPendiente: true,
        mensajePendiente:
            'Fase pendiente de inicio. Los cruces se habilitarán una vez concluyan los encuentros de la fase anterior.',
        partidos: [],
      ));
    }

    // 5. QUINTA RONDA (Gran Final y Tercer Puesto)
    final matchesQuintaRonda = partidos.where((p) {
      final f = p.fase?.toUpperCase().trim() ?? '';
      return f.contains('QUINTA') ||
          (f.contains('FINAL') && !f.contains('SEMI')) ||
          f.contains('TERCER');
    }).toList();

    if (matchesQuintaRonda.isNotEmpty) {
      sections.add(FixtureSection(
        id: 'gran_final',
        fase: TournamentPhase.quintaRonda,
        titulo: 'Quinta Ronda (Gran Final y 3° Puesto)',
        subtitulo: 'Definición del Título de Campeón y Tercer Lugar',
        numeroJornada: 11,
        partidos: matchesQuintaRonda,
        esPendiente: false,
      ));
    } else {
      sections.add(const FixtureSection(
        id: 'gran_final',
        fase: TournamentPhase.quintaRonda,
        titulo: 'Quinta Ronda (Gran Final y 3° Puesto)',
        subtitulo: 'Definición del Título de Campeón y Tercer Lugar',
        numeroJornada: 11,
        esPendiente: true,
        mensajePendiente:
            'Fase pendiente de inicio. Los cruces se habilitarán una vez concluyan los encuentros de la fase anterior.',
        partidos: [],
      ));
    }

    return sections;
  }
}

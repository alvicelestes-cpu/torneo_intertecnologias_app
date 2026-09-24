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
  /// Mientras la Primera Fase esté en disputa (actualmente en Fecha 5), las rondas posteriores
  /// se muestran visibles en estado "Por definir" con sus emparejamientos reglamentarios.
  /// Cuando el backend resuelva y provea los partidos oficiales, se cargan automáticamente.
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

    // Comprobar si la Primera Fase ya culminó (todas las 7 fechas jugadas y finalizadas)
    final todosPartidosPrimeraFase = partidosPrimeraFase.values.expand((l) => l).toList();
    final bool primeraFaseCompleta = todosPartidosPrimeraFase.isNotEmpty &&
        todosPartidosPrimeraFase.where((p) => (p.jornada ?? 0) == 7).isNotEmpty &&
        todosPartidosPrimeraFase.every((p) => p.esFinalizado);

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
      // Estado de espera / Teórico con siembra reglamentaria
      final mensajeA = primeraFaseCompleta
          ? 'Clasificados confirmados de Primera Fase. Punto Invisible asignado al 1° puesto.'
          : 'Pendiente de clasificación: Se sembrarán los puestos 1°, 3°, 5° y 7° al concluir la Jornada 7. El 1° puesto cuenta con Ventaja Deportiva (Punto Invisible).';
      final mensajeB = primeraFaseCompleta
          ? 'Clasificados confirmados de Primera Fase. Punto Invisible asignado al 2° puesto.'
          : 'Pendiente de clasificación: Se sembrarán los puestos 2°, 4°, 6° y 8° al concluir la Jornada 7. El 2° puesto cuenta con Ventaja Deportiva (Punto Invisible).';

      sections.add(FixtureSection(
        id: 'cuadrangular_grupo_a',
        fase: TournamentPhase.segundaRonda,
        titulo: 'Cuadrangular Semifinal - Grupo A',
        subtitulo: '1°, 3°, 5° y 7° de Primera Fase (1° con Punto Invisible)',
        numeroJornada: 8,
        esPendiente: !primeraFaseCompleta,
        mensajePendiente: mensajeA,
        partidos: _generarPartidosProvisoriosCuadrangularA(posiciones),
      ));

      sections.add(FixtureSection(
        id: 'cuadrangular_grupo_b',
        fase: TournamentPhase.segundaRonda,
        titulo: 'Cuadrangular Semifinal - Grupo B',
        subtitulo: '2°, 4°, 6° y 8° de Primera Fase (2° con Punto Invisible)',
        numeroJornada: 8,
        esPendiente: !primeraFaseCompleta,
        mensajePendiente: mensajeB,
        partidos: _generarPartidosProvisoriosCuadrangularB(posiciones),
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
      sections.add(FixtureSection(
        id: 'cuartos_de_final',
        fase: TournamentPhase.terceraRonda,
        titulo: 'Tercera Ronda (Cuartos de Final)',
        subtitulo: 'Cruces directos entre clasificados de Grupos A y B',
        numeroJornada: 9,
        esPendiente: true,
        mensajePendiente:
            'Pendiente de clasificación: Llaves entre los 4 clasificados del Grupo A y los 4 clasificados del Grupo B.',
        partidos: _generarPartidosProvisoriosCuartos(),
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
      sections.add(FixtureSection(
        id: 'semifinal',
        fase: TournamentPhase.cuartaRonda,
        titulo: 'Cuarta Ronda (Semifinales)',
        subtitulo: 'Ganador Llave 1 vs Llave 4 | Ganador Llave 3 vs Llave 2',
        numeroJornada: 10,
        esPendiente: true,
        mensajePendiente:
            'Pendiente de clasificación: Ganadores de las 4 llaves de Cuartos de Final.',
        partidos: _generarPartidosProvisoriosSemifinal(),
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
      sections.add(FixtureSection(
        id: 'gran_final',
        fase: TournamentPhase.quintaRonda,
        titulo: 'Quinta Ronda (Gran Final y 3° Puesto)',
        subtitulo: 'Definición del Título de Campeón y Tercer Lugar',
        numeroJornada: 11,
        esPendiente: true,
        mensajePendiente:
            'Pendiente de clasificación: Finalistas del torneo (Ganador SF1 vs SF2) y disputa del 3° puesto.',
        partidos: _generarPartidosProvisoriosFinal(),
      ));
    }

    return sections;
  }

  // -------------------------------------------------------------
  // GENERACIÓN DE EMPAREJAMIENTOS REGLAMENTARIOS EN ESTADO PENDIENTE
  // -------------------------------------------------------------

  static List<Partido> _generarPartidosProvisoriosCuadrangularA(List<Posicion> posiciones) {
    final p1 = posiciones.isNotEmpty ? posiciones[0].equipo : null;
    final p3 = posiciones.length > 2 ? posiciones[2].equipo : null;
    final p5 = posiciones.length > 4 ? posiciones[4].equipo : null;
    final p7 = posiciones.length > 6 ? posiciones[6].equipo : null;

    final n1 = p1 != null ? '1° P.F. ($p1) [★ Ventaja]' : '1° P.F. (Por definir) [★ Ventaja]';
    final n3 = p3 != null ? '3° P.F. ($p3)' : '3° P.F. (Por definir)';
    final n5 = p5 != null ? '5° P.F. ($p5)' : '5° P.F. (Por definir)';
    final n7 = p7 != null ? '7° P.F. ($p7)' : '7° P.F. (Por definir)';

    return [
      // Fecha 1
      Partido(
        id: 0,
        equipoLocalNombre: n1,
        equipoLocalSigla: '1°A',
        equipoVisitanteNombre: n7,
        equipoVisitanteSigla: '7°A',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo A - Fecha 1',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: n3,
        equipoLocalSigla: '3°A',
        equipoVisitanteNombre: n5,
        equipoVisitanteSigla: '5°A',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo A - Fecha 1',
      ),
      // Fecha 2
      Partido(
        id: 0,
        equipoLocalNombre: n1,
        equipoLocalSigla: '1°A',
        equipoVisitanteNombre: n5,
        equipoVisitanteSigla: '5°A',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo A - Fecha 2',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: n7,
        equipoLocalSigla: '7°A',
        equipoVisitanteNombre: n3,
        equipoVisitanteSigla: '3°A',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo A - Fecha 2',
      ),
      // Fecha 3
      Partido(
        id: 0,
        equipoLocalNombre: n1,
        equipoLocalSigla: '1°A',
        equipoVisitanteNombre: n3,
        equipoVisitanteSigla: '3°A',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo A - Fecha 3',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: n5,
        equipoLocalSigla: '5°A',
        equipoVisitanteNombre: n7,
        equipoVisitanteSigla: '7°A',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo A - Fecha 3',
      ),
    ];
  }

  static List<Partido> _generarPartidosProvisoriosCuadrangularB(List<Posicion> posiciones) {
    final p2 = posiciones.length > 1 ? posiciones[1].equipo : null;
    final p4 = posiciones.length > 3 ? posiciones[3].equipo : null;
    final p6 = posiciones.length > 5 ? posiciones[5].equipo : null;
    final p8 = posiciones.length > 7 ? posiciones[7].equipo : null;

    final n2 = p2 != null ? '2° P.F. ($p2) [★ Ventaja]' : '2° P.F. (Por definir) [★ Ventaja]';
    final n4 = p4 != null ? '4° P.F. ($p4)' : '4° P.F. (Por definir)';
    final n6 = p6 != null ? '6° P.F. ($p6)' : '6° P.F. (Por definir)';
    final n8 = p8 != null ? '8° P.F. ($p8)' : '8° P.F. (Por definir)';

    return [
      // Fecha 1
      Partido(
        id: 0,
        equipoLocalNombre: n2,
        equipoLocalSigla: '2°B',
        equipoVisitanteNombre: n8,
        equipoVisitanteSigla: '8°B',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo B - Fecha 1',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: n4,
        equipoLocalSigla: '4°B',
        equipoVisitanteNombre: n6,
        equipoVisitanteSigla: '6°B',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo B - Fecha 1',
      ),
      // Fecha 2
      Partido(
        id: 0,
        equipoLocalNombre: n2,
        equipoLocalSigla: '2°B',
        equipoVisitanteNombre: n6,
        equipoVisitanteSigla: '6°B',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo B - Fecha 2',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: n8,
        equipoLocalSigla: '8°B',
        equipoVisitanteNombre: n4,
        equipoVisitanteSigla: '4°B',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo B - Fecha 2',
      ),
      // Fecha 3
      Partido(
        id: 0,
        equipoLocalNombre: n2,
        equipoLocalSigla: '2°B',
        equipoVisitanteNombre: n4,
        equipoVisitanteSigla: '4°B',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo B - Fecha 3',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: n6,
        equipoLocalSigla: '6°B',
        equipoVisitanteNombre: n8,
        equipoVisitanteSigla: '8°B',
        estado: 'POR DEFINIR',
        fase: 'SEGUNDA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Grupo B - Fecha 3',
      ),
    ];
  }

  static List<Partido> _generarPartidosProvisoriosCuartos() {
    return const [
      Partido(
        id: 0,
        equipoLocalNombre: '1° Grupo A',
        equipoLocalSigla: '1°A',
        equipoVisitanteNombre: '4° Grupo B',
        equipoVisitanteSigla: '4°B',
        estado: 'POR DEFINIR',
        fase: 'TERCERA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Llave 1 (Cuartos)',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: '2° Grupo A',
        equipoLocalSigla: '2°A',
        equipoVisitanteNombre: '3° Grupo B',
        equipoVisitanteSigla: '3°B',
        estado: 'POR DEFINIR',
        fase: 'TERCERA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Llave 2 (Cuartos)',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: '1° Grupo B',
        equipoLocalSigla: '1°B',
        equipoVisitanteNombre: '4° Grupo A',
        equipoVisitanteSigla: '4°A',
        estado: 'POR DEFINIR',
        fase: 'TERCERA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Llave 3 (Cuartos)',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: '2° Grupo B',
        equipoLocalSigla: '2°B',
        equipoVisitanteNombre: '3° Grupo A',
        equipoVisitanteSigla: '3°A',
        estado: 'POR DEFINIR',
        fase: 'TERCERA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Llave 4 (Cuartos)',
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
        fase: 'CUARTA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Semifinal 1',
      ),
      Partido(
        id: 0,
        equipoLocalNombre: 'Ganador Llave 3',
        equipoLocalSigla: 'G3',
        equipoVisitanteNombre: 'Ganador Llave 2',
        equipoVisitanteSigla: 'G2',
        estado: 'POR DEFINIR',
        fase: 'CUARTA_RONDA',
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
        fase: 'QUINTA_RONDA',
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
        fase: 'QUINTA_RONDA',
        cancha: 'Cancha Principal',
        llave: 'Tercer Puesto',
      ),
    ];
  }
}

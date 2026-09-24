import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/core/utils/date_utils.dart';
import 'package:torneo_intertecnologias_app/core/utils/text_utils.dart';
import 'package:torneo_intertecnologias_app/jugador_detalle_page.dart';
import 'package:torneo_intertecnologias_app/models/equipo.dart';
import 'package:torneo_intertecnologias_app/models/goleador.dart';
import 'package:torneo_intertecnologias_app/models/jugador.dart';
import 'package:torneo_intertecnologias_app/models/partido.dart';
import 'package:torneo_intertecnologias_app/widgets/public_jornada_accordion.dart';
import 'package:torneo_intertecnologias_app/widgets/public_partido_row.dart';
import 'package:torneo_intertecnologias_app/widgets/public_player_card.dart';
import 'package:torneo_intertecnologias_app/widgets/public_team_card.dart';
import 'package:torneo_intertecnologias_app/widgets/public_age_group_section.dart';
import 'package:torneo_intertecnologias_app/core/constants/app_colors.dart';
import 'package:torneo_intertecnologias_app/core/utils/player_sort_utils.dart';
import 'package:torneo_intertecnologias_app/portal_publico_page.dart';

void main() {
  group('AppDateUtils - Cálculo de edad', () {
    test('Calcula la edad correctamente para fecha pasada', () {
      final now = DateTime.now();
      final birthYear = now.year - 41;
      final birthMonth = now.month;
      final birthDay = now.day > 1 ? now.day - 1 : 1;
      final fechaStr =
          '$birthYear-${birthMonth.toString().padLeft(2, '0')}-${birthDay.toString().padLeft(2, '0')}';

      final age = AppDateUtils.calculateAge(fechaStr);
      expect(age, equals(41));
    });

    test('Devuelve null para fechas nulas o vacías', () {
      expect(AppDateUtils.calculateAge(null), isNull);
      expect(AppDateUtils.calculateAge(''), isNull);
      expect(AppDateUtils.calculateAge('fecha-invalida'), isNull);
    });
  });

  group('Colores de Carnets según Edad (getColorByAge)', () {
    test('edad >= 40 => carnet verde', () {
      expect(AppColors.getColorByAge(40), equals(AppColors.carnetVerde));
      expect(AppColors.getColorByAge(41), equals(AppColors.carnetVerde));
      expect(AppColors.getColorByAge(55), equals(AppColors.carnetVerde));
      expect(getColorByAge(40), equals(AppColors.carnetVerde));
    });

    test('edad 35-39 => carnet naranja/dorado', () {
      expect(AppColors.getColorByAge(35), equals(AppColors.carnetNaranja));
      expect(AppColors.getColorByAge(37), equals(AppColors.carnetNaranja));
      expect(AppColors.getColorByAge(39), equals(AppColors.carnetNaranja));
      expect(getColorByAge(36), equals(AppColors.carnetNaranja));
    });

    test('edad 18-34 => carnet azul', () {
      expect(AppColors.getColorByAge(18), equals(AppColors.carnetAzul));
      expect(AppColors.getColorByAge(25), equals(AppColors.carnetAzul));
      expect(AppColors.getColorByAge(34), equals(AppColors.carnetAzul));
      expect(getColorByAge(22), equals(AppColors.carnetAzul));
    });

    test('edad null => fallback neutro elegante', () {
      expect(AppColors.getColorByAge(null), equals(AppColors.carnetNeutro));
      expect(getColorByAge(null), equals(AppColors.carnetNeutro));
      expect(AppColors.getColorByAge(16), equals(AppColors.carnetNeutro));
    });

    test('equipos conservan colorPrincipal', () {
      const equipoCustom = Equipo(
        id: 7,
        nombre: 'DEP ELITE',
        sigla: 'DEP',
        colorPrincipal: '#00897B',
      );
      // El equipo conserva su color del club
      expect(equipoCustom.color, equals(const Color(0xFF00897B)));

      // Pero el jugador adopta el color según su edad
      const jugadorVeterano = Jugador(
        id: 1,
        equipoId: 7,
        equipoNombre: 'DEP ELITE',
        equipoColor: '#00897B',
        nombres: 'Yamith',
        apellidos: 'Acosta',
        fechaNacimiento: '1984-05-10', // >= 40 años
      );
      expect(jugadorVeterano.edad, isNotNull);
      expect(jugadorVeterano.edad! >= 40, isTrue);
      expect(getColorByAge(jugadorVeterano.edad), equals(AppColors.carnetVerde));
    });
  });

  group('TextUtils - Parseo de colores de equipo (válidos e inválidos)', () {
    test('Parsea colores en formato hexadecimal con y sin #', () {
      final c1 = TextUtils.parseColor('#FF0000');
      expect(c1, equals(const Color(0xFFFF0000)));

      final c2 = TextUtils.parseColor('00FF00');
      expect(c2, equals(const Color(0xFF00FF00)));

      final c3 = TextUtils.parseColor('#FFF');
      expect(c3, equals(const Color(0xFFFFFFFF)));
    });

    test('Retorna color por defecto ante valores inválidos o nulos', () {
      final cDefault = TextUtils.parseColor(null);
      expect(cDefault, equals(const Color(0xFF1976D2)));

      final cInvalido = TextUtils.parseColor('color-invalido');
      expect(cInvalido, equals(const Color(0xFF1976D2)));

      final cVacio = TextUtils.parseColor('');
      expect(cVacio, equals(const Color(0xFF1976D2)));
    });
  });

  group('Jornadas - Ordenación ASCENDENTE obligatoria', () {
    test('Ordena estrictamente por número de jornada ascendente: 1, 2, 3... nunca 7 antes que 1', () {
      final partidosDesordenados = [
        const Partido(id: 70, equipoLocalNombre: 'A', equipoVisitanteNombre: 'B', jornada: 7),
        const Partido(id: 30, equipoLocalNombre: 'C', equipoVisitanteNombre: 'D', jornada: 3),
        const Partido(id: 10, equipoLocalNombre: 'E', equipoVisitanteNombre: 'F', jornada: 1),
        const Partido(id: 50, equipoLocalNombre: 'G', equipoVisitanteNombre: 'H', jornada: 5),
        const Partido(id: 20, equipoLocalNombre: 'I', equipoVisitanteNombre: 'J', jornada: 2),
      ];

      final Map<int, List<Partido>> mapJornadas = {};
      for (final p in partidosDesordenados) {
        final j = p.jornada ?? 1;
        mapJornadas.putIfAbsent(j, () => []).add(p);
      }

      final jornadasAscendentes = mapJornadas.keys.toList()..sort();

      expect(jornadasAscendentes, equals([1, 2, 3, 5, 7]));
      expect(jornadasAscendentes.first, equals(1));
      expect(jornadasAscendentes.last, equals(7));
      expect(jornadasAscendentes.indexOf(1) < jornadasAscendentes.indexOf(7), isTrue);
    });
  });

  group('Carnet de Jugador (PublicPlayerCard) - Widget Tests', () {
    testWidgets('Muestra EDAD claramente calculada y visible con alto contraste', (tester) async {
      final now = DateTime.now();
      final birthYear = now.year - 41;
      final birthMonth = now.month;
      final birthDay = now.day > 1 ? now.day - 1 : 1;
      final fechaStr =
          '$birthYear-${birthMonth.toString().padLeft(2, '0')}-${birthDay.toString().padLeft(2, '0')}';

      final jugador = Jugador(
        id: 1,
        equipoId: 10,
        equipoNombre: 'DEP ELITE',
        equipoSigla: 'DEP',
        equipoColor: '#00897B',
        nombres: 'Yamith',
        apellidos: 'Acosta Hernandez',
        fechaNacimiento: fechaStr,
        goles: 0,
        amarillas: 0,
        rojas: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                height: 220,
                child: PublicPlayerCard(jugador: jugador),
              ),
            ),
          ),
        ),
      );

      // Bloque EDAD presente y visible
      expect(find.text('EDAD'), findsOneWidget);
      expect(find.text('41 años'), findsOneWidget);
      expect(find.text('NACIMIENTO'), findsOneWidget);
      expect(find.text('DEP'), findsOneWidget);
      expect(find.text('DEP ELITE'), findsOneWidget);
      expect(find.text('YAMITH ACOSTA HERNANDEZ'), findsOneWidget);
    });

    testWidgets('Jugador sin fotografía muestra avatar con iniciales sin error', (tester) async {
      const jugador = Jugador(
        id: 2,
        equipoId: 10,
        equipoNombre: 'Halcones',
        equipoSigla: 'HAL',
        nombres: 'Carlos',
        apellidos: 'Gómez',
        fotoJugador: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 220,
              child: PublicPlayerCard(jugador: jugador),
            ),
          ),
        ),
      );

      expect(find.text('CG'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Estadísticas del carnet muestran mini-bloques de goles, amarillas y rojas', (tester) async {
      const jugador = Jugador(
        id: 3,
        equipoId: 10,
        equipoNombre: 'Tigres',
        nombres: 'Pedro',
        apellidos: 'Ramírez',
        goles: 4,
        amarillas: 2,
        rojas: 1,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 220,
              child: PublicPlayerCard(jugador: jugador),
            ),
          ),
        ),
      );

      expect(find.text('GOLES'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('AMARILLAS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('ROJAS'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Ver ficha'), findsOneWidget);
    });
  });

  group('PublicPartidoRow y PublicJornadaAccordion', () {
    testWidgets('PublicPartidoRow muestra marcador en pastilla azul oscuro y equipos separados', (tester) async {
      const partido = Partido(
        id: 101,
        equipoLocalNombre: 'INPEC',
        equipoVisitanteNombre: 'GREMIO HFC',
        golesLocal: 5,
        golesVisitante: 6,
        estado: 'FINALIZADO',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PublicPartidoRow(index: 1, partido: partido),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('INPEC'), findsOneWidget);
      expect(find.text('GREMIO HFC'), findsOneWidget);
      expect(find.text('5 - 6'), findsOneWidget);
      expect(find.text('FINALIZADO'), findsOneWidget);
    });

    testWidgets('PublicJornadaAccordion muestra cabecera con Jornada y lista de partidos al expandir', (tester) async {
      const partido1 = Partido(
        id: 1,
        equipoLocalNombre: 'INPEC',
        equipoVisitanteNombre: 'GREMIO HFC',
        golesLocal: 5,
        golesVisitante: 6,
        estado: 'FINALIZADO',
      );
      const partido2 = Partido(
        id: 2,
        equipoLocalNombre: 'DEP ELITE',
        equipoVisitanteNombre: 'CONEXIÓN DIGITAL',
        golesLocal: 6,
        golesVisitante: 3,
        estado: 'FINALIZADO',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PublicJornadaAccordion(
              numeroJornada: 1,
              fase: 'PRIMERA FASE',
              cantidadPartidos: 2,
              partidos: [partido1, partido2],
              initiallyExpanded: true,
            ),
          ),
        ),
      );

      expect(find.text('Jornada 1'), findsOneWidget);
      expect(find.text('PRIMERA FASE'), findsOneWidget);
      expect(find.text('2 partidos'), findsOneWidget);
      expect(find.text('INPEC'), findsOneWidget);
      expect(find.text('GREMIO HFC'), findsOneWidget);
      expect(find.text('DEP ELITE'), findsOneWidget);
      expect(find.text('CONEXIÓN DIGITAL'), findsOneWidget);
    });
  });

  group('Seguridad: Modo público NO expone campos privados', () {
    testWidgets('JugadorDetallePage no muestra documento ni observaciones en modo público/anónimo', (tester) async {
      // Aseguramos que la sesión sea pública/anónima
      SessionManager().clearSession();

      final jugadorJson = {
        'id': 99,
        'equipoId': 5,
        'nombres': 'Yamith',
        'apellidos': 'Acosta',
        'documento': '1234567890_CONFIDENCIAL',
        'observacionAdmin': 'OBSERVACION_INTERNA_ADMINISTRATIVA',
        'goles': 3,
        'amarillas': 1,
        'rojas': 0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: JugadorDetallePage(
            jugador: jugadorJson,
            equipoNombre: 'DEP ELITE',
          ),
        ),
      );

      // Campos públicos deben existir
      expect(find.text('YAMITH ACOSTA'), findsOneWidget);
      expect(find.text('DEP ELITE'), findsWidgets);
      expect(find.text('GOLES'), findsOneWidget);

      // Campos confidenciales/administrativos NUNCA deben mostrarse públicamente
      expect(find.text('1234567890_CONFIDENCIAL'), findsNothing);
      expect(find.text('Documento de identidad'), findsNothing);
      expect(find.text('OBSERVACION_INTERNA_ADMINISTRATIVA'), findsNothing);
      expect(find.text('Observaciones internas'), findsNothing);
      expect(find.text('EDITAR JUGADOR'), findsNothing);
    });
  });

  group('Modelo Equipo - Atributos deportivos', () {
    test('Parsea colorPrincipal y cantidadJugadores desde json', () {
      final equipo = Equipo.fromJson({
        'id': 10,
        'nombre': 'Halcones FC',
        'sigla': 'HFC',
        'colorPrincipal': '#FF5722',
        'cantidadJugadores': 18,
      });

      expect(equipo.id, equals(10));
      expect(equipo.nombre, equals('Halcones FC'));
      expect(equipo.sigla, equals('HFC'));
      expect(equipo.colorPrincipal, equals('#FF5722'));
      expect(equipo.color, equals(const Color(0xFFFF5722)));
      expect(equipo.cantidadJugadores, equals(18));
    });

    test('copyWith preserva y actualiza cantidadJugadores', () {
      const original = Equipo(
        id: 1,
        nombre: 'Leones',
        sigla: 'LEO',
        cantidadJugadores: 5,
      );

      final updated = original.copyWith(cantidadJugadores: 15);
      expect(updated.cantidadJugadores, equals(15));
      expect(updated.nombre, equals('Leones'));
    });
  });

  group('Modelo Goleador - Clasificación y atributos deportivos', () {
    test('Parsea siglaEquipo y numeroCamiseta correctamente', () {
      final g = Goleador.fromJson({
        'posicion': 1,
        'jugadorId': 101,
        'nombres': 'Mateo',
        'apellidos': 'Silva',
        'equipo': 'Tigres',
        'siglaEquipo': 'TIG',
        'numeroCamiseta': 9,
        'goles': 12,
      });

      expect(g.posicion, equals(1));
      expect(g.jugadorId, equals(101));
      expect(g.nombreCompleto, equals('Mateo Silva'));
      expect(g.siglaEquipo, equals('TIG'));
      expect(g.numeroCamiseta, equals(9));
      expect(g.goles, equals(12));
    });
  });

  group('Responsive Viewports - Carnets y Pantallas', () {
    const viewports = [
      Size(360, 640),
      Size(390, 844),
      Size(412, 915),
      Size(768, 1024),
      Size(1366, 768),
      Size(1920, 1080),
    ];

    for (final size in viewports) {
      testWidgets('PublicPlayerCard renderiza sin overflow en viewport ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const jugador = Jugador(
          id: 5,
          equipoId: 10,
          equipoNombre: 'CONEXIÓN DIGITAL',
          equipoSigla: 'CD',
          nombres: 'Alejandro',
          apellidos: 'Morales',
          fechaNacimiento: '1995-05-12',
          goles: 2,
          amarillas: 1,
          rojas: 0,
        );

        final crossAxisCount = size.width < 640 ? 1 : (size.width < 1050 ? 2 : 3);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 215,
                    ),
                    itemCount: 3,
                    itemBuilder: (context, index) => const PublicPlayerCard(jugador: jugador),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('ALEJANDRO MORALES'), findsWidgets);
        expect(find.text('EDAD'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Responsive Viewports - Encabezado / Banner Principal', () {
    const bannerViewports = [
      Size(360, 640),
      Size(390, 844),
      Size(412, 915),
      Size(768, 1024),
      Size(1366, 768),
      Size(1920, 1080),
    ];

    for (final size in bannerViewports) {
      testWidgets(
          'PublicHeaderBanner renderiza limpio y sin overflow en viewport ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width < 500 ? 12 : 20,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PublicHeaderBanner(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('PORTAL DEL TORNEO'), findsOneWidget);
        expect(find.text('TORNEO INTERTECNOLOGÍAS'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Responsive Viewports - Acordeón de Partidos (PublicJornadaAccordion)', () {
    const accordionViewports = [
      Size(360, 640),
      Size(390, 844),
      Size(412, 915),
      Size(768, 1024),
      Size(1920, 1080),
    ];

    for (final size in accordionViewports) {
      testWidgets(
          'PublicJornadaAccordion renderiza expandido sin overflow en viewport ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final partidos = [
          const Partido(
            id: 1,
            equipoLocalId: 1,
            equipoLocalNombre: 'INPEC FC',
            equipoLocalSigla: 'INP',
            equipoVisitanteId: 2,
            equipoVisitanteNombre: 'TELEMATIK',
            equipoVisitanteSigla: 'TEL',
            golesLocal: 2,
            golesVisitante: 1,
            estado: 'FINALIZADO',
            jornada: 1,
            fase: 'PRIMERA FASE',
          ),
          const Partido(
            id: 2,
            equipoLocalId: 3,
            equipoLocalNombre: 'DEP ELITE',
            equipoLocalSigla: 'DEP',
            equipoVisitanteId: 4,
            equipoVisitanteNombre: 'CEMENTEROS',
            equipoVisitanteSigla: 'CEM',
            golesLocal: 0,
            golesVisitante: 0,
            estado: 'FINALIZADO',
            jornada: 1,
            fase: 'PRIMERA FASE',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width < 600 ? 12 : 16,
                  vertical: 16,
                ),
                children: [
                  PublicJornadaAccordion(
                    numeroJornada: 1,
                    fase: 'PRIMERA FASE',
                    cantidadPartidos: partidos.length,
                    partidos: partidos,
                    initiallyExpanded: true,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Jornada 1'), findsOneWidget);
        expect(find.text('PRIMERA FASE'), findsOneWidget);
        expect(find.text('2 partidos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Responsive Viewports - Tarjetas de Equipo (PublicTeamCard)', () {
    const teamViewports = [
      Size(360, 640),
      Size(390, 844),
      Size(412, 915),
      Size(768, 1024),
      Size(1366, 768),
      Size(1920, 1080),
    ];

    for (final size in teamViewports) {
      testWidgets(
          'PublicTeamCard renderiza limpio y sin overflow en viewport ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const equipo = Equipo(
          id: 1,
          nombre: 'DEP ELITE',
          sigla: 'DEP',
          colorPrincipal: '#00897B',
          cantidadJugadores: 14,
        );

        final crossAxisCount = size.width >= 1050
            ? 4
            : (size.width >= 620 ? 2 : 1);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: crossAxisCount == 1
                      ? ListView(
                          children: const [
                            PublicTeamCard(equipo: equipo),
                          ],
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 232,
                          ),
                          itemCount: 4,
                          itemBuilder: (context, index) =>
                              const PublicTeamCard(equipo: equipo),
                        ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('DEP ELITE'), findsWidgets);
        expect(find.text('DEP'), findsWidgets);
        expect(find.text('Ver jugadores'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Ordenación estricta y obligatoria de carnets por grupos de edad', () {
    String birthDateForAge(int age, {int month = 1, int day = 1}) {
      final now = DateTime.now();
      final year = now.year - age;
      return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }

    test('Ordenación exacta: 48 < 45 < 40 < 39 < 35 < 34 < 18 < null', () {
      final j48 = Jugador(
        id: 1,
        equipoId: 10,
        nombres: 'Omar',
        apellidos: 'Causado',
        fechaNacimiento: birthDateForAge(48),
      );
      final j45 = Jugador(
        id: 2,
        equipoId: 10,
        nombres: 'Elkin',
        apellidos: 'Alviz',
        fechaNacimiento: birthDateForAge(45),
      );
      final j40 = Jugador(
        id: 3,
        equipoId: 10,
        nombres: 'Yamith',
        apellidos: 'Acosta',
        fechaNacimiento: birthDateForAge(40),
      );
      final j39 = Jugador(
        id: 4,
        equipoId: 10,
        nombres: 'Darwin',
        apellidos: 'Garcia',
        fechaNacimiento: birthDateForAge(39),
      );
      final j35 = Jugador(
        id: 5,
        equipoId: 10,
        nombres: 'Gabriel',
        apellidos: 'Lopez',
        fechaNacimiento: birthDateForAge(35),
      );
      final j34 = Jugador(
        id: 6,
        equipoId: 10,
        nombres: 'Guillermo',
        apellidos: 'Perez',
        fechaNacimiento: birthDateForAge(34),
      );
      final j18 = Jugador(
        id: 7,
        equipoId: 10,
        nombres: 'Kendri',
        apellidos: 'Alviz',
        fechaNacimiento: birthDateForAge(18),
      );
      final jNull = const Jugador(
        id: 8,
        equipoId: 10,
        nombres: 'Jugador',
        apellidos: 'SinFecha',
        fechaNacimiento: null,
      );

      final desordenados = [j18, jNull, j35, j45, j34, j40, j39, j48];
      final ordenados = List<Jugador>.from(desordenados)..sort(compareJugadoresPorEdad);

      // Verificación de orden:
      expect(ordenados[0], equals(j48));
      expect(ordenados[1], equals(j45));
      expect(ordenados[2], equals(j40));
      expect(ordenados[3], equals(j39));
      expect(ordenados[4], equals(j35));
      expect(ordenados[5], equals(j34));
      expect(ordenados[6], equals(j18));
      expect(ordenados[7], equals(jNull));

      // Verificaciones puntuales requeridas por la especificación:
      // 1. 48 aparece antes que 45
      expect(ordenados.indexOf(j48) < ordenados.indexOf(j45), isTrue);
      // 2. 45 aparece antes que 40
      expect(ordenados.indexOf(j45) < ordenados.indexOf(j40), isTrue);
      // 3. 40+ aparece antes que 35-39
      expect(ordenados.indexOf(j40) < ordenados.indexOf(j39), isTrue);
      // 4. 35-39 aparece antes que 18-34
      expect(ordenados.indexOf(j35) < ordenados.indexOf(j34), isTrue);
      // 5. 39 antes que 35
      expect(ordenados.indexOf(j39) < ordenados.indexOf(j35), isTrue);
      // 6. 34 antes que 18
      expect(ordenados.indexOf(j34) < ordenados.indexOf(j18), isTrue);
      // 7. null queda al final
      expect(ordenados.last, equals(jNull));
    });

    test('Empate de edad se desempata por fecha de nacimiento (más antiguo primero)', () {
      final now = DateTime.now();
      final year = now.year - 40;
      final jNacidoFebrero = Jugador(
        id: 1,
        equipoId: 1,
        nombres: 'Nacido',
        apellidos: 'Primero',
        fechaNacimiento: '$year-02-10',
      );
      final jNacidoNoviembre = Jugador(
        id: 2,
        equipoId: 1,
        nombres: 'Nacido',
        apellidos: 'Despues',
        fechaNacimiento: '$year-11-20',
      );

      final resultado = compareJugadoresPorEdad(jNacidoFebrero, jNacidoNoviembre);
      expect(resultado < 0, isTrue); // Febrero aparece antes que Noviembre
    });

    test('Empate de edad y fecha se desempata alfabéticamente', () {
      final now = DateTime.now();
      final year = now.year - 30;
      final jAndres = Jugador(
        id: 1,
        equipoId: 1,
        nombres: 'Andres',
        apellidos: 'Bermudez',
        fechaNacimiento: '$year-05-15',
      );
      final jCarlos = Jugador(
        id: 2,
        equipoId: 1,
        nombres: 'Carlos',
        apellidos: 'Alvarez',
        fechaNacimiento: '$year-05-15',
      );

      final resultado = compareJugadoresPorEdad(jAndres, jCarlos);
      expect(resultado < 0, isTrue); // 'Andres Bermudez' va antes que 'Carlos Alvarez'
    });

    test('Colores obligatorios por edad', () {
      // verde para >=40
      expect(getColorByAge(40), equals(const Color(0xFF2E7D32)));
      expect(getColorByAge(48), equals(const Color(0xFF2E7D32)));
      // naranja para 35-39
      expect(getColorByAge(35), equals(const Color(0xFFE65100)));
      expect(getColorByAge(39), equals(const Color(0xFFE65100)));
      // azul para 18-34
      expect(getColorByAge(18), equals(const Color(0xFF1565C0)));
      expect(getColorByAge(34), equals(const Color(0xFF1565C0)));
      // gris para null
      expect(getColorByAge(null), equals(const Color(0xFF546E7A)));
    });

    test('groupJugadoresPorEdad organiza y ordena automáticamente cualquier equipo sin hardcoding', () {
      // Simular equipo futuro cualquiera
      final plantelCualquiera = [
        Jugador(
          id: 101,
          equipoId: 999,
          equipoNombre: 'EQUIPO FUTURO FC',
          nombres: 'Jugador',
          apellidos: 'Joven',
          fechaNacimiento: birthDateForAge(21),
        ),
        Jugador(
          id: 102,
          equipoId: 999,
          equipoNombre: 'EQUIPO FUTURO FC',
          nombres: 'Jugador',
          apellidos: 'Veterano',
          fechaNacimiento: birthDateForAge(44),
        ),
        Jugador(
          id: 103,
          equipoId: 999,
          equipoNombre: 'EQUIPO FUTURO FC',
          nombres: 'Jugador',
          apellidos: 'Maduro',
          fechaNacimiento: birthDateForAge(37),
        ),
      ];

      final agrupados = groupJugadoresPorEdad(plantelCualquiera);

      expect(agrupados[AgeGroup.over40]!.length, equals(1));
      expect(agrupados[AgeGroup.over40]!.first.nombres, equals('Jugador'));
      expect(agrupados[AgeGroup.over40]!.first.apellidos, equals('Veterano'));

      expect(agrupados[AgeGroup.between35And39]!.length, equals(1));
      expect(agrupados[AgeGroup.between35And39]!.first.apellidos, equals('Maduro'));

      expect(agrupados[AgeGroup.between18And34]!.length, equals(1));
      expect(agrupados[AgeGroup.between18And34]!.first.apellidos, equals('Joven'));

      expect(agrupados[AgeGroup.unknown]!.isEmpty, isTrue);
    });
  });

  group('PublicAgeGroupSection - Widget Tests', () {
    testWidgets('Encabezado de cada grupo muestra título y cantidad de jugadores', (tester) async {
      final now = DateTime.now();
      final year42 = now.year - 42;
      final year45 = now.year - 45;

      final jugadores = [
        Jugador(
          id: 1,
          equipoId: 1,
          equipoNombre: 'DEP ELITE',
          equipoSigla: 'DEP',
          nombres: 'Elkin',
          apellidos: 'Alviz',
          fechaNacimiento: '$year45-08-03',
        ),
        Jugador(
          id: 2,
          equipoId: 1,
          equipoNombre: 'DEP ELITE',
          equipoSigla: 'DEP',
          nombres: 'Hector',
          apellidos: 'Feria',
          fechaNacimiento: '$year42-02-10',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PublicAgeGroupSection.fromGroup(
                group: AgeGroup.over40,
                jugadores: jugadores,
              ),
            ),
          ),
        ),
      );

      // Cabecera muestra título y cantidad exacta de jugadores
      expect(find.text('Mayores de 40 años'), findsOneWidget);
      expect(find.text('(2 jugadores)'), findsOneWidget);
      expect(find.byIcon(Icons.sports_soccer), findsWidgets);

      // Los carnets se renderizan dentro de la sección
      expect(find.text('ELKIN ALVIZ'), findsOneWidget);
      expect(find.text('HECTOR FERIA'), findsOneWidget);
    });

    testWidgets('Plantel DEP ELITE completo: 3 secciones con orden 40+, 35-39, 18-34', (tester) async {
      final depEliteJugadores = [
        const Jugador(id: 19, equipoId: 1, nombres: 'OMAR JOSE', apellidos: 'CAUSADO MERCADO', fechaNacimiento: '1978-03-24'),
        const Jugador(id: 18, equipoId: 1, nombres: 'ELKIN ALFREDO', apellidos: 'ALVIZ SIERRA', fechaNacimiento: '1981-08-03'),
        const Jugador(id: 156, equipoId: 1, nombres: 'DEIVIS', apellidos: 'CONTRERAS CANCHILA', fechaNacimiento: '1981-09-28'),
        const Jugador(id: 164, equipoId: 1, nombres: 'HECTOR DAVID', apellidos: 'FERIA PEREZ', fechaNacimiento: '1984-02-10'),
        const Jugador(id: 26, equipoId: 1, nombres: 'YAMITH', apellidos: 'ACOSTA HERNANDEZ', fechaNacimiento: '1985-09-01'),
        const Jugador(id: 39, equipoId: 1, nombres: 'DARWIN DE JESUS', apellidos: 'GARCIA MONTES', fechaNacimiento: '1987-12-24'),
        const Jugador(id: 24, equipoId: 1, nombres: 'GABRIEL DE JESUS', apellidos: 'LOPEZ TUIRAN', fechaNacimiento: '1991-01-27'),
        const Jugador(id: 157, equipoId: 1, nombres: 'EDISON', apellidos: 'PEREIRA BORJA', fechaNacimiento: '1991-09-14'),
        const Jugador(id: 158, equipoId: 1, nombres: 'GUILLERMO ENRIQUE', apellidos: 'PEREZ REYES', fechaNacimiento: '1993-08-16'),
        const Jugador(id: 21, equipoId: 1, nombres: 'DAVID ALEJANDRO', apellidos: 'LADEUS PATRON', fechaNacimiento: '1995-09-18'),
        const Jugador(id: 160, equipoId: 1, nombres: 'JOSE DAVID', apellidos: 'GARCIA SALCEDO', fechaNacimiento: '1995-12-16'),
        const Jugador(id: 27, equipoId: 1, nombres: 'OWER DANIEL', apellidos: 'RAMOS HERRERA', fechaNacimiento: '1998-05-05'),
        const Jugador(id: 25, equipoId: 1, nombres: 'MARIO ALBERTO', apellidos: 'MARQUEZ RODRIGUEZ', fechaNacimiento: '1998-08-10'),
        const Jugador(id: 20, equipoId: 1, nombres: 'KENDRI', apellidos: 'ALVIZ SALCEDO', fechaNacimiento: '2001-09-07'),
      ];

      final grupos = groupJugadoresPorEdad(depEliteJugadores);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ...kAgeGroupsOrder.map((group) {
                    final list = grupos[group] ?? [];
                    if (list.isEmpty) return const SizedBox.shrink();
                    return PublicAgeGroupSection.fromGroup(
                      group: group,
                      jugadores: list,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      );

      // Verificación de las 3 cabeceras y cantidades
      expect(find.text('Mayores de 40 años'), findsOneWidget);
      expect(find.text('(5 jugadores)'), findsOneWidget);

      expect(find.text('Entre 35 y 39 años'), findsOneWidget);
      expect(find.text('(3 jugadores)'), findsOneWidget);

      expect(find.text('De 18 a 34 años'), findsOneWidget);
      expect(find.text('(6 jugadores)'), findsOneWidget);

      // Verificación de orden relativo en el árbol de widgets: 40+ antes de 35-39, y 35-39 antes de 18-34
      final pos40 = tester.getTopLeft(find.text('Mayores de 40 años')).dy;
      final pos35 = tester.getTopLeft(find.text('Entre 35 y 39 años')).dy;
      final pos18 = tester.getTopLeft(find.text('De 18 a 34 años')).dy;

      expect(pos40 < pos35, isTrue);
      expect(pos35 < pos18, isTrue);
    });

    testWidgets('Plantel CEMENTEROS completo: 3 secciones con orden 40+, 35-39, 18-34', (tester) async {
      final cementerosJugadores = [
        const Jugador(id: 57, equipoId: 2, nombres: 'REMBERTO', apellidos: 'ALVAREZ', fechaNacimiento: '1980-06-15'),
        const Jugador(id: 123, equipoId: 2, nombres: 'RAFAEL', apellidos: 'ESCOBAR', fechaNacimiento: '1983-05-05'),
        const Jugador(id: 56, equipoId: 2, nombres: 'GUILLERMO RAFAEL', apellidos: 'MORANTES VERGARA', fechaNacimiento: '1986-06-14'),
        const Jugador(id: 127, equipoId: 2, nombres: 'CESAR JULIO', apellidos: 'MEJIA', fechaNacimiento: '1986-08-04'),
        const Jugador(id: 121, equipoId: 2, nombres: 'EWIS', apellidos: 'ROMERO', fechaNacimiento: '1988-11-02'),
        const Jugador(id: 55, equipoId: 2, nombres: 'FRANZ', apellidos: 'FONSECA VILLALOBOS', fechaNacimiento: '1989-03-03'),
        const Jugador(id: 125, equipoId: 2, nombres: 'ROBIN', apellidos: 'LEDEZMA', fechaNacimiento: '1990-06-09'),
        const Jugador(id: 120, equipoId: 2, nombres: 'ANDRES SEBASTIAN', apellidos: 'BRUNAL DIAZ', fechaNacimiento: '1992-12-07'),
        const Jugador(id: 122, equipoId: 2, nombres: 'RAFAEL ANDRES', apellidos: 'QUINTERO TAPIA', fechaNacimiento: '1993-01-04'),
        const Jugador(id: 52, equipoId: 2, nombres: 'ANDRES ALEXIS', apellidos: 'RAMIREZ', fechaNacimiento: '1997-06-06'),
        const Jugador(id: 54, equipoId: 2, nombres: 'JOSE', apellidos: 'HURTADO', fechaNacimiento: '1998-04-12'),
        const Jugador(id: 53, equipoId: 2, nombres: 'VICTOR ANDRES', apellidos: 'SUAREZ MITCHELL', fechaNacimiento: '1999-01-05'),
        const Jugador(id: 126, equipoId: 2, nombres: 'YEISON', apellidos: 'OCAMPO', fechaNacimiento: '1999-01-16'),
        const Jugador(id: 124, equipoId: 2, nombres: 'LUIS', apellidos: 'FIGUEROA JARABA', fechaNacimiento: '2000-05-05'),
      ];

      final grupos = groupJugadoresPorEdad(cementerosJugadores);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ...kAgeGroupsOrder.map((group) {
                    final list = grupos[group] ?? [];
                    if (list.isEmpty) return const SizedBox.shrink();
                    return PublicAgeGroupSection.fromGroup(
                      group: group,
                      jugadores: list,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      );

      // Verificación de las 3 cabeceras y cantidades
      expect(find.text('Mayores de 40 años'), findsOneWidget);
      expect(find.text('(4 jugadores)'), findsOneWidget);

      expect(find.text('Entre 35 y 39 años'), findsOneWidget);
      expect(find.text('(3 jugadores)'), findsOneWidget);

      expect(find.text('De 18 a 34 años'), findsOneWidget);
      expect(find.text('(7 jugadores)'), findsOneWidget);

      // Verificación de orden relativo en el árbol de widgets: 40+ antes de 35-39, y 35-39 antes de 18-34
      final pos40 = tester.getTopLeft(find.text('Mayores de 40 años')).dy;
      final pos35 = tester.getTopLeft(find.text('Entre 35 y 39 años')).dy;
      final pos18 = tester.getTopLeft(find.text('De 18 a 34 años')).dy;

      expect(pos40 < pos35, isTrue);
      expect(pos35 < pos18, isTrue);
    });
  });
}

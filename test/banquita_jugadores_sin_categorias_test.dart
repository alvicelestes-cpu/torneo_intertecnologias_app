import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_intertecnologias_app/core/utils/player_sort_utils.dart';
import 'package:torneo_intertecnologias_app/jugadores_equipo_page.dart';
import 'package:torneo_intertecnologias_app/jugadores_page.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';
import 'package:torneo_intertecnologias_app/models/equipo.dart';
import 'package:torneo_intertecnologias_app/models/goleador.dart';
import 'package:torneo_intertecnologias_app/models/jugador.dart';
import 'package:torneo_intertecnologias_app/models/torneo_model.dart';
import 'package:torneo_intertecnologias_app/services/equipos_service.dart';
import 'package:torneo_intertecnologias_app/services/jugadores_service.dart';
import 'package:torneo_intertecnologias_app/services/torneo_service.dart';
import 'package:torneo_intertecnologias_app/widgets/public_age_group_section.dart';
import 'package:torneo_intertecnologias_app/widgets/public_player_card.dart';

class FakeEquiposService extends EquiposService {
  final List<Jugador> jugadores;
  final List<Equipo> equipos;

  FakeEquiposService({required this.jugadores, required this.equipos});

  @override
  Future<List<Jugador>> getJugadoresEquipo(
    int equipoId, {
    String? token,
    int? campeonatoId,
    int? torneoId,
  }) async {
    return jugadores;
  }

  @override
  Future<List<Equipo>> getEquipos({
    String? token,
    int? campeonatoId,
    int? torneoId,
  }) async {
    return equipos;
  }
}

class FakeTorneoService extends TorneoService {
  @override
  Future<List<Goleador>> getGoleadores({
    String? token,
    int? campeonatoId,
    int? torneoId,
    bool cargarFotos = false,
  }) async {
    return [];
  }
}

class FakeJugadoresService extends JugadoresService {
  final List<Jugador> jugadores;

  FakeJugadoresService({required this.jugadores});

  @override
  Future<List<Jugador>> getJugadores({
    String? token,
    int? campeonatoId,
    int? torneoId,
  }) async {
    return jugadores;
  }

  @override
  Future<Jugador> getJugadorById(int id, {String? token, int? campeonatoId, int? torneoId}) async {
    return jugadores.firstWhere((j) => j.id == id);
  }
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final jugadoresBanquita = [
    const Jugador(
      id: 190,
      equipoId: 31,
      equipoNombre: 'Amigos del fútbol',
      equipoSigla: 'ADF',
      equipoColor: '#0d6efd',
      nombres: 'Mario alberto',
      apellidos: 'marquez Rodríguez',
      numeroCamiseta: 7,
      documento: '1193237398',
      fechaNacimiento: '1998-08-18', // 28 años
      fotoJugador: '/uploads/jugadores/9b47e9f9f93e40468c371a38b8f7a9b1.jpg',
      estado: 'VALIDADO',
      goles: 0,
      amarillas: 0,
      rojas: 0,
    ),
    const Jugador(
      id: 188,
      equipoId: 31,
      equipoNombre: 'Amigos del fútbol',
      equipoSigla: 'ADF',
      equipoColor: '#0d6efd',
      nombres: 'Hernán José',
      apellidos: 'pestana perez',
      numeroCamiseta: 15,
      documento: '1102862856',
      fechaNacimiento: '1994-09-18', // 32 años
      fotoJugador: '/uploads/jugadores/c954b9990601493e8890d2ea5c35c961.jpg',
      estado: 'VALIDADO',
      goles: 2,
      amarillas: 1,
      rojas: 0,
    ),
    const Jugador(
      id: 189,
      equipoId: 31,
      equipoNombre: 'Amigos del fútbol',
      equipoSigla: 'ADF',
      equipoColor: '#0d6efd',
      nombres: 'NEDER ENRIQUE',
      apellidos: 'LEON OLIVERO',
      numeroCamiseta: 17,
      documento: '1047464215',
      fechaNacimiento: '1993-09-16', // 33 años
      fotoJugador: '/uploads/jugadores/86b02e8159384158aef6777da152b831.jpg',
      estado: 'VALIDADO',
      goles: 1,
      amarillas: 0,
      rojas: 0,
    ),
  ];

  final equipoBanquita = const Equipo(
    id: 31,
    nombre: 'Amigos del fútbol',
    sigla: 'ADF',
    colorPrincipal: '#0d6efd',
  );

  final jugadoresIntertecnologias = [
    const Jugador(
      id: 1,
      equipoId: 10,
      equipoNombre: 'TIENDA RACING FC',
      nombres: 'Carlos',
      apellidos: 'Veterano',
      numeroCamiseta: 10,
      fechaNacimiento: '1980-01-01', // >= 40 años
      estado: 'VALIDADO',
    ),
    const Jugador(
      id: 2,
      equipoId: 10,
      equipoNombre: 'TIENDA RACING FC',
      nombres: 'Andrés',
      apellidos: 'Maduro',
      numeroCamiseta: 8,
      fechaNacimiento: '1988-05-10', // 35 a 39 años
      estado: 'VALIDADO',
    ),
    const Jugador(
      id: 3,
      equipoId: 10,
      equipoNombre: 'TIENDA RACING FC',
      nombres: 'Juan',
      apellidos: 'Joven',
      numeroCamiseta: 11,
      fechaNacimiento: '2000-03-20', // 18 a 34 años
      estado: 'VALIDADO',
    ),
  ];

  final equipoIntertecnologias = const Equipo(
    id: 10,
    nombre: 'TIENDA RACING FC',
    sigla: 'TRF',
    colorPrincipal: '#0D233A',
  );

  group('1. Detección y Aislamiento Multitorneo de Categorías de Edad', () {
    test('Únicamente Torneo Banquita ID 2 y slug exacto torneo-demo NO tienen categorías de edad', () {
      expect(torneoTieneCategoriasEdad(id: 2), isFalse);
      expect(torneoTieneCategoriasEdad(slug: 'torneo-demo'), isFalse);
      expect(torneoTieneCategoriasEdad(id: 2, slug: 'cualquier-slug'), isFalse);
      expect(torneoTieneCategoriasEdad(slug: 'TORNEO-DEMO '), isFalse);
    });

    test('Torneo Intertecnologías ID 1 e intertecnologias SÍ tienen categorías de edad', () {
      expect(torneoTieneCategoriasEdad(id: 1), isTrue);
      expect(torneoTieneCategoriasEdad(slug: 'intertecnologias'), isTrue);
      expect(torneoTieneCategoriasEdad(slug: 'torneo-intertecnologias-2026'), isTrue);
      expect(torneoTieneCategoriasEdad(nombre: 'Torneo Intertecnologías 2026'), isTrue);
      expect(torneoTieneCategoriasEdad(), isTrue); // Fallback por defecto seguro
    });

    test('Torneo hipotético futuro con palabra "banquita" en nombre o slug conserva categorías de edad (TRUE)', () {
      // Un torneo distinto (ej. id 99, slug "copa-banquitera", nombre "Torneo Banquita Futuro")
      // NO debe heredar automáticamente la desactivación de categorías
      const idHipotetico = 99;
      const slugHipotetico = 'copa-banquitera';
      const nombreHipotetico = 'Torneo Banquita Futuro';

      expect(
        torneoTieneCategoriasEdad(
          id: idHipotetico,
          slug: slugHipotetico,
          nombre: nombreHipotetico,
        ),
        isTrue,
      );

      // Verificación individual de slug y nombre futuros
      expect(torneoTieneCategoriasEdad(slug: 'torneo-banquitas-los-altos-2026'), isTrue);
      expect(torneoTieneCategoriasEdad(nombre: 'Torneo Banquita Los Altos'), isTrue);

      // Verificación en modelo TorneoModel
      final tHipotetico = TorneoModel(
        id: idHipotetico,
        organizacionId: 1,
        organizacionNombre: 'Organización Nueva',
        nombre: nombreHipotetico,
        slug: slugHipotetico,
      );
      expect(tHipotetico.tieneCategoriasEdad, isTrue);

      // Verificación en modelo Campeonato
      const cHipotetico = Campeonato(
        id: idHipotetico,
        nombre: nombreHipotetico,
        slug: slugHipotetico,
      );
      expect(cHipotetico.tieneCategoriasEdad, isTrue);
    });

    test('TorneoModel y Campeonato exponen tieneCategoriasEdad de forma coherente', () {
      final t1 = TorneoModel.defaults();
      expect(t1.id, equals(1));
      expect(t1.tieneCategoriasEdad, isTrue);

      final t2 = TorneoModel(
        id: 2,
        organizacionId: 1,
        organizacionNombre: 'Los Altos',
        nombre: 'Torneo Banquita Los Altos',
        slug: 'torneo-demo',
      );
      expect(t2.tieneCategoriasEdad, isFalse);

      const c1 = Campeonato(id: 1, nombre: 'Intertecnologías', slug: 'intertecnologias');
      expect(c1.tieneCategoriasEdad, isTrue);

      const c2 = Campeonato(id: 2, nombre: 'Banquita', slug: 'torneo-demo');
      expect(c2.tieneCategoriasEdad, isFalse);
    });


    test('sortJugadoresSinCategorias ordena por número de camiseta ascendente', () {
      final ordenados = sortJugadoresSinCategorias(jugadoresBanquita);
      expect(ordenados.map((j) => j.numeroCamiseta).toList(), equals([7, 15, 17]));
      expect(ordenados.first.nombres, equals('Mario alberto'));
      expect(ordenados.last.nombres, equals('NEDER ENRIQUE'));
    });
  });

  group('2. Torneo Banquita ID 2 en JugadoresEquipoPage (Sin Categorías)', () {
    testWidgets(
        'Banquita ID 2: NO renderiza "De 18 a 34 años", NO muestra encabezados de rango, muestra todos los jugadores y sus edades',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: JugadoresEquipoPage(
            equipoId: 31,
            equipoNombre: 'Amigos del fútbol',
            torneoId: 2,
            tieneCategoriasEdad: false,
            equiposService: FakeEquiposService(
              jugadores: jugadoresBanquita,
              equipos: [equipoBanquita],
            ),
            jugadoresService: FakeJugadoresService(jugadores: jugadoresBanquita),
            torneoService: FakeTorneoService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. NO debe renderizar bloques o encabezados por rango de edad
      expect(find.text('De 18 a 34 años'), findsNothing);
      expect(find.text('Entre 35 y 39 años'), findsNothing);
      expect(find.text('Mayores de 40 años'), findsNothing);
      expect(find.text('40 años o más'), findsNothing);
      expect(find.text('Edad no disponible'), findsNothing);
      expect(find.byType(PublicAgeGroupSection), findsNothing);

      // 2. Debe renderizar la cuadrícula normal de jugadores
      expect(find.byType(PublicPlayersGrid), findsOneWidget);
      expect(find.byType(PublicPlayerCard), findsNWidgets(3));

      // 3. Verifica datos de cada jugador en sus tarjetas
      // Jugador Mario Alberto (#7)
      expect(find.text('MARIO ALBERTO MARQUEZ RODRÍGUEZ'), findsOneWidget);
      expect(find.text('#7'), findsOneWidget);

      // Jugador Hernán José (#15)
      expect(find.text('HERNÁN JOSÉ PESTANA PEREZ'), findsOneWidget);
      expect(find.text('#15'), findsOneWidget);

      // Jugador Neder Enrique (#17)
      expect(find.text('NEDER ENRIQUE LEON OLIVERO'), findsOneWidget);
      expect(find.text('#17'), findsOneWidget);

      // Edades individuales visibles y calculadas
      expect(find.text('EDAD'), findsNWidgets(3));
      expect(find.text('NACIMIENTO'), findsNWidgets(3));

      // Botones "Ver ficha" presentes en cada tarjeta
      expect(find.text('Ver ficha'), findsNWidgets(3));
    });
  });

  group('3. Torneo Intertecnologías ID 1 en JugadoresEquipoPage (Conserva Categorías)', () {
    testWidgets(
        'Intertecnologías ID 1: Conserva categorías de edad y encabezados por rango',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: JugadoresEquipoPage(
            equipoId: 10,
            equipoNombre: 'TIENDA RACING FC',
            torneoId: 1,
            tieneCategoriasEdad: true,
            equiposService: FakeEquiposService(
              jugadores: jugadoresIntertecnologias,
              equipos: [equipoIntertecnologias],
            ),
            jugadoresService: FakeJugadoresService(jugadores: jugadoresIntertecnologias),
            torneoService: FakeTorneoService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // En Torneo ID 1 se deben conservar los encabezados de edad
      expect(find.byType(PublicAgeGroupSection), findsNWidgets(3));
      expect(find.text('Mayores de 40 años'), findsOneWidget);
      expect(find.text('Entre 35 y 39 años'), findsOneWidget);
      expect(find.text('De 18 a 34 años'), findsOneWidget);

      // Las tarjetas de jugadores se renderizan dentro de sus secciones
      expect(find.byType(PublicPlayerCard), findsNWidgets(3));
      expect(find.text('CARLOS VETERANO'), findsOneWidget);
      expect(find.text('ANDRÉS MADURO'), findsOneWidget);
      expect(find.text('JUAN JOVEN'), findsOneWidget);
    });
  });

  group('4. Responsividad y ausencia de Overflows', () {
    testWidgets('Escritorio (1280x800): Renderiza sin overflow en Banquita ID 2',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: JugadoresEquipoPage(
            equipoId: 31,
            equipoNombre: 'Amigos del fútbol',
            torneoId: 2,
            tieneCategoriasEdad: false,
            equiposService: FakeEquiposService(
              jugadores: jugadoresBanquita,
              equipos: [equipoBanquita],
            ),
            jugadoresService: FakeJugadoresService(jugadores: jugadoresBanquita),
            torneoService: FakeTorneoService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PublicPlayersGrid), findsOneWidget);
    });

    testWidgets('Móvil (375x667): Renderiza sin overflow en Banquita ID 2',
        (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: JugadoresEquipoPage(
            equipoId: 31,
            equipoNombre: 'Amigos del fútbol',
            torneoId: 2,
            tieneCategoriasEdad: false,
            equiposService: FakeEquiposService(
              jugadores: jugadoresBanquita,
              equipos: [equipoBanquita],
            ),
            jugadoresService: FakeJugadoresService(jugadores: jugadoresBanquita),
            torneoService: FakeTorneoService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PublicPlayersGrid), findsOneWidget);

    });
  });

  group('5. JugadoresPage general respeta torneo sin categorías', () {
    testWidgets('JugadoresPage general en Banquita ID 2 no muestra encabezados de edad',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: JugadoresPage(
            torneoId: 2,
            tieneCategoriasEdad: false,
            jugadoresService: FakeJugadoresService(jugadores: jugadoresBanquita),
            equiposService: FakeEquiposService(
              jugadores: jugadoresBanquita,
              equipos: [equipoBanquita],
            ),
            torneoService: FakeTorneoService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('De 18 a 34 años'), findsNothing);
      expect(find.text('Mayores de 40 años'), findsNothing);
      expect(find.byType(PublicAgeGroupSection), findsNothing);
      expect(find.byType(PublicPlayersGrid), findsOneWidget);
      expect(find.byType(PublicPlayerCard), findsNWidgets(3));
    });
  });
}

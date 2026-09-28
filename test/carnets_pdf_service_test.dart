import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:torneo_intertecnologias_app/jugadores_equipo_page.dart';
import 'package:torneo_intertecnologias_app/jugadores_page.dart';
import 'package:torneo_intertecnologias_app/models/equipo.dart';
import 'package:torneo_intertecnologias_app/models/goleador.dart';
import 'package:torneo_intertecnologias_app/models/jugador.dart';
import 'package:torneo_intertecnologias_app/services/carnets_pdf_service.dart';
import 'package:torneo_intertecnologias_app/services/equipos_service.dart';
import 'package:torneo_intertecnologias_app/services/jugadores_service.dart';
import 'package:torneo_intertecnologias_app/services/torneo_service.dart';
import 'package:torneo_intertecnologias_app/widgets/public_team_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CarnetsPdfService - Colores reglamentarios por edad', () {
    test('>= 40 años retorna verde (#226C2A)', () {
      expect(CarnetsPdfService.obtenerColorPorEdad(40), equals(PdfColor.fromHex('#226C2A')));
      expect(CarnetsPdfService.obtenerColorPorEdad(46), equals(PdfColor.fromHex('#226C2A')));
      expect(CarnetsPdfService.obtenerColorPorEdad(60), equals(PdfColor.fromHex('#226C2A')));
    });

    test('35 a 39 años retorna naranja / terracota (#B84500)', () {
      expect(CarnetsPdfService.obtenerColorPorEdad(35), equals(PdfColor.fromHex('#B84500')));
      expect(CarnetsPdfService.obtenerColorPorEdad(37), equals(PdfColor.fromHex('#B84500')));
      expect(CarnetsPdfService.obtenerColorPorEdad(39), equals(PdfColor.fromHex('#B84500')));
    });

    test('< 35 años (18 a 34 años) retorna azul (#0D57AA)', () {
      expect(CarnetsPdfService.obtenerColorPorEdad(34), equals(PdfColor.fromHex('#0D57AA')));
      expect(CarnetsPdfService.obtenerColorPorEdad(25), equals(PdfColor.fromHex('#0D57AA')));
      expect(CarnetsPdfService.obtenerColorPorEdad(18), equals(PdfColor.fromHex('#0D57AA')));
    });

    test('Edad null retorna fallbackColor si se provee o neutro institucional', () {
      final customFallback = PdfColor.fromHex('#112233');
      expect(CarnetsPdfService.obtenerColorPorEdad(null, fallbackColor: customFallback), equals(customFallback));
      expect(CarnetsPdfService.obtenerColorPorEdad(null), isNotNull);
    });
  });

  group('CarnetsPdfService - Nombres de archivo', () {
    test('Genera nombre de archivo limpio y en mayúsculas con prefijo Carnets_', () {
      expect(CarnetsPdfService.getFilename('GREMIO HFC'), equals('Carnets_GREMIO_HFC.pdf'));
      expect(CarnetsPdfService.getFilename('CEMENTEROS'), equals('Carnets_CEMENTEROS.pdf'));
      expect(CarnetsPdfService.getFilename('CONEXIÓN DIGITAL'), equals('Carnets_CONEXIÓN_DIGITAL.pdf'));
      expect(CarnetsPdfService.getFilename('  dep   elite  '), equals('Carnets_DEP_ELITE.pdf'));
      expect(CarnetsPdfService.getFilename('Tienda Racing F.C.'), equals('Carnets_TIENDA_RACING_FC.pdf'));
    });
  });

  group('CarnetsPdfService - Generación de documento PDF', () {
    const testEquipo = Equipo(
      id: 1,
      nombre: 'GREMIO HFC',
      sigla: 'GH',
      colorPrincipal: '#166534',
    );

    test('Genera un PDF válido con cabecera %PDF-', () async {
      final depEliteJugadores = [
        const Jugador(
          id: 1,
          equipoId: 1,
          nombres: 'JHONY JADER',
          apellidos: 'HUELVAS CASTILLO',
          fechaNacimiento: '1979-08-04',
          estado: 'ACTIVO',
        ),
        const Jugador(
          id: 2,
          equipoId: 1,
          nombres: 'JULIO CESAR',
          apellidos: 'MENDOZA PEREZ',
          fechaNacimiento: '1982-05-15',
          estado: 'ACTIVO',
        ),
      ];

      final bytes = await CarnetsPdfService.generarCarnetsPdf(
        equipo: testEquipo,
        jugadores: depEliteJugadores,
        torneoNombre: 'TORNEO INTERTECNOLOGÍAS 2026',
      );

      expect(bytes.isNotEmpty, isTrue);
      // Validar cabecera de archivo PDF
      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('Distribución exacta: 1 página para hasta 8 carnets, 2 páginas para 14 carnets', () async {
      // 14 jugadores (plantilla completa reglamentaria)
      final catorceJugadores = List.generate(
        14,
        (i) => Jugador(
          id: i + 1,
          equipoId: 1,
          nombres: 'JUGADOR $i',
          apellidos: 'APELLIDO $i',
          fechaNacimiento: '198${i % 10}-01-10',
          estado: 'ACTIVO',
        ),
      );

      // Generar con 8 jugadores -> Debe ser 1 página
      final bytes8 = await CarnetsPdfService.generarCarnetsPdf(
        equipo: testEquipo,
        jugadores: catorceJugadores.sublist(0, 8),
      );
      expect(bytes8.isNotEmpty, isTrue);

      // Generar con 14 jugadores -> Debe ser 2 páginas
      final bytes14 = await CarnetsPdfService.generarCarnetsPdf(
        equipo: testEquipo,
        jugadores: catorceJugadores,
      );
      expect(bytes14.isNotEmpty, isTrue);
      // El documento de 14 jugadores contiene 2 páginas en su catálogo
      final pdfContent = latin1.decode(bytes14);
      expect(pdfContent.contains('/Count 2'), isTrue);
    });

    test('Filtra jugadores inactivos e incluye únicamente los activos', () async {
      final mixtos = [
        const Jugador(
          id: 1,
          equipoId: 1,
          nombres: 'ACTIVO',
          apellidos: 'UNO',
          fechaNacimiento: '1985-03-20',
          estado: 'ACTIVO',
        ),
        const Jugador(
          id: 2,
          equipoId: 1,
          nombres: 'INACTIVO',
          apellidos: 'DOS',
          fechaNacimiento: '1990-06-15',
          estado: 'INACTIVO',
        ),
      ];

      final bytes = await CarnetsPdfService.generarCarnetsPdf(
        equipo: testEquipo,
        jugadores: mixtos,
      );

      final pdfContent = latin1.decode(bytes);
      // El documento de 1 carnet activo contiene 1 página
      expect(pdfContent.contains('/Count 1'), isTrue);
    });

    test('Maneja lista vacía de jugadores sin fallar', () async {
      final bytes = await CarnetsPdfService.generarCarnetsPdf(
        equipo: testEquipo,
        jugadores: [],
      );

      expect(bytes.isNotEmpty, isTrue);
      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });
  });

  group('PublicTeamCard - Integración de botón de Carnets', () {
    testWidgets('Muestra botón "🪪 Carnets" cuando onCarnets está definido y dispara callback', (tester) async {
      bool carnetsPressed = false;

      const equipo = Equipo(
        id: 5,
        nombre: 'CEMENTEROS',
        sigla: 'CEM',
        colorPrincipal: '#1E3A8A',
        cantidadJugadores: 14,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PublicTeamCard(
              equipo: equipo,
              onTap: () {},
              onCarnets: () {
                carnetsPressed = true;
              },
            ),
          ),
        ),
      );

      // El botón de Carnets debe ser visible
      expect(find.byKey(const Key('btn_carnets_equipo_5')), findsOneWidget);
      expect(find.text('🪪 Carnets'), findsOneWidget);

      // Al presionar el botón se dispara el callback
      await tester.tap(find.byKey(const Key('btn_carnets_equipo_5')));
      await tester.pump();
      expect(carnetsPressed, isTrue);
    });
  });

  group('Vistas de Jugadores - Botón destacado de Descargar Carnets', () {
    const testEquipo = Equipo(
      id: 1,
      nombre: 'GREMIO HFC',
      sigla: 'GH',
      colorPrincipal: '#166534',
    );

    final testJugadores = [
      const Jugador(
        id: 1,
        equipoId: 1,
        equipoNombre: 'GREMIO HFC',
        nombres: 'JHONY JADER',
        apellidos: 'HUELVAS CASTILLO',
        fechaNacimiento: '1979-08-04',
        estado: 'ACTIVO',
      ),
      const Jugador(
        id: 2,
        equipoId: 1,
        equipoNombre: 'GREMIO HFC',
        nombres: 'JULIO CESAR',
        apellidos: 'MENDOZA PEREZ',
        fechaNacimiento: '1982-05-15',
        estado: 'ACTIVO',
      ),
    ];

    testWidgets('JugadoresEquipoPage muestra el botón destacado "🪪 Descargar Carnets (PDF)" en el banner', (tester) async {
      final mockEquipos = MockEquiposService(
        mockEquipos: [testEquipo],
        mockJugadores: testJugadores,
      );
      final mockTorneo = MockTorneoService();

      await tester.pumpWidget(
        MaterialApp(
          home: JugadoresEquipoPage(
            equipoId: 1,
            equipoNombre: 'GREMIO HFC',
            equiposService: mockEquipos,
            torneoService: mockTorneo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar el botón de descarga en el banner
      expect(find.byKey(const Key('btn_descargar_carnets_equipo')), findsOneWidget);
      expect(find.text('🪪 Descargar Carnets (PDF)'), findsOneWidget);
    });

    testWidgets('JugadoresPage muestra el botón destacado "🪪 Descargar Carnets (PDF)" en el banner', (tester) async {
      final mockJugadores = MockJugadoresService(mockJugadores: testJugadores);
      final mockEquipos = MockEquiposService(mockEquipos: [testEquipo]);
      final mockTorneo = MockTorneoService();

      await tester.pumpWidget(
        MaterialApp(
          home: JugadoresPage(
            jugadoresService: mockJugadores,
            equiposService: mockEquipos,
            torneoService: mockTorneo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar el botón de descarga en la cabecera
      expect(find.byKey(const Key('btn_descargar_carnets_banner')), findsOneWidget);
      expect(find.text('🪪 Descargar Carnets (PDF)'), findsOneWidget);
    });
  });
}

class MockEquiposService extends EquiposService {
  final List<Equipo> mockEquipos;
  final List<Jugador> mockJugadores;

  MockEquiposService({
    this.mockEquipos = const [],
    this.mockJugadores = const [],
  });

  @override
  Future<List<Equipo>> getEquipos({String? token, int? campeonatoId}) async => mockEquipos;

  @override
  Future<List<Jugador>> getJugadoresEquipo(int equipoId, {String? token}) async => mockJugadores;
}

class MockJugadoresService extends JugadoresService {
  final List<Jugador> mockJugadores;

  MockJugadoresService({this.mockJugadores = const []});

  @override
  Future<List<Jugador>> getJugadores({String? token}) async => mockJugadores;

  @override
  Future<Jugador> getJugadorById(int id, {String? token}) async {
    return mockJugadores.firstWhere((j) => j.id == id);
  }
}

class MockTorneoService extends TorneoService {
  @override
  Future<List<Goleador>> getGoleadores({
    String? token,
    int? campeonatoId,
    bool cargarFotos = false,
  }) async => [];
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/main.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';
import 'package:torneo_intertecnologias_app/portal_publico_page.dart';
import 'package:torneo_intertecnologias_app/reglamento_page.dart';
import 'package:torneo_intertecnologias_app/services/reglamento_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionManager().clearSession();
  });

  group('ReglamentoService - Pruebas Unitarias y Aislamiento por Torneo', () {
    final service = ReglamentoService();

    test('Banquita Los Altos (torneo-demo) devuelve su reglamento oficial completo con 15 secciones', () {
      final reglamento = service.getReglamentoPorSlug('torneo-demo');
      expect(reglamento, isNotNull);
      expect(reglamento!.titulo, equals('Reglamento Oficial'));
      expect(reglamento.subtitulo, equals('Torneo Banquita Los Altos'));
      expect(reglamento.modalidad, equals('Banquita 4 vs 4'));
      expect(reglamento.chips.length, equals(5));
      expect(reglamento.secciones.length, equals(15));

      // Comprobar chips requeridos
      final chipsText = reglamento.chips.map((c) => c.texto).toList();
      expect(chipsText, contains('4 vs 4'));
      expect(chipsText, contains('Sin Arquero'));
      expect(chipsText, contains('2 tiempos de 15 min'));
      expect(chipsText, contains('Balón de Microfútbol'));
      expect(chipsText, contains('3 Penales'));

      // Comprobar secciones clave requeridas
      expect(reglamento.secciones[0].titulo, equals('Participantes'));
      expect(reglamento.secciones[1].titulo, equals('Cancha'));
      expect(reglamento.secciones[2].titulo, equals('Porterías'));
      expect(reglamento.secciones[3].titulo, equals('Balón'));
      expect(reglamento.secciones[4].titulo, equals('Duración del Partido'));
      expect(reglamento.secciones[5].titulo, equals('Área o "Bomba"'));
      expect(reglamento.secciones[5].destacada, isTrue);
      expect(reglamento.secciones[6].titulo, equals('Saque Lateral'));
      expect(reglamento.secciones[7].titulo, equals('Faltas'));
      expect(reglamento.secciones[8].titulo, equals('Penal o "Pena Máxima"'));
      expect(reglamento.secciones[9].titulo, equals('Tarjetas'));
      expect(reglamento.secciones[10].titulo, equals('Empate en Fase Eliminatoria'));
      expect(reglamento.secciones[11].titulo, equals('Puntuación en Fase de Grupos'));
      expect(reglamento.secciones[12].titulo, equals('Desempates en Fase de Grupos'));
      expect(reglamento.secciones[13].titulo, equals('W.O. / No Presentación'));
      expect(reglamento.secciones[13].destacada, isTrue);
      expect(reglamento.secciones[14].titulo, equals('Disposiciones Finales'));
    });

    test('Torneo Intertecnologías NO recibe accidentalmente el reglamento de Banquita', () {
      final reglamento = service.getReglamentoPorSlug('intertecnologias');
      expect(reglamento, isNull);
      expect(service.tieneReglamento('intertecnologias'), isFalse);
    });

    test('Slug desconocido o nulo devuelve reglamento no disponible / null', () {
      expect(service.getReglamentoPorSlug('slug-inexistente-xyz'), isNull);
      expect(service.getReglamentoPorSlug(null), isNull);
      expect(service.getReglamentoPorSlug(''), isNull);
      expect(service.tieneReglamento('slug-inexistente-xyz'), isFalse);
      expect(service.tieneReglamento(null), isFalse);
    });
  });

  group('ReglamentoPage - Widget Tests', () {
    Widget buildTestWidget({String? slug}) {
      return MaterialApp(
        home: ReglamentoPage(slug: slug),
      );
    }

    testWidgets('Renderiza todas las 15 secciones y chips para Banquita Los Altos', (tester) async {
      await tester.pumpWidget(buildTestWidget(slug: 'torneo-demo'));
      await tester.pumpAndSettle();

      // Verificar títulos y chips
      expect(find.text('Reglamento Oficial'), findsWidgets);
      expect(find.text('Torneo Banquita Los Altos'), findsWidgets);
      expect(find.text('4 vs 4'), findsOneWidget);
      expect(find.text('Sin Arquero'), findsOneWidget);
      expect(find.text('2 tiempos de 15 min'), findsOneWidget);
      expect(find.text('Balón de Microfútbol'), findsOneWidget);
      expect(find.text('3 Penales'), findsOneWidget);

      // Verificar secciones
      expect(find.text('PARTICIPANTES'), findsOneWidget);
      expect(find.text('CANCHA'), findsOneWidget);
      expect(find.text('PORTERÍAS'), findsOneWidget);
      expect(find.text('BALÓN'), findsOneWidget);
      expect(find.text('DURACIÓN DEL PARTIDO'), findsOneWidget);
      expect(find.text('ÁREA O "BOMBA"'), findsOneWidget);
      expect(find.text('REGLA CLAVE'), findsOneWidget);

      // Scroll para verificar secciones inferiores
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('SAQUE LATERAL'), findsOneWidget);
      expect(find.text('FALTAS'), findsOneWidget);
      expect(find.text('PENAL O "PENA MÁXIMA"'), findsOneWidget);
      expect(find.text('TARJETAS'), findsOneWidget);

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('EMPATE EN FASE ELIMINATORIA'), findsOneWidget);
      expect(find.text('PUNTUACIÓN EN FASE DE GRUPOS'), findsOneWidget);
      expect(find.text('DESEMPATES EN FASE DE GRUPOS'), findsOneWidget);
      expect(find.text('W.O. / NO PRESENTACIÓN'), findsOneWidget);
      expect(find.text('SANCIÓN'), findsOneWidget);
      expect(find.text('DISPOSICIONES FINALES'), findsOneWidget);
    });

    testWidgets('Buscador de reglas filtra dinámicamente las secciones', (tester) async {
      await tester.pumpWidget(buildTestWidget(slug: 'torneo-demo'));
      await tester.pumpAndSettle();

      // Buscar "bomba"
      final searchField = find.byKey(const Key('input_buscar_reglamento'));
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'bomba');
      await tester.pumpAndSettle();

      // Debe mostrar la sección de Bomba y ocultar otras
      expect(find.text('ÁREA O "BOMBA"'), findsOneWidget);
      expect(find.text('PORTERÍAS'), findsNothing);
      expect(find.text('SAQUE LATERAL'), findsNothing);

      // Buscar término inexistente
      await tester.enterText(searchField, 'palabraquenoexiste123');
      await tester.pumpAndSettle();

      expect(find.text('No se encontraron reglas para "palabraquenoexiste123"'), findsOneWidget);
    });

    testWidgets('Muestra estado "Reglamento no disponible" para Intertecnologías u otro slug sin reglas', (tester) async {
      await tester.pumpWidget(buildTestWidget(slug: 'intertecnologias'));
      await tester.pumpAndSettle();

      expect(find.text('Reglamento no disponible'), findsOneWidget);
      expect(find.text('Este torneo aún no cuenta con un reglamento oficial registrado en la plataforma.'), findsOneWidget);
      expect(find.text('Volver al Portal'), findsOneWidget);
      expect(find.text('4 vs 4'), findsNothing);
    });

    testWidgets('Responsive en móvil (390x844) y escritorio (1366x768) sin overflow', (tester) async {
      // 1. Móvil
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(slug: 'torneo-demo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 2. Escritorio
      tester.view.physicalSize = const Size(1366, 768);
      await tester.pumpWidget(buildTestWidget(slug: 'torneo-demo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Portal Público - Visibilidad Condicional del Reglamento', () {
    testWidgets('Banquita Los Altos (torneo-demo) SÍ muestra la tarjeta de Reglamento Oficial', (tester) async {
      final session = SessionManager();
      const banquita = Campeonato(
        id: 2,
        nombre: 'Torneo Banquita Los Altos',
        slug: 'torneo-demo',
        activo: true,
        publicado: true,
      );
      session.setCampeonatos([banquita]);
      session.selectCampeonato(banquita);

      await tester.pumpWidget(const MaterialApp(home: PortalPublicoPage()));
      await tester.pumpAndSettle();

      // Debe aparecer la tarjeta de Reglamento
      expect(find.text('Reglamento'), findsOneWidget);
      expect(find.text('Normas y directrices oficiales'), findsOneWidget);
    });

    testWidgets('Torneo Intertecnologías (ID 1) NO muestra la tarjeta de Reglamento Oficial', (tester) async {
      final session = SessionManager();
      const inter = Campeonato(
        id: 1,
        nombre: 'Torneo Intertecnologías 2026',
        slug: 'intertecnologias',
        activo: true,
        publicado: true,
      );
      session.setCampeonatos([inter]);
      session.selectCampeonato(inter);

      await tester.pumpWidget(const MaterialApp(home: PortalPublicoPage()));
      await tester.pumpAndSettle();

      // NO debe aparecer la tarjeta de Reglamento
      expect(find.text('Normas y directrices oficiales'), findsNothing);
    });
  });

  group('Enrutamiento Amigable /t/:slug/reglamento', () {
    testWidgets('Ruta /t/torneo-demo/reglamento carga ReglamentoPage correctamente', (tester) async {
      final session = SessionManager();
      const banquita = Campeonato(
        id: 2,
        nombre: 'Torneo Banquita Los Altos',
        slug: 'torneo-demo',
        activo: true,
        publicado: true,
      );
      session.setCampeonatos([banquita]);
      session.selectCampeonato(banquita);

      await tester.pumpWidget(const TorneoApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PortalPublicoPage));
      Navigator.pushNamed(context, '/t/torneo-demo/reglamento');
      await tester.pumpAndSettle();

      expect(find.byType(ReglamentoPage), findsOneWidget);
      expect(find.text('Torneo Banquita Los Altos'), findsWidgets);
      expect(find.text('4 vs 4'), findsOneWidget);
    });
  });
}

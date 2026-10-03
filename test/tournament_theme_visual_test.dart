import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_intertecnologias_app/core/constants/app_colors.dart';
import 'package:torneo_intertecnologias_app/core/theme/tournament_theme.dart';
import 'package:torneo_intertecnologias_app/models/equipo.dart';
import 'package:torneo_intertecnologias_app/models/jugador.dart';
import 'package:torneo_intertecnologias_app/core/session/session_manager.dart';
import 'package:torneo_intertecnologias_app/equipos_page.dart';
import 'package:torneo_intertecnologias_app/jugadores_equipo_page.dart';
import 'package:torneo_intertecnologias_app/jugador_detalle_page.dart';
import 'package:torneo_intertecnologias_app/models/campeonato.dart';
import 'package:torneo_intertecnologias_app/services/carnets_pdf_service.dart';
import 'package:torneo_intertecnologias_app/widgets/public_player_card.dart';
import 'package:torneo_intertecnologias_app/widgets/public_team_card.dart';

void main() {
  group('TournamentTheme - Visual & Chromatic Identity Tests', () {
    final now = DateTime.now();
    final fecha28 = DateTime(now.year - 28, 1, 1).toIso8601String();
    final fecha48 = DateTime(now.year - 48, 1, 1).toIso8601String();
    final fecha37 = DateTime(now.year - 37, 1, 1).toIso8601String();
    final fecha22 = DateTime(now.year - 22, 1, 1).toIso8601String();
    final fecha45 = DateTime(now.year - 45, 1, 1).toIso8601String();

    final jugador28 = Jugador(
      id: 101,
      equipoId: 31,
      nombres: 'Mario',
      apellidos: 'Barrientos',
      numeroCamiseta: 10,
      fechaNacimiento: fecha28,
      equipoNombre: 'Amigos del fútbol',
    );

    final jugador48 = Jugador(
      id: 102,
      equipoId: 31,
      nombres: 'Omar',
      apellidos: 'Perez',
      numeroCamiseta: 8,
      fechaNacimiento: fecha48,
      equipoNombre: 'Amigos del fútbol',
    );

    final jugador37 = Jugador(
      id: 103,
      equipoId: 1,
      nombres: 'Carlos',
      apellidos: 'Sanchez',
      numeroCamiseta: 7,
      fechaNacimiento: fecha37,
      equipoNombre: 'Racing FC',
    );

    final jugador22 = Jugador(
      id: 104,
      equipoId: 1,
      nombres: 'Andres',
      apellidos: 'Lopez',
      numeroCamiseta: 11,
      fechaNacimiento: fecha22,
      equipoNombre: 'Racing FC',
    );

    final jugador45 = Jugador(
      id: 105,
      equipoId: 1,
      nombres: 'Gabriel',
      apellidos: 'Garcia',
      numeroCamiseta: 9,
      fechaNacimiento: fecha45,
      equipoNombre: 'Racing FC',
    );

    // 1. Banquita 28 años usa tema Banquita
    test('1. Banquita 28 años usa tema Banquita', () {
      final theme = TournamentTheme.banquita;
      expect(theme.usaCategoriasEdad, isFalse);
      expect(theme.getPlayerCardHeaderColor(jugador28.edad), equals(const Color(0xFF064E3B)));
      expect(theme.getPlayerCardAccentColor(jugador28.edad), equals(const Color(0xFFF59E0B)));
      expect(theme.getPlayerDorsalBadgeColor(jugador28.edad), equals(const Color(0xFFF59E0B)));
      expect(theme.getPlayerDorsalTextColor(jugador28.edad), equals(Colors.white));
      expect(theme.getPlayerAgeTextColor(jugador28.edad), equals(const Color(0xFF064E3B)));
      expect(theme.getPlayerCardButtonColor(jugador28.edad), equals(const Color(0xFF047857)));
      expect(theme.getPlayerCardHeaderGradient(jugador28.edad), equals(const [Color(0xFF064E3B), Color(0xFF047857)]));
    });

    // 2. Banquita 48 años usa exactamente la misma familia cromática
    test('2. Banquita 48 años usa exactamente la misma familia cromática', () {
      final theme = TournamentTheme.banquita;
      expect(theme.getPlayerCardHeaderColor(jugador48.edad), equals(theme.getPlayerCardHeaderColor(jugador28.edad)));
      expect(theme.getPlayerCardAccentColor(jugador48.edad), equals(theme.getPlayerCardAccentColor(jugador28.edad)));
      expect(theme.getPlayerDorsalBadgeColor(jugador48.edad), equals(theme.getPlayerDorsalBadgeColor(jugador28.edad)));
      expect(theme.getPlayerDorsalTextColor(jugador48.edad), equals(theme.getPlayerDorsalTextColor(jugador28.edad)));
      expect(theme.getPlayerAgeTextColor(jugador48.edad), equals(theme.getPlayerAgeTextColor(jugador28.edad)));
      expect(theme.getPlayerCardButtonColor(jugador48.edad), equals(theme.getPlayerCardButtonColor(jugador28.edad)));
      expect(theme.getPlayerCardHeaderGradient(jugador48.edad), equals(theme.getPlayerCardHeaderGradient(jugador28.edad)));
    });

    // 3. Banquita no utiliza verde/naranja/azul por categoría
    test('3. Banquita no utiliza verde/naranja/azul por categoría', () {
      final theme = TournamentTheme.banquita;
      // Omar 48 años NO es verde (#2E7D32)
      expect(theme.getPlayerCardHeaderColor(48), isNot(equals(AppColors.carnetVerde)));
      // Carlos 37 años NO es naranja (#E65100)
      expect(theme.getPlayerCardHeaderColor(37), isNot(equals(AppColors.carnetNaranja)));
      expect(theme.getPlayerCardAccentColor(37), isNot(equals(AppColors.carnetNaranja)));
      // Mario 28 años NO es azul (#1565C0)
      expect(theme.getPlayerCardHeaderColor(28), isNot(equals(AppColors.carnetAzul)));
      expect(theme.getPlayerCardAccentColor(28), isNot(equals(AppColors.carnetAzul)));
    });

    // 4. Intertecnologías >40 continúa verde
    test('4. Intertecnologías >40 continúa verde', () {
      final theme = TournamentTheme.intertecnologias;
      expect(theme.usaCategoriasEdad, isTrue);
      expect(theme.getPlayerCardHeaderColor(jugador45.edad), equals(const Color(0xFF2E7D32)));
      expect(theme.getPlayerCardAccentColor(jugador45.edad), equals(const Color(0xFF2E7D32)));
      expect(theme.getPlayerAgeTextColor(jugador45.edad), equals(const Color(0xFF2E7D32)));
    });

    // 5. Intertecnologías 35–39 continúa naranja
    test('5. Intertecnologías 35–39 continúa naranja', () {
      final theme = TournamentTheme.intertecnologias;
      expect(theme.usaCategoriasEdad, isTrue);
      expect(theme.getPlayerCardHeaderColor(jugador37.edad), equals(const Color(0xFFE65100)));
      expect(theme.getPlayerCardAccentColor(jugador37.edad), equals(const Color(0xFFE65100)));
      expect(theme.getPlayerAgeTextColor(jugador37.edad), equals(const Color(0xFFE65100)));
    });

    // 6. Intertecnologías 18–34 continúa azul
    test('6. Intertecnologías 18–34 continúa azul', () {
      final theme = TournamentTheme.intertecnologias;
      expect(theme.usaCategoriasEdad, isTrue);
      expect(theme.getPlayerCardHeaderColor(jugador22.edad), equals(const Color(0xFF1565C0)));
      expect(theme.getPlayerCardAccentColor(jugador22.edad), equals(const Color(0xFF1565C0)));
      expect(theme.getPlayerAgeTextColor(jugador22.edad), equals(const Color(0xFF1565C0)));
    });

    // 7. Equipos Banquita usan TournamentTheme Banquita
    test('7. Equipos Banquita usan TournamentTheme Banquita', () {
      final theme = TournamentTheme.banquita;
      final amigosDelFutbol = const Equipo(
        id: 31,
        nombre: 'Amigos del fútbol',
        sigla: 'ADF',
        cantidadJugadores: 6,
      );
      final realPuertaRoja = const Equipo(
        id: 32,
        nombre: 'Real Puerta Roja',
        sigla: 'RPR',
        cantidadJugadores: 7,
      );

      // Sin color específico o default, ambos usan verde deportivo oficial de Banquita, NO azul eléctrico
      final colorAmigos = theme.getTeamColor(amigosDelFutbol);
      final colorReal = theme.getTeamColor(realPuertaRoja);
      expect(colorAmigos, equals(const Color(0xFF064E3B)));
      expect(colorReal, equals(const Color(0xFF064E3B)));
      expect(colorAmigos, isNot(equals(const Color(0xFF1976D2))));
      expect(colorReal, isNot(equals(const Color(0xFF1976D2))));
    });

    // 8. Portal torneo-demo usa tema Banquita
    test('8. Portal torneo-demo usa tema Banquita', () {
      final themeSlug = TournamentTheme.fromIdOrSlug(slug: 'torneo-demo');
      expect(themeSlug.id, equals(2));
      expect(themeSlug.type, equals(TournamentType.banquita));
      expect(themeSlug.scaffoldBackground, equals(const Color(0xFFF4F8F7)));
      expect(themeSlug.headerGradient, equals(const [
        Color(0xFF064E3B),
        Color(0xFF047857),
      ]));
    });

    // 9. Reglamento torneo-demo usa tema Banquita
    test('9. Reglamento torneo-demo usa tema Banquita', () {
      final theme = TournamentTheme.fromIdOrSlug(slug: 'torneo-demo');
      expect(theme.type, equals(TournamentType.banquita));
      expect(theme.primary, equals(const Color(0xFF064E3B)));
      expect(theme.secondary, equals(const Color(0xFF047857)));
      expect(theme.accent, equals(const Color(0xFFF59E0B)));
    });

    // 10. ID 1 permanece sin regresiones
    test('10. ID 1 permanece sin regresiones', () {
      final themeId1 = TournamentTheme.fromIdOrSlug(id: 1);
      final themeSlug1 = TournamentTheme.fromIdOrSlug(slug: 'intertecnologias');

      expect(themeId1.id, equals(1));
      expect(themeId1.type, equals(TournamentType.intertecnologias));
      expect(themeId1.usaCategoriasEdad, isTrue);
      expect(themeId1.scaffoldBackground, equals(const Color(0xFFF4F7FB)));
      expect(themeId1.headerGradient, equals(const [
        Color(0xFF0D233A),
        Color(0xFF1565C0),
        Color(0xFF1E88E5),
      ]));

      expect(themeSlug1.id, equals(1));
      expect(themeSlug1.type, equals(TournamentType.intertecnologias));
    });

    // Widget Tests: Renderizado de PublicPlayerCard en Banquita
    testWidgets('PublicPlayerCard renderiza con identidad Banquita para 28 y 48 años', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InheritedTournamentTheme(
            theme: TournamentTheme.banquita,
            child: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    height: 220,
                    width: 320,
                    child: PublicPlayerCard(jugador: jugador28),
                  ),
                  SizedBox(
                    height: 220,
                    width: 320,
                    child: PublicPlayerCard(jugador: jugador48),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ambos jugadores deben renderizar sin overflow
      expect(find.text('MARIO BARRIENTOS'), findsOneWidget);
      expect(find.text('OMAR PEREZ'), findsOneWidget);
      expect(find.text('28 años'), findsOneWidget);
      expect(find.text('48 años'), findsOneWidget);
    });

    testWidgets('PublicTeamCard renderiza con colores de Banquita', (tester) async {
      final amigosDelFutbol = const Equipo(
        id: 31,
        nombre: 'Amigos del fútbol',
        sigla: 'ADF',
        cantidadJugadores: 6,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InheritedTournamentTheme(
            theme: TournamentTheme.banquita,
            child: Scaffold(
              body: SizedBox(
                width: 300,
                child: PublicTeamCard(equipo: amigosDelFutbol),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Amigos del fútbol'), findsOneWidget);
      expect(find.text('ADF'), findsNWidgets(2)); // En avatar y en badge
      expect(find.text('Ver jugadores'), findsOneWidget);

      // El contenedor del borde superior debe ser #047857 (secondary Banquita)
      final topBarFinder = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxHeight == 5 && (w.color == const Color(0xFF047857)),
      );
      expect(topBarFinder, findsOneWidget);
    });

    test('11. Equipo con #0d6efd importado se purga a #064E3B en Banquita', () {
      final theme = TournamentTheme.banquita;
      final equipoImportado = const Equipo(
        id: 31,
        nombre: 'Amigos del fútbol',
        sigla: 'ADF',
        colorPrincipal: '#0d6efd', // Color azul eléctrico guardado por la importación
      );
      expect(theme.getTeamColor(equipoImportado), equals(const Color(0xFF064E3B)));
    });

    testWidgets('12. Omar (48) y Mario (28) en Banquita nunca contienen verde #2E7D32 ni azul #1565C0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InheritedTournamentTheme(
            theme: TournamentTheme.banquita,
            child: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    height: 220,
                    width: 320,
                    child: PublicPlayerCard(jugador: jugador48),
                  ),
                  SizedBox(
                    height: 220,
                    width: 320,
                    child: PublicPlayerCard(jugador: jugador28),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que el carnet NO utiliza color Verde (>40 #2E7D32) ni Azul (18-34 #1565C0)
      final edad48Text = tester.widget<Text>(find.text('48 años'));
      expect(edad48Text.style?.color, equals(const Color(0xFF064E3B)));
      expect(edad48Text.style?.color, isNot(equals(const Color(0xFF2E7D32))));

      final edad28Text = tester.widget<Text>(find.text('28 años'));
      expect(edad28Text.style?.color, equals(const Color(0xFF064E3B)));
      expect(edad28Text.style?.color, isNot(equals(const Color(0xFF1565C0))));

      // Verificar bordes de tarjetas: deben ser #047857 (secondary Banquita), no verde #2E7D32 ni azul #1565C0
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsNWidgets(2));
      for (final cardElem in cardFinder.evaluate()) {
        final card = cardElem.widget as Card;
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.side.color, equals(const Color(0xFF047857).withAlpha(70)));
        expect(shape.side.color, isNot(equals(const Color(0xFF2E7D32).withAlpha(70))));
        expect(shape.side.color, isNot(equals(const Color(0xFF1565C0).withAlpha(70))));
      }
    });

    testWidgets('13. EquiposPage en Banquita imprime diagnóstico y usa tema Banquita', (tester) async {
      final session = SessionManager();
      session.selectCampeonato(
        const Campeonato(
          id: 2,
          nombre: 'Torneo Banquita Los Altos',
          slug: 'torneo-demo',
          activo: true,
          publicado: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InheritedTournamentTheme(
            theme: TournamentTheme.banquita,
            child: const EquiposPage(),
          ),
        ),
      );

      await tester.pump();
      expect(TournamentTheme.banquita.id, 2);
      expect(TournamentTheme.banquita.isBanquita, isTrue);
      expect(TournamentTheme.banquita.usaCategoriasEdad, isFalse);
    });

    testWidgets('14. JugadoresEquipoPage en Banquita imprime diagnóstico y usa tema Banquita', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InheritedTournamentTheme(
            theme: TournamentTheme.banquita,
            child: const JugadoresEquipoPage(
              equipoId: 31,
              equipoNombre: 'Amigos del fútbol',
              torneoId: 2,
              tieneCategoriasEdad: false,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(JugadoresEquipoPage), findsOneWidget);
    });

    // ==========================================
    // PRUEBAS DE AISLAMIENTO FASE 6
    // ==========================================

    test('FASE 6 - ID 1: NO usa isBanquita y usaCategoriasEdad == true', () {
      final theme1 = TournamentTheme.intertecnologias;
      expect(theme1.isBanquita, isFalse);
      expect(theme1.isIntertecnologias, isTrue);
      expect(theme1.usaCategoriasEdad, isTrue);
    });

    test('FASE 6 - ID 1: Tarjetas coloreadas según categoría (45 verde, 38 naranja, 31 azul)', () {
      final theme1 = TournamentTheme.intertecnologias;
      expect(theme1.getPlayerCardHeaderColor(45), equals(const Color(0xFF2E7D32)));
      expect(theme1.getPlayerCardHeaderColor(38), equals(const Color(0xFFE65100)));
      expect(theme1.getPlayerCardHeaderColor(31), equals(const Color(0xFF1565C0)));
    });

    test('FASE 6 - ID 1: Colores propios de equipos se respetan (DEP ELITE #95e41f, CEMENTEROS #2F6B4F)', () {
      final theme1 = TournamentTheme.intertecnologias;
      final depElite = const Equipo(
        id: 1,
        campeonatoId: 1,
        nombre: 'DEP ELITE',
        sigla: 'DEP',
        colorPrincipal: '#95e41f',
        logo: '/uploads/equipos/equipo_1.png',
      );
      final cementeros = const Equipo(
        id: 2,
        campeonatoId: 1,
        nombre: 'CEMENTEROS',
        sigla: 'CEM',
        colorPrincipal: '#2F6B4F',
      );

      expect(theme1.getTeamColor(depElite), equals(const Color(0xFF95E41F)));
      expect(theme1.getTeamColor(cementeros), equals(const Color(0xFF2F6B4F)));
    });

    testWidgets('FASE 6 - ID 1: PublicTeamCard respeta color propio de DEP ELITE (#95e41f) y botón original', (tester) async {
      final depElite = const Equipo(
        id: 1,
        campeonatoId: 1,
        nombre: 'DEP ELITE',
        sigla: 'DEP',
        colorPrincipal: '#95e41f',
        cantidadJugadores: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InheritedTournamentTheme(
            theme: TournamentTheme.intertecnologias,
            child: Scaffold(
              body: SizedBox(
                width: 320,
                child: PublicTeamCard(equipo: depElite),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Borde superior debe ser #95e41f (color de DEP ELITE), NO petróleo ni turquesa
      final topBorderFinder = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxHeight == 5 && (w.color == const Color(0xFF95E41F)),
      );
      expect(topBorderFinder, findsOneWidget);
    });

    testWidgets('FASE 6 - ID 1: PublicPlayerCard para jugador 45 años tiene color verde (#2E7D32)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InheritedTournamentTheme(
            theme: TournamentTheme.intertecnologias,
            child: Scaffold(
              body: SizedBox(
                width: 320,
                height: 220,
                child: PublicPlayerCard(jugador: jugador45),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final edadText = tester.widget<Text>(find.text('45 años'));
      expect(edadText.style?.color, equals(const Color(0xFF2E7D32)));
    });

    test('FASE 6 - ID 1: Banner conserva paleta y gradiente original', () {
      final theme1 = TournamentTheme.intertecnologias;
      expect(theme1.headerGradient, equals(const [
        Color(0xFF0D233A),
        Color(0xFF1565C0),
        Color(0xFF1E88E5),
      ]));
    });

    test('FASE 6 - BANQUITA ID 2: isBanquita == true y usaCategoriasEdad == false', () {
      final theme2 = TournamentTheme.banquita;
      expect(theme2.isBanquita, isTrue);
      expect(theme2.usaCategoriasEdad, isFalse);
    });

    testWidgets('Banquita: PublicPlayerCard renderiza con gradiente verde profesional y badge dorsal ámbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InheritedTournamentTheme(
            theme: TournamentTheme.banquita,
            child: Scaffold(
              body: SizedBox(
                width: 320,
                height: 220,
                child: PublicPlayerCard(jugador: jugador28),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge dorsal #10
      expect(find.text('#10'), findsOneWidget);
      final dorsalContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('#10'),
          matching: find.byType(Container),
        ).first,
      );
      final dorsalDec = dorsalContainer.decoration as BoxDecoration;
      expect(dorsalDec.color, equals(const Color(0xFFF59E0B))); // Ámbar / Dorado

      // Header con gradiente deportivo verde [Color(0xFF064E3B), Color(0xFF047857)]
      final headerContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('MARIO BARRIENTOS'),
          matching: find.byType(Container),
        ).first,
      );
      final headerDec = headerContainer.decoration as BoxDecoration;
      final gradient = headerDec.gradient as LinearGradient;
      expect(gradient.colors, equals(const [Color(0xFF064E3B), Color(0xFF047857)]));
    });

    testWidgets('Banquita: JugadorDetallePage renderiza con tema verde y acentos dorados', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: InheritedTournamentTheme(
            theme: TournamentTheme.banquita,
            child: JugadorDetallePage(
              jugador: jugador28.toJson(),
              equipoNombre: 'Amigos del fútbol',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('MARIO BARRIENTOS'), findsOneWidget);
      expect(find.text('DORSAL / CAMISETA'), findsOneWidget);
      expect(find.text('#10'), findsOneWidget);

      // AppBar tiene fondo verde deportivo oscuro
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(const Color(0xFF064E3B)));
    });

    test('Banquita: CarnetsPdfService genera PDF con tema verde y badge dorado sin errores', () async {
      final bytes = await CarnetsPdfService.generarCarnetsPdf(
        equipo: const Equipo(id: 31, nombre: 'Amigos del fútbol', sigla: 'ADF'),
        jugadores: [jugador28, jugador48],
        torneoNombre: 'Torneo Banquita Los Altos',
        torneoId: 2,
      );

      expect(bytes.isNotEmpty, isTrue);
      final header = String.fromCharCodes(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });
  });
}

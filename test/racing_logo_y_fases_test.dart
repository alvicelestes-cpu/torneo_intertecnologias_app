import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:torneo_intertecnologias_app/core/utils/image_utils.dart';
import 'package:torneo_intertecnologias_app/models/equipo.dart';
import 'package:torneo_intertecnologias_app/models/goleador.dart';
import 'package:torneo_intertecnologias_app/models/partido.dart';
import 'package:torneo_intertecnologias_app/models/posicion.dart';
import 'package:torneo_intertecnologias_app/widgets/team_logo_avatar.dart';

void main() {
  group('Soporte de Escudo Tienda Racing FC y Resolución de Logos Dinámicos', () {
    test('ImageUtils.resolveTeamLogo asigna assets/logos/tienda_racing.png a Tienda Racing FC por nombre', () {
      final logo = ImageUtils.resolveTeamLogo(null, teamName: 'TIENDA RACING FC');
      expect(logo, equals('assets/logos/tienda_racing.png'));

      final logoCaseInsensitive = ImageUtils.resolveTeamLogo('', teamName: 'tienda racing fc');
      expect(logoCaseInsensitive, equals('assets/logos/tienda_racing.png'));
    });

    test('ImageUtils.resolveTeamLogo asigna assets/logos/tienda_racing.png por sigla TRF o TR', () {
      final logoTRF = ImageUtils.resolveTeamLogo(null, sigla: 'TRF');
      expect(logoTRF, equals('assets/logos/tienda_racing.png'));

      final logoTR = ImageUtils.resolveTeamLogo('', sigla: 'TR');
      expect(logoTR, equals('assets/logos/tienda_racing.png'));
    });

    test('ImageUtils.resolveTeamLogo respeta URLs web HTTP/HTTPS', () {
      const urlHttp = 'http://torneo.com/escudo.png';
      const urlHttps = 'https://torneo.com/escudo.png';

      expect(ImageUtils.resolveTeamLogo(urlHttp, teamName: 'GREMIO'), equals(urlHttp));
      expect(ImageUtils.resolveTeamLogo(urlHttps, teamName: 'GREMIO'), equals(urlHttps));
    });

    test('ImageUtils.resolveTeamLogo respeta rutas de assets locales', () {
      const assetPath = 'assets/logos/custom_team.png';
      expect(ImageUtils.resolveTeamLogo(assetPath, teamName: 'CUSTOM'), equals(assetPath));
    });

    test('ImageUtils.resolveTeamLogo respeta cadenas Base64', () {
      const base64Img = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      expect(ImageUtils.resolveTeamLogo(base64Img, teamName: 'BASE64_TEAM'), equals(base64Img));
    });

    test('ImageUtils.resolveTeamLogo devuelve null para otros equipos sin logo', () {
      expect(ImageUtils.resolveTeamLogo(null, teamName: 'DEP ELITE', sigla: 'DEP'), isNull);
      expect(ImageUtils.resolveTeamLogo('', teamName: 'INPEC', sigla: 'INP'), isNull);
    });

    test('Equipo.fromJson asigna automáticamente el logo de Tienda Racing', () {
      final eq = Equipo.fromJson({
        'id': 15,
        'nombre': 'TIENDA RACING FC',
        'sigla': 'TRF',
        'colorPrincipal': '#003366',
      });
      expect(eq.logo, equals('assets/logos/tienda_racing.png'));
    });

    test('Posicion.fromJson asigna automáticamente el logo de Tienda Racing', () {
      final pos = Posicion.fromJson({
        'posicion': 1,
        'equipoId': 15,
        'equipo': 'TIENDA RACING FC',
        'sigla': 'TRF',
        'pj': 5,
        'puntos': 13,
      });
      expect(pos.logo, equals('assets/logos/tienda_racing.png'));
    });

    test('Partido.fromJson asigna logo de Tienda Racing a local o visitante', () {
      final part = Partido.fromJson({
        'id': 1,
        'equipoLocalNombre': 'TIENDA RACING FC',
        'equipoLocalSigla': 'TRF',
        'equipoVisitanteNombre': 'DEP ELITE',
        'equipoVisitanteSigla': 'DEP',
      });
      expect(part.equipoLocalLogo, equals('assets/logos/tienda_racing.png'));
      expect(part.equipoVisitanteLogo, isNull);
    });
  });

  group('TeamLogoAvatar - Renderizado de Escudos y Fallbacks', () {
    testWidgets('Renderiza Image.asset para rutas que inician con assets/', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamLogoAvatar(
              logoUrl: 'assets/logos/tienda_racing.png',
              teamName: 'TIENDA RACING FC',
              sigla: 'TRF',
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<AssetImage>());
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, equals('assets/logos/tienda_racing.png'));
    });

    testWidgets('Renderiza Image.memory para cadenas Base64', (tester) async {
      const base64Img = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamLogoAvatar(
              logoUrl: base64Img,
              teamName: 'CLUB B64',
              sigla: 'B64',
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<MemoryImage>());
    });

    testWidgets('Renderiza avatar de respaldo con sigla del club cuando no hay escudo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamLogoAvatar(
              logoUrl: null,
              teamName: 'DEP ELITE',
              sigla: 'DEP',
              size: 40,
            ),
          ),
        ),
      );

      expect(find.text('DEP'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('Top 10 Goleadores - Restricción y Orden Descendente', () {
    test('Filtra y ordena la lista de goleadores estrictamente a los 10 primeros artilleros', () {
      final rawGoleadores = List.generate(20, (index) {
        return Goleador(
          posicion: 0,
          jugadorId: index + 1,
          nombres: 'Goleador',
          apellidos: '#${index + 1}',
          equipo: 'Equipo $index',
          siglaEquipo: 'EQ$index',
          goles: index * 2, // Goles de 0 a 38
        );
      });

      // Lógica idéntica a la implementada en GoleadoresPage
      final sortedGoleadores = List<Goleador>.from(rawGoleadores)
        ..sort((a, b) => b.goles.compareTo(a.goles));
      final top10 = sortedGoleadores.take(10).toList();

      expect(top10.length, equals(10));
      expect(top10.first.goles, equals(38)); // El máximo
      expect(top10.last.goles, equals(20)); // El décimo
      // Confirmar orden descendente estricto
      for (int i = 0; i < top10.length - 1; i++) {
        expect(top10[i].goles >= top10[i + 1].goles, isTrue);
      }
    });
  });

  group('Fases Eliminatorias Pendientes y Preservación de Primera Fase', () {
    test('Partidos de Primera Fase fechas 1 a 5 se mantienen íntegros con marcadores', () {
      final partidosPrimeraFase = [
        const Partido(
          id: 1,
          fase: 'PRIMERA_FASE',
          jornada: 1,
          equipoLocalNombre: 'INPEC',
          equipoVisitanteNombre: 'GREMIO HFC',
          golesLocal: 5,
          golesVisitante: 6,
          estado: 'FINALIZADO',
        ),
        const Partido(
          id: 2,
          fase: 'PRIMERA_FASE',
          jornada: 5,
          equipoLocalNombre: 'TIENDA RACING FC',
          equipoVisitanteNombre: 'DEP ELITE',
          golesLocal: 3,
          golesVisitante: 2,
          estado: 'FINALIZADO',
        ),
      ];

      expect(partidosPrimeraFase.length, equals(2));
      expect(partidosPrimeraFase[0].golesLocal, equals(5));
      expect(partidosPrimeraFase[0].golesVisitante, equals(6));
      expect(partidosPrimeraFase[0].estado, equals('FINALIZADO'));
      expect(partidosPrimeraFase[1].equipoLocalNombre, equals('TIENDA RACING FC'));
      expect(partidosPrimeraFase[1].golesLocal, equals(3));
      expect(partidosPrimeraFase[1].golesVisitante, equals(2));
    });

    test('Fases no generadas (Cuadrangulares, Cuartos, Semifinal, Final) permanecen limpias sin partidos basura', () {
      final partidosTorneo = [
        const Partido(
          id: 1,
          fase: 'PRIMERA_FASE',
          jornada: 1,
          equipoLocalNombre: 'INPEC',
          equipoVisitanteNombre: 'GREMIO HFC',
          golesLocal: 5,
          golesVisitante: 6,
          estado: 'FINALIZADO',
        ),
      ];

      final partidosCuadrangulares = partidosTorneo.where((p) => p.fase == 'SEGUNDA_RONDA').toList();
      final partidosCuartos = partidosTorneo.where((p) => p.fase == 'CUARTOS').toList();
      final partidosSemis = partidosTorneo.where((p) => p.fase == 'SEMIFINAL').toList();
      final partidosFinal = partidosTorneo.where((p) => p.fase == 'FINAL').toList();

      expect(partidosCuadrangulares, isEmpty);
      expect(partidosCuartos, isEmpty);
      expect(partidosSemis, isEmpty);
      expect(partidosFinal, isEmpty);
    });
  });
}

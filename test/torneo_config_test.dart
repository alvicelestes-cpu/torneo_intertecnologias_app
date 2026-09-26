import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_intertecnologias_app/models/torneo_model.dart';
import 'package:torneo_intertecnologias_app/services/torneo_config_service.dart';
import 'package:torneo_intertecnologias_app/configuracion_torneo_page.dart';

void main() {
  group('TorneoModel Tests', () {
    test('Valores por defecto son seguros y compatibles', () {
      final model = TorneoModel.defaults();
      expect(model.id, equals(1));
      expect(model.limiteJugadores, equals(14));
      expect(model.tienePuntoInvisible, isTrue);
      expect(model.topGoleadoresMax, equals(10));
      expect(model.activo, isTrue);
    });

    test('Serialización y deserialización JSON', () {
      final json = {
        'id': 2,
        'organizacionId': 1,
        'nombre': 'Torneo Clausura 2026',
        'slug': 'clausura-2026',
        'limiteJugadores': 18,
        'tienePuntoInvisible': false,
        'topGoleadoresMax': 15,
        'activo': true,
      };

      final model = TorneoModel.fromJson(json);
      expect(model.id, equals(2));
      expect(model.nombre, equals('Torneo Clausura 2026'));
      expect(model.limiteJugadores, equals(18));
      expect(model.tienePuntoInvisible, isFalse);
      expect(model.topGoleadoresMax, equals(15));

      final serialized = model.toJson();
      expect(serialized['limiteJugadores'], equals(18));
      expect(serialized['tienePuntoInvisible'], isFalse);
      expect(serialized['topGoleadoresMax'], equals(15));
    });

    test('copyWith preserva o actualiza campos correctamente', () {
      final original = TorneoModel.defaults();
      final updated = original.copyWith(
        limiteJugadores: 20,
        tienePuntoInvisible: false,
      );

      expect(updated.limiteJugadores, equals(20));
      expect(updated.tienePuntoInvisible, isFalse);
      expect(updated.nombre, equals(original.nombre));
      expect(updated.topGoleadoresMax, equals(original.topGoleadoresMax));
    });
  });

  group('TorneoConfigService Tests', () {
    test('Instancia Singleton provee getters dinámicos', () {
      final service = TorneoConfigService();
      expect(service.torneo, isNotNull);
      expect(service.limiteJugadores, isA<int>());
      expect(service.tienePuntoInvisible, isA<bool>());
      expect(service.topGoleadoresMax, isA<int>());
    });
  });

  group('ConfiguracionTorneoPage Widget Tests', () {
    testWidgets('Renderiza controles de configuración de torneo', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ConfiguracionTorneoPage(),
        ),
      );

      // Esperar a que cargue
      await tester.pumpAndSettle();

      // Verificar que se visualizan los títulos y secciones
      expect(find.text('Configuración del Torneo'), findsOneWidget);
      expect(find.text('Nombre del Torneo'), findsOneWidget);
      expect(find.text('Cupo Máximo por Equipo'), findsOneWidget);
      expect(find.text('Ventaja Deportiva ("Punto Invisible")'), findsOneWidget);
      expect(find.text('Top de Goleadores'), findsOneWidget);
      expect(find.text('GUARDAR CONFIGURACIÓN'), findsOneWidget);
    });
  });
}

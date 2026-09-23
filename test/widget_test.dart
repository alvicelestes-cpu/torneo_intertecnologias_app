import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_intertecnologias_app/main.dart';
import 'package:torneo_intertecnologias_app/portal_publico_page.dart';

void main() {
  testWidgets('TorneoApp carga PortalPublicoPage por defecto como ruta inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const TorneoApp());
    expect(find.byType(PortalPublicoPage), findsOneWidget);
    expect(find.text('PORTAL DEL TORNEO'), findsOneWidget);
    expect(find.text('Torneo Intertecnologías'), findsWidgets);
  });

  testWidgets('Ruta /login carga LoginPage', (WidgetTester tester) async {
    await tester.pumpWidget(const TorneoApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/login');
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });

  testWidgets('Ruta /admin carga LoginPage', (WidgetTester tester) async {
    await tester.pumpWidget(const TorneoApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/admin');
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}

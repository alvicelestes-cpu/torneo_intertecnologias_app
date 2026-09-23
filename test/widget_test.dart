import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_intertecnologias_app/main.dart';

void main() {
  testWidgets('TorneoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TorneoApp());
    expect(find.text('Torneo Intertecnologías'), findsOneWidget);
  });
}

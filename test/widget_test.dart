import 'package:flutter_test/flutter_test.dart';
import 'package:vie_de_famille/main.dart';

void main() {
  testWidgets('App démarre sans crash', (WidgetTester tester) async {
    await tester.pumpWidget(const VieDeFamilleApp());
    expect(find.text('VieDeFamille'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/main.dart';

void main() {
  testWidgets('App démarre sans crash', (WidgetTester tester) async {
    // Envelopper dans ProviderScope avec storage null (pas de SharedPreferences requis)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(null),
        ],
        child: const VieDeFamilleApp(),
      ),
    );
    expect(find.text('VieDeFamille'), findsOneWidget);
    // Avancer pour vider le timer du SplashScreen (800ms)
    await tester.pump(const Duration(seconds: 1));
  });
}

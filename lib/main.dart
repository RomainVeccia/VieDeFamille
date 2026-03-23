import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vie_de_famille/ui/screens/splash_screen.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VieDeFamilleApp()));
}

/// Point d'entrée de l'application VieDeFamille
class VieDeFamilleApp extends StatelessWidget {
  const VieDeFamilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VieDeFamille',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

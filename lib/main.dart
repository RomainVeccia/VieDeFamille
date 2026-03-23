import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/data/local/storage_service.dart';
import 'package:vie_de_famille/ui/screens/splash_screen.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les locales pour intl (dates en français)
  await initializeDateFormatting('fr_FR', null);

  // Initialiser le storage local
  final storage = await StorageService.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const VieDeFamilleApp(),
    ),
  );
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
      locale: const Locale('fr', 'FR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      home: const SplashScreen(),
    );
  }
}

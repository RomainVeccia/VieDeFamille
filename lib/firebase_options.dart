// ⚠️  PLACEHOLDER — remplacer par le vrai fichier généré par :
//     flutterfire configure --project=TON_PROJECT_ID
//
// Commandes pour générer ce fichier :
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure --project=vie-de-famille-xxx
//
// En attendant, ce placeholder fait échouer proprement Firebase.initializeApp()
// et l'app tourne en mode local (NullSync).

// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ⚠️  Remplacer par vos vraies options Firebase
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_API_KEY',
    appId: 'REPLACE_APP_ID',
    messagingSenderId: 'REPLACE_SENDER_ID',
    projectId: 'REPLACE_PROJECT_ID',
    authDomain: 'REPLACE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_API_KEY',
    appId: 'REPLACE_APP_ID',
    messagingSenderId: 'REPLACE_SENDER_ID',
    projectId: 'REPLACE_PROJECT_ID',
    storageBucket: 'REPLACE_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_API_KEY',
    appId: 'REPLACE_APP_ID',
    messagingSenderId: 'REPLACE_SENDER_ID',
    projectId: 'REPLACE_PROJECT_ID',
    storageBucket: 'REPLACE_PROJECT_ID.appspot.com',
    iosBundleId: 'com.romano.vieDeFamille',
  );
}

// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vie_de_famille/data/remote/sync_service.dart';
import 'package:vie_de_famille/firebase_options.dart';

/// Implémentation Firebase Firestore du SyncService
/// Structure : families/{familyId}/{collection}/{id}
class FirestoreSync implements SyncService {
  static const _familyId = 'veccia'; // identifiant de la famille

  final FirebaseFirestore _db;

  FirestoreSync._(this._db);

  /// Initialise Firebase et retourne une instance de FirestoreSync.
  /// Retourne null si Firebase n'est pas configuré ou inaccessible.
  static Future<FirestoreSync?> tryInit() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final db = FirebaseFirestore.instance;
      // Activer la persistence offline
      db.settings = const Settings(persistenceEnabled: true);
      return FirestoreSync._(db);
    } catch (e) {
      // Firebase non configuré ou erreur réseau — mode local uniquement
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection('families').doc(_familyId).collection(name);

  @override
  Future<void> upsert(String collection, Map<String, dynamic> item) async {
    try {
      await _col(collection).doc(item['id'] as String).set(item);
    } catch (_) {
      // Erreur silencieuse — les données sont déjà en local
    }
  }

  @override
  Future<void> delete(String collection, String id) async {
    try {
      await _col(collection).doc(id).delete();
    } catch (_) {}
  }

  @override
  Stream<List<Map<String, dynamic>>>? watch(String collection) {
    return _col(collection).snapshots().map(
          (snap) => snap.docs.map((d) => d.data()).toList(),
        );
  }

  @override
  bool get isActive => true;
}

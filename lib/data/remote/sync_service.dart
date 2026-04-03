/// Interface de synchronisation — NullSync par défaut, FirestoreSync quand Firebase est configuré
abstract class SyncService {
  /// Créer ou mettre à jour un document dans une collection
  Future<void> upsert(String collection, Map<String, dynamic> item);

  /// Supprimer un document d'une collection
  Future<void> delete(String collection, String id);

  /// Stream temps réel d'une collection (null si sync désactivé)
  Stream<List<Map<String, dynamic>>>? watch(String collection);

  /// true si le service est connecté à un backend distant
  bool get isActive;
}

/// Implémentation vide — stockage local uniquement
class NullSync implements SyncService {
  const NullSync();

  @override
  Future<void> upsert(String collection, Map<String, dynamic> item) async {}

  @override
  Future<void> delete(String collection, String id) async {}

  @override
  Stream<List<Map<String, dynamic>>>? watch(String collection) => null;

  @override
  bool get isActive => false;
}

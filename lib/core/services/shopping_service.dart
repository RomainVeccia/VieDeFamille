import 'package:vie_de_famille/core/models/shopping_item.dart';

/// Logique métier pour les listes de courses
class ShoppingService {
  ShoppingService._();

  /// Articles d'une liste donnée
  static List<ShoppingItem> forList(
    List<ShoppingItem> items,
    String listId,
  ) =>
      items.where((i) => i.listId == listId).toList();

  /// Articles non cochés d'une liste
  static List<ShoppingItem> pending(
    List<ShoppingItem> items,
    String listId,
  ) =>
      items.where((i) => i.listId == listId && !i.checked).toList();

  /// Articles cochés d'une liste
  static List<ShoppingItem> checked(
    List<ShoppingItem> items,
    String listId,
  ) =>
      items.where((i) => i.listId == listId && i.checked).toList();

  /// Regrouper les articles par catégorie pour une liste
  static Map<ShoppingCategory, List<ShoppingItem>> groupByCategory(
    List<ShoppingItem> items,
    String listId,
  ) {
    final listItems = forList(items, listId);
    final Map<ShoppingCategory, List<ShoppingItem>> result = {};
    for (final cat in ShoppingCategory.values) {
      final inCat = listItems.where((i) => i.category == cat).toList();
      if (inCat.isNotEmpty) result[cat] = inCat;
    }
    return result;
  }

  /// Pourcentage de complétion d'une liste (0.0 à 1.0)
  static double completion(List<ShoppingItem> items, String listId) {
    final listItems = forList(items, listId);
    if (listItems.isEmpty) return 0.0;
    final done = listItems.where((i) => i.checked).length;
    return done / listItems.length;
  }

  /// Nombre total d'articles dans une liste
  static int count(List<ShoppingItem> items, String listId) =>
      items.where((i) => i.listId == listId).length;
}

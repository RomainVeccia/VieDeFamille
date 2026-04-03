import 'package:flutter_test/flutter_test.dart';
import 'package:vie_de_famille/core/models/shopping_list.dart';
import 'package:vie_de_famille/core/models/shopping_item.dart';
import 'package:vie_de_famille/core/services/shopping_service.dart';

void main() {
  // === ShoppingList ===
  group('ShoppingList', () {
    test('créer une liste', () {
      final list = ShoppingList.create(name: 'Courses du samedi', createdBy: 'romain');
      expect(list.name, 'Courses du samedi');
      expect(list.createdBy, 'romain');
      expect(list.id, isNotEmpty);
    });

    test('serialisation JSON aller-retour', () {
      final list = ShoppingList.create(name: 'Liste test', createdBy: 'user-1');
      final restored = ShoppingList.fromJson(list.toJson());
      expect(restored.name, list.name);
      expect(restored.id, list.id);
      expect(restored.createdBy, list.createdBy);
    });

    test('copyWith ne change que le nom', () {
      final list = ShoppingList.create(name: 'Ancienne', createdBy: 'x');
      final updated = list.copyWith(name: 'Nouvelle');
      expect(updated.name, 'Nouvelle');
      expect(updated.id, list.id);
      expect(updated.createdBy, list.createdBy);
    });
  });

  // === ShoppingItem ===
  group('ShoppingItem', () {
    test('créer un article', () {
      final item = ShoppingItem.create(
        listId: 'list-1',
        name: 'Lait',
        quantity: '2L',
        category: ShoppingCategory.laitier,
        addedBy: 'romain',
      );
      expect(item.name, 'Lait');
      expect(item.quantity, '2L');
      expect(item.category, ShoppingCategory.laitier);
      expect(item.checked, false);
    });

    test('cocher un article', () {
      final item = ShoppingItem.create(
        listId: 'list-1',
        name: 'Pain',
        addedBy: 'romain',
      );
      final checked = item.check();
      expect(checked.checked, true);
      expect(checked.id, item.id);
      expect(checked.name, item.name);
    });

    test('décocher un article', () {
      final item = ShoppingItem.create(
        listId: 'list-1',
        name: 'Pain',
        addedBy: 'romain',
      ).check();
      final unchecked = item.uncheck();
      expect(unchecked.checked, false);
      expect(unchecked.id, item.id);
    });

    test('serialisation JSON aller-retour', () {
      final item = ShoppingItem.create(
        listId: 'list-42',
        name: 'Yaourts',
        quantity: '6',
        category: ShoppingCategory.laitier,
        addedBy: 'joanne',
      );
      final restored = ShoppingItem.fromJson(item.toJson());
      expect(restored.name, item.name);
      expect(restored.listId, item.listId);
      expect(restored.quantity, item.quantity);
      expect(restored.category, ShoppingCategory.laitier);
      expect(restored.checked, false);
    });

    test('catégorie par défaut = autres', () {
      final item = ShoppingItem.create(
        listId: 'list-1',
        name: 'Truc',
        addedBy: 'x',
      );
      expect(item.category, ShoppingCategory.autres);
    });

    test('emoji et label des catégories', () {
      expect(ShoppingCategory.fruits.emoji, isNotEmpty);
      expect(ShoppingCategory.viandes.label, contains('Viandes'));
      expect(ShoppingCategory.laitier.label, contains('laitier'));
      expect(ShoppingCategory.menager.emoji, isNotEmpty);
    });
  });

  // === ShoppingService ===
  group('ShoppingService', () {
    final items = [
      ShoppingItem.create(listId: 'A', name: 'Lait', addedBy: 'x',
          category: ShoppingCategory.laitier),
      ShoppingItem.create(listId: 'A', name: 'Pain', addedBy: 'x',
          category: ShoppingCategory.boulangerie),
      ShoppingItem.create(listId: 'A', name: 'Pommes', addedBy: 'x',
          category: ShoppingCategory.fruits),
      ShoppingItem.create(listId: 'B', name: 'Détergent', addedBy: 'x',
          category: ShoppingCategory.menager),
    ];

    // On crée des versions cochées manuellement
    final mixedItems = [
      items[0].check(), // lait coché
      items[1],         // pain non coché
      items[2],         // pommes non coché
      items[3].check(), // détergent coché
    ];

    test('forList filtre par listId', () {
      expect(ShoppingService.forList(items, 'A').length, 3);
      expect(ShoppingService.forList(items, 'B').length, 1);
      expect(ShoppingService.forList(items, 'C').length, 0);
    });

    test('pending retourne les articles non cochés', () {
      expect(ShoppingService.pending(mixedItems, 'A').length, 2); // pain + pommes
    });

    test('checked retourne les articles cochés', () {
      expect(ShoppingService.checked(mixedItems, 'A').length, 1); // lait
      expect(ShoppingService.checked(mixedItems, 'B').length, 1); // détergent
    });

    test('completion calcule le bon pourcentage', () {
      expect(ShoppingService.completion(mixedItems, 'A'), closeTo(1 / 3, 0.01));
      expect(ShoppingService.completion(mixedItems, 'B'), 1.0);
      expect(ShoppingService.completion(mixedItems, 'C'), 0.0);
    });

    test('count retourne le bon nombre', () {
      expect(ShoppingService.count(items, 'A'), 3);
      expect(ShoppingService.count(items, 'B'), 1);
    });

    test('groupByCategory regroupe correctement', () {
      final groups = ShoppingService.groupByCategory(items, 'A');
      expect(groups[ShoppingCategory.laitier]?.length, 1);
      expect(groups[ShoppingCategory.boulangerie]?.length, 1);
      expect(groups[ShoppingCategory.fruits]?.length, 1);
      expect(groups[ShoppingCategory.menager], isNull); // pas dans liste A
    });
  });
}

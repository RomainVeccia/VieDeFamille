import 'package:uuid/uuid.dart';

enum ShoppingCategory {
  fruits,
  viandes,
  laitier,
  boissons,
  menager,
  boulangerie,
  surgeles,
  autres,
}

extension ShoppingCategoryExtension on ShoppingCategory {
  String get label {
    switch (this) {
      case ShoppingCategory.fruits:
        return 'Fruits & Légumes';
      case ShoppingCategory.viandes:
        return 'Viandes & Poissons';
      case ShoppingCategory.laitier:
        return 'Produits laitiers';
      case ShoppingCategory.boissons:
        return 'Boissons';
      case ShoppingCategory.menager:
        return 'Ménager';
      case ShoppingCategory.boulangerie:
        return 'Boulangerie';
      case ShoppingCategory.surgeles:
        return 'Surgelés';
      case ShoppingCategory.autres:
        return 'Autres';
    }
  }

  String get emoji {
    switch (this) {
      case ShoppingCategory.fruits:
        return '🥦';
      case ShoppingCategory.viandes:
        return '🥩';
      case ShoppingCategory.laitier:
        return '🧀';
      case ShoppingCategory.boissons:
        return '🥤';
      case ShoppingCategory.menager:
        return '🧹';
      case ShoppingCategory.boulangerie:
        return '🥖';
      case ShoppingCategory.surgeles:
        return '🧊';
      case ShoppingCategory.autres:
        return '🛒';
    }
  }
}

/// Article dans une liste de courses
class ShoppingItem {
  final String id;
  final String listId;
  final String name;
  final String? quantity; // "2", "500g", "1 paquet"...
  final ShoppingCategory category;
  final bool checked;
  final String addedBy; // member.id
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity,
    this.category = ShoppingCategory.autres,
    this.checked = false,
    required this.addedBy,
    required this.createdAt,
  });

  factory ShoppingItem.create({
    required String listId,
    required String name,
    String? quantity,
    ShoppingCategory category = ShoppingCategory.autres,
    required String addedBy,
  }) {
    return ShoppingItem(
      id: const Uuid().v4(),
      listId: listId,
      name: name,
      quantity: quantity,
      category: category,
      addedBy: addedBy,
      createdAt: DateTime.now(),
    );
  }

  ShoppingItem check() => ShoppingItem(
        id: id,
        listId: listId,
        name: name,
        quantity: quantity,
        category: category,
        checked: true,
        addedBy: addedBy,
        createdAt: createdAt,
      );

  ShoppingItem uncheck() => ShoppingItem(
        id: id,
        listId: listId,
        name: name,
        quantity: quantity,
        category: category,
        checked: false,
        addedBy: addedBy,
        createdAt: createdAt,
      );

  ShoppingItem copyWith({
    String? name,
    String? quantity,
    ShoppingCategory? category,
    bool? checked,
  }) {
    return ShoppingItem(
      id: id,
      listId: listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      checked: checked ?? this.checked,
      addedBy: addedBy,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'listId': listId,
        'name': name,
        'quantity': quantity,
        'category': category.index,
        'checked': checked,
        'addedBy': addedBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        listId: json['listId'] as String,
        name: json['name'] as String,
        quantity: json['quantity'] as String?,
        category: ShoppingCategory.values[json['category'] as int? ?? 7],
        checked: json['checked'] as bool? ?? false,
        addedBy: json['addedBy'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

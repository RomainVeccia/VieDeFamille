import 'package:uuid/uuid.dart';

/// Liste de courses partagée — peut contenir plusieurs articles
class ShoppingList {
  final String id;
  final String name;
  final String createdBy; // member.id
  final DateTime createdAt;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
  });

  factory ShoppingList.create({
    required String name,
    required String createdBy,
  }) {
    return ShoppingList(
      id: const Uuid().v4(),
      name: name,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
  }

  ShoppingList copyWith({String? name}) {
    return ShoppingList(
      id: id,
      name: name ?? this.name,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
        id: json['id'] as String,
        name: json['name'] as String,
        createdBy: json['createdBy'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

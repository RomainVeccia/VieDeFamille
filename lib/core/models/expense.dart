import 'package:uuid/uuid.dart';

/// Dépense familiale — assignée à une catégorie, payée par un membre
class Expense {
  final String id;
  final String categoryId;
  final double amount;
  final String description;
  final String paidBy; // member.id
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.paidBy,
    required this.date,
    required this.createdAt,
  });

  factory Expense.create({
    required String categoryId,
    required double amount,
    required String description,
    required String paidBy,
    DateTime? date,
  }) {
    final now = DateTime.now();
    return Expense(
      id: const Uuid().v4(),
      categoryId: categoryId,
      amount: amount,
      description: description,
      paidBy: paidBy,
      date: date ?? now,
      createdAt: now,
    );
  }

  Expense copyWith({
    String? categoryId,
    double? amount,
    String? description,
    String? paidBy,
    DateTime? date,
  }) {
    return Expense(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paidBy: paidBy ?? this.paidBy,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'amount': amount,
        'description': description,
        'paidBy': paidBy,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String,
        paidBy: json['paidBy'] as String,
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

import 'package:uuid/uuid.dart';

/// Catégorie de dépense — avec budget mensuel limite
class BudgetCategory {
  final String id;
  final String name;
  final String icon; // emoji
  final double monthlyLimit; // 0 = pas de limite
  final int colorIndex;
  final DateTime createdAt;

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.monthlyLimit = 0,
    this.colorIndex = 0,
    required this.createdAt,
  });

  factory BudgetCategory.create({
    required String name,
    required String icon,
    double monthlyLimit = 0,
    int colorIndex = 0,
  }) {
    return BudgetCategory(
      id: const Uuid().v4(),
      name: name,
      icon: icon,
      monthlyLimit: monthlyLimit,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
    );
  }

  /// Catégories par défaut pour une nouvelle famille
  static List<BudgetCategory> defaults() {
    final now = DateTime.now();
    return [
      BudgetCategory(id: 'cat_courses', name: 'Courses', icon: '🛒', monthlyLimit: 400, colorIndex: 0, createdAt: now),
      BudgetCategory(id: 'cat_restaurant', name: 'Restaurant', icon: '🍽️', monthlyLimit: 150, colorIndex: 1, createdAt: now),
      BudgetCategory(id: 'cat_transport', name: 'Transport', icon: '🚗', monthlyLimit: 200, colorIndex: 2, createdAt: now),
      BudgetCategory(id: 'cat_sante', name: 'Santé', icon: '💊', monthlyLimit: 100, colorIndex: 3, createdAt: now),
      BudgetCategory(id: 'cat_loisirs', name: 'Loisirs', icon: '🎉', monthlyLimit: 200, colorIndex: 4, createdAt: now),
      BudgetCategory(id: 'cat_enfants', name: 'Enfants', icon: '👶', monthlyLimit: 150, colorIndex: 5, createdAt: now),
      BudgetCategory(id: 'cat_maison', name: 'Maison', icon: '🏠', monthlyLimit: 100, colorIndex: 6, createdAt: now),
      BudgetCategory(id: 'cat_autres', name: 'Autres', icon: '💳', monthlyLimit: 0, colorIndex: 7, createdAt: now),
    ];
  }

  BudgetCategory copyWith({
    String? name,
    String? icon,
    double? monthlyLimit,
    int? colorIndex,
  }) {
    return BudgetCategory(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'monthlyLimit': monthlyLimit,
        'colorIndex': colorIndex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 0,
        colorIndex: json['colorIndex'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

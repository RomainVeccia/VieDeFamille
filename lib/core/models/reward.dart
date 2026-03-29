import 'package:uuid/uuid.dart';

/// Récompense échangeable contre des points
class Reward {
  final String id;
  final String title;
  final String emoji;
  final int cost; // en points
  final String createdBy;
  final DateTime createdAt;

  const Reward({
    required this.id,
    required this.title,
    required this.emoji,
    required this.cost,
    required this.createdBy,
    required this.createdAt,
  });

  factory Reward.create({
    required String title,
    required String emoji,
    required int cost,
    required String createdBy,
  }) {
    return Reward(
      id: const Uuid().v4(),
      title: title,
      emoji: emoji,
      cost: cost,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'cost': cost,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        cost: json['cost'] as int,
        createdBy: json['createdBy'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Récompenses pré-configurées
class RewardTemplates {
  RewardTemplates._();

  static const suggestions = [
    ('🍕', 'Pizza ce soir', 50),
    ('🎮', '1h de jeu vidéo', 30),
    ('🍫', 'Un dessert au choix', 25),
    ('📱', '30min d\'écran en plus', 20),
    ('🎬', 'Film au choix en famille', 60),
    ('🛒', 'Petit achat au choix (5€)', 100),
    ('🎂', 'Gâteau au choix', 40),
    ('😴', 'Coucher 30min plus tard', 35),
    ('🎪', 'Sortie au choix', 150),
    ('⭐', 'Pas de corvée pendant 1 jour', 80),
  ];
}

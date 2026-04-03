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

enum RewardTier { small, medium, large }

extension RewardTierExtension on RewardTier {
  String get label {
    switch (this) {
      case RewardTier.small:  return 'Petites';
      case RewardTier.medium: return 'Moyennes';
      case RewardTier.large:  return 'Grandes';
    }
  }

  String get badge {
    switch (this) {
      case RewardTier.small:  return '🥉';
      case RewardTier.medium: return '🥈';
      case RewardTier.large:  return '🥇';
    }
  }

  String get range {
    switch (this) {
      case RewardTier.small:  return '20 – 50 pts';
      case RewardTier.medium: return '50 – 150 pts';
      case RewardTier.large:  return '150 – 300 pts';
    }
  }
}

/// Récompenses pré-configurées — 3 niveaux
class RewardTemplates {
  RewardTemplates._();

  // (emoji, titre, coût, tier)
  static const all = <(String, String, int, RewardTier)>[
    // 🥉 Petites
    ('📱', '30 min d\'écran en plus',       25, RewardTier.small),
    ('😴', 'Coucher 20 min plus tard',      30, RewardTier.small),
    ('🎮', '1h de jeu vidéo',              40, RewardTier.small),
    ('🛏️', 'Grasse mat\' accordée',         45, RewardTier.small),
    // 🥈 Moyennes
    ('🍽️', 'Repas de ton choix',            50, RewardTier.medium),
    ('🍕', 'Pizza ce soir',                 60, RewardTier.medium),
    ('🎬', 'Film au choix en famille',      65, RewardTier.medium),
    ('🎲', 'Soirée jeux de société',        70, RewardTier.medium),
    ('⭐', 'Journée sans corvée',            80, RewardTier.medium),
    ('🧇', 'Petit déj\' spécial au lit',    85, RewardTier.medium),
    ('🍣', 'Resto au choix',               120, RewardTier.medium),
    // 🥇 Grandes
    ('🛒', 'Petit achat (5€)',             150, RewardTier.large),
    ('🏊', 'Piscine / bowling',            175, RewardTier.large),
    ('🎁', 'Cadeau surprise (10€)',        200, RewardTier.large),
    ('🎡', 'Sortie parc / activité',       250, RewardTier.large),
    ('👑', 'Roi·ne du week-end',           300, RewardTier.large),
  ];

  static List<(String, String, int, RewardTier)> forTier(RewardTier tier) =>
      all.where((r) => r.$4 == tier).toList();
}

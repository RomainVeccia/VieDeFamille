import 'package:uuid/uuid.dart';

/// Historique d'une récompense échangée par un membre
class ClaimedReward {
  final String id;
  final String memberId;
  final String rewardTitle;
  final String rewardEmoji;
  final int cost;
  final DateTime claimedAt;

  const ClaimedReward({
    required this.id,
    required this.memberId,
    required this.rewardTitle,
    required this.rewardEmoji,
    required this.cost,
    required this.claimedAt,
  });

  factory ClaimedReward.create({
    required String memberId,
    required String rewardTitle,
    required String rewardEmoji,
    required int cost,
  }) {
    return ClaimedReward(
      id: const Uuid().v4(),
      memberId: memberId,
      rewardTitle: rewardTitle,
      rewardEmoji: rewardEmoji,
      cost: cost,
      claimedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'rewardTitle': rewardTitle,
        'rewardEmoji': rewardEmoji,
        'cost': cost,
        'claimedAt': claimedAt.toIso8601String(),
      };

  factory ClaimedReward.fromJson(Map<String, dynamic> json) => ClaimedReward(
        id: json['id'] as String,
        memberId: json['memberId'] as String,
        rewardTitle: json['rewardTitle'] as String,
        rewardEmoji: json['rewardEmoji'] as String,
        cost: json['cost'] as int,
        claimedAt: DateTime.parse(json['claimedAt'] as String),
      );
}

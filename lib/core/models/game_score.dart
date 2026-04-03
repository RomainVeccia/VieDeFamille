import 'package:uuid/uuid.dart';

/// Types de jeux disponibles dans "Chance du jour"
enum GameType {
  tetris,
  marble,
}

/// Score d'un membre sur un jeu
class GameScore {
  final String id;
  final String memberId;
  final GameType gameType;
  final int score;
  final DateTime playedAt;

  const GameScore({
    required this.id,
    required this.memberId,
    required this.gameType,
    required this.score,
    required this.playedAt,
  });

  factory GameScore.create({
    required String memberId,
    required GameType gameType,
    required int score,
  }) {
    return GameScore(
      id: const Uuid().v4(),
      memberId: memberId,
      gameType: gameType,
      score: score,
      playedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'gameType': gameType.name,
        'score': score,
        'playedAt': playedAt.toIso8601String(),
      };

  factory GameScore.fromJson(Map<String, dynamic> json) => GameScore(
        id: json['id'] as String,
        memberId: json['memberId'] as String,
        gameType: GameType.values.byName(json['gameType'] as String),
        score: json['score'] as int,
        playedAt: DateTime.parse(json['playedAt'] as String),
      );
}

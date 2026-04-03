import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/models/member.dart';

/// Logique de classement des scores de jeux
class GameScoreService {
  GameScoreService._();

  /// Meilleur score d'un membre pour un jeu
  static int memberBestScore(
    List<GameScore> scores,
    String memberId,
    GameType gameType,
  ) {
    final memberScores = scores
        .where((s) => s.memberId == memberId && s.gameType == gameType)
        .map((s) => s.score);
    if (memberScores.isEmpty) return 0;
    return memberScores.reduce((a, b) => a > b ? a : b);
  }

  /// Classement des membres pour un jeu donné (trié par meilleur score desc)
  static List<(Member, int)> ranking(
    List<GameScore> scores,
    List<Member> members,
    GameType gameType,
  ) {
    final result = <(Member, int)>[];
    for (final member in members) {
      final best = memberBestScore(scores, member.id, gameType);
      result.add((member, best));
    }
    result.sort((a, b) => b.$2.compareTo(a.$2));
    return result;
  }

  /// Nom lisible d'un type de jeu
  static String gameName(GameType type) {
    switch (type) {
      case GameType.tetris:
        return 'Tetris';
      case GameType.marble:
        return 'Marble Madness';
    }
  }

  /// Emoji d'un type de jeu
  static String gameEmoji(GameType type) {
    switch (type) {
      case GameType.tetris:
        return '🧱';
      case GameType.marble:
        return '🔮';
    }
  }
}

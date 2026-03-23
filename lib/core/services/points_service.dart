import 'package:vie_de_famille/core/models/member.dart';

/// Service de gamification — calcul des points, classement, titres
class PointsService {
  PointsService._();

  /// Classement des membres par points (décroissant)
  static List<Member> ranking(List<Member> members) {
    final sorted = List<Member>.from(members);
    sorted.sort((a, b) => b.totalPointsEarned.compareTo(a.totalPointsEarned));
    return sorted;
  }

  /// Titre basé sur les points totaux gagnés
  static String title(int totalPoints) {
    if (totalPoints >= 1000) return 'Super Star ⭐';
    if (totalPoints >= 500) return 'Champion 🏆';
    if (totalPoints >= 200) return 'Pro 💪';
    if (totalPoints >= 100) return 'Motivé 🔥';
    if (totalPoints >= 50) return 'En forme 💫';
    if (totalPoints >= 10) return 'Débutant 🌱';
    return 'Nouveau 👋';
  }

  /// Points nécessaires pour le prochain titre
  static int nextMilestone(int totalPoints) {
    if (totalPoints >= 1000) return 1000; // déjà au max
    if (totalPoints >= 500) return 1000;
    if (totalPoints >= 200) return 500;
    if (totalPoints >= 100) return 200;
    if (totalPoints >= 50) return 100;
    if (totalPoints >= 10) return 50;
    return 10;
  }

  /// Progression vers le prochain titre (0.0 à 1.0)
  static double progress(int totalPoints) {
    final next = nextMilestone(totalPoints);
    if (totalPoints >= 1000) return 1.0;

    // Trouver le palier précédent
    int previous = 0;
    for (final milestone in [0, 10, 50, 100, 200, 500, 1000]) {
      if (milestone >= next) break;
      if (totalPoints >= milestone) previous = milestone;
    }

    final range = next - previous;
    if (range == 0) return 1.0;
    return (totalPoints - previous) / range;
  }
}

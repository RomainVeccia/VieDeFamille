import 'package:vie_de_famille/core/models/family_task.dart';

/// Service de logique métier pour les tâches — pur, ZÉRO import UI
class TaskService {
  TaskService._();

  /// Tâches du jour (assignées à un membre ou toutes)
  static List<FamilyTask> todayTasks(
    List<FamilyTask> all, {
    String? memberId,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.where((t) {
      // Filtre par membre si spécifié
      if (memberId != null && t.assignedTo != memberId) return false;

      // Tâches récurrentes quotidiennes → toujours visibles
      if (t.recurrence == TaskRecurrence.daily) return true;

      // Tâches avec date du jour
      if (t.dueDate != null) {
        final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return due.isAtSameMomentAs(today);
      }

      // Tâches sans date → créées aujourd'hui
      final created = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      return created.isAtSameMomentAs(today);
    }).toList();
  }

  /// Tâches non terminées
  static List<FamilyTask> pending(List<FamilyTask> all) {
    return all.where((t) => !t.completed).toList();
  }

  /// Tâches terminées aujourd'hui
  static List<FamilyTask> completedToday(List<FamilyTask> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.where((t) {
      if (!t.completed || t.completedAt == null) return false;
      final completed = DateTime(
          t.completedAt!.year, t.completedAt!.month, t.completedAt!.day);
      return completed.isAtSameMomentAs(today);
    }).toList();
  }

  /// Taux de complétion du jour (0.0 à 1.0)
  static double todayCompletionRate(List<FamilyTask> all) {
    final today = todayTasks(all);
    if (today.isEmpty) return 0.0;
    final done = today.where((t) => t.completed).length;
    return done / today.length;
  }

  /// Tâches assignées à un membre
  static List<FamilyTask> forMember(List<FamilyTask> all, String memberId) {
    return all.where((t) => t.assignedTo == memberId).toList();
  }
}

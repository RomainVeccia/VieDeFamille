import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/core/models/family_task.dart';
import 'package:vie_de_famille/core/models/family_message.dart';
import 'package:vie_de_famille/core/models/family_event.dart';
import 'package:vie_de_famille/core/models/reward.dart';
import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/services/task_service.dart';
import 'package:vie_de_famille/data/local/storage_service.dart';

// ============================================================
// Storage — initialisé dans le splash, puis overridé
// ============================================================
final storageServiceProvider = Provider<StorageService?>((ref) => null);

// ============================================================
// MEMBRES
// ============================================================
class MembersNotifier extends StateNotifier<List<Member>> {
  final StorageService? _storage;

  MembersNotifier(this._storage) : super(_storage?.getMembers() ?? []);

  Future<void> add(Member member) async {
    state = [...state, member];
    await _storage?.saveMembers(state);
  }

  Future<void> update(Member member) async {
    state = state.map((m) => m.id == member.id ? member : m).toList();
    await _storage?.saveMembers(state);
  }

  Future<void> remove(String id) async {
    state = state.where((m) => m.id != id).toList();
    await _storage?.saveMembers(state);
  }

  /// Ajoute des points à un membre (gamification)
  Future<void> addPoints(String memberId, int points) async {
    state = state.map((m) {
      if (m.id != memberId) return m;
      return m.copyWith(
        points: m.points + points,
        totalPointsEarned: m.totalPointsEarned + points,
      );
    }).toList();
    await _storage?.saveMembers(state);
  }

  /// Retire des points (quand on décoche une tâche)
  Future<void> removePoints(String memberId, int points) async {
    state = state.map((m) {
      if (m.id != memberId) return m;
      return m.copyWith(
        points: (m.points - points).clamp(0, m.points),
      );
    }).toList();
    await _storage?.saveMembers(state);
  }
}

final membersProvider =
    StateNotifierProvider<MembersNotifier, List<Member>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return MembersNotifier(storage);
});

// ============================================================
// MEMBRE COURANT
// ============================================================
class CurrentMemberNotifier extends StateNotifier<String?> {
  final StorageService? _storage;

  CurrentMemberNotifier(this._storage)
      : super(_storage?.getCurrentMemberId());

  Future<void> set(String id) async {
    state = id;
    await _storage?.setCurrentMemberId(id);
  }
}

final currentMemberProvider =
    StateNotifierProvider<CurrentMemberNotifier, String?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return CurrentMemberNotifier(storage);
});

/// Le Member complet du membre courant
/// Fallback : si pas de membre courant mais des membres existent, prend le premier
final currentMemberDataProvider = Provider<Member?>((ref) {
  final memberId = ref.watch(currentMemberProvider);
  final members = ref.watch(membersProvider);

  if (members.isEmpty) return null;

  // Chercher le membre courant par son id
  if (memberId != null) {
    final found = members.where((m) => m.id == memberId);
    if (found.isNotEmpty) return found.first;
  }

  // Fallback : retourner le premier membre (sans modifier l'état ici)
  return members.first;
});

// ============================================================
// TÂCHES
// ============================================================
class TasksNotifier extends StateNotifier<List<FamilyTask>> {
  final StorageService? _storage;
  final Ref _ref;

  TasksNotifier(this._storage, this._ref) : super(_storage?.getTasks() ?? []) {
    // Reset automatique des tâches récurrentes complétées la veille
    _resetRecurringTasks();
  }

  /// Remet à zéro les tâches récurrentes complétées avant aujourd'hui 7h
  Future<void> _resetRecurringTasks() async {
    final now = DateTime.now();
    final today7h = DateTime(now.year, now.month, now.day, 7);
    bool changed = false;

    state = state.map((t) {
      if (!t.completed) return t;
      if (t.recurrence == TaskRecurrence.none) return t;
      if (t.completedAt == null) return t;
      // Si complétée avant aujourd'hui 7h → reset
      if (t.completedAt!.isBefore(today7h)) {
        changed = true;
        return t.uncomplete();
      }
      return t;
    }).toList();

    if (changed) await _storage?.saveTasks(state);
  }

  Future<void> add(FamilyTask task) async {
    state = [...state, task];
    await _storage?.saveTasks(state);
  }

  /// Toggle complete — ajoute/retire les points automatiquement
  Future<void> toggle(String taskId) async {
    state = state.map((t) {
      if (t.id != taskId) return t;
      if (t.completed) {
        // Décoche → retirer les points
        if (t.assignedTo != null) {
          _ref
              .read(membersProvider.notifier)
              .removePoints(t.assignedTo!, t.pointsValue);
        }
        return t.uncomplete();
      } else {
        // Coche → ajouter les points
        if (t.assignedTo != null) {
          _ref
              .read(membersProvider.notifier)
              .addPoints(t.assignedTo!, t.pointsValue);
        }
        return t.complete();
      }
    }).toList();
    await _storage?.saveTasks(state);
  }

  Future<void> remove(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _storage?.saveTasks(state);
  }

  Future<void> update(FamilyTask task) async {
    state = state.map((t) => t.id == task.id ? task : t).toList();
    await _storage?.saveTasks(state);
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<FamilyTask>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TasksNotifier(storage, ref);
});

/// Tâches du jour
final todayTasksProvider = Provider<List<FamilyTask>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return TaskService.todayTasks(tasks);
});

// ============================================================
// MESSAGES
// ============================================================
class MessagesNotifier extends StateNotifier<List<FamilyMessage>> {
  final StorageService? _storage;

  MessagesNotifier(this._storage) : super(_storage?.getMessages() ?? []);

  Future<void> add(FamilyMessage message) async {
    state = [message, ...state];
    await _storage?.saveMessages(state);
  }

  Future<void> togglePin(String id) async {
    state = state.map((m) {
      if (m.id != id) return m;
      return m.copyWith(pinned: !m.pinned);
    }).toList();
    await _storage?.saveMessages(state);
  }

  Future<void> remove(String id) async {
    state = state.where((m) => m.id != id).toList();
    await _storage?.saveMessages(state);
  }

  /// Marquer une requête comme faite / pas faite
  Future<void> toggleDone(String id) async {
    state = state.map((m) {
      if (m.id != id) return m;
      return m.copyWith(done: !m.done);
    }).toList();
    await _storage?.saveMessages(state);
  }
}

final messagesProvider =
    StateNotifierProvider<MessagesNotifier, List<FamilyMessage>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return MessagesNotifier(storage);
});

/// Messages/requêtes reçus par un membre spécifique
final messagesForMemberProvider =
    Provider.family<List<FamilyMessage>, String>((ref, memberId) {
  final messages = ref.watch(messagesProvider);
  return messages.where((m) => m.recipientId == memberId).toList();
});

// ============================================================
// ÉVÉNEMENTS
// ============================================================
class EventsNotifier extends StateNotifier<List<FamilyEvent>> {
  final StorageService? _storage;

  EventsNotifier(this._storage) : super(_storage?.getEvents() ?? []);

  Future<void> add(FamilyEvent event) async {
    state = [...state, event];
    await _storage?.saveEvents(state);
  }

  Future<void> update(FamilyEvent event) async {
    state = state.map((e) => e.id == event.id ? event : e).toList();
    await _storage?.saveEvents(state);
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _storage?.saveEvents(state);
  }
}

final eventsProvider =
    StateNotifierProvider<EventsNotifier, List<FamilyEvent>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return EventsNotifier(storage);
});

/// Événements d'un jour spécifique
final eventsForDayProvider =
    Provider.family<List<FamilyEvent>, DateTime>((ref, day) {
  final events = ref.watch(eventsProvider);
  return events.where((e) => e.isOnDay(day)).toList();
});

// ============================================================
// RÉCOMPENSES
// ============================================================
class RewardsNotifier extends StateNotifier<List<Reward>> {
  final StorageService? _storage;

  RewardsNotifier(this._storage) : super(_storage?.getRewards() ?? []);

  Future<void> add(Reward reward) async {
    state = [...state, reward];
    await _storage?.saveRewards(state);
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _storage?.saveRewards(state);
  }
}

final rewardsProvider =
    StateNotifierProvider<RewardsNotifier, List<Reward>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return RewardsNotifier(storage);
});

// ============================================================
// SCORES DE JEUX
// ============================================================
class GameScoresNotifier extends StateNotifier<List<GameScore>> {
  final StorageService? _storage;

  GameScoresNotifier(this._storage)
      : super(_storage?.getGameScores() ?? []);

  Future<void> add(GameScore score) async {
    state = [...state, score];
    await _storage?.saveGameScores(state);
  }
}

final gameScoresProvider =
    StateNotifierProvider<GameScoresNotifier, List<GameScore>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return GameScoresNotifier(storage);
});

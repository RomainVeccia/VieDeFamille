import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/core/models/family_task.dart';
import 'package:vie_de_famille/core/models/family_message.dart';
import 'package:vie_de_famille/core/models/family_event.dart';
import 'package:vie_de_famille/core/models/reward.dart';
import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/models/shopping_list.dart';
import 'package:vie_de_famille/core/models/shopping_item.dart';
import 'package:vie_de_famille/core/models/budget_category.dart';
import 'package:vie_de_famille/core/models/expense.dart';
import 'package:vie_de_famille/core/services/task_service.dart';
import 'package:vie_de_famille/data/local/storage_service.dart';
import 'package:vie_de_famille/core/models/claimed_reward.dart';
import 'package:vie_de_famille/data/remote/sync_service.dart';

// ============================================================
// Storage — initialisé dans le splash, puis overridé
// ============================================================
final storageServiceProvider = Provider<StorageService?>((ref) => null);

// ============================================================
// Sync Service — NullSync par défaut, FirestoreSync après init Firebase
// ============================================================
final syncServiceProvider = Provider<SyncService>((ref) => const NullSync());

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

  if (memberId != null) {
    final found = members.where((m) => m.id == memberId);
    if (found.isNotEmpty) return found.first;
  }

  return members.first;
});

// ============================================================
// TÂCHES
// ============================================================
class TasksNotifier extends StateNotifier<List<FamilyTask>> {
  final StorageService? _storage;
  final SyncService _sync;
  final Ref _ref;

  static const _col = 'tasks';

  TasksNotifier(this._storage, this._sync, this._ref)
      : super(_storage?.getTasks() ?? []) {
    _resetRecurringTasks();
    _listenRemote();
  }

  /// Écoute Firestore et met à jour l'état local en temps réel
  void _listenRemote() {
    _sync.watch(_col)?.listen((remoteData) {
      if (!mounted) return;
      try {
        final items = remoteData
            .map((e) => FamilyTask.fromJson(e))
            .toList();
        state = items;
        _storage?.saveTasks(state);
      } catch (_) {}
    });
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
    await _sync.upsert(_col, task.toJson());
  }

  /// Toggle complete — ajoute/retire les points automatiquement
  Future<void> toggle(String taskId) async {
    FamilyTask? updated;
    state = state.map((t) {
      if (t.id != taskId) return t;
      if (t.completed) {
        if (t.assignedTo != null) {
          _ref.read(membersProvider.notifier).removePoints(t.assignedTo!, t.pointsValue);
        }
        updated = t.uncomplete();
      } else {
        if (t.assignedTo != null) {
          _ref.read(membersProvider.notifier).addPoints(t.assignedTo!, t.pointsValue);
        }
        updated = t.complete();
      }
      return updated!;
    }).toList();
    await _storage?.saveTasks(state);
    if (updated != null) await _sync.upsert(_col, updated!.toJson());
  }

  Future<void> remove(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _storage?.saveTasks(state);
    await _sync.delete(_col, id);
  }

  Future<void> update(FamilyTask task) async {
    state = state.map((t) => t.id == task.id ? task : t).toList();
    await _storage?.saveTasks(state);
    await _sync.upsert(_col, task.toJson());
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<FamilyTask>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  return TasksNotifier(storage, sync, ref);
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
  final SyncService _sync;

  static const _col = 'messages';

  MessagesNotifier(this._storage, this._sync)
      : super(_storage?.getMessages() ?? []) {
    _listenRemote();
  }

  void _listenRemote() {
    _sync.watch(_col)?.listen((remoteData) {
      if (!mounted) return;
      try {
        final items = remoteData.map((e) => FamilyMessage.fromJson(e)).toList();
        // Trier par date décroissante
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = items;
        _storage?.saveMessages(state);
      } catch (_) {}
    });
  }

  Future<void> add(FamilyMessage message) async {
    state = [message, ...state];
    await _storage?.saveMessages(state);
    await _sync.upsert(_col, message.toJson());
  }

  Future<void> togglePin(String id) async {
    FamilyMessage? updated;
    state = state.map((m) {
      if (m.id != id) return m;
      updated = m.copyWith(pinned: !m.pinned);
      return updated!;
    }).toList();
    await _storage?.saveMessages(state);
    if (updated != null) await _sync.upsert(_col, updated!.toJson());
  }

  Future<void> remove(String id) async {
    state = state.where((m) => m.id != id).toList();
    await _storage?.saveMessages(state);
    await _sync.delete(_col, id);
  }

  Future<void> toggleDone(String id) async {
    FamilyMessage? updated;
    state = state.map((m) {
      if (m.id != id) return m;
      updated = m.copyWith(done: !m.done);
      return updated!;
    }).toList();
    await _storage?.saveMessages(state);
    if (updated != null) await _sync.upsert(_col, updated!.toJson());
  }
}

final messagesProvider =
    StateNotifierProvider<MessagesNotifier, List<FamilyMessage>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  return MessagesNotifier(storage, sync);
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
  final SyncService _sync;

  static const _col = 'events';

  EventsNotifier(this._storage, this._sync)
      : super(_storage?.getEvents() ?? []) {
    _listenRemote();
  }

  void _listenRemote() {
    _sync.watch(_col)?.listen((remoteData) {
      if (!mounted) return;
      try {
        final items = remoteData.map((e) => FamilyEvent.fromJson(e)).toList();
        state = items;
        _storage?.saveEvents(state);
      } catch (_) {}
    });
  }

  Future<void> add(FamilyEvent event) async {
    state = [...state, event];
    await _storage?.saveEvents(state);
    await _sync.upsert(_col, event.toJson());
  }

  Future<void> update(FamilyEvent event) async {
    state = state.map((e) => e.id == event.id ? event : e).toList();
    await _storage?.saveEvents(state);
    await _sync.upsert(_col, event.toJson());
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _storage?.saveEvents(state);
    await _sync.delete(_col, id);
  }
}

final eventsProvider =
    StateNotifierProvider<EventsNotifier, List<FamilyEvent>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  return EventsNotifier(storage, sync);
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

  Future<void> update(Reward reward) async {
    state = state.map((r) => r.id == reward.id ? reward : r).toList();
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
// RÉCOMPENSES ÉCHANGÉES (historique)
// ============================================================
class ClaimedRewardsNotifier extends StateNotifier<List<ClaimedReward>> {
  final StorageService? _storage;

  ClaimedRewardsNotifier(this._storage)
      : super(_storage?.getClaimedRewards() ?? []);

  Future<void> add(ClaimedReward claim) async {
    state = [claim, ...state];
    await _storage?.saveClaimedRewards(state);
  }

  List<ClaimedReward> forMember(String memberId) =>
      state.where((c) => c.memberId == memberId).toList();
}

final claimedRewardsProvider =
    StateNotifierProvider<ClaimedRewardsNotifier, List<ClaimedReward>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ClaimedRewardsNotifier(storage);
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

// ============================================================
// LISTES DE COURSES
// ============================================================
class ShoppingListsNotifier extends StateNotifier<List<ShoppingList>> {
  final StorageService? _storage;
  final SyncService _sync;

  static const _col = 'shopping_lists';

  ShoppingListsNotifier(this._storage, this._sync)
      : super(_storage?.getShoppingLists() ?? []) {
    _listenRemote();
  }

  void _listenRemote() {
    _sync.watch(_col)?.listen((remoteData) {
      if (!mounted) return;
      try {
        final items = remoteData.map((e) => ShoppingList.fromJson(e)).toList();
        state = items;
        _storage?.saveShoppingLists(state);
      } catch (_) {}
    });
  }

  Future<void> add(ShoppingList list) async {
    state = [...state, list];
    await _storage?.saveShoppingLists(state);
    await _sync.upsert(_col, list.toJson());
  }

  Future<void> remove(String id) async {
    state = state.where((l) => l.id != id).toList();
    await _storage?.saveShoppingLists(state);
    await _sync.delete(_col, id);
  }

  Future<void> update(ShoppingList list) async {
    state = state.map((l) => l.id == list.id ? list : l).toList();
    await _storage?.saveShoppingLists(state);
    await _sync.upsert(_col, list.toJson());
  }
}

final shoppingListsProvider =
    StateNotifierProvider<ShoppingListsNotifier, List<ShoppingList>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  return ShoppingListsNotifier(storage, sync);
});

// ============================================================
// ARTICLES DE COURSES
// ============================================================
class ShoppingItemsNotifier extends StateNotifier<List<ShoppingItem>> {
  final StorageService? _storage;
  final SyncService _sync;

  static const _col = 'shopping_items';

  ShoppingItemsNotifier(this._storage, this._sync)
      : super(_storage?.getShoppingItems() ?? []) {
    _listenRemote();
  }

  void _listenRemote() {
    _sync.watch(_col)?.listen((remoteData) {
      if (!mounted) return;
      try {
        final items = remoteData.map((e) => ShoppingItem.fromJson(e)).toList();
        state = items;
        _storage?.saveShoppingItems(state);
      } catch (_) {}
    });
  }

  Future<void> add(ShoppingItem item) async {
    state = [...state, item];
    await _storage?.saveShoppingItems(state);
    await _sync.upsert(_col, item.toJson());
  }

  Future<void> toggle(String itemId) async {
    ShoppingItem? updated;
    state = state.map((i) {
      if (i.id != itemId) return i;
      updated = i.checked ? i.uncheck() : i.check();
      return updated!;
    }).toList();
    await _storage?.saveShoppingItems(state);
    if (updated != null) await _sync.upsert(_col, updated!.toJson());
  }

  Future<void> remove(String id) async {
    state = state.where((i) => i.id != id).toList();
    await _storage?.saveShoppingItems(state);
    await _sync.delete(_col, id);
  }

  Future<void> removeForList(String listId) async {
    final toDelete = state.where((i) => i.listId == listId).toList();
    state = state.where((i) => i.listId != listId).toList();
    await _storage?.saveShoppingItems(state);
    for (final item in toDelete) {
      await _sync.delete(_col, item.id);
    }
  }

  Future<void> uncheckAll(String listId) async {
    final toUpdate = <ShoppingItem>[];
    state = state.map((i) {
      if (i.listId != listId) return i;
      final u = i.uncheck();
      toUpdate.add(u);
      return u;
    }).toList();
    await _storage?.saveShoppingItems(state);
    for (final item in toUpdate) {
      await _sync.upsert(_col, item.toJson());
    }
  }
}

final shoppingItemsProvider =
    StateNotifierProvider<ShoppingItemsNotifier, List<ShoppingItem>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  return ShoppingItemsNotifier(storage, sync);
});

// ============================================================
// CATÉGORIES BUDGET
// ============================================================
class BudgetCategoriesNotifier extends StateNotifier<List<BudgetCategory>> {
  final StorageService? _storage;

  BudgetCategoriesNotifier(this._storage)
      : super(_storage?.getBudgetCategories() ?? []);

  Future<void> add(BudgetCategory category) async {
    state = [...state, category];
    await _storage?.saveBudgetCategories(state);
  }

  Future<void> update(BudgetCategory category) async {
    state = state.map((c) => c.id == category.id ? category : c).toList();
    await _storage?.saveBudgetCategories(state);
  }

  Future<void> remove(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _storage?.saveBudgetCategories(state);
  }
}

final budgetCategoriesProvider =
    StateNotifierProvider<BudgetCategoriesNotifier, List<BudgetCategory>>(
        (ref) {
  final storage = ref.watch(storageServiceProvider);
  return BudgetCategoriesNotifier(storage);
});

// ============================================================
// DÉPENSES
// ============================================================
class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final StorageService? _storage;
  final SyncService _sync;

  static const _col = 'expenses';

  ExpensesNotifier(this._storage, this._sync)
      : super(_storage?.getExpenses() ?? []) {
    _listenRemote();
  }

  void _listenRemote() {
    _sync.watch(_col)?.listen((remoteData) {
      if (!mounted) return;
      try {
        final items = remoteData.map((e) => Expense.fromJson(e)).toList();
        state = items;
        _storage?.saveExpenses(state);
      } catch (_) {}
    });
  }

  Future<void> add(Expense expense) async {
    state = [...state, expense];
    await _storage?.saveExpenses(state);
    await _sync.upsert(_col, expense.toJson());
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _storage?.saveExpenses(state);
    await _sync.delete(_col, id);
  }

  Future<void> update(Expense expense) async {
    state = state.map((e) => e.id == expense.id ? expense : e).toList();
    await _storage?.saveExpenses(state);
    await _sync.upsert(_col, expense.toJson());
  }
}

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  return ExpensesNotifier(storage, sync);
});

// ============================================================
// STATUT DE SYNCHRONISATION
// ============================================================
final syncStatusProvider = Provider<bool>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return sync.isActive;
});

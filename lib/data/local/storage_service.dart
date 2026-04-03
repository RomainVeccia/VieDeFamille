import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:vie_de_famille/core/models/claimed_reward.dart';

/// Service de stockage local — SharedPreferences + JSON
class StorageService {
  static const _membersKey = 'vdf_members';
  static const _tasksKey = 'vdf_tasks';
  static const _messagesKey = 'vdf_messages';
  static const _eventsKey = 'vdf_events';
  static const _rewardsKey = 'vdf_rewards';
  static const _gameScoresKey = 'vdf_game_scores';
  static const _currentMemberKey = 'vdf_current_member';
  static const _shoppingListsKey = 'vdf_shopping_lists';
  static const _shoppingItemsKey = 'vdf_shopping_items';
  static const _budgetCategoriesKey = 'vdf_budget_categories';
  static const _expensesKey = 'vdf_expenses';
  static const _claimedRewardsKey = 'vdf_claimed_rewards';

  // Singleton
  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static const _seededKey = 'vdf_seeded';

  static Future<StorageService> getInstance() async {
    if (_instance != null) return _instance!;
    final service = StorageService._();
    service._prefs = await SharedPreferences.getInstance();
    _instance = service;

    // Seed les données par défaut au premier lancement
    if (!service._prefs.containsKey(_seededKey)) {
      await service._seedDefaultMembers();
      await service._seedDefaultBudgetCategories();
      await service._seedDefaultRewards();
      await service._prefs.setBool(_seededKey, true);
    }

    return service;
  }

  /// Pré-enregistre les membres de la famille Veccia
  Future<void> _seedDefaultMembers() async {
    final now = DateTime.now();
    final members = [
      Member(
        id: 'romain',
        name: 'Romain',
        avatarIndex: 0, // 👨
        status: 'Papa',
        birthday: DateTime(1990, 1, 1),
        colorIndex: 0,
        createdAt: now,
      ),
      Member(
        id: 'joanne',
        name: 'Joanne',
        avatarIndex: 1, // 👩
        status: 'Maman',
        birthday: DateTime(1990, 1, 1),
        colorIndex: 1,
        createdAt: now,
      ),
      Member(
        id: 'thea',
        name: 'Théa',
        avatarIndex: 3, // 👧
        status: 'Sœur',
        birthday: DateTime(2015, 1, 1),
        colorIndex: 2,
        createdAt: now,
      ),
      Member(
        id: 'lucas',
        name: 'Lucas',
        avatarIndex: 2, // 👦
        status: 'Frère',
        birthday: DateTime(2017, 1, 1),
        colorIndex: 3,
        createdAt: now,
      ),
    ];
    await saveMembers(members);
    await setCurrentMemberId('romain');
  }

  // --- Members ---
  List<Member> getMembers() {
    final json = _prefs.getString(_membersKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => Member.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMembers(List<Member> members) async {
    final json = jsonEncode(members.map((m) => m.toJson()).toList());
    await _prefs.setString(_membersKey, json);
  }

  // --- Tasks ---
  List<FamilyTask> getTasks() {
    final json = _prefs.getString(_tasksKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => FamilyTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTasks(List<FamilyTask> tasks) async {
    final json = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _prefs.setString(_tasksKey, json);
  }

  // --- Messages ---
  List<FamilyMessage> getMessages() {
    final json = _prefs.getString(_messagesKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => FamilyMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMessages(List<FamilyMessage> messages) async {
    final json = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _prefs.setString(_messagesKey, json);
  }

  // --- Events ---
  List<FamilyEvent> getEvents() {
    final json = _prefs.getString(_eventsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => FamilyEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEvents(List<FamilyEvent> events) async {
    final json = jsonEncode(events.map((e) => e.toJson()).toList());
    await _prefs.setString(_eventsKey, json);
  }

  // --- Rewards ---
  List<Reward> getRewards() {
    final json = _prefs.getString(_rewardsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => Reward.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRewards(List<Reward> rewards) async {
    final json = jsonEncode(rewards.map((r) => r.toJson()).toList());
    await _prefs.setString(_rewardsKey, json);
  }

  // --- Game Scores ---
  List<GameScore> getGameScores() {
    final json = _prefs.getString(_gameScoresKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => GameScore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveGameScores(List<GameScore> scores) async {
    final json = jsonEncode(scores.map((s) => s.toJson()).toList());
    await _prefs.setString(_gameScoresKey, json);
  }

  // --- Current Member ---
  String? getCurrentMemberId() => _prefs.getString(_currentMemberKey);

  Future<void> setCurrentMemberId(String id) async {
    await _prefs.setString(_currentMemberKey, id);
  }

  // --- Shopping Lists ---
  List<ShoppingList> getShoppingLists() {
    final json = _prefs.getString(_shoppingListsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ShoppingList.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveShoppingLists(List<ShoppingList> lists) async {
    final json = jsonEncode(lists.map((l) => l.toJson()).toList());
    await _prefs.setString(_shoppingListsKey, json);
  }

  // --- Shopping Items ---
  List<ShoppingItem> getShoppingItems() {
    final json = _prefs.getString(_shoppingItemsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveShoppingItems(List<ShoppingItem> items) async {
    final json = jsonEncode(items.map((i) => i.toJson()).toList());
    await _prefs.setString(_shoppingItemsKey, json);
  }

  // --- Budget Categories ---
  List<BudgetCategory> getBudgetCategories() {
    final json = _prefs.getString(_budgetCategoriesKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => BudgetCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBudgetCategories(List<BudgetCategory> categories) async {
    final json = jsonEncode(categories.map((c) => c.toJson()).toList());
    await _prefs.setString(_budgetCategoriesKey, json);
  }

  // --- Expenses ---
  List<Expense> getExpenses() {
    final json = _prefs.getString(_expensesKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final json = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await _prefs.setString(_expensesKey, json);
  }

  /// Initialise les catégories de budget par défaut
  Future<void> _seedDefaultBudgetCategories() async {
    await saveBudgetCategories(BudgetCategory.defaults());
  }

  // --- Claimed Rewards ---
  List<ClaimedReward> getClaimedRewards() {
    final json = _prefs.getString(_claimedRewardsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ClaimedReward.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveClaimedRewards(List<ClaimedReward> claims) async {
    final json = jsonEncode(claims.map((c) => c.toJson()).toList());
    await _prefs.setString(_claimedRewardsKey, json);
  }

  /// Pré-charge les 16 récompenses par défaut (3 niveaux)
  Future<void> _seedDefaultRewards() async {
    final now = DateTime.now();
    final rewards = RewardTemplates.all.map((r) => Reward(
      id: 'reward_${r.$3}_${r.$2.hashCode.abs()}',
      title: r.$2,
      emoji: r.$1,
      cost: r.$3,
      createdBy: 'romain',
      createdAt: now,
    )).toList();
    await saveRewards(rewards);
  }
}

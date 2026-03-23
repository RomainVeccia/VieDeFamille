import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/core/models/family_task.dart';
import 'package:vie_de_famille/core/models/family_message.dart';
import 'package:vie_de_famille/core/models/family_event.dart';

/// Service de stockage local — SharedPreferences + JSON
class StorageService {
  static const _membersKey = 'vdf_members';
  static const _tasksKey = 'vdf_tasks';
  static const _messagesKey = 'vdf_messages';
  static const _eventsKey = 'vdf_events';
  static const _currentMemberKey = 'vdf_current_member';

  // Singleton
  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance != null) return _instance!;
    final service = StorageService._();
    service._prefs = await SharedPreferences.getInstance();
    _instance = service;
    return service;
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

  // --- Current Member ---
  String? getCurrentMemberId() => _prefs.getString(_currentMemberKey);

  Future<void> setCurrentMemberId(String id) async {
    await _prefs.setString(_currentMemberKey, id);
  }
}

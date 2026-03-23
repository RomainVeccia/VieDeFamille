import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high }

enum TaskRecurrence { none, daily, weekly, monthly }

/// Tâche familiale — assignable, cochable, avec points de gamification
class FamilyTask {
  final String id;
  final String title;
  final String? description;
  final String? assignedTo; // member.id
  final String createdBy; // member.id
  final TaskPriority priority;
  final TaskRecurrence recurrence;
  final DateTime? dueDate;
  final bool completed;
  final DateTime? completedAt;
  final int pointsValue;
  final DateTime createdAt;

  const FamilyTask({
    required this.id,
    required this.title,
    this.description,
    this.assignedTo,
    required this.createdBy,
    this.priority = TaskPriority.medium,
    this.recurrence = TaskRecurrence.none,
    this.dueDate,
    this.completed = false,
    this.completedAt,
    this.pointsValue = 10,
    required this.createdAt,
  });

  factory FamilyTask.create({
    required String title,
    String? description,
    String? assignedTo,
    required String createdBy,
    TaskPriority priority = TaskPriority.medium,
    TaskRecurrence recurrence = TaskRecurrence.none,
    DateTime? dueDate,
    int pointsValue = 10,
  }) {
    return FamilyTask(
      id: const Uuid().v4(),
      title: title,
      description: description,
      assignedTo: assignedTo,
      createdBy: createdBy,
      priority: priority,
      recurrence: recurrence,
      dueDate: dueDate,
      pointsValue: pointsValue,
      createdAt: DateTime.now(),
    );
  }

  /// Marque la tâche comme complétée
  FamilyTask complete() => copyWith(
        completed: true,
        completedAt: DateTime.now(),
      );

  /// Remet la tâche en non complétée
  FamilyTask uncomplete() => FamilyTask(
        id: id,
        title: title,
        description: description,
        assignedTo: assignedTo,
        createdBy: createdBy,
        priority: priority,
        recurrence: recurrence,
        dueDate: dueDate,
        completed: false,
        completedAt: null,
        pointsValue: pointsValue,
        createdAt: createdAt,
      );

  bool get isOverdue =>
      dueDate != null && !completed && dueDate!.isBefore(DateTime.now());

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  FamilyTask copyWith({
    String? title,
    String? description,
    String? assignedTo,
    TaskPriority? priority,
    TaskRecurrence? recurrence,
    DateTime? dueDate,
    bool? completed,
    DateTime? completedAt,
    int? pointsValue,
  }) {
    return FamilyTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      pointsValue: pointsValue ?? this.pointsValue,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'createdBy': createdBy,
        'priority': priority.index,
        'recurrence': recurrence.index,
        'dueDate': dueDate?.toIso8601String(),
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
        'pointsValue': pointsValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FamilyTask.fromJson(Map<String, dynamic> json) => FamilyTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        assignedTo: json['assignedTo'] as String?,
        createdBy: json['createdBy'] as String,
        priority: TaskPriority.values[json['priority'] as int],
        recurrence: TaskRecurrence.values[json['recurrence'] as int],
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        completed: json['completed'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        pointsValue: json['pointsValue'] as int? ?? 10,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

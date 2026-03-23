import 'package:uuid/uuid.dart';

/// Événement du calendrier familial
class FamilyEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime dateStart;
  final DateTime? dateEnd;
  final bool allDay;
  final String? location;
  final List<String> participantIds;
  final int colorIndex;
  final String createdBy;
  final DateTime createdAt;

  const FamilyEvent({
    required this.id,
    required this.title,
    this.description,
    required this.dateStart,
    this.dateEnd,
    this.allDay = false,
    this.location,
    this.participantIds = const [],
    this.colorIndex = 0,
    required this.createdBy,
    required this.createdAt,
  });

  factory FamilyEvent.create({
    required String title,
    String? description,
    required DateTime dateStart,
    DateTime? dateEnd,
    bool allDay = false,
    String? location,
    List<String> participantIds = const [],
    int colorIndex = 0,
    required String createdBy,
  }) {
    return FamilyEvent(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dateStart: dateStart,
      dateEnd: dateEnd,
      allDay: allDay,
      location: location,
      participantIds: participantIds,
      colorIndex: colorIndex,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
  }

  /// Vérifie si l'événement tombe sur un jour donné
  bool isOnDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final eventStart = DateTime(
        dateStart.year, dateStart.month, dateStart.day);

    if (dateEnd == null) {
      return eventStart.isAtSameMomentAs(dayStart);
    }

    final eventEnd = DateTime(dateEnd!.year, dateEnd!.month, dateEnd!.day)
        .add(const Duration(days: 1));
    return eventStart.isBefore(dayEnd) && eventEnd.isAfter(dayStart);
  }

  FamilyEvent copyWith({
    String? title,
    String? description,
    DateTime? dateStart,
    DateTime? dateEnd,
    bool? allDay,
    String? location,
    List<String>? participantIds,
    int? colorIndex,
  }) {
    return FamilyEvent(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      participantIds: participantIds ?? this.participantIds,
      colorIndex: colorIndex ?? this.colorIndex,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dateStart': dateStart.toIso8601String(),
        'dateEnd': dateEnd?.toIso8601String(),
        'allDay': allDay,
        'location': location,
        'participantIds': participantIds,
        'colorIndex': colorIndex,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FamilyEvent.fromJson(Map<String, dynamic> json) => FamilyEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        dateStart: DateTime.parse(json['dateStart'] as String),
        dateEnd: json['dateEnd'] != null
            ? DateTime.parse(json['dateEnd'] as String)
            : null,
        allDay: json['allDay'] as bool? ?? false,
        location: json['location'] as String?,
        participantIds:
            (json['participantIds'] as List<dynamic>?)?.cast<String>() ?? [],
        colorIndex: json['colorIndex'] as int? ?? 0,
        createdBy: json['createdBy'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

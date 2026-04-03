import 'package:uuid/uuid.dart';
import 'package:vie_de_famille/core/utils/school_holidays.dart';

enum EventRecurrence { none, weekly, monthly }

extension EventRecurrenceExtension on EventRecurrence {
  String get label {
    switch (this) {
      case EventRecurrence.none:    return 'Une seule fois';
      case EventRecurrence.weekly:  return 'Chaque semaine';
      case EventRecurrence.monthly: return 'Chaque mois';
    }
  }

  String get shortLabel {
    switch (this) {
      case EventRecurrence.none:    return '';
      case EventRecurrence.weekly:  return '🔁 Hebdo';
      case EventRecurrence.monthly: return '🔁 Mensuel';
    }
  }
}

/// Événement du calendrier familial — avec récurrence optionnelle
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
  final EventRecurrence recurrence;
  // Exclus des vacances scolaires (zone B par défaut) — utile pour activités régulières
  final bool excludeSchoolHolidays;

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
    this.recurrence = EventRecurrence.none,
    this.excludeSchoolHolidays = false,
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
    EventRecurrence recurrence = EventRecurrence.none,
    bool excludeSchoolHolidays = false,
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
      recurrence: recurrence,
      excludeSchoolHolidays: excludeSchoolHolidays,
    );
  }

  /// Vérifie si l'événement doit s'afficher un jour donné (gère la récurrence)
  bool isOnDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final eventStart = DateTime(dateStart.year, dateStart.month, dateStart.day);

    // L'événement ne peut pas apparaître avant sa date de début
    if (dayStart.isBefore(eventStart)) return false;

    // Exclusion vacances scolaires (uniquement pour les récurrences)
    if (recurrence != EventRecurrence.none &&
        excludeSchoolHolidays &&
        SchoolHolidays.isHoliday(day)) {
      return false;
    }

    switch (recurrence) {
      case EventRecurrence.none:
        // Événement ponctuel — logique existante
        if (dateEnd == null) {
          return eventStart.isAtSameMomentAs(dayStart);
        }
        final dayEnd = dayStart.add(const Duration(days: 1));
        final eventEnd =
            DateTime(dateEnd!.year, dateEnd!.month, dateEnd!.day)
                .add(const Duration(days: 1));
        return eventStart.isBefore(dayEnd) && eventEnd.isAfter(dayStart);

      case EventRecurrence.weekly:
        // Même jour de la semaine que dateStart
        return day.weekday == dateStart.weekday;

      case EventRecurrence.monthly:
        // Même jour du mois que dateStart (gère les mois courts : si le jour n'existe pas, on skip)
        if (dateStart.day > _daysInMonth(day.year, day.month)) return false;
        return day.day == dateStart.day;
    }
  }

  /// Nombre de jours dans un mois donné
  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  FamilyEvent copyWith({
    String? title,
    String? description,
    DateTime? dateStart,
    DateTime? dateEnd,
    bool? allDay,
    String? location,
    List<String>? participantIds,
    int? colorIndex,
    EventRecurrence? recurrence,
    bool? excludeSchoolHolidays,
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
      recurrence: recurrence ?? this.recurrence,
      excludeSchoolHolidays: excludeSchoolHolidays ?? this.excludeSchoolHolidays,
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
        'recurrence': recurrence.index,
        'excludeSchoolHolidays': excludeSchoolHolidays,
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
        recurrence: EventRecurrence
            .values[json['recurrence'] as int? ?? 0],
        excludeSchoolHolidays:
            json['excludeSchoolHolidays'] as bool? ?? false,
      );
}

import 'package:uuid/uuid.dart';

/// Membre de la famille — profil avec photo, avatar, status, anniversaire, points
class Member {
  final String id;
  final String name;
  final String? photoPath;
  final int avatarIndex;
  final String status; // "Papa", "Maman", "Fils"...
  final DateTime birthday;
  final int colorIndex;
  final int points;
  final int totalPointsEarned;
  final DateTime createdAt;

  const Member({
    required this.id,
    required this.name,
    this.photoPath,
    required this.avatarIndex,
    required this.status,
    required this.birthday,
    required this.colorIndex,
    this.points = 0,
    this.totalPointsEarned = 0,
    required this.createdAt,
  });

  /// Crée un nouveau membre avec un id généré
  factory Member.create({
    required String name,
    required String status,
    required DateTime birthday,
    int avatarIndex = 0,
    int colorIndex = 0,
    String? photoPath,
  }) {
    return Member(
      id: const Uuid().v4(),
      name: name,
      photoPath: photoPath,
      avatarIndex: avatarIndex,
      status: status,
      birthday: birthday,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
    );
  }

  /// Parent = Papa ou Maman (peut gérer les récompenses)
  bool get isParent =>
      ['papa', 'maman'].contains(status.toLowerCase().trim());

  /// Calcule l'âge depuis la date de naissance
  int get age {
    final now = DateTime.now();
    int years = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      years--;
    }
    return years;
  }

  /// Prochain anniversaire
  DateTime get nextBirthday {
    final now = DateTime.now();
    var next = DateTime(now.year, birthday.month, birthday.day);
    if (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      next = DateTime(now.year + 1, birthday.month, birthday.day);
    }
    return next;
  }

  Member copyWith({
    String? name,
    String? photoPath,
    int? avatarIndex,
    String? status,
    DateTime? birthday,
    int? colorIndex,
    int? points,
    int? totalPointsEarned,
  }) {
    return Member(
      id: id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      status: status ?? this.status,
      birthday: birthday ?? this.birthday,
      colorIndex: colorIndex ?? this.colorIndex,
      points: points ?? this.points,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoPath': photoPath,
        'avatarIndex': avatarIndex,
        'status': status,
        'birthday': birthday.toIso8601String(),
        'colorIndex': colorIndex,
        'points': points,
        'totalPointsEarned': totalPointsEarned,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        name: json['name'] as String,
        photoPath: json['photoPath'] as String?,
        avatarIndex: json['avatarIndex'] as int,
        status: json['status'] as String,
        birthday: DateTime.parse(json['birthday'] as String),
        colorIndex: json['colorIndex'] as int,
        points: json['points'] as int? ?? 0,
        totalPointsEarned: json['totalPointsEarned'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

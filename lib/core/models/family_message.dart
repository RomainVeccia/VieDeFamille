import 'package:uuid/uuid.dart';

enum MessageType { message, idea, announcement }

/// Message ou idée partagée entre membres de la famille
class FamilyMessage {
  final String id;
  final String authorId;
  final String content;
  final MessageType type;
  final bool pinned;
  final DateTime createdAt;

  const FamilyMessage({
    required this.id,
    required this.authorId,
    required this.content,
    this.type = MessageType.message,
    this.pinned = false,
    required this.createdAt,
  });

  factory FamilyMessage.create({
    required String authorId,
    required String content,
    MessageType type = MessageType.message,
  }) {
    return FamilyMessage(
      id: const Uuid().v4(),
      authorId: authorId,
      content: content,
      type: type,
      createdAt: DateTime.now(),
    );
  }

  FamilyMessage copyWith({
    String? content,
    MessageType? type,
    bool? pinned,
  }) {
    return FamilyMessage(
      id: id,
      authorId: authorId,
      content: content ?? this.content,
      type: type ?? this.type,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'content': content,
        'type': type.index,
        'pinned': pinned,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FamilyMessage.fromJson(Map<String, dynamic> json) => FamilyMessage(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        content: json['content'] as String,
        type: MessageType.values[json['type'] as int],
        pinned: json['pinned'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

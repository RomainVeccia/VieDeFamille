import 'package:uuid/uuid.dart';

enum MessageType { message, idea, announcement, request }

/// Message ou idée partagée entre membres de la famille
/// recipientId null = message public (mur familial)
/// recipientId renseigné = message direct ou requête à un membre
class FamilyMessage {
  final String id;
  final String authorId;
  final String? recipientId;
  final String content;
  final MessageType type;
  final bool pinned;
  final bool done; // pour les requêtes : marquée comme faite
  final DateTime createdAt;

  const FamilyMessage({
    required this.id,
    required this.authorId,
    this.recipientId,
    required this.content,
    this.type = MessageType.message,
    this.pinned = false,
    this.done = false,
    required this.createdAt,
  });

  factory FamilyMessage.create({
    required String authorId,
    required String content,
    String? recipientId,
    MessageType type = MessageType.message,
  }) {
    return FamilyMessage(
      id: const Uuid().v4(),
      authorId: authorId,
      recipientId: recipientId,
      content: content,
      type: type,
      createdAt: DateTime.now(),
    );
  }

  /// Est-ce un message public (mur familial) ?
  bool get isPublic => recipientId == null;

  /// Est-ce un message direct ?
  bool get isDirect => recipientId != null;

  FamilyMessage copyWith({
    String? content,
    MessageType? type,
    bool? pinned,
    bool? done,
  }) {
    return FamilyMessage(
      id: id,
      authorId: authorId,
      recipientId: recipientId,
      content: content ?? this.content,
      type: type ?? this.type,
      pinned: pinned ?? this.pinned,
      done: done ?? this.done,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'recipientId': recipientId,
        'content': content,
        'type': type.index,
        'pinned': pinned,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FamilyMessage.fromJson(Map<String, dynamic> json) => FamilyMessage(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        recipientId: json['recipientId'] as String?,
        content: json['content'] as String,
        type: MessageType.values[json['type'] as int],
        pinned: json['pinned'] as bool? ?? false,
        done: json['done'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

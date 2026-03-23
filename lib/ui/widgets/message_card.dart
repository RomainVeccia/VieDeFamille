import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vie_de_famille/core/models/family_message.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

/// Card de message sur le mur familial
class MessageCard extends StatelessWidget {
  final FamilyMessage message;
  final Member? author;
  final VoidCallback? onLongPress;

  const MessageCard({
    super.key,
    required this.message,
    this.author,
    this.onLongPress,
  });

  String get _typeLabel {
    switch (message.type) {
      case MessageType.message:
        return 'Message';
      case MessageType.idea:
        return 'Idée 💡';
      case MessageType.announcement:
        return 'Annonce 📢';
    }
  }

  Color get _typeColor {
    switch (message.type) {
      case MessageType.message:
        return AppTheme.primary;
      case MessageType.idea:
        return AppTheme.secondary;
      case MessageType.announcement:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: message.pinned
              ? const BorderSide(color: AppTheme.accent, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header : avatar + nom + date + pin
              Row(
                children: [
                  if (author != null) MemberAvatar(member: author!, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author?.name ?? 'Inconnu',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM à HH:mm').format(message.createdAt),
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge type
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _typeLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _typeColor,
                      ),
                    ),
                  ),
                  if (message.pinned) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.push_pin, size: 16, color: AppTheme.accent),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Contenu
              Text(
                message.content,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

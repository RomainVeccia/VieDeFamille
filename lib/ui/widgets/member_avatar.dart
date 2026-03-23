import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/avatars.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

/// Avatar d'un membre — emoji dans un cercle coloré
class MemberAvatar extends StatelessWidget {
  final Member member;
  final double size;
  final bool showName;
  final bool showPoints;
  final VoidCallback? onTap;

  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 48,
    this.showName = false,
    this.showPoints = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.memberColors[
        member.colorIndex % AppTheme.memberColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
            ),
            child: Center(
              child: Text(
                FamilyAvatars.get(member.avatarIndex),
                style: TextStyle(fontSize: size * 0.45),
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(height: 4),
            Text(
              member.name,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (showPoints) ...[
            const SizedBox(height: 2),
            Text(
              '${member.points} pts',
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

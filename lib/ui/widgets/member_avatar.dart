import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/avatars.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

/// Avatar d'un membre — photo si dispo, sinon emoji dans un cercle coloré
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
    final hasPhoto = member.photoPath != null && member.photoPath!.isNotEmpty;

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
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? _buildPhoto()
                : Center(
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

  Widget _buildPhoto() {
    if (kIsWeb) {
      // Sur le web, les chemins locaux ne marchent pas via File
      // On utilise Image.network pour les data URIs ou URLs
      return Image.network(
        member.photoPath!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => Center(
          child: Text(
            FamilyAvatars.get(member.avatarIndex),
            style: TextStyle(fontSize: size * 0.45),
          ),
        ),
      );
    }
    return Image.file(
      File(member.photoPath!),
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, _, _) => Center(
        child: Text(
          FamilyAvatars.get(member.avatarIndex),
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/add_member_screen.dart';
import 'package:vie_de_famille/ui/screens/member_profile_screen.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

/// Écran famille — grille 2 colonnes des membres
class FamilyViewScreen extends ConsumerWidget {
  const FamilyViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'La Famille',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline,
                      size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun membre',
                    style: GoogleFonts.quicksand(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez votre premier membre !',
                    style: GoogleFonts.nunito(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: members.map((member) {
                  final color = AppTheme.memberColors[
                      member.colorIndex % AppTheme.memberColors.length];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MemberProfileScreen(member: member),
                          ),
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: color, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MemberAvatar(member: member, size: 36),
                                const SizedBox(height: 4),
                                Text(
                                  member.name,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  member.status,
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${member.points} pts',
                                    style: GoogleFonts.nunito(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addMember',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddMemberScreen()),
        ),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

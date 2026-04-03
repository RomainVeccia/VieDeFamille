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
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Adapter la grille pour tout voir sans scroller
                  final cols = members.length <= 4 ? 2 : 3;
                  final rows = (members.length / cols).ceil();
                  const spacing = 8.0;
                  final availH = constraints.maxHeight - (rows - 1) * spacing;
                  final availW = constraints.maxWidth - (cols - 1) * spacing;
                  final cardW = availW / cols;
                  final cardH = availH / rows;
                  final ratio = cardW / cardH;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: ratio.clamp(0.8, 2.0),
                    ),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final color = AppTheme.memberColors[
                          member.colorIndex % AppTheme.memberColors.length];
                      final compact = cardH < 120;

                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MemberProfileScreen(member: member),
                          ),
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: color, width: 2),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: compact ? 4 : 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MemberAvatar(
                                    member: member,
                                    size: compact ? 32 : 40),
                                SizedBox(height: compact ? 3 : 5),
                                Text(
                                  member.name,
                                  style: GoogleFonts.quicksand(
                                    fontSize: compact ? 13 : 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${member.status} · ${member.age} ans',
                                  style: GoogleFonts.nunito(
                                    fontSize: compact ? 10 : 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                SizedBox(height: compact ? 2 : 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${member.points} pts',
                                    style: GoogleFonts.nunito(
                                      fontSize: compact ? 10 : 11,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
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

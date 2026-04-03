import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/core/services/game_score_service.dart';
import 'package:vie_de_famille/ui/screens/games/tetris_game_screen.dart';
import 'package:vie_de_famille/ui/screens/games/marble_game_screen.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

/// Écran de sélection de jeu — "Chance du jour"
class GameSelectionScreen extends ConsumerStatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  ConsumerState<GameSelectionScreen> createState() =>
      _GameSelectionScreenState();
}

class _GameSelectionScreenState extends ConsumerState<GameSelectionScreen> {
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(currentMemberDataProvider);
      if (current != null) {
        setState(() => _selectedMemberId = current.id);
      }
    });
  }

  Member? get _selectedMember {
    final members = ref.read(membersProvider);
    if (_selectedMemberId == null) return null;
    final found = members.where((m) => m.id == _selectedMemberId);
    return found.isNotEmpty ? found.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final scores = ref.watch(gameScoresProvider);
    final members = ref.watch(membersProvider);
    final selected = _selectedMember;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Chance du jour',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélecteur de joueur
            Text(
              'Qui joue ?',
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: members.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final m = members[index];
                  final isSelected = m.id == _selectedMemberId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMemberId = m.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: isSelected
                            ? Border.all(color: AppTheme.primary, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MemberAvatar(member: m, size: 44),
                          const SizedBox(height: 4),
                          Text(
                            m.name,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Choisis ton jeu ! 🎮',
              style: GoogleFonts.quicksand(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gagne des points et grimpe au classement',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            _buildGameCard(
              context: context,
              emoji: '🧱',
              title: 'Tetris',
              subtitle: 'Le classique des blocs qui tombent',
              color: const Color(0xFF2196F3),
              bestScore: selected != null
                  ? GameScoreService.memberBestScore(
                      scores, selected.id, GameType.tetris)
                  : 0,
              onTap: selected != null
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TetrisGameScreen(playerId: selected.id),
                        ),
                      )
                  : null,
            ),
            const SizedBox(height: 12),
            _buildGameCard(
              context: context,
              emoji: '🔮',
              title: 'Marble Madness',
              subtitle: 'Guide la bille jusqu\'au bout !',
              color: const Color(0xFF388E3C),
              bestScore: selected != null
                  ? GameScoreService.memberBestScore(
                      scores, selected.id, GameType.marble)
                  : 0,
              onTap: selected != null
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MarbleGameScreen(playerId: selected.id),
                        ),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required int bestScore,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap != null ? 1.0 : 0.5,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.quicksand(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (bestScore > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Record : $bestScore pts',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.play_arrow_rounded, color: color, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

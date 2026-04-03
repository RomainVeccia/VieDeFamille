import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/core/services/game_score_service.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

/// Écran Classement — scores des jeux par membre
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _games = GameType.values;
  static const _gameColors = [
    Color(0xFF2196F3), // Tetris
    Color(0xFF4CAF50), // Lemmings
    Color(0xFF388E3C), // Marble
    Color(0xFFE53935), // Kart
    Color(0xFFFF8A80), // Worms
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _games.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, [WidgetRef? _]) {
    final scores = ref.watch(gameScoresProvider);
    final members = ref.watch(membersProvider);
    final currentMember = ref.watch(currentMemberDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Classement',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: _games
              .map((g) => Tab(
                    text:
                        '${GameScoreService.gameEmoji(g)} ${GameScoreService.gameName(g)}',
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _games.asMap().entries.map((entry) {
          final i = entry.key;
          final gameType = entry.value;
          final ranking =
              GameScoreService.ranking(scores, members, gameType);
          final hasScores = ranking.any((r) => r.$2 > 0);

          if (!hasScores) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    GameScoreService.gameEmoji(gameType),
                    style: const TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun score encore !',
                    style: GoogleFonts.quicksand(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jouez pour apparaître ici',
                    style: GoogleFonts.nunito(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ranking.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final (member, bestScore) = ranking[index];
              if (bestScore == 0) return const SizedBox.shrink();

              final medal = switch (index) {
                0 => '🥇',
                1 => '🥈',
                2 => '🥉',
                _ => '${index + 1}.',
              };
              final isCurrentUser = member.id == currentMember?.id;

              return Card(
                elevation: isCurrentUser ? 3 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isCurrentUser
                      ? BorderSide(color: _gameColors[i], width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Médaille / rang
                      SizedBox(
                        width: 36,
                        child: index < 3
                            ? Text(medal,
                                style: const TextStyle(fontSize: 24),
                                textAlign: TextAlign.center)
                            : Text(medal,
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 12),
                      // Avatar
                      MemberAvatar(member: member, size: 40),
                      const SizedBox(width: 12),
                      // Nom
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (isCurrentUser)
                              Text(
                                'C\'est toi !',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: _gameColors[i],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Score
                      Text(
                        '$bestScore pts',
                        style: GoogleFonts.quicksand(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _gameColors[i],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

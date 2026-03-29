import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/reward.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

/// Écran récompenses — liste + échange contre des points
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    final currentMember = ref.watch(currentMemberDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Récompenses',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Points du membre courant
          if (currentMember != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary,
                    AppTheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  MemberAvatar(member: currentMember, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentMember.name,
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Points disponibles',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${currentMember.points}',
                    style: GoogleFonts.quicksand(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    ' pts',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

          // Liste des récompenses
          Expanded(
            child: rewards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎁',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Aucune récompense',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ajoutez-en avec le bouton +',
                          style: GoogleFonts.nunito(
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rewards.length,
                    itemBuilder: (context, index) {
                      final reward = rewards[index];
                      final canAfford = currentMember != null &&
                          currentMember.points >= reward.cost;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: canAfford
                              ? const BorderSide(
                                  color: AppTheme.success, width: 1.5)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Text(reward.emoji,
                              style: const TextStyle(fontSize: 32)),
                          title: Text(
                            reward.title,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${reward.cost} pts',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: canAfford
                                  ? AppTheme.success
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          trailing: canAfford
                              ? ElevatedButton(
                                  onPressed: () =>
                                      _claimReward(context, ref, reward),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),
                                  child: const Text('Échanger'),
                                )
                              : Text(
                                  'Il manque ${reward.cost - (currentMember?.points ?? 0)} pts',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReward(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Échanger une récompense contre des points
  void _claimReward(BuildContext context, WidgetRef ref, Reward reward) {
    final current = ref.read(currentMemberDataProvider);
    if (current == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${reward.emoji} ${reward.title}',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Échanger ${reward.cost} points contre cette récompense ?',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(membersProvider.notifier)
                  .removePoints(current.id, reward.cost);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${reward.emoji} ${reward.title} débloqué ! -${reward.cost} pts'),
                ),
              );
            },
            child: const Text('Échanger !'),
          ),
        ],
      ),
    );
  }

  /// Ajouter une nouvelle récompense (custom ou suggestion)
  void _showAddReward(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    var selectedEmoji = '🎁';
    var cost = 50;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle récompense',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Suggestions rapides
              Text('Suggestions :', style: GoogleFonts.nunito(fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: RewardTemplates.suggestions.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Text(s.$1),
                        label: Text(s.$2, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          setSheetState(() {
                            titleController.text = s.$2;
                            selectedEmoji = s.$1;
                            cost = s.$3;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Champ titre
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Récompense',
                  hintText: 'Ex: Pizza ce soir',
                ),
              ),
              const SizedBox(height: 12),

              // Coût en points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Coût :', style: GoogleFonts.nunito(fontSize: 14)),
                  Text(
                    '$cost pts',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: cost.toDouble(),
                min: 10,
                max: 200,
                divisions: 19,
                activeColor: AppTheme.primary,
                label: '$cost pts',
                onChanged: (v) => setSheetState(() => cost = v.round()),
              ),
              const SizedBox(height: 12),

              // Bouton créer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    final current = ref.read(currentMemberDataProvider);
                    if (current == null) return;

                    final reward = Reward.create(
                      title: titleController.text.trim(),
                      emoji: selectedEmoji,
                      cost: cost,
                      createdBy: current.id,
                    );
                    ref.read(rewardsProvider.notifier).add(reward);
                    Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Créer la récompense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

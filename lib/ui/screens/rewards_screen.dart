import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vie_de_famille/core/models/claimed_reward.dart';
import 'package:vie_de_famille/core/models/reward.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

const _tierColors = {
  RewardTier.small:  Color(0xFFCD7F32),
  RewardTier.medium: Color(0xFF9E9E9E),
  RewardTier.large:  Color(0xFFFFB300),
};

RewardTier _tierOf(Reward r) {
  if (r.cost < 50) return RewardTier.small;
  if (r.cost < 150) return RewardTier.medium;
  return RewardTier.large;
}

/// Écran récompenses — 3 niveaux + historique
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewards = ref.watch(rewardsProvider);
    final currentMember = ref.watch(currentMemberDataProvider);
    final isParent = currentMember?.isParent ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Récompenses',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            ...RewardTier.values.map((t) => Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(t.badge, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                Text(t.label,
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            )),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.history, size: 16),
              const SizedBox(width: 4),
              Text('Historique',
                  style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ])),
          ],
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
        ),
      ),
      body: Column(
        children: [
          if (currentMember != null) _PointsBanner(member: currentMember),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                ...RewardTier.values.map((tier) => _RewardList(
                  rewards: rewards.where((r) => _tierOf(r) == tier).toList(),
                  tier: tier,
                  currentPoints: currentMember?.points ?? 0,
                  isParent: isParent,
                  onClaim: (r) => _claimReward(r),
                  onEdit: (r) => _showRewardForm(existing: r),
                  onDelete: (r) =>
                      ref.read(rewardsProvider.notifier).remove(r.id),
                )),
                _HistoryTab(),
              ],
            ),
          ),
        ],
      ),
      // FAB visible seulement pour les parents
      floatingActionButton: isParent
          ? FloatingActionButton.extended(
              heroTag: 'addReward',
              onPressed: () => _showRewardForm(),
              icon: const Icon(Icons.add),
              label: const Text('Récompense'),
            )
          : null,
    );
  }

  void _claimReward(Reward reward) {
    final current = ref.read(currentMemberDataProvider);
    if (current == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${reward.emoji} ${reward.title}',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Échanger ${reward.cost} pts contre cette récompense ?',
                style: GoogleFonts.nunito(fontSize: 15)),
            const SizedBox(height: 8),
            Text('Il te restera ${current.points - reward.cost} pts',
                style: GoogleFonts.nunito(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              // Débiter les points
              ref
                  .read(membersProvider.notifier)
                  .removePoints(current.id, reward.cost);
              // Enregistrer dans l'historique
              ref.read(claimedRewardsProvider.notifier).add(
                    ClaimedReward.create(
                      memberId: current.id,
                      rewardTitle: reward.title,
                      rewardEmoji: reward.emoji,
                      cost: reward.cost,
                    ),
                  );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.success,
                  content: Text(
                    '${reward.emoji} ${reward.title} débloqué ! -${reward.cost} pts',
                    style: GoogleFonts.nunito(color: Colors.white),
                  ),
                ),
              );
            },
            child: const Text('Échanger !'),
          ),
        ],
      ),
    );
  }

  /// Formulaire création / édition (parents uniquement)
  void _showRewardForm({Reward? existing}) {
    final isEdit = existing != null;
    final titleCtrl =
        TextEditingController(text: existing?.title ?? '');
    var emoji = existing?.emoji ?? '🎁';
    var cost = existing?.cost ?? 50;
    RewardTier tier = existing != null
        ? _tierOf(existing)
        : RewardTier.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Modifier la récompense' : 'Nouvelle récompense',
                      style: GoogleFonts.quicksand(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (isEdit)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.error),
                        onPressed: () {
                          ref
                              .read(rewardsProvider.notifier)
                              .remove(existing.id);
                          Navigator.of(ctx).pop();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Suggestions rapides par tier
                ...RewardTier.values.map((t) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(t.badge,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text('${t.label} · ${t.range}',
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: _tierColors[t],
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: RewardTemplates.forTier(t).map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              avatar: Text(s.$1,
                                  style: const TextStyle(fontSize: 13)),
                              label: Text('${s.$2} · ${s.$3}pts',
                                  style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              onPressed: () => setSheet(() {
                                titleCtrl.text = s.$2;
                                emoji = s.$1;
                                cost = s.$3;
                                tier = t;
                              }),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                )),

                const Divider(),
                const SizedBox(height: 8),

                // Champ titre
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom de la récompense',
                    hintText: 'Ex: Soirée pyjama',
                    prefixText: '$emoji  ',
                  ),
                ),
                const SizedBox(height: 12),

                // Slider coût
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Coût :',
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_tierColors[tier] ?? AppTheme.primary)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$cost pts',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color:
                                _tierColors[tier] ?? AppTheme.primary,
                          )),
                    ),
                  ],
                ),
                Slider(
                  value: cost.toDouble(),
                  min: 10,
                  max: 300,
                  divisions: 29,
                  activeColor: _tierColors[tier] ?? AppTheme.primary,
                  label: '$cost pts',
                  onChanged: (v) => setSheet(() {
                    cost = v.round();
                    tier = cost < 50
                        ? RewardTier.small
                        : cost < 150
                            ? RewardTier.medium
                            : RewardTier.large;
                  }),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final current = ref.read(currentMemberDataProvider);
                      if (current == null) return;
                      if (isEdit) {
                        ref.read(rewardsProvider.notifier).update(
                              Reward(
                                id: existing.id,
                                title: titleCtrl.text.trim(),
                                emoji: emoji,
                                cost: cost,
                                createdBy: existing.createdBy,
                                createdAt: existing.createdAt,
                              ),
                            );
                      } else {
                        ref.read(rewardsProvider.notifier).add(
                              Reward.create(
                                title: titleCtrl.text.trim(),
                                emoji: emoji,
                                cost: cost,
                                createdBy: current.id,
                              ),
                            );
                      }
                      Navigator.of(ctx).pop();
                    },
                    icon: Icon(isEdit ? Icons.save : Icons.add),
                    label: Text(
                        isEdit ? 'Enregistrer' : 'Créer la récompense'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Bandeau points
// ─────────────────────────────────────────
class _PointsBanner extends StatelessWidget {
  final dynamic member;
  const _PointsBanner({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          MemberAvatar(member: member, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(
                  member.isParent ? 'Administrateur' : 'Points disponibles',
                  style:
                      GoogleFonts.nunito(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Text('${member.points}',
              style: GoogleFonts.quicksand(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(' pts',
              style:
                  GoogleFonts.nunito(fontSize: 13, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Liste récompenses par tier
// ─────────────────────────────────────────
class _RewardList extends StatelessWidget {
  final List<Reward> rewards;
  final RewardTier tier;
  final int currentPoints;
  final bool isParent;
  final void Function(Reward) onClaim;
  final void Function(Reward) onEdit;
  final void Function(Reward) onDelete;

  const _RewardList({
    required this.rewards,
    required this.tier,
    required this.currentPoints,
    required this.isParent,
    required this.onClaim,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _tierColors[tier] ?? AppTheme.primary;

    if (rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tier.badge, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Aucune récompense ${tier.label.toLowerCase()}',
                style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary)),
            if (isParent) ...[
              const SizedBox(height: 4),
              Text('Appuie sur + pour en ajouter',
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: rewards.length,
      itemBuilder: (context, i) {
        final r = rewards[i];
        final canAfford = currentPoints >= r.cost;
        final missing = r.cost - currentPoints;

        return Dismissible(
          key: Key(r.id),
          direction: isParent
              ? DismissDirection.endToStart
              : DismissDirection.none,
          onDismissed: (_) => onDelete(r),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: canAfford
                  ? BorderSide(color: color, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Emoji
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(
                          alpha: canAfford ? 0.15 : 0.07),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(r.emoji,
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Titre + coût
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: canAfford
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            )),
                        const SizedBox(height: 2),
                        Row(children: [
                          Text('${r.cost} pts',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: canAfford
                                    ? color
                                    : AppTheme.textSecondary,
                              )),
                          if (!canAfford) ...[
                            const SizedBox(width: 6),
                            Text('(encore $missing pts)',
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary)),
                          ],
                        ]),
                      ],
                    ),
                  ),

                  // Bouton parent : modifier
                  if (isParent)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: AppTheme.textSecondary),
                      onPressed: () => onEdit(r),
                    )
                  // Bouton enfant : échanger ou cadenas
                  else if (canAfford)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => onClaim(r),
                      child: Text('Échanger',
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    )
                  else
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_outline,
                          size: 18, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────
// Onglet Historique
// ─────────────────────────────────────────
class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claims = ref.watch(claimedRewardsProvider);
    final members = ref.watch(membersProvider);

    if (claims.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Aucune récompense échangée',
                style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: claims.length,
      itemBuilder: (context, i) {
        final c = claims[i];
        final member =
            members.where((m) => m.id == c.memberId).firstOrNull;
        final tier = c.cost < 50
            ? RewardTier.small
            : c.cost < 150
                ? RewardTier.medium
                : RewardTier.large;
        final color = _tierColors[tier] ?? AppTheme.primary;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text(c.rewardEmoji,
                          style: const TextStyle(fontSize: 22))),
                ),
                if (member != null)
                  Positioned(
                    bottom: -2,
                    right: -4,
                    child: MemberAvatar(member: member, size: 20),
                  ),
              ],
            ),
            title: Text(c.rewardTitle,
                style: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${member?.name ?? '?'} · ${DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(c.claimedAt)}',
              style: GoogleFonts.nunito(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: Text(
              '-${c.cost} pts',
              style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ),
        );
      },
    );
  }
}

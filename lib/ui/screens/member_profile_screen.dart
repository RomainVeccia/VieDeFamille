import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vie_de_famille/core/models/family_message.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/core/services/points_service.dart';
import 'package:vie_de_famille/core/services/task_service.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';
import 'package:vie_de_famille/ui/widgets/task_card.dart';
import 'package:vie_de_famille/core/models/claimed_reward.dart';
import 'package:vie_de_famille/core/models/avatars.dart';

/// Profil d'un membre — avatar, infos, points, tâches, messages, requêtes
class MemberProfileScreen extends ConsumerWidget {
  final Member member;

  const MemberProfileScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    final liveMember = members.firstWhere(
      (m) => m.id == member.id,
      orElse: () => member,
    );

    final allTasks = ref.watch(tasksProvider);
    final memberTasks = TaskService.forMember(allTasks, liveMember.id);
    final allClaims = ref.watch(claimedRewardsProvider);
    final memberClaims = allClaims.where((c) => c.memberId == liveMember.id).toList();
    final pendingTasks = memberTasks.where((t) => !t.completed).toList();
    final completedTasks = memberTasks.where((t) => t.completed).toList();

    // Messages et requêtes reçus par ce membre
    final memberMessages = ref.watch(messagesForMemberProvider(liveMember.id));
    final directMessages =
        memberMessages.where((m) => m.type == MessageType.message).toList();
    final requests =
        memberMessages.where((m) => m.type == MessageType.request).toList();
    final pendingRequests = requests.where((r) => !r.done).toList();
    final doneRequests = requests.where((r) => r.done).toList();

    final title = PointsService.title(liveMember.totalPointsEarned);
    final progress = PointsService.progress(liveMember.totalPointsEarned);
    final nextMilestone =
        PointsService.nextMilestone(liveMember.totalPointsEarned);

    final color = AppTheme.memberColors[
        liveMember.colorIndex % AppTheme.memberColors.length];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          liveMember.name,
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header — avatar + boutons photo / avatar
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _showAvatarPicker(context, ref, liveMember),
                  child: MemberAvatar(member: liveMember, size: 96),
                ),
                // Bouton photo (caméra)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _pickPhoto(context, ref, liveMember),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.background, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                // Bouton avatar (emoji)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () => _showAvatarPicker(context, ref, liveMember),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.background, width: 2),
                      ),
                      child: const Icon(Icons.face, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              liveMember.name,
              style: GoogleFonts.quicksand(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              liveMember.status,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${liveMember.age} ans - ${DateFormat('dd/MM/yyyy').format(liveMember.birthday)}',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // === Boutons actions : Envoyer message + Faire une requête ===
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSendDialog(
                      context,
                      ref,
                      liveMember,
                      MessageType.message,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSendDialog(
                      context,
                      ref,
                      liveMember,
                      MessageType.request,
                    ),
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: const Text('Requête'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section points
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          '${liveMember.totalPointsEarned} pts',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Prochain palier : $nextMilestone pts',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // === Section requêtes reçues ===
            if (requests.isNotEmpty) ...[
              _sectionTitle('Requêtes reçues', Icons.assignment),
              const SizedBox(height: 8),
              ...pendingRequests.map((r) => _buildRequestCard(ref, r, members)),
              if (doneRequests.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Terminées (${doneRequests.length})',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                ...doneRequests.map((r) => _buildRequestCard(ref, r, members)),
              ],
              const SizedBox(height: 24),
            ],

            // === Section messages reçus ===
            if (directMessages.isNotEmpty) ...[
              _sectionTitle('Messages reçus', Icons.chat_bubble_outline),
              const SizedBox(height: 8),
              ...directMessages.map((msg) {
                final author =
                    members.where((m) => m.id == msg.authorId).firstOrNull;
                return Card(
                  child: ListTile(
                    leading: author != null
                        ? MemberAvatar(member: author, size: 36)
                        : null,
                    title: Text(
                      msg.content,
                      style: GoogleFonts.nunito(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${author?.name ?? "?"} - ${DateFormat('dd/MM HH:mm').format(msg.createdAt)}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // === Section tâches à faire ===
            _sectionTitle(
                'Tâches à faire (${pendingTasks.length})',
                Icons.check_circle_outline),
            const SizedBox(height: 8),
            if (pendingTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Aucune tâche en cours 🎉',
                  style: GoogleFonts.nunito(color: AppTheme.textSecondary),
                ),
              )
            else
              ...pendingTasks.map((task) => TaskCard(
                    task: task,
                    assignee: liveMember,
                    onToggle: (_) =>
                        ref.read(tasksProvider.notifier).toggle(task.id),
                  )),

            // === Section tâches terminées ===
            if (completedTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle(
                  'Terminées (${completedTasks.length})',
                  Icons.task_alt),
              const SizedBox(height: 8),
              ...completedTasks.map((task) => Opacity(
                    opacity: 0.6,
                    child: TaskCard(
                      task: task,
                      assignee: liveMember,
                      onToggle: (_) =>
                          ref.read(tasksProvider.notifier).toggle(task.id),
                    ),
                  )),
            ],

            // === Section récompenses obtenues ===
            const SizedBox(height: 24),
            _sectionTitle(
                'Récompenses obtenues (${memberClaims.length})',
                Icons.emoji_events),
            const SizedBox(height: 8),
            if (memberClaims.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Aucune récompense encore échangée',
                  style: GoogleFonts.nunito(color: AppTheme.textSecondary),
                ),
              )
            else
              ...memberClaims.map((claim) => _buildClaimCard(claim)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimCard(ClaimedReward claim) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(claim.rewardEmoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          claim.rewardTitle,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(claim.claimedAt),
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '-${claim.cost} pts',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE65100),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textPrimary),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
      WidgetRef ref, FamilyMessage request, List<Member> members) {
    final author =
        members.where((m) => m.id == request.authorId).firstOrNull;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: request.done ? AppTheme.success : AppTheme.secondary,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: request.done,
          onChanged: (_) =>
              ref.read(messagesProvider.notifier).toggleDone(request.id),
          activeColor: AppTheme.success,
        ),
        title: Text(
          request.content,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: request.done ? TextDecoration.lineThrough : null,
            color: request.done ? AppTheme.textSecondary : AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          'De ${author?.name ?? "?"} - ${DateFormat('dd/MM').format(request.createdAt)}',
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Ouvre le sélecteur d'avatar avec verrous par palier de points
  void _showAvatarPicker(BuildContext context, WidgetRef ref, Member member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choisir un avatar',
                style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${member.totalPointsEarned} pts gagnés — ${_unlockedCount(member.totalPointsEarned)} avatars débloqués',
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              _AvatarTierPickerSheet(
                selectedIndex: member.avatarIndex,
                totalPoints: member.totalPointsEarned,
                onSelect: (i) {
                  final updated = member.copyWith(avatarIndex: i);
                  ref.read(membersProvider.notifier).update(updated);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _unlockedCount(int pts) =>
      FamilyAvatars.tiers.where((t) => pts >= t.requiredPoints).fold(0, (acc, t) => acc + t.emojis.length);

  /// Choisir une photo de profil depuis la galerie
  void _pickPhoto(
      BuildContext context, WidgetRef ref, Member member) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) {
      final updated = member.copyWith(photoPath: image.path);
      ref.read(membersProvider.notifier).update(updated);
    }
  }

  /// Dialogue pour envoyer un message ou une requête
  void _showSendDialog(
    BuildContext context,
    WidgetRef ref,
    Member recipient,
    MessageType type,
  ) {
    final controller = TextEditingController();
    final isRequest = type == MessageType.request;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isRequest
              ? 'Requête pour ${recipient.name}'
              : 'Message à ${recipient.name}',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isRequest
                ? 'Ex: Peux-tu sortir les poubelles ?'
                : 'Votre message...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              final current = ref.read(currentMemberDataProvider);
              if (current == null) return;

              final msg = FamilyMessage.create(
                authorId: current.id,
                recipientId: recipient.id,
                content: controller.text.trim(),
                type: type,
              );
              ref.read(messagesProvider.notifier).add(msg);
              Navigator.of(ctx).pop();
            },
            icon: Icon(isRequest ? Icons.send : Icons.chat_bubble),
            label: Text(isRequest ? 'Envoyer' : 'Envoyer'),
          ),
        ],
      ),
    );
  }
}

/// Grille d'avatars avec verrous — utilisée dans le bottom sheet du profil
class _AvatarTierPickerSheet extends StatelessWidget {
  final int selectedIndex;
  final int totalPoints;
  final void Function(int index) onSelect;

  const _AvatarTierPickerSheet({
    required this.selectedIndex,
    required this.totalPoints,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    int globalIndex = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: FamilyAvatars.tiers.map((tier) {
        final tierStart = globalIndex;
        globalIndex += tier.emojis.length;
        final isLocked = totalPoints < tier.requiredPoints;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              child: Row(
                children: [
                  Text(tier.badge, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    tier.label,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isLocked ? Colors.grey.shade400 : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (tier.requiredPoints > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.grey.shade200
                            : AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
                            size: 11,
                            color: isLocked ? Colors.grey.shade400 : AppTheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${tier.requiredPoints} pts',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isLocked ? Colors.grey.shade400 : AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: tier.emojis.length,
              itemBuilder: (_, i) {
                final index = tierStart + i;
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: isLocked ? null : () => onSelect(index),
                  child: Opacity(
                    opacity: isLocked ? 0.3 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tier.emojis[i],
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }
}

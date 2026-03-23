import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/core/services/points_service.dart';
import 'package:vie_de_famille/core/services/task_service.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';
import 'package:vie_de_famille/ui/widgets/task_card.dart';

/// Profil d'un membre — avatar, infos, points, tâches assignées
class MemberProfileScreen extends ConsumerWidget {
  final Member member;

  const MemberProfileScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Suivre les données live du membre (points à jour)
    final members = ref.watch(membersProvider);
    final liveMember = members.firstWhere(
      (m) => m.id == member.id,
      orElse: () => member,
    );

    final allTasks = ref.watch(tasksProvider);
    final memberTasks = TaskService.forMember(allTasks, liveMember.id);
    final pendingTasks = memberTasks.where((t) => !t.completed).toList();

    final title = PointsService.title(liveMember.totalPointsEarned);
    final progress = PointsService.progress(liveMember.totalPointsEarned);
    final nextMilestone =
        PointsService.nextMilestone(liveMember.totalPointsEarned);

    final color = AppTheme.memberColors[
        liveMember.colorIndex % AppTheme.memberColors.length];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          liveMember.name,
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header — avatar + infos
            MemberAvatar(member: liveMember, size: 96),
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
                    // Barre de progression
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

            // Section tâches assignées
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tâches assignées',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (pendingTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucune tâche en cours',
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
          ],
        ),
      ),
    );
  }
}

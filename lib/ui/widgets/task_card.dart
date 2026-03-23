import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/family_task.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

/// Card de tâche avec checkbox, assigné et priorité
class TaskCard extends StatelessWidget {
  final FamilyTask task;
  final Member? assignee;
  final ValueChanged<bool?> onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const TaskCard({
    super.key,
    required this.task,
    this.assignee,
    required this.onToggle,
    this.onTap,
    this.onDismissed,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.high:
        return AppTheme.error;
      case TaskPriority.medium:
        return AppTheme.secondary;
      case TaskPriority.low:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: onDismissed != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onDismissed: (_) => onDismissed?.call(),
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: task.completed,
                  onChanged: onToggle,
                  activeColor: AppTheme.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // Priorité (petit point coloré)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),

                // Titre + points
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: task.completed
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        '+${task.pointsValue} pts',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: task.completed
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Avatar assigné
                if (assignee != null)
                  MemberAvatar(member: assignee!, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

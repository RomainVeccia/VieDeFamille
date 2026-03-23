import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/family_task.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/core/services/task_service.dart';
import 'package:vie_de_famille/ui/screens/add_task_screen.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/task_card.dart';

/// Écran tâches — filtres par membre + listes pending/done
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  /// null = toutes, 'today' = aujourd'hui, sinon memberId
  String? _filter;
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(tasksProvider);
    final members = ref.watch(membersProvider);

    // Appliquer les filtres
    List<FamilyTask> filtered;
    if (_filter == null) {
      filtered = allTasks;
    } else if (_filter == 'today') {
      filtered = TaskService.todayTasks(allTasks);
    } else {
      filtered = TaskService.forMember(allTasks, _filter!);
    }

    final pending = filtered.where((t) => !t.completed).toList();
    final completed = filtered.where((t) => t.completed).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Tâches',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Chips de filtre
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildChip('Toutes', null),
                const SizedBox(width: 8),
                _buildChip("Aujourd'hui", 'today'),
                ...members.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      avatar: CircleAvatar(
                        backgroundColor: AppTheme.memberColors[
                            m.colorIndex % AppTheme.memberColors.length],
                        radius: 12,
                        child: Text(
                          m.name.isNotEmpty ? m.name[0] : '?',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white),
                        ),
                      ),
                      label: Text(m.name),
                      selected: _filter == m.id,
                      onSelected: (_) =>
                          setState(() => _filter = _filter == m.id ? null : m.id),
                      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Liste des tâches
          Expanded(
            child: pending.isEmpty && completed.isEmpty
                ? Center(
                    child: Text(
                      'Aucune tâche',
                      style:
                          GoogleFonts.nunito(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Tâches en attente
                      ...pending.map((task) {
                        final assignee = task.assignedTo != null
                            ? members
                                .where((m) => m.id == task.assignedTo)
                                .firstOrNull
                            : null;
                        return TaskCard(
                          task: task,
                          assignee: assignee,
                          onToggle: (_) => ref
                              .read(tasksProvider.notifier)
                              .toggle(task.id),
                          onDismissed: () => ref
                              .read(tasksProvider.notifier)
                              .remove(task.id),
                        );
                      }),

                      // Section terminées (pliable)
                      if (completed.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => setState(
                              () => _showCompleted = !_showCompleted),
                          child: Row(
                            children: [
                              Icon(
                                _showCompleted
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Terminées (${completed.length})',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showCompleted)
                          ...completed.map((task) {
                            final assignee = task.assignedTo != null
                                ? members
                                    .where((m) => m.id == task.assignedTo)
                                    .firstOrNull
                                : null;
                            return TaskCard(
                              task: task,
                              assignee: assignee,
                              onToggle: (_) => ref
                                  .read(tasksProvider.notifier)
                                  .toggle(task.id),
                            );
                          }),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddTaskScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChip(String label, String? filterValue) {
    return FilterChip(
      label: Text(label),
      selected: _filter == filterValue,
      onSelected: (_) =>
          setState(() => _filter = _filter == filterValue ? null : filterValue),
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
    );
  }
}

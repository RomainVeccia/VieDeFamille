import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/family_task.dart';
import 'package:vie_de_famille/core/models/task_templates.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

/// Écran de sélection de tâches pré-remplies par catégorie
class TaskTemplatesScreen extends ConsumerStatefulWidget {
  const TaskTemplatesScreen({super.key});

  @override
  ConsumerState<TaskTemplatesScreen> createState() =>
      _TaskTemplatesScreenState();
}

class _TaskTemplatesScreenState extends ConsumerState<TaskTemplatesScreen> {
  final Set<int> _selectedIndices = {};
  String? _assignedTo;
  TaskCategory _currentCategory = TaskCategory.enfants;

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);
    final templates = TaskTemplates.forCategory(_currentCategory);

    // Grouper par récurrence
    final daily =
        templates.where((t) => t.recurrence == TaskRecurrence.daily).toList();
    final weekly =
        templates.where((t) => t.recurrence == TaskRecurrence.weekly).toList();
    final monthly =
        templates.where((t) => t.recurrence == TaskRecurrence.monthly).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ajouter des tâches',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Tabs catégories
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: TaskTemplates.categories.entries.map((entry) {
                final cat = entry.key;
                final label = entry.value.$1;
                final emoji = entry.value.$2;
                final selected = _currentCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Text(emoji, style: const TextStyle(fontSize: 16)),
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _currentCategory = cat;
                      _selectedIndices.clear();
                    }),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Assigner à
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Assigner à :',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final m = members[index];
                        final selected = _assignedTo == m.id;
                        return GestureDetector(
                          onTap: () => setState(
                            () => _assignedTo = selected ? null : m.id,
                          ),
                          child: Opacity(
                            opacity: selected ? 1.0 : 0.4,
                            child: Container(
                              decoration: selected
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primary,
                                        width: 2,
                                      ),
                                    )
                                  : null,
                              child: MemberAvatar(member: m, size: 40),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Bouton tout sélectionner / désélectionner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_selectedIndices.length == templates.length) {
                        _selectedIndices.clear();
                      } else {
                        _selectedIndices.clear();
                        _selectedIndices.addAll(
                          List.generate(templates.length, (i) => i),
                        );
                      }
                    });
                  },
                  icon: Icon(
                    _selectedIndices.length == templates.length
                        ? Icons.deselect
                        : Icons.select_all,
                    size: 18,
                  ),
                  label: Text(
                    _selectedIndices.length == templates.length
                        ? 'Tout désélectionner'
                        : 'Tout sélectionner',
                    style: GoogleFonts.nunito(fontSize: 13),
                  ),
                ),
                const Spacer(),
                if (_selectedIndices.isNotEmpty)
                  Text(
                    '${_selectedIndices.length}/${templates.length}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // Liste des templates
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (daily.isNotEmpty) ...[
                  _sectionHeader('📅 Tous les jours', '5 pts chacune'),
                  ...daily.map((t) => _buildTemplateCard(t, templates)),
                  const SizedBox(height: 12),
                ],
                if (weekly.isNotEmpty) ...[
                  _sectionHeader('📆 Chaque semaine', '10-15 pts chacune'),
                  ...weekly.map((t) => _buildTemplateCard(t, templates)),
                  const SizedBox(height: 12),
                ],
                if (monthly.isNotEmpty) ...[
                  _sectionHeader('🗓️ Chaque mois', '15-30 pts chacune'),
                  ...monthly.map((t) => _buildTemplateCard(t, templates)),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      // Bouton flottant : ajouter les tâches sélectionnées
      floatingActionButton: _selectedIndices.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _addSelectedTasks(templates),
              icon: const Icon(Icons.add),
              label: Text('Ajouter ${_selectedIndices.length} tâche(s)'),
            )
          : FloatingActionButton.extended(
              onPressed: () => _addAllTasks(templates),
              icon: const Icon(Icons.select_all),
              label: const Text('Tout ajouter'),
            ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
      TaskTemplate template, List<TaskTemplate> allTemplates) {
    final index = allTemplates.indexOf(template);
    final selected = _selectedIndices.contains(index);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? const BorderSide(color: AppTheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Text(template.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(
          template.title,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '+${template.pointsValue} pts',
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: AppTheme.success,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Checkbox(
          value: selected,
          onChanged: (_) => setState(() {
            if (selected) {
              _selectedIndices.remove(index);
            } else {
              _selectedIndices.add(index);
            }
          }),
          activeColor: AppTheme.primary,
        ),
        onTap: () => setState(() {
          if (selected) {
            _selectedIndices.remove(index);
          } else {
            _selectedIndices.add(index);
          }
        }),
      ),
    );
  }

  Future<void> _addSelectedTasks(List<TaskTemplate> templates) async {
    final current = ref.read(currentMemberDataProvider);
    if (current == null) return;

    for (final index in _selectedIndices) {
      final t = templates[index];
      final task = FamilyTask.create(
        title: t.title,
        createdBy: current.id,
        assignedTo: _assignedTo,
        category: t.category,
        recurrence: t.recurrence,
        pointsValue: t.pointsValue,
      );
      await ref.read(tasksProvider.notifier).add(task);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${_selectedIndices.length} tâche(s) ajoutée(s) ! 🎉'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _addAllTasks(List<TaskTemplate> templates) async {
    final current = ref.read(currentMemberDataProvider);
    if (current == null) return;

    for (final t in templates) {
      final task = FamilyTask.create(
        title: t.title,
        createdBy: current.id,
        assignedTo: _assignedTo,
        category: t.category,
        recurrence: t.recurrence,
        pointsValue: t.pointsValue,
      );
      await ref.read(tasksProvider.notifier).add(task);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Toutes les tâches ${TaskTemplates.categories[_currentCategory]!.$1} ajoutées ! 🎉'),
        ),
      );
      Navigator.of(context).pop();
    }
  }
}

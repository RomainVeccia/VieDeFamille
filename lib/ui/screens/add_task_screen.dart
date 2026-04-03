import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vie_de_famille/core/models/family_task.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

/// Formulaire de création/édition d'une tâche
class AddTaskScreen extends ConsumerStatefulWidget {
  final FamilyTask? task; // null = création, non-null = édition

  const AddTaskScreen({super.key, this.task});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  String? _assignedTo;
  late TaskPriority _priority;
  DateTime? _dueDate;
  late double _pointsValue;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _assignedTo = t?.assignedTo;
    _priority = t?.priority ?? TaskPriority.medium;
    _dueDate = t?.dueDate;
    _pointsValue = (t?.pointsValue ?? 10).toDouble();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(tasksProvider.notifier);

    if (_isEditing) {
      final t = widget.task!;
      final updated = FamilyTask(
        id: t.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        assignedTo: _assignedTo,
        createdBy: t.createdBy,
        priority: _priority,
        recurrence: t.recurrence,
        category: t.category,
        dueDate: _dueDate,
        completed: t.completed,
        completedAt: t.completedAt,
        pointsValue: _pointsValue.round(),
        createdAt: t.createdAt,
      );
      await notifier.update(updated);
    } else {
      final currentMember = ref.read(currentMemberDataProvider);
      if (currentMember == null) return;
      final task = FamilyTask.create(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        assignedTo: _assignedTo,
        createdBy: currentMember.id,
        priority: _priority,
        dueDate: _dueDate,
        pointsValue: _pointsValue.round(),
      );
      await notifier.add(task);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Modifier la tâche' : 'Nouvelle tâche',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Ex: Sortir les poubelles',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Détails supplémentaires...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Assigner à — avatars horizontaux
              Text(
                'Assigner à',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    final selected = _assignedTo == m.id;
                    return GestureDetector(
                      onTap: () => setState(
                        () => _assignedTo = selected ? null : m.id,
                      ),
                      child: Opacity(
                        opacity: selected ? 1.0 : 0.5,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: selected
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primary,
                                        width: 3,
                                      ),
                                    )
                                  : null,
                              child: MemberAvatar(member: m, size: 44),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.name,
                              style: GoogleFonts.nunito(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Priorité
              Text(
                'Priorité',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityButton(
                      'Faible', TaskPriority.low, AppTheme.success),
                  const SizedBox(width: 8),
                  _buildPriorityButton(
                      'Moyen', TaskPriority.medium, AppTheme.secondary),
                  const SizedBox(width: 8),
                  _buildPriorityButton(
                      'Urgent', TaskPriority.high, AppTheme.error),
                ],
              ),
              const SizedBox(height: 20),

              // Date limite
              Text(
                'Date limite (optionnel)',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDueDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _dueDate != null
                            ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                            : 'Choisir une date',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: _dueDate != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Points (slider)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Points',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_pointsValue.round()} pts',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _pointsValue,
                min: 5,
                max: 50,
                divisions: 9,
                activeColor: AppTheme.primary,
                label: '${_pointsValue.round()} pts',
                onChanged: (v) => setState(() => _pointsValue = v),
              ),
              const SizedBox(height: 24),

              // Bouton sauvegarder
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Enregistrer' : 'Créer la tâche'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(
      String label, TaskPriority priority, Color color) {
    final selected = _priority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

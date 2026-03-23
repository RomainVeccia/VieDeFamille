import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vie_de_famille/core/models/avatars.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/home_screen.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

/// Formulaire d'ajout d'un nouveau membre de la famille
class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _statusController = TextEditingController();
  DateTime? _birthday;
  int _avatarIndex = 0;
  int _colorIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une date de naissance')),
      );
      return;
    }

    final member = Member.create(
      name: _nameController.text.trim(),
      status: _statusController.text.trim(),
      birthday: _birthday!,
      avatarIndex: _avatarIndex,
      colorIndex: _colorIndex,
    );

    await ref.read(membersProvider.notifier).add(member);

    // Si c'est le premier membre, on le définit comme membre courant
    final members = ref.read(membersProvider);
    if (members.length == 1) {
      await ref.read(currentMemberProvider.notifier).set(member.id);
    }

    if (!mounted) return;

    // Si on peut pop (vient du FamilyViewScreen) → retour
    // Sinon (premier lancement depuis splash) → aller au HomeScreen
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Nouveau membre',
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
              // Nom
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  hintText: 'Ex: Marie',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // Status
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(
                  labelText: 'Statut',
                  hintText: 'Ex: Maman, Papa, Fils...',
                ),
              ),
              const SizedBox(height: 16),

              // Date de naissance
              Text(
                'Date de naissance',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickBirthday,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _birthday != null
                        ? DateFormat('dd/MM/yyyy').format(_birthday!)
                        : 'Choisir une date',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: _birthday != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Avatar — grille d'emojis
              Text(
                'Avatar',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: FamilyAvatars.emojis.length,
                itemBuilder: (context, index) {
                  final selected = _avatarIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _avatarIndex = index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          FamilyAvatars.emojis[index],
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Couleur
              Text(
                'Couleur',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  AppTheme.memberColors.length,
                  (index) {
                    final c = AppTheme.memberColors[index];
                    final selected = _colorIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _colorIndex = index),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppTheme.textPrimary : c,
                            width: selected ? 3 : 0,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Bouton sauvegarder
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

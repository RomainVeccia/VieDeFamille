import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _photoPath;

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _photoPath = image.path);
    }
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
      photoPath: _photoPath,
    );

    await ref.read(membersProvider.notifier).add(member);

    // Toujours définir le membre courant s'il n'y en a pas
    final currentId = ref.read(currentMemberProvider);
    if (currentId == null) {
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
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
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

              // Photo de profil
              Text(
                'Photo',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.15),
                        backgroundImage: _photoPath != null
                            ? (kIsWeb
                                    ? NetworkImage(_photoPath!)
                                    : FileImage(File(_photoPath!)))
                                as ImageProvider
                            : null,
                        child: _photoPath == null
                            ? Text(
                                FamilyAvatars.get(_avatarIndex),
                                style: const TextStyle(fontSize: 40),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.background, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_photoPath != null)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _photoPath = null),
                    child: Text(
                      'Supprimer la photo',
                      style: GoogleFonts.nunito(color: AppTheme.error),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Avatar emoji (fallback si pas de photo)
              Text(
                'Ou choisir un avatar',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _AvatarTierGrid(
                selectedIndex: _avatarIndex,
                unlockedPoints: null, // création = tout visible
                onSelect: (i) => setState(() => _avatarIndex = i),
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

/// Grille d'avatars groupée par tier — réutilisée dans add_member et profile
class _AvatarTierGrid extends StatelessWidget {
  /// Index avatar sélectionné
  final int selectedIndex;

  /// Points totaux du membre (null = tout débloqué — ex: création)
  final int? unlockedPoints;

  final void Function(int index) onSelect;

  const _AvatarTierGrid({
    required this.selectedIndex,
    required this.unlockedPoints,
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
        final isLocked = unlockedPoints != null &&
            unlockedPoints! < tier.requiredPoints;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du tier
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
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
            // Grille 10 avatars
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
                    opacity: isLocked ? 0.35 : 1.0,
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

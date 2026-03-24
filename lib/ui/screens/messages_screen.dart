import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/family_message.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/message_card.dart';

/// Écran messages — mur familial avec messages, idées, annonces
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMessages = ref.watch(messagesProvider);
    final members = ref.watch(membersProvider);

    // Mur familial = messages publics uniquement (pas les directs)
    final messages = allMessages.where((m) => m.isPublic).toList();

    final pinned = messages.where((m) => m.pinned).toList();
    final unpinned = messages.where((m) => !m.pinned).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: messages.isEmpty
          ? Center(
              child: Text(
                'Aucun message',
                style: GoogleFonts.nunito(color: AppTheme.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Messages épinglés
                if (pinned.isNotEmpty) ...[
                  ...pinned.map((msg) {
                    final author =
                        members.where((m) => m.id == msg.authorId).firstOrNull;
                    return MessageCard(
                      message: msg,
                      author: author,
                      onLongPress: () =>
                          _showMessageOptions(context, ref, msg),
                    );
                  }),
                  const Divider(height: 24),
                ],
                // Reste des messages
                ...unpinned.map((msg) {
                  final author =
                      members.where((m) => m.id == msg.authorId).firstOrNull;
                  return MessageCard(
                    message: msg,
                    author: author,
                    onLongPress: () =>
                        _showMessageOptions(context, ref, msg),
                  );
                }),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewMessageSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Options sur un message (épingler / supprimer)
  void _showMessageOptions(
      BuildContext context, WidgetRef ref, FamilyMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Options',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                msg.pinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: AppTheme.accent,
              ),
              title: Text(msg.pinned ? 'Désépingler' : 'Épingler'),
              onTap: () {
                ref.read(messagesProvider.notifier).togglePin(msg.id);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.error),
              title: const Text('Supprimer'),
              onTap: () {
                ref.read(messagesProvider.notifier).remove(msg.id);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet pour créer un nouveau message
  void _showNewMessageSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    var selectedType = MessageType.message;

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
                'Nouveau message',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Votre message...',
                ),
              ),
              const SizedBox(height: 12),
              // Chips type
              Row(
                children: [
                  _typeChip(
                    'Message',
                    MessageType.message,
                    selectedType,
                    (t) => setSheetState(() => selectedType = t),
                  ),
                  const SizedBox(width: 8),
                  _typeChip(
                    'Idée',
                    MessageType.idea,
                    selectedType,
                    (t) => setSheetState(() => selectedType = t),
                  ),
                  const SizedBox(width: 8),
                  _typeChip(
                    'Annonce',
                    MessageType.announcement,
                    selectedType,
                    (t) => setSheetState(() => selectedType = t),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    final current = ref.read(currentMemberDataProvider);
                    if (current == null) return;

                    final msg = FamilyMessage.create(
                      authorId: current.id,
                      content: controller.text.trim(),
                      type: selectedType,
                    );
                    ref.read(messagesProvider.notifier).add(msg);
                    Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(
    String label,
    MessageType type,
    MessageType selected,
    ValueChanged<MessageType> onSelected,
  ) {
    final isSelected = selected == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(type),
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
    );
  }
}

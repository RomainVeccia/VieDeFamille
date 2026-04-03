import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/shopping_list.dart';
import 'package:vie_de_famille/core/models/shopping_item.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/core/services/shopping_service.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

/// Écran principal des listes de courses
class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListsProvider);
    final items = ref.watch(shoppingItemsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Courses', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddListDialog(context, ref),
            tooltip: 'Nouvelle liste',
          ),
        ],
      ),
      body: lists.isEmpty
          ? _EmptyState(onAdd: () => _showAddListDialog(context, ref))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                final count = ShoppingService.count(items, list.id);
                final done = items.where((i) => i.listId == list.id && i.checked).length;
                return _ShoppingListCard(
                  list: list,
                  itemCount: count,
                  doneCount: done,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ShoppingListDetail(list: list),
                    ),
                  ),
                  onDelete: () => _confirmDelete(context, ref, list, items),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddListDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddListDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final currentMember = ref.read(currentMemberDataProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nouvelle liste', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex: Courses du week-end'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              ref.read(shoppingListsProvider.notifier).add(
                    ShoppingList.create(
                      name: name,
                      createdBy: currentMember?.id ?? 'unknown',
                    ),
                  );
              Navigator.of(ctx).pop();
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
    List<ShoppingItem> items,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer "${list.name}" ?',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: const Text('Tous les articles de cette liste seront supprimés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () {
              ref.read(shoppingItemsProvider.notifier).removeForList(list.id);
              ref.read(shoppingListsProvider.notifier).remove(list.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _ShoppingListCard extends StatelessWidget {
  final ShoppingList list;
  final int itemCount;
  final int doneCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ShoppingListCard({
    required this.list,
    required this.itemCount,
    required this.doneCount,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = itemCount > 0 ? doneCount / itemCount : 0.0;
    final allDone = itemCount > 0 && doneCount == itemCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: allDone
                          ? AppTheme.success.withValues(alpha: 0.15)
                          : AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      allDone ? Icons.check_circle : Icons.shopping_cart,
                      color: allDone ? AppTheme.success : AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          itemCount == 0
                              ? 'Aucun article'
                              : '$doneCount/$itemCount article${itemCount > 1 ? 's' : ''}',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (itemCount > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      allDone ? AppTheme.success : AppTheme.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Aucune liste de courses',
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crée ta première liste\npour commencer les courses !',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle liste'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DÉTAIL D'UNE LISTE
// ============================================================

class _ShoppingListDetail extends ConsumerStatefulWidget {
  final ShoppingList list;
  const _ShoppingListDetail({required this.list});

  @override
  ConsumerState<_ShoppingListDetail> createState() => _ShoppingListDetailState();
}

class _ShoppingListDetailState extends ConsumerState<_ShoppingListDetail> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shoppingItemsProvider);
    final listItems = ShoppingService.forList(items, widget.list.id);

    final toGet = listItems.where((i) => !i.checked).toList()
      ..sort((a, b) => a.category.index.compareTo(b.category.index));
    final inCart = listItems.where((i) => i.checked).toList()
      ..sort((a, b) => a.category.index.compareTo(b.category.index));

    final total = listItems.length;
    final done = inCart.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.list.name,
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        actions: [
          if (inCart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tout remettre dans la liste',
              onPressed: () =>
                  ref.read(shoppingItemsProvider.notifier).uncheckAll(widget.list.id),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          if (total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? done / total : 0,
                        minHeight: 8,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                            done == total ? AppTheme.success : AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    toGet.isEmpty ? 'Tout dans le caddie !' : '${toGet.length} restant${toGet.length > 1 ? 's' : ''}',
                    style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          Expanded(
            child: listItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun article dans cette liste',
                          style: GoogleFonts.nunito(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    children: [
                      // ── Zone 1 : À acheter ──
                      if (toGet.isNotEmpty) ...[
                        _SectionHeader(
                          label: 'À acheter',
                          count: toGet.length,
                          color: AppTheme.primary,
                        ),
                        ...toGet.map((item) => _ToGetTile(item: item)),
                      ],

                      // ── Zone 2 : Dans le caddie ──
                      if (inCart.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SectionHeader(
                          label: 'Dans le caddie',
                          count: inCart.length,
                          color: AppTheme.success,
                          icon: Icons.shopping_cart,
                        ),
                        ...inCart.map((item) => _InCartTile(item: item)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddShoppingItemScreen(listId: widget.list.id),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    this.icon = Icons.check_box_outline_blank,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.nunito(fontSize: 12, color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Article à acheter — case à cocher vide, tap = passe dans le caddie
class _ToGetTile extends ConsumerWidget {
  final ShoppingItem item;
  const _ToGetTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        onTap: () => ref.read(shoppingItemsProvider.notifier).toggle(item.id),
        leading: GestureDetector(
          onTap: () => ref.read(shoppingItemsProvider.notifier).toggle(item.id),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.primary, width: 2),
              color: Colors.transparent,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          item.quantity != null
              ? '${item.category.emoji} ${item.category.label}  ·  ${item.quantity}'
              : '${item.category.emoji} ${item.category.label}',
          style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
          onPressed: () => ref.read(shoppingItemsProvider.notifier).remove(item.id),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

/// Article dans le caddie — coché, barré, bouton "Remettre dans la liste"
class _InCartTile extends ConsumerWidget {
  final ShoppingItem item;
  const _InCartTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: AppTheme.success.withValues(alpha: 0.06),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => ref.read(shoppingItemsProvider.notifier).toggle(item.id),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(6),
              color: AppTheme.success,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: AppTheme.textSecondary,
            decoration: TextDecoration.lineThrough,
            decorationColor: AppTheme.textSecondary,
          ),
        ),
        subtitle: Text(
          item.quantity != null
              ? '${item.category.emoji}  ·  ${item.quantity}'
              : item.category.emoji,
          style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: TextButton.icon(
          onPressed: () => ref.read(shoppingItemsProvider.notifier).toggle(item.id),
          icon: const Icon(Icons.add, size: 15),
          label: const Text('Remettre', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FORMULAIRE AJOUT ARTICLE
// ============================================================

class AddShoppingItemScreen extends ConsumerStatefulWidget {
  final String listId;
  const AddShoppingItemScreen({super.key, required this.listId});

  @override
  ConsumerState<AddShoppingItemScreen> createState() => _AddShoppingItemScreenState();
}

class _AddShoppingItemScreenState extends ConsumerState<AddShoppingItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  ShoppingCategory _selectedCategory = ShoppingCategory.autres;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final currentMember = ref.read(currentMemberDataProvider);
    ref.read(shoppingItemsProvider.notifier).add(
          ShoppingItem.create(
            listId: widget.listId,
            name: name,
            quantity: _quantityController.text.trim().isEmpty
                ? null
                : _quantityController.text.trim(),
            category: _selectedCategory,
            addedBy: currentMember?.id ?? 'unknown',
          ),
        );
    // Vider pour ajouter un autre article rapidement
    _nameController.clear();
    _quantityController.clear();
    setState(() => _selectedCategory = ShoppingCategory.autres);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Ajouter un article',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Article *',
                hintText: 'Ex: Lait, Pain, Yaourts...',
                prefixIcon: Icon(Icons.shopping_basket_outlined),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité (optionnel)',
                hintText: 'Ex: 2, 500g, 1 paquet',
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Catégorie',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ShoppingCategory.values.map((cat) {
                final selected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text('${cat.emoji} ${cat.label}'),
                  selected: selected,
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

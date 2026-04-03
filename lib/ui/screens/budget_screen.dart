import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vie_de_famille/core/models/budget_category.dart';
import 'package:vie_de_famille/core/models/expense.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/core/services/budget_service.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

/// Écran principal du budget familial
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(budgetCategoriesProvider);
    final expenses = ref.watch(expensesProvider);
    final members = ref.watch(membersProvider);

    final totalMonth = BudgetService.totalCurrentMonth(expenses);
    final recentExpenses = BudgetService.recent(expenses);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Budget', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddExpenseScreen(),
              ),
            ),
            tooltip: 'Ajouter une dépense',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte total du mois
            _MonthSummaryCard(total: totalMonth, expenses: expenses, categories: categories),
            const SizedBox(height: 20),

            // Catégories avec barres de progression
            Text(
              'Par catégorie',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...categories.map((cat) {
              final spent = BudgetService.totalForCategory(expenses, cat.id);
              final overBudget = BudgetService.isOverBudget(expenses, cat);
              final usage = BudgetService.budgetUsage(expenses, cat);
              return _CategoryBudgetCard(
                category: cat,
                spent: spent,
                overBudget: overBudget,
                usage: usage,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _CategoryDetailScreen(
                      category: cat,
                      expenses: expenses,
                      members: members,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Dépenses récentes
            if (recentExpenses.isNotEmpty) ...[
              Text(
                'Dépenses récentes',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...recentExpenses.take(10).map((e) {
                final cat = categories.where((c) => c.id == e.categoryId).firstOrNull;
                final member = members.where((m) => m.id == e.paidBy).firstOrNull;
                return _ExpenseTile(
                  expense: e,
                  category: cat,
                  memberName: member?.name ?? '?',
                  onDelete: () => ref.read(expensesProvider.notifier).remove(e.id),
                );
              }),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  final double total;
  final List<Expense> expenses;
  final List<BudgetCategory> categories;

  const _MonthSummaryCard({
    required this.total,
    required this.expenses,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(now);
    final totalLimit = categories.fold<double>(0, (sum, c) => sum + c.monthlyLimit);
    final overBudgetCount = categories.where((c) =>
        BudgetService.isOverBudget(expenses, c)).length;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B7B6F), Color(0xFF3D5A52)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthName,
              style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${total.toStringAsFixed(2)} €',
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (totalLimit > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Budget total : ${totalLimit.toStringAsFixed(0)} €',
                style: GoogleFonts.nunito(color: Colors.white60, fontSize: 13),
              ),
            ],
            if (overBudgetCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⚠️ $overBudgetCount catégorie${overBudgetCount > 1 ? 's' : ''} dépassée${overBudgetCount > 1 ? 's' : ''}',
                  style: GoogleFonts.nunito(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  final BudgetCategory category;
  final double spent;
  final bool overBudget;
  final double usage;
  final VoidCallback onTap;

  const _CategoryBudgetCard({
    required this.category,
    required this.spent,
    required this.overBudget,
    required this.usage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = category.monthlyLimit > 0;
    final barColor = overBudget
        ? AppTheme.budgetNegative
        : usage > 0.8
            ? AppTheme.secondary
            : AppTheme.budgetPositive;
    final memberColors = AppTheme.memberColors;
    final color = memberColors[category.colorIndex % memberColors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(category.icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          hasLimit
                              ? '${spent.toStringAsFixed(2)} € / ${category.monthlyLimit.toStringAsFixed(0)} €'
                              : '${spent.toStringAsFixed(2)} €',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: overBudget ? AppTheme.budgetNegative : AppTheme.textSecondary,
                            fontWeight: overBudget ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (overBudget)
                    const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.budgetNegative, size: 20),
                ],
              ),
              if (hasLimit) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usage.clamp(0.0, 1.0),
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(barColor),
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

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final BudgetCategory? category;
  final String memberName;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.memberName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              category?.icon ?? '💳',
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          expense.description,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${category?.name ?? '?'} · $memberName · ${DateFormat('d MMM', 'fr_FR').format(expense.date)}',
          style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${expense.amount.toStringAsFixed(2)} €',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DÉTAIL D'UNE CATÉGORIE
// ============================================================

class _CategoryDetailScreen extends StatelessWidget {
  final BudgetCategory category;
  final List<Expense> expenses;
  final List<dynamic> members;

  const _CategoryDetailScreen({
    required this.category,
    required this.expenses,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final catExpenses = BudgetService.forCategory(expenses, category.id);
    final total = BudgetService.totalForCategory(expenses, category.id);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '${category.icon} ${category.name}',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: catExpenses.isEmpty
          ? Center(
              child: Text(
                'Aucune dépense ce mois',
                style: GoogleFonts.nunito(color: AppTheme.textSecondary),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total ce mois',
                              style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
                          Text(
                            '${total.toStringAsFixed(2)} €',
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: catExpenses.length,
                    itemBuilder: (ctx, i) {
                      final e = catExpenses[i];
                      final member = (members as List).where((m) => m.id == e.paidBy).firstOrNull;
                      return Consumer(
                        builder: (_, ref, __) => _ExpenseTile(
                          expense: e,
                          category: category,
                          memberName: member?.name ?? '?',
                          onDelete: () => ref.read(expensesProvider.notifier).remove(e.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// FORMULAIRE AJOUT DÉPENSE
// ============================================================

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedMemberId;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    final desc = _descController.text.trim();

    if (amount == null || amount <= 0 || desc.isEmpty ||
        _selectedCategoryId == null || _selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplis tous les champs')),
      );
      return;
    }

    ref.read(expensesProvider.notifier).add(
          Expense.create(
            categoryId: _selectedCategoryId!,
            amount: amount,
            description: desc,
            paidBy: _selectedMemberId!,
            date: _date,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(budgetCategoriesProvider);
    final members = ref.watch(membersProvider);
    final currentMember = ref.watch(currentMemberDataProvider);

    // Pré-sélectionner le membre courant
    if (_selectedMemberId == null && currentMember != null) {
      _selectedMemberId = currentMember.id;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Nouvelle dépense',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Montant
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant *',
                hintText: '0.00',
                prefixIcon: Icon(Icons.euro),
                suffixText: '€',
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Ex: Supermarché, Essence...',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 16),

            // Catégorie
            Text('Catégorie *',
                style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final selected = _selectedCategoryId == cat.id;
                return ChoiceChip(
                  label: Text('${cat.icon} ${cat.name}'),
                  selected: selected,
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Payé par
            Text('Payé par *',
                style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members.map((m) {
                final selected = _selectedMemberId == m.id;
                return ChoiceChip(
                  label: Text(m.name),
                  selected: selected,
                  selectedColor: AppTheme.secondary.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _selectedMemberId = m.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
              title: Text(
                DateFormat('d MMMM yyyy', 'fr_FR').format(_date),
                style: GoogleFonts.nunito(),
              ),
              subtitle: Text('Date de la dépense',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  locale: const Locale('fr', 'FR'),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

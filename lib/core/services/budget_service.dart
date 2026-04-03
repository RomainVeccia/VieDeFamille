import 'package:vie_de_famille/core/models/expense.dart';
import 'package:vie_de_famille/core/models/budget_category.dart';

/// Logique métier pour le budget familial
class BudgetService {
  BudgetService._();

  /// Dépenses du mois courant
  static List<Expense> currentMonth(List<Expense> expenses) {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
  }

  /// Dépenses d'un mois donné
  static List<Expense> forMonth(
    List<Expense> expenses,
    int year,
    int month,
  ) =>
      expenses
          .where((e) => e.date.year == year && e.date.month == month)
          .toList();

  /// Total des dépenses pour une catégorie ce mois
  static double totalForCategory(
    List<Expense> expenses,
    String categoryId,
  ) {
    final month = currentMonth(expenses);
    return month
        .where((e) => e.categoryId == categoryId)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Total global des dépenses ce mois
  static double totalCurrentMonth(List<Expense> expenses) =>
      currentMonth(expenses).fold(0.0, (sum, e) => sum + e.amount);

  /// Dépenses par membre ce mois (qui a dépensé combien)
  static Map<String, double> byMember(List<Expense> expenses) {
    final month = currentMonth(expenses);
    final Map<String, double> result = {};
    for (final e in month) {
      result[e.paidBy] = (result[e.paidBy] ?? 0) + e.amount;
    }
    return result;
  }

  /// Vérifier si une catégorie dépasse son budget mensuel
  static bool isOverBudget(
    List<Expense> expenses,
    BudgetCategory category,
  ) {
    if (category.monthlyLimit <= 0) return false;
    return totalForCategory(expenses, category.id) > category.monthlyLimit;
  }

  /// Pourcentage utilisé du budget d'une catégorie (0.0 à 1.0+)
  static double budgetUsage(
    List<Expense> expenses,
    BudgetCategory category,
  ) {
    if (category.monthlyLimit <= 0) return 0.0;
    return totalForCategory(expenses, category.id) / category.monthlyLimit;
  }

  /// Dépenses récentes (7 derniers jours), triées par date
  static List<Expense> recent(List<Expense> expenses) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final result = expenses.where((e) => e.date.isAfter(cutoff)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  /// Dépenses d'une catégorie ce mois, triées par date desc
  static List<Expense> forCategory(
    List<Expense> expenses,
    String categoryId,
  ) {
    final month = currentMonth(expenses);
    return month.where((e) => e.categoryId == categoryId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}

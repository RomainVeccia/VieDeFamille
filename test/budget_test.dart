import 'package:flutter_test/flutter_test.dart';
import 'package:vie_de_famille/core/models/budget_category.dart';
import 'package:vie_de_famille/core/models/expense.dart';
import 'package:vie_de_famille/core/services/budget_service.dart';

void main() {
  // === BudgetCategory ===
  group('BudgetCategory', () {
    test('créer une catégorie', () {
      final cat = BudgetCategory.create(
        name: 'Courses',
        icon: '🛒',
        monthlyLimit: 400,
        colorIndex: 0,
      );
      expect(cat.name, 'Courses');
      expect(cat.icon, '🛒');
      expect(cat.monthlyLimit, 400);
      expect(cat.id, isNotEmpty);
    });

    test('defaults retourne 8 catégories', () {
      final cats = BudgetCategory.defaults();
      expect(cats.length, 8);
      expect(cats.map((c) => c.name), contains('Courses'));
      expect(cats.map((c) => c.name), contains('Transport'));
    });

    test('serialisation JSON aller-retour', () {
      final cat = BudgetCategory.create(
        name: 'Test', icon: '💡', monthlyLimit: 100, colorIndex: 2,
      );
      final restored = BudgetCategory.fromJson(cat.toJson());
      expect(restored.name, cat.name);
      expect(restored.icon, cat.icon);
      expect(restored.monthlyLimit, cat.monthlyLimit);
      expect(restored.id, cat.id);
    });

    test('copyWith met à jour seulement le champ voulu', () {
      final cat = BudgetCategory.create(name: 'A', icon: '🅰️', monthlyLimit: 100);
      final updated = cat.copyWith(monthlyLimit: 200);
      expect(updated.monthlyLimit, 200);
      expect(updated.name, 'A');
      expect(updated.id, cat.id);
    });
  });

  // === Expense ===
  group('Expense', () {
    test('créer une dépense', () {
      final e = Expense.create(
        categoryId: 'cat_courses',
        amount: 75.50,
        description: 'Supermarché',
        paidBy: 'romain',
      );
      expect(e.amount, 75.50);
      expect(e.description, 'Supermarché');
      expect(e.paidBy, 'romain');
      expect(e.id, isNotEmpty);
    });

    test('serialisation JSON aller-retour', () {
      final e = Expense.create(
        categoryId: 'cat_loisirs',
        amount: 25.00,
        description: 'Cinéma',
        paidBy: 'joanne',
        date: DateTime(2026, 4, 1),
      );
      final restored = Expense.fromJson(e.toJson());
      expect(restored.amount, 25.00);
      expect(restored.description, 'Cinéma');
      expect(restored.categoryId, 'cat_loisirs');
      expect(restored.date.day, 1);
      expect(restored.date.month, 4);
    });

    test('copyWith change seulement le montant', () {
      final e = Expense.create(
        categoryId: 'cat_1',
        amount: 10,
        description: 'Test',
        paidBy: 'x',
      );
      final updated = e.copyWith(amount: 20);
      expect(updated.amount, 20);
      expect(updated.description, 'Test');
      expect(updated.id, e.id);
    });
  });

  // === BudgetService ===
  group('BudgetService', () {
    final now = DateTime.now();

    // Dépenses de ce mois
    final expenses = [
      Expense.create(categoryId: 'courses', amount: 120, description: 'Courses', paidBy: 'romain',
          date: DateTime(now.year, now.month, 5)),
      Expense.create(categoryId: 'courses', amount: 80, description: 'Courses 2', paidBy: 'joanne',
          date: DateTime(now.year, now.month, 10)),
      Expense.create(categoryId: 'loisirs', amount: 50, description: 'Cinéma', paidBy: 'romain',
          date: DateTime(now.year, now.month, 12)),
      // Dépense du mois dernier
      Expense.create(categoryId: 'courses', amount: 200, description: 'Ancien', paidBy: 'romain',
          date: DateTime(now.year, now.month - 1, 1)),
    ];

    final catCourses = BudgetCategory.create(
      name: 'Courses', icon: '🛒', monthlyLimit: 300, colorIndex: 0,
    ).copyWith(); // même id, mais on override

    // Catégorie avec id fixe pour les tests
    final catCoursesFixed = BudgetCategory(
      id: 'courses',
      name: 'Courses',
      icon: '🛒',
      monthlyLimit: 300,
      colorIndex: 0,
      createdAt: DateTime.now(),
    );

    final catLoisirs = BudgetCategory(
      id: 'loisirs',
      name: 'Loisirs',
      icon: '🎉',
      monthlyLimit: 100,
      colorIndex: 1,
      createdAt: DateTime.now(),
    );

    test('currentMonth filtre le mois courant', () {
      expect(BudgetService.currentMonth(expenses).length, 3);
    });

    test('totalForCategory ce mois', () {
      expect(BudgetService.totalForCategory(expenses, 'courses'), 200.0);
      expect(BudgetService.totalForCategory(expenses, 'loisirs'), 50.0);
    });

    test('totalCurrentMonth somme tout ce mois', () {
      expect(BudgetService.totalCurrentMonth(expenses), 250.0);
    });

    test('byMember ventile par payeur', () {
      final byMember = BudgetService.byMember(expenses);
      expect(byMember['romain'], closeTo(170, 0.01)); // 120 + 50
      expect(byMember['joanne'], 80.0);
    });

    test('isOverBudget détecte le dépassement', () {
      // courses : 200 / 300 → pas encore dépassé
      expect(BudgetService.isOverBudget(expenses, catCoursesFixed), false);

      // catégorie avec limite à 150 → dépassement
      final catTight = BudgetCategory(
        id: 'courses', name: 'Courses', icon: '🛒',
        monthlyLimit: 150, colorIndex: 0, createdAt: DateTime.now(),
      );
      expect(BudgetService.isOverBudget(expenses, catTight), true);
    });

    test('isOverBudget avec limite 0 retourne false', () {
      final catNoLimit = BudgetCategory(
        id: 'courses', name: 'Courses', icon: '🛒',
        monthlyLimit: 0, colorIndex: 0, createdAt: DateTime.now(),
      );
      expect(BudgetService.isOverBudget(expenses, catNoLimit), false);
    });

    test('budgetUsage retourne la bonne fraction', () {
      // courses : 200 / 300 ≈ 0.667
      expect(BudgetService.budgetUsage(expenses, catCoursesFixed), closeTo(200 / 300, 0.01));
      // loisirs : 50 / 100 = 0.5
      expect(BudgetService.budgetUsage(expenses, catLoisirs), closeTo(0.5, 0.01));
    });

    test('recent retourne seulement les 7 derniers jours', () {
      final recent = expenses.where((e) =>
          e.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length;
      expect(BudgetService.recent(expenses).length, recent);
    });

    test('forCategory filtre par catégorie ce mois', () {
      final catExpenses = BudgetService.forCategory(expenses, 'courses');
      expect(catExpenses.length, 2); // 120 + 80 (pas l'ancien mois)
    });

    test('forMonth filtre par mois précis', () {
      final lastMonth = BudgetService.forMonth(
          expenses, now.year, now.month - 1);
      expect(lastMonth.length, 1);
      expect(lastMonth.first.amount, 200);
    });
  });
}

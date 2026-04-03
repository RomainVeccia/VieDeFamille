import 'package:flutter_test/flutter_test.dart';
import 'package:vie_de_famille/core/models/expense.dart';
import 'package:vie_de_famille/core/models/budget_category.dart';
import 'package:vie_de_famille/core/services/budget_service.dart';

void main() {
  group('BudgetService', () {
    final now = DateTime.now();

    /// Helper to create an expense
    Expense makeExpense({
      String id = 'exp-1',
      String categoryId = 'cat_courses',
      double amount = 50.0,
      String paidBy = 'romain',
      DateTime? date,
    }) {
      return Expense(
        id: id,
        categoryId: categoryId,
        amount: amount,
        description: 'Test expense',
        paidBy: paidBy,
        date: date ?? now,
        createdAt: now,
      );
    }

    group('currentMonth', () {
      test('should return only expenses from the current month', () {
        final expenses = [
          makeExpense(id: 'this-month', date: now),
          makeExpense(
            id: 'last-month',
            date: DateTime(now.year, now.month - 1 > 0 ? now.month - 1 : 12,
                1),
          ),
        ];

        final result = BudgetService.currentMonth(expenses);

        expect(result.length, equals(1));
        expect(result.first.id, equals('this-month'));
      });

      test('should return empty list when no expenses this month', () {
        final expenses = [
          makeExpense(
            id: 'old',
            date: DateTime(now.year - 1, now.month, 15),
          ),
        ];

        final result = BudgetService.currentMonth(expenses);

        expect(result, isEmpty);
      });
    });

    group('forMonth', () {
      test('should return expenses for a specific month and year', () {
        final expenses = [
          makeExpense(id: 'jan', date: DateTime(2026, 1, 15)),
          makeExpense(id: 'feb', date: DateTime(2026, 2, 10)),
          makeExpense(id: 'jan2', date: DateTime(2026, 1, 20)),
        ];

        final result = BudgetService.forMonth(expenses, 2026, 1);

        expect(result.length, equals(2));
        expect(result.every((e) => e.date.month == 1), isTrue);
      });
    });

    group('totalForCategory', () {
      test('should sum expenses for a category in the current month', () {
        final expenses = [
          makeExpense(id: 'e1', categoryId: 'cat_courses', amount: 100),
          makeExpense(id: 'e2', categoryId: 'cat_courses', amount: 50),
          makeExpense(id: 'e3', categoryId: 'cat_restaurant', amount: 30),
        ];

        final total = BudgetService.totalForCategory(expenses, 'cat_courses');

        expect(total, equals(150.0));
      });

      test('should return 0 when no expenses for category', () {
        final expenses = [
          makeExpense(id: 'e1', categoryId: 'cat_restaurant', amount: 30),
        ];

        final total = BudgetService.totalForCategory(expenses, 'cat_courses');

        expect(total, equals(0.0));
      });
    });

    group('totalCurrentMonth', () {
      test('should sum all expenses for the current month', () {
        final expenses = [
          makeExpense(id: 'e1', amount: 100),
          makeExpense(id: 'e2', amount: 50),
          makeExpense(id: 'e3', amount: 25),
        ];

        final total = BudgetService.totalCurrentMonth(expenses);

        expect(total, equals(175.0));
      });
    });

    group('byMember', () {
      test('should group expenses by member for the current month', () {
        final expenses = [
          makeExpense(id: 'e1', paidBy: 'romain', amount: 100),
          makeExpense(id: 'e2', paidBy: 'joanne', amount: 50),
          makeExpense(id: 'e3', paidBy: 'romain', amount: 30),
        ];

        final result = BudgetService.byMember(expenses);

        expect(result['romain'], equals(130.0));
        expect(result['joanne'], equals(50.0));
      });

      test('should return empty map when no expenses this month', () {
        final expenses = <Expense>[];

        final result = BudgetService.byMember(expenses);

        expect(result, isEmpty);
      });
    });

    group('isOverBudget', () {
      test('should return true when expenses exceed monthly limit', () {
        final category = BudgetCategory(
          id: 'cat_courses',
          name: 'Courses',
          icon: 'cart',
          monthlyLimit: 100,
          createdAt: now,
        );
        final expenses = [
          makeExpense(id: 'e1', categoryId: 'cat_courses', amount: 60),
          makeExpense(id: 'e2', categoryId: 'cat_courses', amount: 50),
        ];

        expect(BudgetService.isOverBudget(expenses, category), isTrue);
      });

      test('should return false when expenses are under limit', () {
        final category = BudgetCategory(
          id: 'cat_courses',
          name: 'Courses',
          icon: 'cart',
          monthlyLimit: 400,
          createdAt: now,
        );
        final expenses = [
          makeExpense(id: 'e1', categoryId: 'cat_courses', amount: 100),
        ];

        expect(BudgetService.isOverBudget(expenses, category), isFalse);
      });

      test('should return false when category has no limit (0)', () {
        final category = BudgetCategory(
          id: 'cat_autres',
          name: 'Autres',
          icon: 'card',
          monthlyLimit: 0,
          createdAt: now,
        );
        final expenses = [
          makeExpense(id: 'e1', categoryId: 'cat_autres', amount: 9999),
        ];

        expect(BudgetService.isOverBudget(expenses, category), isFalse);
      });
    });

    group('budgetUsage', () {
      test('should return percentage of budget used', () {
        final category = BudgetCategory(
          id: 'cat_courses',
          name: 'Courses',
          icon: 'cart',
          monthlyLimit: 200,
          createdAt: now,
        );
        final expenses = [
          makeExpense(id: 'e1', categoryId: 'cat_courses', amount: 100),
        ];

        final usage = BudgetService.budgetUsage(expenses, category);

        expect(usage, equals(0.5));
      });

      test('should return value greater than 1.0 when over budget', () {
        final category = BudgetCategory(
          id: 'cat_courses',
          name: 'Courses',
          icon: 'cart',
          monthlyLimit: 100,
          createdAt: now,
        );
        final expenses = [
          makeExpense(id: 'e1', categoryId: 'cat_courses', amount: 150),
        ];

        final usage = BudgetService.budgetUsage(expenses, category);

        expect(usage, equals(1.5));
      });

      test('should return 0.0 when category has no limit', () {
        final category = BudgetCategory(
          id: 'cat_autres',
          name: 'Autres',
          icon: 'card',
          monthlyLimit: 0,
          createdAt: now,
        );

        final usage = BudgetService.budgetUsage([], category);

        expect(usage, equals(0.0));
      });
    });

    group('recent', () {
      test('should return expenses from the last 7 days sorted by date desc',
          () {
        final expenses = [
          makeExpense(
              id: 'old', date: now.subtract(const Duration(days: 10))),
          makeExpense(
              id: 'recent1', date: now.subtract(const Duration(days: 2))),
          makeExpense(
              id: 'recent2', date: now.subtract(const Duration(days: 1))),
          makeExpense(id: 'today', date: now),
        ];

        final result = BudgetService.recent(expenses);

        expect(result.length, equals(3));
        expect(result.first.id, equals('today'));
        expect(result.last.id, equals('recent1'));
      });
    });

    group('forCategory', () {
      test(
          'should return expenses for a category this month sorted by date desc',
          () {
        final expenses = [
          makeExpense(id: 'e1', categoryId: 'cat_courses',
              date: DateTime(now.year, now.month, 1)),
          makeExpense(id: 'e2', categoryId: 'cat_courses',
              date: DateTime(now.year, now.month, 15)),
          makeExpense(id: 'e3', categoryId: 'cat_restaurant', date: now),
        ];

        final result = BudgetService.forCategory(expenses, 'cat_courses');

        expect(result.length, equals(2));
        // Sorted by date descending
        expect(result.first.date.isAfter(result.last.date), isTrue);
      });
    });
  });
}

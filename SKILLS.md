# SKILLS.md — Templates et patterns de code

> Templates réutilisables. Claude Code s'en inspire pour garder la cohérence.

---

## Skill 1 — Nouveau module

```
# Template : créer un nouveau module
# 1. Créer le fichier dans le bon dossier
# 2. Ajouter les imports
# 3. Créer la classe/fonction principale
# 4. Écrire les tests
# 5. Brancher dans l'app

# Checklist :
# - [ ] Fichier créé au bon endroit
# - [ ] Tests créés
# - [ ] Tests passent
# - [ ] Importé là où c'est nécessaire
# - [ ] Linter clean
```

---

## Skill 2 — Gestion d'erreurs

```dart
// Pattern Dart/Flutter
sealed class AppError {
  final String message;
  const AppError(this.message);
}

class FamilyError extends AppError {
  const FamilyError(super.message);
}

class TaskError extends AppError {
  const TaskError(super.message);
}

class BudgetError extends AppError {
  const BudgetError(super.message);
}

class NetworkError extends AppError {
  const NetworkError(super.message);
}

// Utilisation avec Result pattern
// ou try/catch structuré
```

---

## Skill 3 — Logging structuré

```dart
import 'package:logger/logger.dart';

final logger = Logger();

// Niveaux :
logger.d("Détail technique pour debug");
logger.i("Action importante réussie");
logger.w("Situation anormale mais gérée");
logger.e("Erreur qui empêche une action");
logger.f("Erreur fatale, app compromise");

// JAMAIS de print() en prod
// JAMAIS de données sensibles dans les logs
// JAMAIS de montants/budget dans les logs
```

---

## Skill 4 — Tests

```dart
// Pattern Flutter test
void main() {
  group('TaskService', () {
    test('nominal case: create task', () {
      final task = TaskService.create(title: 'Faire les courses');
      expect(task.title, equals('Faire les courses'));
      expect(task.completed, isFalse);
    });

    test('edge case: empty title', () {
      expect(() => TaskService.create(title: ''), throwsA(isA<TaskError>()));
    });

    test('recurrence: daily task', () {
      final task = TaskService.create(
        title: 'Sortir les poubelles',
        recurrence: Recurrence.daily,
      );
      expect(task.nextDueDate, equals(tomorrow));
    });
  });

  group('BudgetCalculator', () {
    test('monthly total', () {
      final total = BudgetCalculator.monthlyTotal(expenses);
      expect(total, equals(1250.50));
    });

    test('over budget alert', () {
      final alert = BudgetCalculator.checkBudget(category, expenses);
      expect(alert.isOverBudget, isTrue);
    });
  });
}
```

---

## Skill 5 — Commit message

```
Format : [type] description courte en français

Types :
- [feat]     Nouvelle fonctionnalité
- [fix]      Correction de bug
- [refactor] Refactoring sans changement fonctionnel
- [test]     Ajout/modification de tests
- [docs]     Documentation
- [style]    Formatage, linter
- [perf]     Optimisation performance
- [security] Correction sécurité
- [build]    Build, dépendances, CI

Exemples :
- [feat] Ajout du module de gestion des tâches récurrentes
- [fix] Correction du calcul budget mensuel
- [refactor] Extraction du service de notifications
- [test] Tests unitaires pour le calculateur de budget (28 tests)
```

---

## Skill 6 — Architecture propre

```
# Règle : Dépendances vers l'intérieur uniquement

UI → Core ✅
UI → Data ✅
Data → Core ✅
Core → UI ❌ INTERDIT
Core → Data ❌ INTERDIT (utiliser des interfaces)
Data → UI ❌ INTERDIT

# Core ne dépend de RIEN d'externe
# C'est le cœur pur de l'application
```

---

## Skill 7 — Checklist release

```
# Avant de publier :
- [ ] Tous les tests passent
- [ ] Linter 0 erreur
- [ ] Pas de TODO/FIXME/HACK critiques
- [ ] Pas de credentials dans le code
- [ ] Pas de print()/console.log() de debug
- [ ] README à jour
- [ ] Version bumped
- [ ] Changelog mis à jour
- [ ] Build OK
- [ ] Test sur device/navigateur réel
- [ ] Données famille bien isolées (multi-tenant)
- [ ] Données budget chiffrées
```

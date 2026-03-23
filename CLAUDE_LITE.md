# CLAUDE_LITE.md — VieDeFamille

> Version allégée pour les tâches P0-P1. Charger CLAUDE.md complet pour les décisions d'archi.

## Projet
VieDeFamille = app mobile de gestion familiale (Flutter/Dart). Tâches, courses, planning, budget, communication.

## Stack
```
Flutter 3.x | Dart | Firebase (gratuit) | SQLite | Riverpod
```

## Architecture (résumé)
```
core/engine/  → Répartition tâches, calculs budget, rappels
core/models/  → Family, Member, Task, Event, Budget, ShoppingList
core/services/→ Gestion tâches, planning, budget, notifications
ui/screens/   → Home, Tasks, Calendar, Shopping, Budget, Messages, Profile
ui/widgets/   → Cards, listes, calendrier, graphiques
data/local/   → SQLite (tâches, budget, profils)
data/remote/  → Firebase (sync famille, auth, notifications)
test/         → Tests unitaires
```

## Conventions
- Code : anglais | Commentaires : français | Commits : français
- Classes : PascalCase | Fonctions : camelCase | Fichiers : snake_case
- Pas de print() → logger | Pas de bare catch → spécifique

## Règles
- core/ n'importe JAMAIS ui/
- Pas de credentials en clair
- TDD sur core/ (budget, répartition, planning)
- Commiter souvent

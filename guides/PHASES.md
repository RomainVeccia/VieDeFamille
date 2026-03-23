# PHASES.md — Guide de progression

> Chaque projet suit ces phases. Adapte le contenu, garde la structure.

---

## Phase 1 — Setup & Fondations
```
Prompt Claude Code :
"Session 1 — Setup projet.
Orient + résumé 3 lignes.
1. Créer le projet Flutter (flutter create vie_de_famille)
2. Créer l'arborescence complète (core/, ui/, data/)
3. Dépendances (pubspec.yaml)
4. Config (logging, linter, .gitignore)
5. Git init + premier commit
Propose le plan, GO."
```
Commit : `[setup] initialisation du projet`

## Phase 2 — Core / Logique métier
```
"Session 2 — Core.
Orient + résumé 3 lignes.
Implémenter les modèles et services :
- Family, Member, Task, Event, ShoppingList, Budget
- TaskService, CalendarService, BudgetService, ShoppingService
TDD : tests d'abord, code ensuite.
Propose le plan, GO."
```
Commit : `[core] modèles et services métier`

## Phase 3 — Interface utilisateur
```
"Session 3 — UI.
Orient + résumé 3 lignes.
Créer les écrans principaux :
- Home (dashboard), Tasks, Calendar, Shopping, Budget
- Navigation bottom tabs
Tons chauds (vert sauge, orange, caramel), animations subtiles.
Propose le plan, GO."
```
Commit : `[ui] écrans principaux`

## Phase 4 — Données & Sync
```
"Session 4 — Data.
Orient + résumé 3 lignes.
BDD locale SQLite, Firebase sync temps réel entre membres.
Mode offline-first.
Propose le plan, GO."
```
Commit : `[data] persistance et sync Firebase`

## Phase 5 — Gamification
```
"Session 5 — Gamification.
Orient + résumé 3 lignes.
Points pour tâches, récompenses personnalisées, classement familial.
Propose le plan, GO."
```
Commit : `[feat] gamification familiale`

## Phase 6 — Polish & Distribution
```
"Session 6 — Polish.
Orient + résumé 3 lignes.
1. Animations, sons, transitions
2. Notifications push
3. Dark mode
4. Landing page
5. CGU + Privacy Policy
Propose le plan, GO."
```
Commit : `[release] v1.0.0`

## Phase 7 — Fortress (sécurité & robustesse)
```
"Session 7 — Fortress.
Orient + résumé 3 lignes.
1. Firebase Security Rules (isolation par famille)
2. Chiffrement données sensibles
3. Mode offline robuste
4. Stress testing
5. Backup données locales
Propose le plan, GO."
```

## Phase 8 — Packaging & Stores
```
"Session 8 — Stores.
Orient + résumé 3 lignes.
1. Build iOS + Android release
2. Assets stores (icônes, screenshots, descriptions)
3. TestFlight + Internal Testing
4. Soumission stores
Propose le plan, GO."
```

---

## Entre chaque phase : REVIEW
```
"Review complète Phase [N] :
1. Passe 1 : conformité au spec
2. Passe 2 : qualité (linter + tests)
3. Passe 3 : security scan (données famille isolées)
Si 3/3 PASS → commit + tag + push. Sinon → fix d'abord."
```

---

## Commandes utiles pendant les sessions

| Tu veux... | Tu tapes... |
|---|---|
| État du projet | "Orient — résumé 3 lignes" |
| Lancer les tests | "Lance les tests et montre les résultats" |
| Security scan | "Lance le security scan Passe 3" |
| Fix rapide | "QUICKFLOW : [problème en 1 ligne]" |
| Finir la session | "PERSIST : sauvegarde tout et confirme" |
| Mode agent | "Active le [Agent] et analyse [sujet]" |
| Audit complet | "Audit complet — score /100 et recommandations" |

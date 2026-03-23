# WORKFLOWS.md — Processus de travail

---

## Workflow 1 — TDD (Test-Driven Development)

> Obligatoire sur core/ (logique métier). Optionnel sur ui/.

```
1. ÉCRIRE LE TEST qui fail
   → Le test décrit CE QUE la fonction doit faire
   → pytest / flutter test / jest → FAIL (rouge)

2. ÉCRIRE LE CODE MINIMUM pour que le test passe
   → Pas d'optimisation, juste faire passer le test
   → pytest → PASS (vert)

3. REFACTORER
   → Nettoyer, simplifier, DRY
   → pytest → toujours PASS (vert)

4. RÉPÉTER pour le prochain cas
```

### Quand utiliser TDD
- ✅ Logique métier (calculs budget, répartition tâches, récurrences)
- ✅ Services (API calls, data access, sync)
- ✅ Modèles de données (validation, transformation)
- ❌ UI pure (layouts, animations) → tester manuellement
- ❌ Prototypage rapide → tests après

---

## Workflow 2 — Brainstorm avant de coder

> Obligatoire pour toute feature > 5 fichiers.

```
1. DÉFINIR le problème en 1-2 phrases
2. LISTER 3 approches possibles
3. ÉVALUER chaque approche :
   - Complexité (1-5)
   - Maintenabilité (1-5)
   - Performance (1-5)
   - Risques
4. CHOISIR avec le développeur
5. DOCUMENTER la décision dans tasks/decisions/
6. CODER
```

---

## Workflow 3 — Review 3 passes

> Avant de valider toute feature complète.

```
PASSE 1 — Conformité
- La feature fait ce qui est demandé ?
- Tous les cas sont couverts ?
- Les edge cases sont gérés ?

PASSE 2 — Qualité
- Linter clean (ruff / eslint / dart analyze) ?
- Tests passent tous ?
- Pas de code dupliqué ?
- Fonctions < 30 lignes ?
- Nommage clair ?

PASSE 3 — Sécurité
- Pas de credentials en dur ?
- Inputs validées ?
- Données famille bien isolées ?
- Pas de print() debug oublié ?
- Données sensibles (budget) protégées ?
```

---

## Workflow 4 — Session de travail

> Structure d'une session Claude Code.

```
1. ORIENT (2 min)
   - Où en est-on ? (git log, tasks/todo.md)
   - Qu'est-ce qu'on fait aujourd'hui ?
   - Résumé 3 lignes

2. PLAN (5 min)
   - Lister les tâches
   - Estimer le temps
   - Prioriser

3. CODE (le gros du temps)
   - TDD sur core/
   - Commit souvent
   - /compact si contexte > 60%

4. REVIEW (5 min)
   - Review 3 passes
   - Tests passent ?
   - Commit final

5. PERSIST (2 min)
   - Mettre à jour tasks/todo.md
   - Mettre à jour PROJECT-STATUS.md
   - Résumé de ce qui a été fait
```

---

## Workflow 5 — Gestion du contexte

> Claude Code a une fenêtre de contexte limitée. Optimiser.

```
RÈGLES :
- /compact dès 60% de contexte utilisé
- Commiter souvent → permet de repartir propre
- Utiliser le bon palier (P0 pour un fix, P4 pour un audit)
- Limiter les outputs : | head -20, | tail -10
- Ne pas inliner de gros fichiers → read avec offset
- Si session saturée → PERSIST + nouvelle session
```

---

## Workflow 6 — Bug fix

```
1. REPRODUIRE le bug (log, screenshot, étapes)
2. LOCALISER la cause (grep, debugger, git bisect)
3. ÉCRIRE UN TEST qui reproduit le bug → FAIL
4. FIXER le code → test PASS
5. VÉRIFIER qu'on n'a rien cassé (suite complète)
6. COMMIT avec message "[fix] description du bug"
```

---

## Workflow 7 — Release

```
1. Tous les tests passent
2. Linter clean
3. Security scan clean
4. Review 3 passes OK
5. Version bump
6. git tag vX.Y.Z
7. Build (si applicable)
8. Test le build
9. Push + deploy
```

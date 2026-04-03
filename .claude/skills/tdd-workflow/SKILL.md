---
name: tdd-workflow
description: Test-Driven Development sur toute logique metier. Utiliser pour toute nouvelle fonction, classe, ou algorithme. Pas de code de production sans test rouge d'abord.
---

# TDD Workflow

## Iron Law
**PAS DE CODE PROD SANS TEST QUI ECHOUE D'ABORD.**
Supprimer tout code ecrit avant les tests.
Regarder le test echouer pour la BONNE raison avant d'implementer.

## Le cycle RED → GREEN → REFACTOR

### RED — Ecrire le test qui echoue
1. Ecrire le test qui decrit le comportement attendu
2. Lancer le test → il DOIT echouer
3. Verifier que le message d'erreur est logique (pas un crash inattendu)
4. Si le test passe sans code → le test est mal ecrit

### GREEN — Implementation minimale
1. Ecrire le minimum de code pour faire passer le test
2. Pas de generalisation prematuree
3. Pas d'optimisation — juste faire passer le test
4. Relancer le test → il DOIT passer

### REFACTOR — Nettoyer sans casser
1. Eliminer la duplication
2. Ameliorer les noms
3. Simplifier la logique
4. Relancer les tests → ils DOIVENT tous passer

## Anti-patterns tests (a ne JAMAIS faire)
- **Tester les mocks** au lieu du vrai code → inutile, le mock fait ce qu'on lui dit
- **Methodes test-only en prod** → pollue le code de prod avec du code de test
- **Mocks incomplets** → si un mock manque des champs, le test ne teste pas la realite
- **Test qui passe toujours** → un test qui ne peut pas echouer ne protege rien
- **Tests dependants entre eux** → chaque test doit pouvoir tourner independamment
- **teardown oublie** → si setup_module patche, TOUJOURS teardown_module

## Structure test recommandee
```python
# Arrange — preparer le contexte
# Act — executer l'action testee
# Assert — verifier le resultat
```

## Quand appliquer
- Toute fonction avec logique metier (calculs, decisions, transformations)
- Toute integration API (mocker l'API, tester le comportement)
- Tout bug fixe (ecrire le test qui reproduit le bug D'ABORD)
- Pas besoin pour : boilerplate, getters/setters triviaux, scripts one-shot

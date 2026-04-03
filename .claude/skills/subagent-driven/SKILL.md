---
name: subagent-driven
description: Deleguer une tache complexe a un sous-agent isole. Utiliser quand une tache est longue et independante du contexte principal, quand plusieurs taches peuvent tourner en parallele, ou quand on veut isoler le contexte pour eviter la pollution.
---

# Subagent-Driven Development

## Principe
Chaque sous-agent recoit UNIQUEMENT ce dont il a besoin.
Jamais l'historique de session. Jamais le contexte superflu.
Le contexte isole = meilleur output + moins de tokens.

## Quand deleguer
- Tache independante qui ne necessite pas le contexte de la session
- 2+ taches qui peuvent tourner en parallele (fichiers differents, modules differents)
- Review de code (spec compliance + code quality)
- Research sur un sujet specifique

## Template de prompt sous-agent

```
## Contexte
[Nom du projet] — [Stack] — [1 phrase sur ce qu'on fait]

## Ta tache
[Description precise de ce qu'on attend]

Fichiers concernes :
- [chemin/fichier1.py] — [role]
- [chemin/fichier2.py] — [role]

## Contraintes
- [Contrainte 1 — ex: pas de nouvelles dependances]
- [Contrainte 2 — ex: respecter le style existant]

## Output attendu
[Format exact du livrable]

## Status a retourner
- DONE — tache complete, tout fonctionne
- DONE_WITH_CONCERNS — fait mais questions a poser
- BLOCKED — besoin d'une information manquante
- NEEDS_CONTEXT — le contexte fourni est insuffisant
```

## Two-Stage Review
Pour toute implementation importante, deux passes dans l'ordre :

**Passe 1 — Spec compliance**
"Est-ce que ca repond au besoin ?" (pas encore de jugement sur la qualite du code)

**Passe 2 — Code quality**
"Est-ce que c'est bien ecrit ?" (architecture, nommage, tests, performance)

L'ordre compte — evaluer la conformite avant la qualite evite de polir du code qui repond pas au besoin.

## Regles contexte
- Pas d'historique de session dans le prompt du sous-agent
- Donner le texte de la tache directement — pas "lire le fichier X pour comprendre"
- Inclure les extraits de code pertinents si necessaire
- Un sous-agent = une tache = un livrable clair

## Orchestrateur — Phases sequentielles
Pour les taches complexes, enchaîner les agents dans l'ordre :

```
RESEARCH  → Explore agent  → output: research-summary.md
PLAN      → Planner agent  → output: plan.md
IMPLEMENT → TDD agent      → output: code changes
REVIEW    → Reviewer agent → output: review-comments.md
VERIFY    → Build/test     → output: done ou retour IMPLEMENT
```

Regles :
- Chaque phase lit l'output de la precedente (fichier, pas memoire)
- `/clear` entre les agents pour garder le contexte frais
- Jamais sauter une phase — chacune ajoute de la valeur

## Iterative retrieval (max 3 cycles)
Si le retour du sous-agent est insuffisant :
1. Evaluer : "est-ce que ca repond vraiment a l'objectif ?"
2. Si non : poser des questions de suivi specifiques
3. Le sous-agent retourne chercher les reponses
4. Max 3 cycles — apres ca, le sous-agent n'a pas le contexte necessaire

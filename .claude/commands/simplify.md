# /simplify — Review parallèle multi-agents

Lance 3 agents en parallèle pour trouver les améliorations possibles sur le code modifié.

## Agents lancés
1. **code-reviewer** — conformité spec + qualité code
2. **adversarial-reviewer** — réfute les faux positifs du reviewer
3. **security-auditor** — credentials, inputs, permissions

## Scope
- Si des fichiers sont spécifiés → review ces fichiers
- Sinon → review les fichiers modifiés depuis le dernier commit (`git diff --name-only HEAD~1`)

## Ce que chaque agent cherche
- Logique dupliquée (même code dans 2+ endroits)
- Conditionnels imbriqués (>3 niveaux → extraire)
- Fonctions >30 lignes (splitter)
- Requêtes N+1 ou sans index
- Opportunités de réutilisation (helper/util)
- Code mort (imports, fonctions, variables inutilisés)

## Format sortie
```
## /simplify — [N] findings

### CRITIQUE (blocker)
[description] — Fichier:ligne — Fix: [action]

### IMPORTANT
[description] — Fichier:ligne — Fix: [action]

### SUGGESTION
[description] — Fichier:ligne — Fix: [action]

Score : X critique / Y important / Z suggestions
Verdict : PROPRE / A_CORRIGER / BLOQUER
```

## Règles
- Lecture seule — ne modifie rien
- Chaque finding : fichier + ligne + fix concret
- L'adversarial filtre les faux positifs du reviewer
- Si 0 findings → "Code propre, rien à simplifier"

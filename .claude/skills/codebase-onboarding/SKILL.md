---
name: codebase-onboarding
description: Analyser un repo inconnu en 4 phases et generer les artefacts de demarrage (CLAUDE.md, PROJECT_MAP, rules). Utiliser pour un nouveau projet, un onboarding, ou un client qui arrive avec un repo existant.
triggers:
  - nouveau projet a analyser
  - "je connais pas ce repo"
  - onboarding d'un collaborateur
  - repo existant sans documentation Claude
  - "analyse ce projet"
---

# Codebase Onboarding — 4 phases

## Iron Law
**PAS DE CODE AVANT D'AVOIR COMPRIS LE PROJET.**

## Phase 1 — RECONNAISSANCE (5 min)
Lire sans toucher au code : `ls -la`, README, package.json/pyproject.toml/pubspec.yaml, config (tsconfig, Dockerfile, docker-compose), CI/CD, CLAUDE.md existant.

Checklist : Langage, Framework, Package manager, DB, Tests, CI/CD, Deploy, Monorepo.
Resultat : fiche d'identite 10 lignes max.

## Phase 2 — ARCHITECTURE (10 min)
```bash
find . -type d -not -path '*/node_modules/*' -not -path '*/.git/*' -maxdepth 3 | head -50
grep -rn "main\|app\|index" --include="*.ts" --include="*.py" --include="*.dart" -l | head -20
grep -rn "router\|route\|@app\." --include="*.ts" --include="*.py" -l | head -20
git log --format= --name-only | sort | uniq -c | sort -rn | head -20
```
Mapper : modules principaux, entry point, data flow, deps cles, couches, fichiers les plus modifies.

## Phase 3 — CONVENTIONS (10 min)
Observer (pas deviner) : naming (camel/snake/Pascal), testing (pattern+couverture), error handling, state management, imports, comments, git (commits+branches).

## Phase 4 — ARTEFACTS (15 min)
Generer :
1. **CLAUDE.md** — description, stack, commandes (build/test/lint/dev), structure, conventions, patterns/anti-patterns
2. **PROJECT_MAP-{nom}.md** — liens wiki [[]] vers fichiers internes, brain (state/lessons/patterns), projets lies
3. **.claude/rules/** — si conventions fortes detectees (stack, archi, testing)
4. **brain/projects/{nom}/** — state.md (etat initial) + lessons.md (template)
5. **projects.json** — ajouter au registry

## Output final
```markdown
## Onboarding — {NOM}
**Stack** : {langage+framework+DB} | **LOC** : ~{X} | **Tests** : {N} | **Archi** : {pattern}
### Points forts / Points d'attention
### Fichiers generes
- [ ] CLAUDE.md, PROJECT_MAP, .claude/rules/, brain/projects/{nom}/, projects.json
```

## Anti-patterns
- Coder avant explorer — Lire tout le code (commencer par structure) — Deviner les conventions
- Ignorer les tests existants — Copier un CLAUDE.md generique

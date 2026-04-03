---
description: Economie de tokens — paliers, model routing, compact
---

# Economie de tokens

- JAMAIS de screenshot auto — decrire en texte
- Outputs tronques : `| head -20` ou `| tail -10`
- /compact des 60% — si 80% = trop tard
- Strategic /compact — aux transitions de phase (apres exploration, avant execution), pas en plein milieu
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=70` — compaction a 70% au lieu de 95% par defaut → meilleure qualite en sessions longues
- `claude --bare` pour les quick one-shot (pas de rules/hooks/MCP, startup 10x plus rapide)
- **MEMORY.md cap 200 lignes** — au-dela, troncature SILENCIEUSE. Garder < 50 lignes.
- **5 fichiers memoire max par tour** — noms de fichiers descriptifs pour que Sonnet choisisse les bons
- **Subagents partagent le prompt cache** — 5 agents paralleles ≈ cout de 1 seul. Paralleliser.
- **Rolling 5h window** — etaler les sessions (matin + apres-midi) plutot que tout d'un coup
- **Edit prompt > follow-up** — corriger le message original au lieu d'envoyer "non je voulais dire..."

## Model routing
- `/model haiku` — taches simples (tests, triage, validation syntaxique) → -64% vs Sonnet
- `/model sonnet` — implementation quotidienne, fixes, refacto → defaut
- `/model opus` — review adversarial, architecture, deep analysis
- Resultat terrain : **-42% tokens** sur pipeline complet avec routing intelligent

## Context progressif L0→L1→L2
- L0 : chemins seuls (paths) — toujours commencer par la
- L1 : fichiers cibles (read les fichiers pertinents) — si L0 ne suffit pas
- L2 : full context — seulement si vraiment necessaire. Jamais coller du contenu dans le prompt

## Sous-agents — Quand et comment

### Quand spawner un sous-agent
- Exploration librairie inconnue
- Bug complexe sur un module isole
- Boilerplate en parallele (generer tous les modeles, DAOs, etc.)
- Analyses paralleles independantes (review + security + tests)

### Quand NE PAS spawner
- Tache < 50 lignes de code
- Bug dont la cause est identifiee
- Plus rapide a faire qu'a briefer

### Regle du brief cible
```
JAMAIS : passer tout le projet au sous-agent (500+ lignes)
TOUJOURS : brief cible 10-20 lignes avec uniquement ce qui est necessaire
```

### Cout token par type
| Type | Brief | Cout |
|------|-------|------|
| Boilerplate | Schema + conventions | 1x |
| Feature complete | Module + deps + tests | 3x |
| 1 agent conseil | Brief domaine cible | 2x |
| Multi-roles (4 angles) | Sujet + contexte condense | 3x |
| Conseil complet (N agents) | N x brief cible | **EXPLOSIF** |

### Regle d'or orchestration
```
Tache dev courante         → Claude Code seul, pas de sous-agent
Feature multi-fichiers     → 1-2 sous-agents paralleles, briefs cibles
Decision importante        → Multi-roles (4 angles, 1 seul appel)
Decision strategique       → 2-3 agents conseil MAX, briefs cibles
Pre-release critique       → Conseil complet, 1 SEULE FOIS
```

## Build par lot, pas par fichier
- Build/test par lot coherent de features, pas apres chaque fichier
- Analyse statique (ruff, flutter analyze, tsc) suffit pendant le dev
- Full test suite aux limites de lot seulement
- Economise temps + tokens de debug sur des builds intermediaires inutiles

## Anti-boucle infinie (stop_reason)
```
stop_reason == "end_turn" → fini
stop_reason == "tool_use" → executer l'outil
JAMAIS : if response contains "termine" → stop (cause boucle infinie)
JAMAIS : stop after N iterations (arbitraire)
```

## Paliers de chargement

| Palier | Quand | Fichiers charges |
|--------|-------|-----------------|
| P0 | Fix 1 ligne | BRAIN.md + CLAUDE_LITE |
| P1 | Feature | LITE + SKILLS + WORKFLOWS |
| P2 | Archi | CLAUDE.md complet + AGENTS |
| P3 | Strategie | CLAUDE_LITE + AGENTS complet |
| P4 | Audit | TOUS les fichiers (1x max) |

## Plan contingence prix x3 (pret a deployer)
Si Anthropic augmente significativement :
- **quick-persist par defaut** au quotidien, persist complet 1x/semaine
- **Rules consolidees** : 7 fichiers → 1 core-rules.md (~100 lignes), le reste en reference
- **Agents reduits** : 8 → 4 essentiels (code-reviewer, debugger, security-auditor, adversarial)
- **Skills reduits** : 10 → 5 (council, TDD, verification, task-contract, eval-harness)
- **ORIENT purement CLI** : brain.py orient genere un summary 15 lignes, Claude lit SEULEMENT ca
- Estimation : -760 lignes/session = -35% de contexte

---
name: autonomous-loops
description: Lancer des boucles autonomes longues (refacto, migration, batch). 4 patterns documentes avec regles de securite strictes (timeout, budget, condition d'arret). Utiliser pour les gros travaux repetitifs ou multi-etapes.
triggers:
  - gros refactoring
  - migration de codebase
  - nettoyage dead code
  - batch de features similaires
  - "fais ca sur tous les fichiers"
  - "automatise cette tache repetitive"
---

# Autonomous Loops — 4 patterns

## Iron Law
**PAS DE BOUCLE SANS CONDITION D'ARRET EXPLICITE.**

## Securite (non negociable)

Definir avant TOUTE boucle :
```markdown
## LOOP_CONFIG
- Timeout max : {duree} (jamais > 4h) | Budget tokens max : {nombre} (jamais > 500K)
- Condition d'arret : {critere} | Heartbeat : 30 min | Rollback : {comment annuler}
```

**Heartbeat (30 min)** — verifier : progres, budget, qualite, erreurs.
- 2 heartbeats sans progres → STOP | Budget > 80% → STOP | Erreurs repetitives → STOP

**Pre-requis** : git propre, branche `loop/{nom}`, LOOP_CONFIG valide, rollback teste, backup si destructif.

## Pattern 1 — Sequential Pipeline
Sessions en pipeline, output N nourrit N+1.
```bash
claude -p "Genere les modeles: $(cat schemas.json)" --output-file models.ts
claude -p "Review et corrige: $(cat models.ts)" --output-file models_reviewed.ts
```
- Chaque etape a son critere de succes, si echec → stop, outputs intermediaires sauvegardes

## Pattern 2 — De-sloppify
Session 1 implemente vite. Session 2 nettoie (contexte frais, pas de biais).
```bash
claude -p "Review et nettoie ce diff. Conventions du projet. $(git diff main)"
```
- Session 2 ne doit PAS ajouter de features, si bug trouve → signaler sans fixer

## Pattern 3 — Continuous PR Loop
PRs en boucle depuis tasks.txt. Chaque ligne = 1 tache = 1 PR atomique.
```bash
while IFS= read -r task; do
  git checkout -b "auto/$(echo "$task" | tr ' ' '-' | head -c 40)" main
  claude -p "$task" --allowedTools "Edit,Write,Bash(git *)"
  npm test && npm run lint && git add -A && git commit -m "[auto] $task" && gh pr create
  git checkout main
done < tasks.txt
```
- Tests echouent → skip+log | Review humaine avant merge | Max 10 PRs par loop

## Pattern 4 — Contract-Driven
Combiner avec `task-contract`. Contrat READ-ONLY empeche l'agent de terminer avant completion.
Verification par session separee (pas d'auto-evaluation).

## Composition
| Besoin | Composition |
|--------|-------------|
| Feature propre | Contract-Driven → De-sloppify |
| Migration batch | Continuous PR Loop (chaque PR = Pipeline) |
| Refacto qualite | Contract-Driven → PR Loop → De-sloppify |

## Anti-patterns
- Boucle sans timeout/condition d'arret — Auto-merge PRs — Tout en 1 session
- Pas de rollback — Ignorer les echecs — Code non committe

## Quand utiliser / NE PAS utiliser
- OUI : refacto 20+ fichiers, migration, dead code, batch CRUD, boilerplate
- NON : tache < 5 fichiers, bug fix, decision archi, code sensible (auth, paiement)

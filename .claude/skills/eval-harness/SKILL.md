---
name: eval-harness
description: Mesurer la fiabilite d'un agent ou d'un prompt avec pass@k. Lancer la meme tache N fois, compter les succes, iterer jusqu'a 90%+. Utiliser avant de deployer un agent en prod, pour valider un nouveau skill, ou pour comparer deux approches.
---

# Eval Harness — pass@k

## Iron Law
**PAS DE DEPLOY AGENT SANS MESURE DE FIABILITE.**

## Seuils pass@k
| pass@k | Verdict |
|--------|---------|
| < 50% | Inutilisable — reprendre de zero |
| 50-79% | Fragile — ameliorer |
| 80-89% | Correct — dev only |
| 90%+ | Fiable — deployable (3 runs consecutifs = stable) |

## Workflow

### 1. Definir EVAL_SPEC.md
- Tache : description precise
- Input : donnees fixes par run
- Criteres de succes : yes/no, automatisables (tests, grep, compile, lint)
- Commande de verification

### 2. Lancer N fois (min 5, ideal 10)
Reset env (git checkout) → lancer tache → verifier → logger PASS/FAIL+raison.
```bash
for i in $(seq 1 10); do
  git checkout -- .
  claude -p "$(cat prompt.txt)" --output-file result_$i.txt
  python verify.py result_$i.txt >> eval_results.txt
done
```

### 3. Analyser les echecs
- Meme critere echoue partout → prompt mal formule
- Echecs aleatoires differents → prompt trop ambigu
- Echec sur inputs longs → probleme de contexte
- 1/10 → edge case ou bruit

### 4. Iterer
Modifier prompt → relancer N fois → comparer pass@k → repeter jusqu'a 90%+ sur 3 runs consecutifs.

## Comparaison A/B
Mesurer : pass@k (fiabilite), temps moyen (latence), tokens moyen (cout).
Meilleur prompt = meilleur pass@k a cout acceptable.

## Anti-patterns
- Tester 1 fois et deployer — Changer 3 choses entre runs — Criteres flous — Pas de reset entre runs

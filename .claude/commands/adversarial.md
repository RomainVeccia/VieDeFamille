# /adversarial — Audit adversarial complet

Lance un audit adversarial complet du projet ou du brain.
3 agents en parallèle qui challengent TOUT.

## Étape 1 — Lancer 3 agents en parallèle

**Agent 1 : Code Reviewer** (code-reviewer)
- Review du code modifié depuis le dernier commit
- Conformité spec + qualité code

**Agent 2 : Adversarial** (adversarial-reviewer)
- Reçoit les findings de l'agent 1
- Tente de RÉFUTER chaque issue
- Score : +1 par faux positif trouvé, -2 par vrai bug ignoré

**Agent 3 : Contrarian**
- Questionne les hypothèses non dites
- "Qu'est-ce qu'on ne voit pas ?"
- "Et si on a tort sur [X] ?"
- "Quel est le base rate de ce type de décision ?"

## Étape 2 — Synthèse

Combiner les 3 rapports en un verdict :
```
## /adversarial — Verdict

### Findings confirmés (vrais problèmes)
[liste avec fichier:ligne + fix proposé]

### Faux positifs éliminés
[ce que l'adversarial a réfuté avec preuves]

### Angles morts du contrarian
[ce que personne n'avait vu]

### Score
X vrais / Y faux positifs / Z angles morts
Taux de faux positifs : Y/(X+Y) = N%
```

## Étape 3 — Devil's Advocate sur les décisions récentes

Lire les 3 dernières décisions dans lessons.md (section ## Decisions).
Pour chaque décision :
- 3 raisons de NE PAS avoir pris cette décision
- 1 scénario où cette décision nous explose à la figure
- Verdict : CONFIRMÉ / À REVOIR / DANGEREUX

## Règles
- Lecture seule — ne modifie rien
- Chaque finding : fichier + ligne + fix concret
- L'adversarial DOIT essayer de réfuter — pas juste confirmer
- Le contrarian DOIT questionner les hypothèses — pas juste critiquer

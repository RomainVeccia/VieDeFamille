---
name: task-contract
description: Cree un contrat de completion avant toute tache significative. Definit les criteres d'acceptation explicites qui doivent TOUS etre valides avant de declarer la tache terminee. Previent les faux succes et le scope creep.
triggers:
  - nouvelle feature
  - refactoring majeur
  - fix complexe (plus de 3 fichiers)
  - tache avec criteres de succes flous
  - quand on dit "c'est un gros morceau"
---

# Task Contract

## Iron Law
**PAS DE TACHE SANS CONTRAT. PAS DE "C'EST FAIT" SANS CHAQUE CASE COCHEE AVEC PREUVE.**
Contrat READ-ONLY une fois cree. L'agent ne peut PAS le modifier.

## Quand creer
Feature 3+ fichiers, refactoring structurel, fix complexe, tache UI, exigences multiples.

## Template CONTRACT.md
```markdown
# CONTRACT — {NOM}
> Cree le YYYY-MM-DD — READ-ONLY

## Criteres d'acceptation (yes/no, pas de "globalement ok")
- [ ] Critere 1 — description precise
- [ ] Critere 2 — ...

## Tests requis
- [ ] `{commande}` → attendu : {resultat}

## Quality gates
- [ ] Build passe | Lint propre | Pas de regression | Pas de credentials | Pas de TODO

## Verification visuelle (si UI)
- [ ] Mobile 375px | Desktop 1280px | Dark mode 4.5:1 | Pas d'overflow

## Fake win check
- [ ] Tests existants non modifies | Criteres non assouplis | Amelioration reelle
```

## Regles
1. **Immutabilite** — critere impossible → expliquer + demander au user, logger le changement
2. **Completion** — 100% cases cochees avec preuve, 9/10 = pas fini
3. **Fake win detection** — tests inchanges ? memes metriques ? visible pour l'utilisateur ?

## Workflow
1. AVANT coder → creer contrat, montrer au user
2. PENDANT → cocher avec preuves
3. AVANT declarer fait → relire chaque case
4. Case manquante → continuer, pas de commit "final"
5. 10/10 → verification-loop → declarer fait

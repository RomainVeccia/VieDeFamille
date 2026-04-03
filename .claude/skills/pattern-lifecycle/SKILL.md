---
name: pattern-lifecycle
description: Gerer le cycle de vie des patterns — ajout, graduation, deprecation. Utiliser quand un nouveau pattern est decouvert, quand un pattern theorique est valide, ou quand un pattern s'avere faux.
---

# Pattern Lifecycle

## Ajout d'un nouveau pattern
Quand une lecon est decouverte pendant une session :

1. Determiner le type :
   - Ce qui marche → `shared/patterns.md`
   - Ce qui echoue → `shared/anti-patterns.md`
   - Specifique a CE projet uniquement → `projects/[projet]/lessons.md`

2. Tagger la confiance :
   - `★` si prouve par donnees massives (443K trades, pentest, mesure reelle)
   - `◆` si prouve par experience projet (on l'a fait, ca marche)
   - `○` si theorique (article, best practice, pas encore teste)

3. Tagger le domaine : `[python]` `[flutter]` `[web]` `[trading]` `[all]` `[claude]` `[ai]` `[security]`

4. Format : `N. CONFIANCE **Titre** — description courte [tags]`

## Graduation (○ → ◆ → ★)
Quand un pattern theorique est valide en pratique :

1. Le tester sur un VRAI projet (pas en theorie)
2. Verifier le resultat (mesure, test, observation)
3. Si ca marche → changer `○` en `◆` + ajouter le contexte : "Valide sur [projet] le [date]"
4. Si ca marche avec donnees massives → changer en `★`
5. Si ca ne marche PAS → ajouter en anti-pattern avec la raison

## Deprecation
Quand un pattern s'avere faux ou obsolete :

1. Ne PAS supprimer — deplacer dans `shared/archive/deprecated-patterns.md`
2. Ajouter la raison : "Deprece le [date] — raison : [pourquoi]"
3. Si c'est un anti-pattern maintenant → l'ajouter dans anti-patterns.md

## Audit trimestriel (anti-pattern #59)
Tous les 3 mois, passer chaque pattern au crible :
1. Defaut ? (tout le monde fait deja ca sans le dire)
2. Contradiction ? (contredit un autre pattern)
3. Repetition ? (dit la meme chose qu'un autre)
4. Band-aid ? (fix temporaire devenu permanent)
5. Trop vague ? (pas actionnable)

Si oui a 2+ → deprecer ou reformuler.

---
name: systematic-debugging
description: Debug methodique en 4 phases. Utiliser quand un bug est present, quand un fix echoue 2+ fois, ou quand l'origine d'une erreur est inconnue. Ne jamais fixer un symptome sans passer par ce skill.
---

# Systematic Debugging

## Iron Law
**PAS DE FIX SANS INVESTIGATION CAUSE RACINE D'ABORD.**
Si le meme fix echoue 3 fois → questionner l'architecture, pas le code.

## Phase 1 — Investigation (OBLIGATOIRE)
Avant d'ecrire une seule ligne de code :
1. Reproduire le bug de facon deterministe
2. Lire le message d'erreur EN ENTIER (pas juste la derniere ligne)
3. Identifier le fichier + ligne exacte de l'erreur
4. Lister toutes les hypotheses possibles (minimum 3)

## Phase 2 — Root Cause Tracing
Remonter la call stack jusqu'a la source originale :
- Symptome → cause immediate → qui a appele ca → qui a appele ca → ... → trigger original
- Poser la question "qu'est-ce qui a provoque ca ?" a chaque etape
- Ne jamais s'arreter au premier niveau — le vrai bug est souvent 3 niveaux plus haut

## Phase 3 — Hypothese unique
- Choisir UNE hypothese (la plus probable)
- Un seul changement a la fois — jamais 2 variables simultanees
- Definir AVANT de coder : "si mon hypothese est correcte, le test X devra passer"

## Phase 4 — Implementation + Verification
- Implementer le fix minimal
- Verifier que le test defini en Phase 3 passe
- Verifier qu'aucun test existant ne casse
- Si ca ne marche pas → retour Phase 2, nouvelle hypothese

## Defense-in-Depth (apres fix)
Une fois la cause racine corrigee, ajouter validation a plusieurs couches :
- Couche 1 : validation a l'entree (user input, API response)
- Couche 2 : assertion dans le composant intermediaire
- Couche 3 : check pre-operation

## Anti-patterns a eviter
- "Quick fix" sans investigation → regle le symptome, pas le probleme
- Tenter plusieurs fixes simultanement → impossible de savoir lequel a marche
- "Ca devrait marcher maintenant" → run le test, lis l'output, THEN dis ca

## Agent associe
Pour deleguer un debug complexe a un sous-agent isole → utiliser `debugger` agent (.claude/agents/debugger.md).
Meme methodologie, contexte isole, output structure.

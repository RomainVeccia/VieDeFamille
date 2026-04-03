---
name: council
description: Conseil multi-agents — paralleliser N agents specialises pour une decision. Utiliser pour les decisions importantes, les analyses multi-angle, ou les reviews approfondies.
---

# Council — Conseil multi-agents

## Quand invoquer
Decision importante (archi, strategie), analyse multi-angle, review approfondie, RomanoDev dit "conseil"/"reunis le conseil".

## Process en 5 etapes
1. **BRIEFING** — contexte partage : situation, donnees, question
2. **TOUR DE TABLE** — chaque agent : analyse, recommandation, confiance 1-5
   - Chaque agent declare son **blind spot** : "cet angle rate souvent : ..."
3. **DEBAT** — 3 questions obligatoires :
   - "Qu'est-ce qu'on ne voit pas ?" (steelman inverse)
   - "Quel est le base rate ?" (historiquement, ca mene a quoi ?)
   - "Process ou chance ?" (raisonnement ou rationalisation ?)
   - Consensus : 7+ agents → fort | 5-6 → faible | < 5 → WAIT
4. **SYNTHESE** — recommandation + vote + plan + risques
   - **Section obligatoire : Minority Report** — position dissidente avec justification (meme si consensus atteint)
   - **Tags confiance** : chaque recommandation taggee VERIFIE / PROBABLE / INFERE / SPECULATIF
   - **Gap inter-agents** : "Qu'est-ce que la combinaison des reponses revele qu'aucun agent seul ne voyait ?"
5. **DECISION** — RomanoDev valide. Rien sans validation humaine.

## Format reponse agent (JSON)
```json
{"agent":"nom","recommendation":"GO|WAIT|NO","confidence":0.75,"reasoning":"2 lignes max","risk":"principal risque"}
```

## Councils pre-definis (avec polarites)
- **Tech** (tous) : Architecte, Security, DX/UX, Performance, Debt, Ops, Testing, Contrarian
  - Polarites : Architecte↔Debt (ideal↔pragmatique) | Performance↔DX/UX (speed↔ergonomie) | Security↔Ops (lock down↔ship fast)
- **Business** (tous) : Market, Finance, Legal, Growth, User Advocate, Competitor, Risk Manager, Contrarian
  - Polarites : Growth↔Finance (depenser↔economiser) | Legal↔Growth (prudence↔vitesse) | User Advocate↔Competitor (interne↔externe)
- **Game Design** : Game Designer, Systems Designer, UX Designer, Economy Designer, QA Tester, Contrarian
  - Polarites : Game Designer↔QA (fun↔stabilite) | Economy↔UX (monetisation↔experience) | Systems↔Contrarian (coherence↔disruption)

## Multi-roles Romano (mini-council rapide, 1 appel)
4 angles en 1 seul appel : Fondateur (vision?), Ingenieur (faisable?), Commercial (monetisable?), Utilisateur (j'utiliserais?). Cout 3x. Utiliser pour 80% des decisions.

## Devil's Advocate automatique
Apres CHAQUE decision technique logguee (keep/revert dans lessons.md) :
- 3 raisons de NE PAS avoir pris cette decision
- 1 scenario ou cette decision explose a la figure
- Verdict : CONFIRME / A_REVOIR / DANGEREUX
Integre dans le flow council — pas un step separe.

## Regles
- Min 5 / max 10 agents — toujours un Contrarian + un Risk Manager (droit de veto)
- Vote JSON structure — RomanoDev decide, le conseil propose jamais n'execute
- Devil's advocate OBLIGATOIRE sur chaque decision technique

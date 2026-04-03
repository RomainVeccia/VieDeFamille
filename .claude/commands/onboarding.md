# Onboarding — Setup du Brain

Configure le cerveau central d'un nouveau dev. Poser les questions par blocs, attendre les reponses, generer TOUS les fichiers d'un coup.

## Regles
- Questions par blocs thematiques, attendre avant le bloc suivant
- Direct et decontracte, pas corporate
- Generer tous les fichiers sans confirmation individuelle

## BLOC 1 — Profil dev
Message : **Setup Brain — Etape 1/4 : Ton profil**
1. Prenom/pseudo ? | 2. Annees XP ? | 3. Stack principale ? | 4. OS ? | 5. Ton prefere avec Claude ?
Memoriser : NOM, XP, STACK, OS, TON.

## BLOC 2 — Dossier racine
Message : **Etape 2/4 : Structure**
6. Chemin absolu du dossier projets ? | 7. Obsidian installe ?
Memoriser : RACINE, OBSIDIAN.

## BLOC 3 — Projets existants
Message : **Etape 3/4 : Tes projets** — combien ?
Par projet : nom court, description, chemin relatif, stack, LOC, objectif (vital/client/store/perso/portfolio), visibilite, 2-3 priorites.

### BLOC 3.5 — Inputs projet
Par projet : documents, data, visuels, code existant, liens, logique metier, contenus ? → deposer dans `[projet]/inputs/`.

## BLOC 4 — Versioning
Message : **Etape 4/4**
8. Theme noms de version brain ? (Neuroscience recommande / Mythologie / Cosmos / Autre)
9. Nom du premier commit ?

## GENERATION — Tout creer d'un coup

> "Parfait, j'ai tout. Je genere le brain complet."

Executer sans confirmation :
1. **BRAIN.md** — remplacer NOM, XP, STACK, TON, tableau projets
2. **CLAUDE.md** — tableau projets avec chemins reels
3. **CURRENT_STATE.md** — projets avec stats connues
4. **projects/[nom]/** — state.md (rempli) + lessons.md (template) + decisions.md (stack deduites)
5. **prompts/SESSION_[NOM].md** — depuis template, valeurs reelles
6. **shared/versioning.md** — theme choisi + suggestions par projet
7. **PROJECT_MAP.md** racine — liens Obsidian vers brain + projets
8. **BRAIN.md section Projets** — tableau complet
9. **Git init + commit** : `[feat] Brain v1.0 — [NOM_COMMIT] — [NOM] setup initial`

## Resume final
```
Brain configure — Profil : NOM | XP | STACK | Dossier : RACINE
Fichiers : BRAIN.md, CLAUDE.md, CURRENT_STATE.md, projects/[nom]/ x N, prompts/ x N, PROJECT_MAP.md
Demarrer : coller brain/prompts/SESSION_[NOM].md dans Claude Code
Prochaine etape : ajouter `> Brain : lire ../brain/BRAIN.md` en haut du CLAUDE.md de chaque projet
```

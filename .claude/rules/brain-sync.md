---
description: ORIENT (debut) et PERSIST (fin) — le cycle de vie de chaque session
---

# Sync Brain

## ORIENT — Debut de session
Triggers : "ORIENT" uniquement

**Si on est dans le brain lui-meme** → lancer `/cockpit` a la place (vue globale tous projets).
**Si on est dans un projet** → executer la sequence ci-dessous.

### Environnements projet (dev / recette / prod)
Chaque projet a un `env` dans projects.json. Adapter le comportement :
- **dev** : PAS d'alertes API keys/credentials, PAS de security scan, PAS de rappels mode maintenance, PAS de rappels deploy/DNS/SSL. Focus features uniquement.
- **recette** : alertes credentials actives, tests obligatoires, responsive testing, rappels deploy
- **prod** : TOUT actif — security scan, credentials, performance, monitoring
NE PAS rappeler en dev :
- Blockers "EN ATTENTE volontaire"
- Mode maintenance a desactiver
- API keys a regenerer
- Certificats SSL / DNS
- Deployment / mise en prod
Ces sujets ne concernent QUE la recette/prod. En dev, focus sur le CODE.

Executer dans l'ordre, sans demander confirmation :

0. **Localiser le brain** (OBLIGATOIRE — ne JAMAIS skip) :
   - Chercher le dossier `brain/` dans les parents : `../brain/` ou `../../brain/`
   - Tester : `ls ../brain/CLAUDE.md 2>/dev/null || ls ../../brain/CLAUDE.md 2>/dev/null`
   - Stocker le chemin trouve dans `$BRAIN` pour le reste de la session
   - **SI INTROUVABLE → STOP COMPLET. Dire "ERREUR : brain introuvable depuis ce projet. Le brain doit etre au meme niveau ou un niveau au-dessus." NE PAS continuer l'ORIENT.**

0b. **Scan stats fraiches** (conditionnel) :
   - Verifier l'age de `$BRAIN/tools/last_persist.txt`
   - Si modifie il y a **< 2h** → SKIP le scan (CURRENT_STATE deja a jour)
   - Si modifie il y a **>= 2h** ou fichier absent → lancer le scan :
   ```bash
   cd $BRAIN && python tools/brain.py scan
   ```
1. **State du projet** : lire `$BRAIN/projects/[ce-projet]/state.md`
2. **Blockers** : lire la section "Blockers actifs" dans `$BRAIN/CURRENT_STATE.md` — filtrer ce projet
3. **Derniere activite** : lire `$BRAIN/tools/last_persist.txt` si existe
4. **Nouveautes brain** : lire `$BRAIN/CHANGELOG.md` — 5 dernieres lignes
5. **Inbox** : verifier si state.md contient une section ## Inbox avec des lecons non lues
5b. **Index shared** : lire `$BRAIN/shared/INDEX.md` — ne PAS charger les fichiers, juste savoir ce qui existe
6. **Resumer en 5 lignes** :
   - Ligne 1 : etat du projet (version, stats cles, derniere session)
   - Ligne 2 : blockers actifs
   - Ligne 3 : top 3 priorites du state.md
   - Ligne 4 : inbox (lecons non lues d'autres projets)
   - Ligne 5 : "On attaque quoi ?"

## PERSIST — Fin de session
Triggers : "PERSIST" uniquement
Detecteurs auto : "on arrete", "je ferme", "a plus", "merci c'est bon", "fin de session"

> Regle d'or : le prochain Claude doit comprendre l'etat en 30 secondes.

Executer TOUT dans l'ordre, sans demander confirmation.
> `[AUTO]` = commande bash a lancer | `[CLAUDE]` = action de redaction par Claude

### 1. [AUTO] Scanner les stats
```bash
cd $BRAIN && python tools/brain.py scan
```

### 2. [CLAUDE] MAJ state.md du projet
Dans `$BRAIN/projects/[ce-projet]/state.md` :
- Priorites : barrer ce qui est fait, remonter ce qui reste
- Bugs/blockers decouverts pendant la session
- **VERSION BUMP OBLIGATOIRE si feature significative** :
  - Incrementer dans state.md, CLAUDE.md, package.json/pubspec.yaml
  - Donner un NOM a la version (theme du projet : voir shared/versioning.md)
  - **MAJ le numero + nom sur TOUTES les pages HTML** (overview, landing, index, dashboard, changelog)
  - Si pas de feature significative : ne pas incrementer
  - **NE JAMAIS oublier les pages HTML** — c'est l'anti-pattern #79

### 3. [CLAUDE] Lecons apprises (si applicable)
- Lecon universelle → `$BRAIN/shared/anti-patterns.md` ou `patterns.md` avec tag [stack]
- Lecon specifique → `$BRAIN/projects/[ce-projet]/lessons.md`
- Format lecon : `## Lecon #N — Date / Erreur / Correction / Regle / Tags`
- Section ## Decisions dans lessons.md si decision technique prise

### 4. [AUTO] Propager lecons + MAJ dashboard (silencieux)
```bash
cd $BRAIN && python tools/brain.py persist
```
> brain.py persist fait : scan + propagate + inbox + graduate + dashboard + sync rules + health + timeline + adversarial mini-review + timestamp

### 5. [CLAUDE] CHANGELOG du brain
Ajouter une ligne par changement significatif dans `$BRAIN/CHANGELOG.md` :
```
- [type] description courte
```
Types : [feat] [fix] [refactor] [clean] [update] [restructure]

Si la date du jour n'existe pas encore dans le CHANGELOG, ajouter le header `## YYYY-MM-DD` d'abord.

### 6. [CLAUDE] Commit + push brain
```bash
cd $BRAIN && git add -A && git commit -m "[update] MAJ [projet] — fin session YYYY-MM-DD" && git push
```

### 7. [CLAUDE] Commit + push projet
```bash
git add -A && git commit -m "[update] fin session — [resume 1 ligne]" && git push
```

### 8. [CLAUDE] Signal aux autres sessions
Ecrire la date + projet dans `$BRAIN/tools/last_persist.txt`

Ne pas demander confirmation a chaque etape — executer dans l'ordre, signaler seulement si blocage.

## APRES COMPACT ou NOUVELLE SESSION — Relecture obligatoire
Apres chaque /compact ou ouverture de session, RELIRE dans l'ordre :
1. `$BRAIN/projects/[ce-projet]/state.md` — etat complet, priorites, blockers
2. `$BRAIN/projects/[ce-projet]/lessons.md` — lecons apprises, decisions, design
3. `tasks/todo.md` ou scratchpad si existe — taches en cours
4. Les fichiers modifies recemment : `git log --oneline -10` → lire les fichiers touches
Si un fichier a ete modifie depuis le dernier compact mais pas relu → LE RELIRE.
Ne JAMAIS continuer a coder sans avoir relu. C'est la premiere cause de regression.

## URGENCE CONTEXTE — Si contexte > 80% (seuil normal : /compact a 60%, voir token-economy.md)
1. STOP immediat — ne pas continuer a coder
2. Lancer PERSIST (tout sauvegarder)
3. Committer tout
4. Dire : "Contexte sature. Ouvre une nouvelle session et tape ORIENT pour reprendre."
5. Ce n'est PAS une degradation progressive — c'est une URGENCE

## Lost in the Middle
Les informations au milieu d'un long contexte sont manquees par les LLMs.
- Placer les resumes cles en DEBUT de prompt
- Trimmer les resultats d'outils aux champs pertinents
- /compact quand le contexte est plein de logs verbeux
- Utiliser tasks/scratchpad.md pour les findings en cours (survit au compact)

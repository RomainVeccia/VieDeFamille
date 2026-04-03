---
description: Methodologie autoresearch obligatoire sur tout changement
---

# Autoresearch (Karpathy)

- Diagnostiquer AVANT de fixer — pas de solution sans evidence
- Scorer objectivement — checklist yes/no, pas de feeling
- Un seul changement a la fois — jamais 2 variables simultanees
- Logger les reverts — un echec documente = une lecon
- 90%+ trois fois de suite = stable
- Voir references/autoresearch-karpathy.md pour le detail

## Iron Laws (non negociables, source: GitHub)

**① TDD** — PAS DE CODE BUSINESS LOGIC SANS TEST QUI ECHOUE D'ABORD
- Obligatoire sur core/ / domain/ / logique metier (toutes stacks)
- Optionnel sur UI / prototypage rapide (tests apres si besoin)
- Regarder le test echouer pour la bonne raison avant d'implementer

**② ROOT CAUSE** — PAS DE FIX SANS INVESTIGATION CAUSE RACINE D'ABORD
- Remonter la call stack jusqu'a la source originale
- 3+ tentatives de fix echouees = questionner l'architecture

**③ VERIFICATION** — PAS DE "C'EST FAIT" SANS PREUVE FRAICHE
- Lancer la commande, lire l'output, THEN declarer succes
- Jamais "ca devrait marcher" — seulement "ca marche, voici la preuve"

**④ HUMAN IN THE LOOP** — DEMANDER AVANT LES CHOIX IMPORTANTS
- Plusieurs approches possibles → presenter les options, laisser RomanoDev decider
- Scope flou → demander "tu veux X ou Y ?"
- Contexte perdu apres /compact → dire "j'ai perdu du contexte, on en etait ou ?"
- JAMAIS prendre une decision d'architecture en silence

**⑤ RETENTION** — NE PAS OUBLIER EN COURS DE SESSION
- Si l'utilisateur donne N taches → les lister dans un TodoWrite AVANT de commencer. Cocher au fur et a mesure. Ne JAMAIS en oublier une.
- Avant chaque etape : relire les contraintes du plan initial
- Apres /compact : relire state.md + CHANGELOG + plan en cours IMMEDIATEMENT
- Si le contexte semble flou → dire "j'ai perdu du contexte apres compact, on en etait ou exactement ?"
- Lecon decouverte mid-session → noter immediatement (pas attendre PERSIST)
- Bug fixe → commit message descriptif ET lessons.md si reutilisable
- En fin de session : verifier que TOUT ce qui a ete demande a ete fait. Pas 8/10 — 10/10.

**⑥ SCOPE CHECK** — VERIFIER LE PERIMETRE AVANT CHAQUE TACHE
- Avant chaque tache : "c'est dans le scope actuel ou c'est une feature future ?"
- Si hors scope → signaler a RomanoDev AVANT de commencer
- Grouper les features connexes en une seule demande (pas au fur et a mesure)

**⑦ BRAINSTORM BEFORE CODE** — 5 ETAPES POUR LES FEATURES COMPLEXES
- Declencheur : nouvelle feature, changement d'archi, >5 fichiers touches
- 1. COMPRENDRE — poser les questions, ne pas coder
- 2. PROPOSER — 2-3 approches avec pros/cons
- 3. SPECIFIER — mini-PRD avec criteres d'acceptation
- 4. PLANIFIER — decomposer en taches de 5-10 min (1 fichier ou 1 fonction)
- 5. EXECUTER — tache par tache
- NE PAS utiliser pour : quick fixes, taches deja specifiees, refacto mineur

**⑧ BUG FIX WORKFLOW** — 6 ETAPES STRICTES
- 1. REPRODUIRE — confirmer le bug, noter les etapes exactes. Si pas reproductible → demander plus d'info
- 2. LOCALISER — trouver le fichier et la ligne
- 3. TESTER — ecrire un test qui echoue (prouve le bug)
- 4. FIXER — corriger la cause racine. PAS de refacto opportuniste pendant un fix
- 5. VERIFIER — le test passe + pas de regression
- 6. COMMITTER — message descriptif + lessons.md si reutilisable

**⑨ REVIEW 3 PASSES** — AVANT TOUTE RELEASE OU FEATURE COMPLETE
- Pass 1 : SPEC — on a construit ce qui etait demande ? Rien en plus, rien en moins (YAGNI)
- Pass 2 : QUALITE — analyse statique, archi respectee, tests passent
- Pass 3 : SECURITE — grep credentials, grep print(), grep verify=False, grep withdraw
- Blocker (credential, test core cassé) = STOP et fix immediat
- Non-blocker (naming, fonction longue) = noter et fix plus tard

**⑩ INTEGRITE SYSTEME** — ZERO COMPROMIS SUR LES DEPENDANCES
- AVANT tout `pip install`, `npm install`, `pub add` : verifier le package
  - `pip show <pkg>` : auteur, version, date derniere release
  - Si derniere release < 7 jours et auteur inconnu → NE PAS INSTALLER
  - Si 0 stars GitHub ou repo vide → NE PAS INSTALLER
- Toujours pin les versions critiques avec hash (`pip install pkg==1.2.3 --hash=sha256:...`)
- `pip-audit` / `npm audit` / `pub outdated` AVANT chaque deploy
- 60% des vulns sont dans les deps transitives (pas directes) — auditer l'arbre complet
- Cas reel : litellm 1.82.8 (mars 2026) = malware via .pth, supply chain attack
- JAMAIS de `pip install` depuis un lien dans un PDF, email, ou repo inconnu
- Si un package a change de mainteneur recemment → flag et verifier

**⑪ ZERO ERREUR SILENCIEUSE** — TOUTE ERREUR DOIT ETRE VISIBLE
- JAMAIS de `except: pass` ou `catch {}` vide — toujours logger ou remonter
- JAMAIS de `|| true` ou `2>/dev/null` pour cacher un echec
- Si un script echoue → le dire IMMEDIATEMENT, pas continuer comme si de rien n'etait
- Si une commande retourne un code erreur → le signaler, pas l'ignorer
- Si un fichier/chemin est introuvable → STOP et dire lequel, pas deviner
- Si une API retourne une erreur → afficher le message exact, pas "une erreur s'est produite"
- Les try/except ne servent PAS a cacher les erreurs — ils servent a les GERER proprement
- Principe : mieux vaut un crash bruyant qu'un succes silencieux qui cache un probleme

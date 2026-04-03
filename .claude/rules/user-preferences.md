# Preferences utilisateur — A personnaliser

## Profil
- Dev autodidacte, stack Flutter + Next.js/React/TS, autonomie max, feedback direct
- Langue de travail : francais decontracte (tutoiement)

## Conventions de travail

### Tableaux d'estimation — TOUJOURS 2 colonnes temps
Chaque tableau avec des estimations doit avoir **Temps humain** + **Temps Claude**.
La comparaison permet de mesurer le gain reel de l'assistance IA.

### Fichiers custom — JAMAIS ecraser sans lire
Les fichiers overview HTML et autres fichiers manuels sont custom.
TOUJOURS lire un fichier > 200 lignes avant de le reecrire.
Si c'est un fichier custom → proposer des modifications chirurgicales, pas un overwrite.

### Obsidian — TOUJOURS creer PROJECT_MAP + liens wiki
Chaque nouveau projet doit avoir un PROJECT_MAP-[nom].md avec des liens [[]] vers :
- Les fichiers internes du projet
- Les fichiers brain (state, lessons, patterns, BRAIN)
- Les projets lies (meme stack, synergie)

### Starter packs — IMPERATIF complets
Checklist 15 items : CLAUDE.md, .gitignore, README, .claude/rules/, .claude/agents/,
.claude/skills/, .claude/commands/, references/, PROJECT_MAP, port-registry entry.
Se referencer aux projets existants similaires comme base.

### Audits — Sauvegarder les resultats
Apres un full audit, noter la date + resultats dans CHANGELOG ou state.md.
Ne JAMAIS re-auditer ce qui a deja ete verifie recemment (economie tokens).

### Ports locaux
Voir rules/ui-defaults.md — port-registry obligatoire.

### API keys / Blockers repetitifs
Si l'utilisateur a dit "je ferai plus tard" pour un blocker → NE PAS le rappeler a chaque ORIENT.
Le noter dans BLOCKERS.md avec tag "EN ATTENTE (volontaire)" et ne plus en parler.

---
name: verification-loop
description: Boucle de verification complete avant de declarer une tache terminee. Utiliser systematiquement avant tout "c'est fait", avant un commit important, avant un deploy. Previent les faux positifs.
---

# Verification Loop

## Iron Law
**PAS DE "C'EST FAIT" SANS PREUVE FRAICHE.**
Lancer la commande, lire le output, THEN declarer succes.
Jamais "ca devrait marcher" — seulement "ca marche, voici la preuve".

## La boucle (dans l'ordre)

### 1. Build
```bash
# Python
python -m py_compile src/**/*.py

# Flutter
flutter build apk --debug

# Next.js
npm run build

# Node
npm run build
```
→ Zero erreur de compilation avant de continuer.

### 2. Lint
```bash
# Python
ruff check . || flake8 .

# Dart/Flutter
dart analyze

# TypeScript/JS
npm run lint
```
→ Zero warning bloquant.

### 3. Tests
```bash
# Python
pytest --tb=short -q

# Flutter
flutter test

# JS/TS
npm test
```
→ Tous les tests passent. Si un test nouvellement cassé : retour au debug.

### 4. Review du diff
```bash
git diff HEAD
git diff --staged
```
→ Lire chaque changement. Pas de print() oublie. Pas de credentials. Pas de TODO non resolu.

### 5. Responsive (projets web uniquement)
Avant tout commit sur un projet web (Next.js, React, HTML) :
```bash
# Tester 3 breakpoints via Claude Preview ou navigateur
# Mobile  : 375px  → tout visible, rien tronque, touch targets 44px
# Tablet  : 768px  → grille adaptee, sidebar collapse
# Desktop : 1280px → layout complet, pas de scroll horizontal
```
→ Si un breakpoint casse : fixer AVANT de commit. C'est un BLOCKER.
→ Toujours tester mobile EN PREMIER (80% du trafic).
→ Verifier : cards alignees, texte pas tronque, images pas deformees, boutons cliquables.

### 6. Securite (si changement sensible)
- Pas de cle API en dur
- Pas de donnee user loggee
- Pas de endpoint non authentifie

## Quand utiliser
- Avant chaque commit
- Avant de dire "la feature est finie"
- Apres un fix de bug (verifier que rien d'autre n'a casse)
- Avant un deploy ou une PR

## Context budget
Round 1 : passer tout le code modifie
Round 2+ : passer uniquement le diff — pas tout refichier

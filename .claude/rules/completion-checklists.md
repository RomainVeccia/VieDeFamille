---
description: Checklists de completion par stack — verifier AVANT de dire "c'est fait"
---

# Checklists de completion

## Universel (toutes stacks)
- [ ] Version bump si feature significative (state.md + CLAUDE.md + CHANGELOG)
- [ ] MAJ numero de version sur TOUTES les pages HTML (overview, landing, index, dashboard)
- [ ] Zero credential dans logs / BDD / code
- [ ] Zero `print()` / `console.log` oublie — logger uniquement
- [ ] Fichiers modifies testes (pas juste "ca devrait marcher")
- [ ] core/ / domain/ = zero import framework (logique metier pure, toute stack)
- [ ] Fonctions < 30 lignes (sinon splitter)
- [ ] Commentaires expliquent le WHY, pas le WHAT
- [ ] Soft delete par defaut (pas de hard delete sur les donnees utilisateur)
- [ ] PERSIST si fin de session

## Release (en plus de la checklist ci-dessus)
- [ ] Tous les tests passent
- [ ] Analyse statique propre (0 warning)
- [ ] Scan securite propre (5 greps de security.md)
- [ ] Review 3 passes OK (spec + qualite + securite)
- [ ] Git tag vX.Y.Z
- [ ] Version coherente partout : state.md, CLAUDE.md, package.json/pubspec.yaml, CHANGELOG, pages HTML
- [ ] Build + tester le build
- [ ] Deploy + verifier en prod

## Python
- [ ] `ruff check .` propre (analyse statique)
- [ ] `mypy core/` propre (type checking)
- [ ] `pytest tests/` passe
- [ ] Zero logique metier dans la GUI (si PyQt)
- [ ] Couche core/ sans import GUI
- [ ] Type hints sur toutes les signatures publiques

## Flutter (Zumbers, VieDeFamille)
- [ ] `flutter analyze` zero warning
- [ ] Aucun `!` (null assertion) non justifie
- [ ] Zero logique metier dans les widgets
- [ ] Zero import Flutter dans `domain/`
- [ ] BLoC expose un `Stream<State>` via Freezed
- [ ] Repository : cache local avant fetch reseau
- [ ] Debounce 300ms sur les champs de recherche
- [ ] Strings UI en cles i18n (jamais hardcodees)
- [ ] Images : WebP/SVG, aucun asset > 100 Ko
- [ ] build_runner si Drift/Freezed modifie

## Next.js / TypeScript (JoanneDoulaMamaterre)
- [ ] `npm run build` passe sans erreur
- [ ] `tsc --noEmit` propre (type checking)
- [ ] Zero `any` non justifie
- [ ] Pas de `console.log` en prod
- [ ] Images : width/height explicites, WebP, lazy loading
- [ ] **Responsive TESTE** (pas juste "verifie mentalement") :
  - Mobile 375px : tout visible, cards empilees, menu burger, touch 44px
  - Tablet 768px : grille adaptee, sidebar collapse si besoin
  - Desktop 1280px : layout complet, pas de scroll horizontal
  - Si un breakpoint casse = BLOCKER (fixer avant commit)
- [ ] Meta tags / SEO si page publique
- [ ] Server components par defaut, client components seulement si necessaire

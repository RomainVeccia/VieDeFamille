# todo.md — Tâches en cours

> Mis à jour par Claude Code à chaque PERSIST.

## Phase 1 — Setup & Fondations
- [x] Configurer tous les fichiers .md du projet
- [ ] Installer Flutter SDK sur macOS (`brew install --cask flutter`)
- [ ] Installer Xcode + CocoaPods (pour iOS)
- [ ] Créer le projet Flutter (`flutter create vie_de_famille`)
- [ ] Créer l'arborescence (core/, ui/, data/, assets/)
- [ ] Configurer pubspec.yaml (dépendances)
- [ ] Config linter (analysis_options.yaml)
- [ ] Créer .gitignore Flutter
- [ ] Git init + premier commit
- [ ] Premier écran fonctionnel (splash screen)

## Phase 2 — Core (Logique métier)
- [ ] Modèle Family (famille + membres + rôles)
- [ ] Modèle Task (tâches + récurrences + assignation)
- [ ] Modèle Event (planning + participants + rappels)
- [ ] Modèle ShoppingList (courses + items + catégories)
- [ ] Modèle Budget (catégories + dépenses + limites)
- [ ] Service TaskService (CRUD tâches, récurrences)
- [ ] Service CalendarService (CRUD événements, rappels)
- [ ] Service BudgetService (calculs, alertes, graphiques)
- [ ] Service ShoppingService (listes partagées, sync)
- [ ] Tests unitaires logique métier (TDD)

## Phase 3 — UI
- [ ] Écran Accueil (dashboard du jour)
- [ ] Écran Tâches (liste, filtres, assignation)
- [ ] Écran Planning (calendrier, vue semaine/mois)
- [ ] Écran Courses (listes partagées, cocher)
- [ ] Écran Budget (dépenses, graphiques, catégories)
- [ ] Écran Messages (mur familial)
- [ ] Navigation bottom tabs

## Phase 4 — Data & Sync
- [ ] SQLite local (tâches, budget, profils, événements)
- [ ] Firebase Auth (compte famille)
- [ ] Firebase Firestore (sync famille temps réel)
- [ ] Firebase Cloud Messaging (notifications push)
- [ ] Mode offline-first (sync au retour réseau)

## Phase 5 — Gamification
- [ ] Système de points (tâches complétées)
- [ ] Récompenses personnalisées (créées par les parents)
- [ ] Classement familial fun
- [ ] Streak tâches (séries de jours)

## Phase 6 — Polish
- [ ] Animations et transitions
- [ ] Notifications push (rappels tâches, événements)
- [ ] Dark mode
- [ ] Sons subtils (tâche complétée, notification)
- [ ] Onboarding premier lancement
- [ ] Test sur vrais devices (iPhone)

## Phase 7 — Landing Page
- [ ] Design landing page (dark, glassmorphism, hero animé)
- [ ] Développement HTML/CSS/JS
- [ ] Screenshots / mockups de l'app
- [ ] CGU + Privacy Policy
- [ ] Déploiement (Netlify / GitHub Pages)

## Phase 8 — Packaging & Stores
- [ ] Créer compte Apple Developer (99€/an)
- [ ] Créer compte Google Play Console (25€ one-shot)
- [ ] Build iOS release + Archive Xcode
- [ ] Build Android release (AAB)
- [ ] Préparer assets stores (icônes, screenshots, descriptions)
- [ ] TestFlight (beta iOS)
- [ ] Internal Testing (beta Android)

## Phase 9 — Release
- [ ] Soumission App Store
- [ ] Soumission Play Store
- [ ] Landing page live avec liens stores
- [ ] Annonce / partage

## Backlog
- [ ] Partage de photos dans le mur familial
- [ ] Export budget en CSV/PDF
- [ ] Widget iOS (tâches du jour)
- [ ] Rappels intelligents basés sur les habitudes
- [ ] Templates de tâches ménagères pré-remplis
- [ ] Voir tasks/IDEAS.md pour toutes les idées

# CLAUDE.md — VieDeFamille

> **Ordre de lecture** : CLAUDE.md → DATAONME.md → AGENTS.md → WORKFLOWS.md → SKILLS.md → tasks/lessons.md → tasks/todo.md
> **Version LITE** : CLAUDE_LITE.md (tâches simples)

---

## Protocole de chargement

| Palier | Situation | Charger |
|---|---|---|
| **P0** | Fix 1 ligne, 1 bug | CLAUDE_LITE + SKILLS_LITE |
| **P1** | Feature complète | Les 4 LITE + SKILLS.md + WORKFLOWS.md |
| **P2** | Décision archi | CLAUDE.md complet + DATAONME_LITE + AGENTS_LITE + SKILLS.md + WORKFLOWS.md |
| **P3** | Stratégie / biz | CLAUDE_LITE + DATAONME_LITE + AGENTS.md complet |
| **P4** | Audit global | TOUS les complets (1x max) |

---

## Vision

VieDeFamille est une application mobile de gestion familiale qui centralise l'organisation du quotidien : tâches ménagères, courses, planning familial, budget et communication entre membres de la famille. Simple, intuitive et fun — pour que toute la famille s'organise sans prise de tête.

Le projet est développé from scratch en Flutter/Dart pour iOS et Android. L'objectif est de créer une app qui simplifie la vie de famille au quotidien, d'abord pour usage perso puis publication sur les stores.

Budget : 0€ (tout gratuit / open source). Public cible : ma famille d'abord, puis toutes les familles (stores).

### Plateformes cibles
- [x] iOS (Flutter)
- [x] Android (Flutter)
- [ ] Web (React / Next.js / Vue)
- [ ] Desktop Windows (Electron / PyQt / .NET)
- [ ] Desktop Mac
- [ ] API / Backend seul
- [ ] CLI

### Stack technique
```
Flutter 3.x | Dart | Firebase (gratuit) | SQLite local | Riverpod
```

---

## Architecture

```
vie_de_famille/
├── lib/
│   ├── core/                # Logique métier (ZÉRO import UI)
│   │   ├── models/          # Modèles de données (Family, Member, Task, Event, Budget)
│   │   ├── services/        # Gestion tâches, planning, budget, notifications
│   │   ├── engine/          # Moteur de répartition, calculs budget, rappels
│   │   └── utils/           # Utilitaires purs (dates, formatage, calculs)
│   ├── ui/                  # Interface utilisateur
│   │   ├── screens/         # Écrans principaux
│   │   ├── widgets/         # Composants réutilisables (cards, listes, calendrier)
│   │   ├── animations/      # Animations (transitions, feedback, confettis)
│   │   └── theme/           # Couleurs, polices, styles
│   ├── data/                # Accès aux données
│   │   ├── local/           # SQLite / SharedPreferences (tâches, profils, budget)
│   │   └── remote/          # Firebase (sync famille, auth)
│   └── main.dart            # Entry point
├── test/                    # Tests unitaires + widget tests
│   ├── core/                # Tests logique métier, budget, répartition
│   └── ui/                  # Widget tests
├── assets/
│   ├── images/              # Logo, avatars, icônes, illustrations
│   ├── sounds/              # Sons de notifications, succès
│   └── fonts/               # Polices custom
└── pubspec.yaml             # Dépendances
```

### Règle d'or
- `core/` = logique pure, AUCUN import UI — gestion tâches, budget, planning
- `data/` = accès données, pas de logique métier
- `ui/` importe `core/` et `data/`, jamais l'inverse
- `engine/` = répartition des tâches, calculs budget, rappels intelligents
- Pas de credentials en clair dans le code

---

## Modèle de données

```sql
-- Famille
families (id, name, code_invite, created_at)

-- Membre de la famille
members (id, family_id, username, avatar_id, role, color, created_at)

-- Tâche ménagère / à faire
tasks (id, family_id, title, description, assigned_to, category, priority,
       recurrence, due_date, completed, completed_at, created_by, created_at)

-- Liste de courses
shopping_lists (id, family_id, name, created_by, created_at)
shopping_items (id, list_id, name, quantity, category, checked, added_by)

-- Événements / Planning
events (id, family_id, title, description, date_start, date_end,
        all_day, location, participants_json, reminder, color, created_by)

-- Budget familial
budget_categories (id, family_id, name, icon, monthly_limit, color)
expenses (id, family_id, category_id, amount, description, paid_by,
          date, receipt_photo, created_at)

-- Messages / Notes familiales
messages (id, family_id, author_id, content, type, pinned, created_at)

-- Récompenses (gamification famille)
rewards (id, family_id, name, description, points_cost, icon)
member_points (member_id, points, total_earned, updated_at)
```

---

## API / Endpoints

| API | Usage | Limite |
|---|---|---|
| Firebase Auth | Authentification (email, Google, Apple) | Gratuit jusqu'à 50K users |
| Firebase Firestore | Sync famille, tâches partagées, messages | 50K reads/jour gratuit |
| Firebase Cloud Messaging | Notifications push (rappels, tâches) | Gratuit |
| Firebase Analytics | Métriques d'usage | Gratuit |

---

## UI/UX

### Couleurs
- Background : `#F5F0EB` (beige chaud clair)
- Primary : `#5B7B6F` (vert sauge — calme, familial)
- Secondary : `#E8985E` (orange doux — énergie, action)
- Accent : `#D4A574` (caramel — chaleur)
- Success : `#7CB342` (vert pomme — tâche complétée)
- Error : `#E57373` (rouge doux — alerte)
- Budget Positive : `#66BB6A` (vert — sous le budget)
- Budget Negative : `#EF5350` (rouge — dépassement)
- Cards : `#FFFFFF` (blanc — cartes et sections)
- Text Primary : `#2D2D2D` (gris foncé — lisible)
- Text Secondary : `#757575` (gris moyen)

### Typo
- Titres / Logo : Police ronde, chaleureuse (ex: Nunito, Quicksand)
- Corps : Roboto / SF Pro (sans-serif clean)
- Chiffres budget : Police bold, mono-space pour alignement
- Labels : Police légère, petite taille

### Navigation
Bottom tabs : Accueil | Tâches | Planning | Courses | Budget

### Écrans principaux

| Écran | Fichier | Description |
|---|---|---|
| Splash | `screens/splash_screen.dart` | Logo VieDeFamille + animation d'entrée |
| Onboarding | `screens/onboarding_screen.dart` | Créer/rejoindre une famille |
| Accueil | `screens/home_screen.dart` | Dashboard : résumé du jour, tâches urgentes |
| Tâches | `screens/tasks_screen.dart` | Liste des tâches, assignation, filtres |
| Planning | `screens/calendar_screen.dart` | Calendrier familial, événements |
| Courses | `screens/shopping_screen.dart` | Listes de courses partagées |
| Budget | `screens/budget_screen.dart` | Dépenses, catégories, graphiques |
| Messages | `screens/messages_screen.dart` | Mur familial, notes, annonces |
| Profil | `screens/profile_screen.dart` | Membre, stats, réglages famille |
| Paramètres | `screens/settings_screen.dart` | Notifications, thème, export |

---

## Fonctionnalités principales

### Gestion des tâches
- Créer, assigner, prioriser des tâches ménagères
- Tâches récurrentes (tous les jours, semaine, mois)
- Catégories (ménage, cuisine, jardin, admin, enfants...)
- Notifications de rappel
- Historique des tâches complétées

### Planning familial
- Calendrier partagé (vue jour/semaine/mois)
- Événements avec participants (école, sport, RDV, anniversaires)
- Rappels intelligents
- Code couleur par membre

### Liste de courses
- Listes partagées en temps réel
- Catégories auto (fruits, viandes, produits ménagers...)
- Cocher en magasin (sync instantanée)
- Historique des achats fréquents

### Budget familial
- Suivi des dépenses par catégorie
- Budget mensuel par catégorie
- Graphiques de répartition
- Alertes dépassement budget
- Vue par membre (qui a payé quoi)

### Communication
- Mur familial (messages, photos, notes)
- Messages épinglés (infos importantes)
- Rappels et annonces

### Gamification famille
- Points pour les tâches complétées
- Récompenses personnalisées ("Pizza ce soir", "1h de jeu vidéo"...)
- Classement familial fun (pas compétitif, encourageant)

---

## Dépendances principales

```
flutter_riverpod: ^2.4       # State management
sqflite: ^2.3                 # SQLite local (tâches, budget, profils)
firebase_core: ^2.24          # Firebase
firebase_auth: ^4.16          # Authentification
cloud_firestore: ^4.14        # Sync famille en temps réel
firebase_messaging: ^14.0     # Notifications push
go_router: ^12.0              # Navigation
google_fonts: ^6.0            # Polices
table_calendar: ^3.0          # Calendrier
fl_chart: ^0.65               # Graphiques budget
shared_preferences: ^2.2      # Stockage léger (settings)
flutter_animate: ^4.3         # Animations fluides
image_picker: ^1.0            # Photos (reçus, profil)
intl: ^0.19                   # Dates et formatage
```

---

## Conventions de code

### Langue
- Code : **anglais**
- Commentaires : **français** (le POURQUOI)
- Commits : **français**
- Docstrings : **anglais**

### Nommage
| Élément | Convention | Exemple |
|---|---|---|
| Fichiers/modules | snake_case | `task_screen.dart` |
| Classes | PascalCase | `TaskService`, `BudgetCalculator` |
| Fonctions/méthodes | camelCase | `assignTask()`, `calculateBudget()` |
| Constantes | camelCase avec k prefix | `kMaxMembers`, `kDefaultCategories` |
| Variables | camelCase | `currentFamily`, `monthlyBudget` |

### Gestion d'erreurs
```
- Exceptions custom : FamilyError, TaskError, BudgetError, NetworkError
- Jamais de bare catch → toujours spécifique
- Logging structuré via logger package (pas de print en prod)
- Erreurs réseau : retry avec backoff + message user-friendly
```

---

## Sécurité

### Niveau 1 — Toujours actif
- Pas de credentials en clair
- Pas de `print()` en production
- Validation des inputs utilisateur
- Firebase Security Rules strictes sur Firestore
- Données famille isolées (un membre ne voit que sa famille)

### Niveau 2 — Avant release
- Vérification des dépendances (`flutter pub outdated`)
- Test sur vrais devices iOS + Android
- Obfuscation du code Dart en release
- ProGuard pour Android
- Chiffrement des données sensibles (budget)

---

## Build Modes

| Mode | Usage | Détails |
|---|---|---|
| **dev** | Développement local | Logs DEBUG, hot reload, Firebase emulator |
| **release** | Production / store | Logs WARNING, optimisé, minifié |
| **test** | Tests automatisés | Mocks Firebase, pas d'appels réels |

### Packaging
| Plateforme | Outil | Commande | Sortie |
|---|---|---|---|
| iOS | Flutter / Xcode | `flutter build ios` | `.ipa` |
| Android | Flutter / Gradle | `flutter build apk` | `.apk` |

---

## Versioning

Format : `MAJOR.MINOR.PATCH` (semver)

---

## État du projet & Roadmap

### Implémenté
- [x] Configuration des fichiers .md du projet

### En cours
- [ ] Setup Flutter + arborescence

### Prévu
- **Phase 1** : Setup projet Flutter, arborescence, dépendances, git
- **Phase 2** : Core — modèles de données, services (tâches, planning, budget)
- **Phase 3** : UI — écrans principaux (accueil, tâches, planning, courses, budget)
- **Phase 4** : Data — SQLite local, sync Firebase entre membres
- **Phase 5** : Gamification — points, récompenses, classement familial
- **Phase 6** : Polish — animations, notifications push, dark mode, sons
- **Phase 7** : Landing page — page web (dark, glassmorphism, animée)
- **Phase 8** : Packaging — comptes stores, assets, CGU, privacy, soumission
- **Phase 9** : Release — TestFlight + Internal Testing → publication stores

---

## Règles absolues

**Sécurité :**
- Jamais de credentials en clair
- Jamais de données sensibles dans les logs
- Toujours valider les inputs
- Données famille isolées (multi-tenant)

**Qualité :**
- TDD sur la logique métier (core/) — budget, répartition, planning
- Tester avant de merger
- Review avant release

**Économie de tokens :**
- `/compact` dès que le contexte dépasse 60%
- Utiliser le bon palier (P0 pour un fix, pas P4)
- Limiter les outputs : `| head -20`
- Commiter souvent → permet de repartir propre

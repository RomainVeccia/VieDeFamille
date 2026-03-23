# DISTRIBUTION.md — Landing page, CGU, Privacy, Packaging

> Tout ce qu'il faut pour distribuer VieDeFamille sur les stores et le web.

---

## Landing Page — Vision

### Concept
Page unique, tons chauds, illustrations familiales, animations au scroll. Le genre de page qui inspire confiance et donne envie d'organiser sa vie de famille.

### Structure
```
1. HERO (full-screen)
   - Background : dégradé chaud (#F5F0EB → #E8D5C4) + illustrations famille
   - Logo VieDeFamille animé
   - Tagline : "Organisez votre vie de famille, simplement."
   - Sous-titre : "Tâches. Courses. Planning. Budget. Tout en un."
   - Mockup iPhone/Android avec app
   - Boutons : "App Store" + "Google Play"
   - Flèche scroll animée

2. FEATURES (cards avec icônes)
   - 📋 "Tâches partagées" — Qui fait quoi, quand
   - 🛒 "Courses en temps réel" — Cochez ensemble, même à distance
   - 📅 "Planning familial" — Tout le monde au courant
   - 💰 "Budget sous contrôle" — Fini les mauvaises surprises
   - 💬 "Mur familial" — Restez connectés
   - 🏆 "Fun & récompenses" — Motivez toute la famille

3. COMMENT ÇA MARCHE (3 étapes)
   - "1. Créez votre famille" → illustration création
   - "2. Invitez les membres" → illustration invitation
   - "3. Organisez-vous ensemble" → illustration dashboard

4. SCREENSHOTS
   - Carousel de 5 screenshots
   - Mockups iPhone avec reflets

5. TÉMOIGNAGES
   - Cards avec avatars
   - Citations courtes

6. DOWNLOAD (section finale)
   - Grand mockup centré
   - Boutons App Store + Google Play
   - "Gratuit. Pas de pubs. Respectueux de votre vie privée."

7. FOOTER
   - Liens : CGU | Privacy | Contact | GitHub
   - © 2026 Romano / VieDeFamille
```

### Stack Landing Page
```
HTML/CSS/JS vanilla (pas de framework = rapide + léger)
Animations : CSS animations + IntersectionObserver (scroll)
Déploiement : Netlify ou GitHub Pages (gratuit)
```

---

## Packaging — Pipeline complète (dev → stores)

### Pré-requis

#### Comptes à créer
| Compte | Coût | Pourquoi | Quand |
|---|---|---|---|
| GitHub (gratuit) | 0€ | Code + landing page | Phase 1 |
| Firebase (Spark plan) | 0€ | Auth + sync + notifications | Phase 4 |
| Apple Developer | 99€/an | Publier sur App Store | Phase 8 |
| Google Play Console | 25€ (one-shot) | Publier sur Play Store | Phase 8 |

#### Outils à installer sur Mac
```bash
# Flutter SDK
brew install --cask flutter
flutter doctor

# Xcode (pour iOS) — depuis le Mac App Store
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# CocoaPods (dépendances iOS)
sudo gem install cocoapods

# Firebase CLI
npm install -g firebase-tools
```

### Assets nécessaires pour les stores

| Asset | Taille | Format | Quantité |
|---|---|---|---|
| Icône app | 1024x1024 | PNG (pas de transparence iOS) | 1 |
| Screenshots iPhone | 1290x2796 (6.7") | PNG | 5-8 |
| Screenshots iPad | 2048x2732 | PNG | 5-8 (optionnel) |
| Screenshots Android | 1080x1920 | PNG | 5-8 |
| Feature graphic (Play) | 1024x500 | PNG | 1 |
| Vidéo preview | 30s max | MP4 | 1 (optionnel) |
| Logo | Vectoriel | SVG | 1 |

---

## CGU — VieDeFamille

```
CONDITIONS GÉNÉRALES D'UTILISATION — VIEDEFAMILLE

Dernière mise à jour : [DATE]

1. OBJET
VieDeFamille est une application mobile gratuite de gestion familiale,
fournie "telle quelle" à des fins d'organisation du quotidien.

2. ACCEPTATION
L'utilisation de VieDeFamille implique l'acceptation des présentes CGU.

3. COMPTE UTILISATEUR
- La création d'un compte est nécessaire pour synchroniser entre membres
- Un pseudo et un avatar sont nécessaires pour identifier les membres
- L'utilisateur est responsable de la confidentialité de son compte

4. DONNÉES FAMILIALES
- Les données (tâches, planning, budget) sont partagées entre les membres
  de la même famille uniquement
- Chaque famille est isolée : aucun accès croisé possible
- L'administrateur de la famille peut inviter/retirer des membres

5. RESPONSABILITÉ
- VieDeFamille est fourni sans garantie d'aucune sorte
- L'éditeur ne saurait être tenu responsable de tout dommage
  lié à l'utilisation de l'application
- Les données financières (budget) sont indicatives et ne constituent
  pas un conseil financier

6. PROPRIÉTÉ INTELLECTUELLE
- VieDeFamille est la propriété de Romano (Romain Veccia)
- Toute reproduction est interdite sans autorisation

7. MODIFICATIONS
Ces CGU peuvent être modifiées à tout moment. La version en vigueur
est celle disponible dans l'application et sur le site web.

Contact : [EMAIL]
```

---

## Privacy Policy — VieDeFamille

```
POLITIQUE DE CONFIDENTIALITÉ — VIEDEFAMILLE

Dernière mise à jour : [DATE]

1. COLLECTE DE DONNÉES
VieDeFamille collecte uniquement les données nécessaires au fonctionnement :
- Pseudo et avatar (choisis par l'utilisateur)
- Tâches, événements, listes de courses (créés par les membres)
- Dépenses et budgets (saisis par les membres)
- Identifiant anonyme (pour la synchronisation)

VieDeFamille ne collecte PAS :
- Nom réel, email, numéro de téléphone (sauf pour l'auth optionnelle)
- Données de localisation
- Contacts, photos personnelles, ou fichiers
- Données bancaires ou financières réelles

2. STOCKAGE
- Les données sont stockées localement sur votre appareil (SQLite)
- Les données partagées sont stockées sur Firebase (serveurs Google)
- Les données sont chiffrées en transit (HTTPS)
- Les données de budget sont traitées localement

3. PARTAGE
- Aucune donnée n'est vendue à des tiers
- Aucune publicité dans l'application
- Les données sont partagées UNIQUEMENT entre les membres
  d'une même famille (invités par code)

4. SERVICES TIERS
- Firebase Authentication (Google) : gestion des comptes
- Firebase Firestore (Google) : synchronisation famille
- Firebase Cloud Messaging (Google) : notifications push
- Firebase Analytics (Google) : statistiques d'usage anonymes
Voir : https://firebase.google.com/support/privacy

5. DROITS
Vous pouvez à tout moment :
- Supprimer votre compte et vos données dans les paramètres
- Quitter une famille (vos données personnelles sont supprimées)
- Supprimer toutes vos données en désinstallant l'application
- Nous contacter pour toute question : [EMAIL]

6. ENFANTS
VieDeFamille est adapté à un usage familial incluant des enfants.
Les comptes enfants sont gérés par les parents/administrateurs.
Nous ne collectons pas sciemment de données personnelles d'enfants
sans le consentement des parents.

7. MODIFICATIONS
Cette politique peut être mise à jour. La version en vigueur
est celle disponible dans l'application et sur le site web.

Contact : [EMAIL]
```

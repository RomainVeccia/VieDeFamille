---
description: Regles UI par defaut — tout doit etre lisible, aligne, responsive, sans debug visuel
---

# UI Defaults — Non negociable

## Iron Law UI
**TOUT doit etre lisible et aligne PAR DEFAUT. Pas apres debug.**
Claude ne voit pas l'ecran — il doit ANTICIPER les problemes visuels, pas attendre qu'on les signale.

## Regles absolues (toutes stacks)
- **Font minimum 13px** — 11px uniquement pour les labels secondaires
- **Touch targets 44px minimum** — boutons, liens, inputs
- **Rien ne depasse** — overflow:hidden ou scroll, jamais de contenu tronque sans indicateur
- **Rien ne se superpose** — z-index explicite, pas de position:absolute sans conteneur
- **Cards alignees** — grille CSS/Flex, pas de float, hauteur egale par rangee
- **Responsive par defaut** — tester mental : mobile (375px), tablet (768px), desktop (1280px), TV (1920px)
- **Dark mode** — contrast ratio >= 4.5:1 sur tout texte
- **Pas de scroll horizontal** — jamais, sauf tableau de donnees avec indicateur
- **Padding coherent** — memes espacements partout (8/16/24/32px system)
- **Texte jamais tronque sans tooltip** — si ellipsis, ajouter title/tooltip

## Par stack

### Web (Next.js, HTML/CSS)
- Flexbox/Grid > float/position:absolute
- rem > px pour les font sizes
- max-width sur les conteneurs (pas de lignes de 200 chars)
- Images : width/height explicites (evite CLS), lazy loading, WebP
- **iframes** : toujours lazy-loaded, jamais above the fold
- **prefers-reduced-motion** : respecter sur TOUTES les animations CSS/JS
- **Focus visible** : indicateur visible (ring colore) sur TOUS les elements interactifs
- **Contrast piege** : verifier accent-on-background, pas seulement text-on-background

### Flutter
- Expanded/Flexible dans les Row/Column — pas de taille fixe
- MediaQuery pour adapter (mobile/tablet/TV)
- Safe zones TV : screenWidth * 0.05
- blurRadius max 4 sur FireStick (GPU faible)

### Python (si applicable)
- Layouts responsifs par defaut
- Font 13px minimum

## Ports locaux — OBLIGATOIRE
- **AVANT de lancer un dev server** → lire `shared/port-registry.md`
- **JAMAIS** utiliser le port par defaut (3000) sans verifier
- Chaque projet a son port fixe attribue
- Si nouveau projet → prendre le prochain port libre et l'ajouter au registre

## Loading states
- **Shimmer/skeleton** pour le contenu (listes, cards, pages) — jamais de spinner
- **Spinner** uniquement pour les actions (bouton submit, upload)
- Toujours prevoir l'etat vide (placeholder, empty state, "aucun resultat")

## Images (toutes stacks)
- Toujours demander des variantes redimensionnees (pas l'original)
- Lazy loading sur toutes les images hors viewport
- width/height explicites (evite CLS)
- SVG pour les icones, WebP pour les photos
- Max 100Ko par asset embarque

## Inputs
- **Debounce 300ms** sur tous les champs de recherche (toutes stacks)
- Pas d'appel API a chaque keypress — attendre que l'utilisateur finisse de taper

## Quand Claude genere du UI
1. Ecrire le layout RESPONSIVE d'abord (pas le contenu)
2. Verifier mentalement : "est-ce que ca marche sur mobile ET desktop ?"
3. Ajouter les paddings/margins AVANT le contenu
4. Tester : "si le texte fait 3x la taille prevue, est-ce que ca casse ?"
5. Si un element peut etre vide → prevoir l'etat vide (placeholder, empty state)

Onboarding d'un projet CLIENT avec existant. Utiliser quand un client arrive avec un site, une app, des specs, etc.

## BLOC 1 — Le client

Envoie ce message :

---
**Onboarding Client — Etape 1/3 : Le client**

1. **Nom du client** ? (personne ou entreprise)
2. **Le projet en 1 phrase** ?
3. **Budget / mode de facturation** ? (forfait, TJM, abonnement, echange de service)
4. **Deadline** ? (date ou "pas de rush")
5. **Ton prefere** ? (formel client / decontracte pote)

---

## BLOC 2 — L'existant

---
**Etape 2/3 : Ce qui existe deja**

6. **Site web existant** ? → URL
7. **App existante** ? → APK / EXE / TestFlight / lien store
8. **Code source** ? → repo git, zip, FTP
9. **Documents** ? → cahier des charges, maquettes, PDF specs
10. **Base de donnees** ? → schema SQL, export CSV, acces admin
11. **Visuels** ? → logo, charte graphique, palette couleurs, fonts
12. **Contenus** ? → textes, traductions, catalogue, photos
13. **Comptes/acces** ? → hebergement, domaine, Google Analytics, CMS admin

Deposer tout dans `[projet]/inputs/` et me dire ce qu'il y a.

---

## BLOC 3 — Le besoin

---
**Etape 3/3 : Ce qu'on fait**

14. **Type de mission** ?
    - Reecriture complete (l'existant est obsolete)
    - Evolution (ajouter des features)
    - Fix/maintenance (corriger des bugs)
    - Nouveau projet (rien n'existe)
15. **Fonctionnalites principales** ? (liste les 3-5 plus importantes)
16. **Plateforme cible** ? (web / mobile / desktop / API)
17. **Stack imposee** ? (ou libre de choisir)
18. **Hebergement** ? (existant chez le client / a provisionner)

---

## GENERATION

Creer le projet avec /onboarding normal PLUS :
- Analyser l'existant fourni (site, code, DB) et documenter dans state.md
- Lister les problemes detectes (code legacy, failles secu, dette technique)
- Proposer un plan de migration/evolution avec estimations (temps humain + temps Claude)
- Creer `projects/[client]/inputs.md` avec inventaire de tout ce qui a ete fourni

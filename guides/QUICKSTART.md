# QUICKSTART.md — Démarrage en 5 minutes

## Étape 1 — Préparer le dossier
```bash
cd VieDeFamille
# Les fichiers .md sont déjà en place
```

## Étape 2 — Git
```bash
git init
git add .
git commit -m "Init projet — starter pack VieDeFamille"
# Optionnel : repo privé GitHub
gh repo create VieDeFamille --private --source=. --push
```

## Étape 3 — Lancer Claude Code
```bash
claude
```

## Étape 4 — Premier message
```
Lis ONBOARDING.md et lance la Phase 1.
```

Claude Code va lire la config pré-remplie et proposer la Phase 1 (setup Flutter).

## Étape 5 — Coder !
```
GO — lance la Phase 1.
```

## Commandes utiles
| Commande | Action |
|---|---|
| "Orient" | Résumé de l'état du projet |
| "PERSIST" | Sauvegarder l'état avant de quitter |
| "Audit" | Score /100 du projet |
| "/compact" | Libérer du contexte (à 60%) |
| "Active le [Agent]" | Invoquer un agent spécifique |

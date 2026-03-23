# lessons.md — Leçons apprises (universelles)

## Screenshots auto = INTERDIT
Ça sature le contexte. Décrire en texte. Jamais PowerShell/scrot.

## Outputs = TOUJOURS tronquer
`| head -20` ou `| tail -10`. Jamais de dump complet.

## /compact à 60%, pas 80%
Si 80% → souvent trop tard. PERSIST + nouvelle session si besoin.

## Tout persister en BDD
Zéro donnée importante en mémoire seule. SQLite minimum.

## Venv TOUJOURS
`python -m venv .venv` au jour 1. Jamais de packages globaux.

## Credentials = keyring
Jamais en dur, jamais dans un email, jamais dans git.

## TDD sur core/
Test qui fail → code minimum → refactor. Pas l'inverse.

## PERSIST à chaque fin de session
todo + session_log + lessons + PROJECT-STATUS. Sans exception.

## Tester avant d'ajouter des features
Chaque phase doit TOURNER avant de passer à la suivante.

## Offline-first (spécifique VieDeFamille)
L'app doit marcher sans réseau. Sync Firebase quand le réseau revient.

## Données famille = sensibles
Budget, tâches, planning = données privées. Isoler par famille, chiffrer si possible.

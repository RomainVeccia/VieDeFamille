---
description: Voir les decisions keep/revert et les regles extraites
---

Lire les decisions dans les fichiers lessons.md de chaque projet :

```bash
python tools/brain.py search "KEEP\|REVERT\|A VALIDER"
```

Puis lire `intelligence/decisions_log.json` si present.

Resume les patterns et propose des ajustements si le taux de revert est trop haut.

Pour chaque decision KEEP de plus de 30 jours, poser le **test from scratch** :
"Si on repartait de zero aujourd'hui, on choisirait encore ca ? Si non → candidat REVERT (sunk cost)."

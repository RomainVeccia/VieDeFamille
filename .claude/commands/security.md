---
description: Lancer un audit securite sur tous les projets
---

Lance les 5 greps de securite (voir .claude/rules/security.md) sur tous les projets :

```bash
# 1. Credentials
grep -rn "sk-\|ghp_\|AKIA\|password\s*=" --include="*.py" --include="*.ts" --include="*.dart" ../

# 2. Operations dangereuses
grep -rn "withdraw\|transfer\|delete_all\|DROP TABLE" --include="*.py" --include="*.ts" ../

# 3. Debug oublie
grep -rn "print(\|console\.log\|debugPrint" --include="*.py" --include="*.ts" --include="*.dart" ../

# 4. SSL desactive
grep -rn "verify=False\|verify = False\|rejectUnauthorized.*false" --include="*.py" --include="*.ts" ../

# 5. Analyse statique
python tools/brain.py score
```

Analyse les resultats et classe par severite (CRITICAL > HIGH > MEDIUM > LOW).
Si un grep retourne un resultat → BLOCKER (sauf si justifie explicitement).

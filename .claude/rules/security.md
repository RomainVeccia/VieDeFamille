---
description: Regles de securite pour le brain et tous les projets
---

# Securite

- JAMAIS de credentials en clair (API keys, tokens, passwords)
- Toujours keyring ou --dart-define ou env vars
- .env dans .gitignore de CHAQUE projet
- Verifier avec `python tools/brain.py score` avant chaque push
- Lancer `/security` (5 greps) regulierement

## Securite agentique (source: CVEs Claude Code fev 2026 + recherches)

### Lethal trifecta — signal d'alarme immediat
Si les 3 conditions sont reunies dans le meme runtime → DANGER :
1. Donnees privees accessibles
2. Contenu externe non verifie ingere (PDF, email, PR, MCP output)
3. Communication externe possible (curl, webhook, API)

### Permissions settings.json — baseline deny
```json
"deny": [
  "Read(~/.ssh/**)", "Read(~/.aws/**)", "Read(**/.env*)",
  "Write(~/.ssh/**)", "Write(~/.aws/**)",
  "Bash(curl * | bash)", "Bash(ssh *)", "Bash(nc *)", "Bash(scp *)"
]
```

### Skills = supply chain artifacts
- Ne jamais installer un skill d'une source inconnue sans le lire
- Scanner les skills pour : `curl|wget|nc|scp|ssh|ANTHROPIC_BASE_URL`
- Scanner pour caracteres Unicode caches : zero-width, bidi override
- 36% des skills publics contiennent du prompt injection (etude Snyk mars 2026)

### Memoire agentique
- JAMAIS de secrets dans les fichiers memoire (.md, .tmp)
- Separer memoire projet et memoire globale
- Reinitialiser la memoire apres un run sur contenu non fiable (PDF, repo inconnu)

### Scan automatise avant release — 5 commandes obligatoires
Adapter les commandes par stack, mais le principe est universel :
```bash
# 1. Analyse statique (ruff/mypy/flutter analyze/tsc)
ruff check . --select S  # Python (bandit rules)
# 2. Grep credentials
grep -rn "sk-\|ghp_\|AKIA\|password\s*=" --include="*.py" --include="*.ts" --include="*.dart" .
# 3. Grep operations dangereuses
grep -rn "withdraw\|transfer\|delete_all\|DROP TABLE" --include="*.py" --include="*.ts" .
# 4. Grep debug oublie
grep -rn "print(\|console\.log\|debugPrint" --include="*.py" --include="*.ts" --include="*.dart" .
# 5. Grep SSL desactive
grep -rn "verify=False\|verify = False\|rejectUnauthorized.*false" --include="*.py" --include="*.ts" .
```
Si un seul grep retourne un resultat → BLOCKER (sauf si justifie explicitement).

### TTL cache obligatoire sur les API externes
- Chaque appel API externe DOIT avoir un cache TTL
- Re-fetch sans verifier TTL = anti-pattern
- TTL par volatilite : realtime 5s, frequent 30s, hourly 1h, daily 6-12h, static 7d
- JAMAIS d'appel API en boucle sans cache
- Retry avec backoff exponentiel (2^i sec, max 3 retries) sur 429/timeout

### Logging securise
- JAMAIS utiliser le logger HTTP par defaut (il log les headers/body avec credentials)
- Logger custom : method + path seulement, JAMAIS body/headers/query params avec auth
- Erreurs UI = generiques ("Erreur de connexion"). Details techniques → logs seulement
- JAMAIS de stack trace visible a l'utilisateur

### Data purge au logout
- Deconnexion utilisateur = purger TOUTES les donnees locales du profil
- Cache, credentials, images, preferences — tout
- Pas juste le token — TOUT

### Supabase — RLS obligatoire
- Row-Level Security active sur TOUTES les tables, sans exception
- Si une table n'a pas de RLS → blocker avant deploy
- Concerne : JoanneDoulaMamaterre, tout futur projet Supabase

### RGPD / Analytics
- GA4 / analytics JAMAIS charge avant consentement cookies explicite
- Cookie banner obligatoire sur tout site web EU
- Walk-forward validation obligatoire sur tout modele ML (pas de data leakage)

### Soft delete par defaut
- Suppression de donnees = soft delete (status = archived), JAMAIS hard delete
- Sauf donnees temporaires / cache explicitement jetables

### Identite agent
- Creer une identite separee pour l'agent (pas son compte perso GitHub/Gmail/Slack)
- Tokens a courte duree de vie, scopes minimaux
- Si agent compromis = l'agent, pas toi

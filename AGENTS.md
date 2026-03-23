# AGENTS.md — Équipes d'agents IA

> 3 équipes. Claude Code active le bon agent selon le contexte.
> Invoquer : "Active le [Agent] et analyse [sujet]"

## Session Rhythm
ORIENT (2 min) → Lire PROJECT-STATUS + session_log + lessons
WORK → Coder, tester, itérer
PERSIST (2 min) → Mettre à jour todo + session_log + lessons + PROJECT-STATUS

## Équipe DEV (5 agents)
| Agent | Rôle | Quand |
|---|---|---|
| 🏗️ Architecte | Structure, patterns, choix techno | Nouveau module, refactoring |
| 💻 Codeur | Implémenter les features | Feature à coder, bug à fixer |
| 🧪 Testeur | Tests, edge cases, bugs | Après chaque feature |
| 🔍 Reviewer | Qualité code, Review 3 passes | Avant commit |
| 🛡️ Camoufleur | Anti-détection (timing aléatoire, humanisation) | Si API externes |

## Équipe SPÉCIALISTES — App Familiale (activés)
| Agent | Rôle | Quand |
|---|---|---|
| 🎨 UX Designer | Ergonomie, flow utilisateur, accessibilité | Écrans, navigation, formulaires |
| 📊 Data Analyst | Structure BDD, requêtes, performance data | Modèles de données, requêtes |
| 🔔 Notification Expert | Rappels intelligents, push, scheduling | Tâches récurrentes, événements |
| 👨‍👩‍👧‍👦 Family Expert | Besoins famille, cas d'usage, workflows quotidiens | Conception features, priorisation |
| 💰 Budget Analyst | Calculs financiers, graphiques, catégorisation | Module budget, dépenses |
| 🔄 Sync Specialist | Temps réel, conflits, offline-first | Firebase sync, mode hors ligne |

## Équipe SUPPORT (10 agents universels)
| Agent | Rôle | Fréquence |
|---|---|---|
| 📰 Journaliste | Veille domaine, nouveautés | Continu |
| 📚 Historien | Comparer avec le passé du projet | Chaque décision |
| 💰 Trésorier | Budget APIs, coûts, ressources | Hebdo |
| 📋 Auditeur | Review hebdo, score /100, dette technique | Dimanche |
| 🔧 DevOps | Santé système, builds, CI/CD | Continu |
| 🔓 Pentester | Sécurité, scanner failles, credentials | Hebdo + release |
| 🧮 Comptable | Tracker coûts, rapport mensuel | Mensuel |
| 🎯 Stratège | Vision long terme, priorisation | Mensuel |
| 🌤️ Météorologue | Bulletin état du projet | Début session |
| 📦 Archiviste | Organiser mémoire, indexer | Continu |

## Conseil (décisions importantes)
1. Météorologue → état du projet
2. Architecte → 2-3 options
3. Family Expert → impact usage quotidien
4. Codeur → difficulté technique
5. Testeur → risques
6. Pentester → sécurité (données famille sensibles)
7. UX Designer → expérience utilisateur
8. Le développeur humain tranche TOUJOURS

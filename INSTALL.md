# INSTALL.md — Guide d'installation des pré-requis

> À suivre AVANT de lancer Claude Code pour la première fois.
> Choisis ton système : Windows ou macOS.

---

## 🪟 Windows

### 1. Python
```bash
# Télécharger Python 3.12+ depuis python.org
# IMPORTANT : cocher "Add Python to PATH" pendant l'installation
# Vérifier :
python --version
```

### 2. Git
```bash
# Télécharger depuis git-scm.com
# Installer avec les options par défaut
# Vérifier :
git --version
```

### 3. Node.js (pour Claude Code)
```bash
# Télécharger Node.js 18+ depuis nodejs.org (version LTS)
# Installer avec les options par défaut
# Vérifier :
node --version
npm --version
```

### 4. Claude Code
```bash
npm install -g @anthropic-ai/claude-code
# Vérifier :
claude --version
```

### 5. Éditeur de texte (optionnel mais recommandé)
- VS Code : code.visualstudio.com (gratuit)

### 6. Packaging (selon le projet)
- EXE Windows : `pip install pyinstaller` (Python)
- Installeur : NSIS ou Inno Setup (gratuit)

---

## 🍎 macOS

### 1. Homebrew (gestionnaire de paquets — installe tout le reste)
```bash
# Ouvre le Terminal (Applications → Utilitaires → Terminal)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Vérifier :
brew --version
```

### 2. Python
```bash
brew install python@3.12
# Vérifier :
python3 --version
# Note macOS : utiliser python3 et pip3 (pas python/pip)
```

### 3. Git
```bash
# Git est souvent pré-installé sur macOS. Vérifier :
git --version
# Si pas installé :
brew install git
```

### 4. Node.js (pour Claude Code)
```bash
brew install node@18
# Vérifier :
node --version
npm --version
```

### 5. Claude Code
```bash
npm install -g @anthropic-ai/claude-code
# Vérifier :
claude --version
```

### 6. Éditeur de texte (optionnel)
- VS Code : code.visualstudio.com (gratuit, marche sur macOS)

### 7. Packaging (selon le projet)
- Si Flutter : `flutter build ios` / `flutter build apk`

---

## 🔑 Compte Anthropic (obligatoire)

1. Va sur claude.ai
2. Crée un compte (ou connecte-toi)
3. Plan minimum recommandé : **Pro** (20$/mois) pour Claude Code
4. Plan idéal pour du dev intensif : **Max** (100$/mois)

---

## ✅ Checklist "je suis prêt"

```
- [ ] Python 3.12+ installé (python --version OU python3 --version)
- [ ] Git installé (git --version)
- [ ] Node.js 18+ installé (node --version)
- [ ] Claude Code installé (claude --version)
- [ ] Compte Anthropic avec plan Pro ou Max
- [ ] Un dossier vide pour le projet
```

Quand tout est coché → lis QUICKSTART.md et c'est parti !

---

## 🆘 Problèmes courants

### "python n'est pas reconnu" (Windows)
→ Python n'est pas dans le PATH. Réinstaller en cochant "Add to PATH".

### "python3 command not found" (macOS)
→ `brew install python@3.12` puis `echo 'alias python=python3' >> ~/.zshrc`

### "npm: command not found"
→ Node.js n'est pas installé. Installer depuis nodejs.org ou `brew install node`.

### "claude: command not found"
→ `npm install -g @anthropic-ai/claude-code`

### Erreur de permissions npm (macOS)
→ `sudo npm install -g @anthropic-ai/claude-code`

### Claude Code erreur 529 / 500
→ Les serveurs Anthropic sont surchargés. Attendre 10-15 min et réessayer.

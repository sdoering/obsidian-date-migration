# Deployment Guide

Diese Anleitung beschreibt, wie du das Obsidian Date Migration Tool in deiner Entwicklungsumgebung aufsetzen und auf GitHub veröffentlichen kannst.

## 🚀 Schritt-für-Schritt Anleitung

### 1. Projekt nach Development verschieben
```bash
# Kopiere das Projekt in dein Development-Verzeichnis
cp -r /tmp/obsidian-date-migration ~/Development/projects/

# Wechsle ins Projekt
cd ~/Development/projects/obsidian-date-migration
```

### 2. Projekt-Setup
```bash
# Mache Scripts ausführbar
chmod +x scripts/*.sh

# Führe Sanitization durch (entfernt private Daten)
make sanitize

# Teste das Projekt
make dev-test
```

### 3. Git-Repository initialisieren
```bash
# Git-Repository initialisieren
git init

# Alle Dateien hinzufügen
git add -A

# Initial commit
git commit -m "Initial commit: Obsidian Date Migration Tool

- Intelligente Datum-Feld-Migration für Obsidian Vaults
- Makefile-driven mit Testing und Rollback
- Dateisystem-Metadaten als Fallback-Strategie
- Behandlung von Edge Cases (Backup-Wiederherstellung)
- Vollständige Test-Suite und Dokumentation

🚀 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 4. GitHub Repository erstellen
```bash
# Repository auf GitHub erstellen (öffentlich)
gh repo create obsidian-date-migration --public --source=.

# Main-Branch als Standard setzen
git branch -M main

# Push zu GitHub
git push -u origin main
```

### 5. Repository-Konfiguration
```bash
# Repository-Beschreibung setzen
gh repo edit --description "🗓️ Intelligente Datum-Feld-Migration für Obsidian Vaults - Makefile-driven mit Testing und Rollback"

# Topics hinzufügen
gh repo edit --add-topic obsidian,automation,bash,data-migration,second-brain,yaml,markdown
```

### 6. README-Verbesserungen
```bash
# Badge hinzufügen (nach GitHub-Push)
# Füge folgende Badges am Anfang der README.md hinzu:

echo '![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Bash](https://img.shields.io/badge/bash-v4%2B-green.svg)
![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macOS-lightgrey.svg)

' | cat - README.md > temp && mv temp README.md

# Commit und Push
git add README.md
git commit -m "Add badges to README"
git push
```

## 📋 Checkliste vor Veröffentlichung

### ✅ Sicherheit
- [ ] Keine privaten Pfade in den Dateien
- [ ] Keine persönlichen Daten in Logs
- [ ] Sanitization durchgeführt
- [ ] Test-Suite läuft durch

### ✅ Funktionalität
- [ ] Alle Scripts sind ausführbar
- [ ] Makefile-Targets funktionieren
- [ ] Beispiel-Dateien sind vorhanden
- [ ] Dokumentation ist vollständig

### ✅ GitHub
- [ ] Repository ist öffentlich
- [ ] Beschreibung ist gesetzt
- [ ] Topics sind hinzugefügt
- [ ] LICENSE ist vorhanden
- [ ] .gitignore ist konfiguriert

## 🔧 Lokale Nutzung

### Vorbereitung
```bash
# Vault-Pfad konfigurieren
export VAULT_PATH="/path/to/your/obsidian-vault"

# Oder in Makefile anpassen
sed -i 's|VAULT_PATH ?= .*|VAULT_PATH ?= /dein/vault/pfad|' Makefile
```

### Workflow
```bash
# 1. Analyse
make analyze

# 2. Test (Dry-Run)
make test

# 3. Backup
make backup

# 4. Migration
make migrate

# 5. Bei Problemen: Rollback
make rollback
```

## 🌟 Nächste Schritte

### Features für v2.0
- [ ] GUI-Interface mit Electron
- [ ] Konfigurierbare Ziel-Formate
- [ ] Batch-Verarbeitung mehrerer Vaults
- [ ] Plugin-System für andere YAML-Felder
- [ ] Cloud-Integration (Obsidian Sync)

### Community
- [ ] Issues-Template erstellen
- [ ] Contributing-Guidelines
- [ ] Changelog pflegen
- [ ] Releases mit Semantic Versioning

## 📞 Support

Falls du Probleme hast:
1. Prüfe die [Issues](https://github.com/username/obsidian-date-migration/issues)
2. Erstelle ein neues Issue mit:
   - Obsidian-Version
   - Betriebssystem
   - Fehlermeldung
   - Beispiel-Dateien (anonymisiert)

## 📝 Lizenz

MIT License - Siehe [LICENSE](LICENSE) für Details.

---

**Happy Migrating!** 🚀
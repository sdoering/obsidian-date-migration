# Obsidian Date Migration Tool
# Makefile für sichere Datum-Feld-Vereinheitlichung

.PHONY: help setup analyze test migrate rollback clean sanitize github-prep

# Konfiguration
VAULT_PATH ?= $(HOME)/path/to/your/obsidian-vault
BACKUP_DIR = $(VAULT_PATH)/.migration-backup
LOG_FILE = docs/MIGRATION_LOG.md
TIMESTAMP = $(shell date +%Y%m%d_%H%M%S)

# Farben für Output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Zeige verfügbare Commands
	@echo "$(GREEN)Obsidian Date Migration Tool$(NC)"
	@echo "=================================="
	@echo ""
	@echo "Verfügbare Commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)WICHTIG:$(NC) Führe immer 'make analyze' und 'make test' vor 'make migrate' aus!"

setup: ## Initialisiere Projekt und prüfe Voraussetzungen
	@echo "$(GREEN)📋 Setup wird gestartet...$(NC)"
	@chmod +x scripts/*.sh
	@mkdir -p $(BACKUP_DIR)
	@mkdir -p docs
	@echo "$(GREEN)✅ Setup abgeschlossen$(NC)"
	@echo ""
	@echo "$(YELLOW)📁 Vault-Pfad:$(NC) $(VAULT_PATH)"
	@echo "$(YELLOW)💾 Backup-Ordner:$(NC) $(BACKUP_DIR)"

analyze: setup ## Analysiere aktuellen Zustand des Vaults
	@echo "$(GREEN)🔍 Starte Analyse...$(NC)"
	@./scripts/analyze.sh $(VAULT_PATH) | tee -a $(LOG_FILE)
	@echo ""
	@echo "$(GREEN)✅ Analyse abgeschlossen$(NC)"
	@echo "$(YELLOW)📊 Details siehe:$(NC) $(LOG_FILE)"

test: setup ## Führe Dry-Run Test durch (keine Änderungen)
	@echo "$(GREEN)🧪 Starte Test-Lauf...$(NC)"
	@echo "$(YELLOW)⚠️  Dry-Run Modus - Keine echten Änderungen$(NC)"
	@./scripts/test.sh $(VAULT_PATH) | tee -a $(LOG_FILE)
	@echo ""
	@echo "$(GREEN)✅ Test abgeschlossen$(NC)"

migrate: setup backup ## Führe echte Migration durch
	@echo "$(GREEN)🚀 Starte Migration...$(NC)"
	@echo "$(YELLOW)⚠️  ECHTE ÄNDERUNGEN - Backup wurde erstellt$(NC)"
	@read -p "Fortfahren? (y/N) " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		./scripts/migrate.sh $(VAULT_PATH) | tee -a $(LOG_FILE); \
		echo "$(GREEN)✅ Migration abgeschlossen$(NC)"; \
	else \
		echo ""; \
		echo "$(YELLOW)❌ Migration abgebrochen$(NC)"; \
	fi

backup: ## Erstelle Backup vor Migration
	@echo "$(GREEN)💾 Erstelle Backup...$(NC)"
	@if [ -d "$(VAULT_PATH)/.git" ]; then \
		cd $(VAULT_PATH) && git add -A && git commit -m "Backup vor Datum-Migration $(TIMESTAMP)" || true; \
		echo "$(GREEN)✅ Git-Backup erstellt$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Kein Git-Repo gefunden, erstelle Datei-Backup...$(NC)"; \
		rsync -av --exclude='.*' $(VAULT_PATH)/ $(BACKUP_DIR)/$(TIMESTAMP)/; \
		echo "$(GREEN)✅ Datei-Backup erstellt: $(BACKUP_DIR)/$(TIMESTAMP)/$(NC)"; \
	fi

rollback: ## Rollback zur letzten Version
	@echo "$(RED)🔄 Starte Rollback...$(NC)"
	@echo "$(YELLOW)⚠️  Dies wird alle Änderungen rückgängig machen$(NC)"
	@read -p "Fortfahren? (y/N) " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		if [ -d "$(VAULT_PATH)/.git" ]; then \
			cd $(VAULT_PATH) && git reset --hard HEAD~1; \
			echo "$(GREEN)✅ Git-Rollback durchgeführt$(NC)"; \
		else \
			LATEST_BACKUP=$$(ls -t $(BACKUP_DIR) | head -1); \
			if [ -n "$$LATEST_BACKUP" ]; then \
				rsync -av --delete $(BACKUP_DIR)/$$LATEST_BACKUP/ $(VAULT_PATH)/; \
				echo "$(GREEN)✅ Datei-Rollback durchgeführt: $$LATEST_BACKUP$(NC)"; \
			else \
				echo "$(RED)❌ Kein Backup gefunden$(NC)"; \
			fi; \
		fi; \
	else \
		echo ""; \
		echo "$(YELLOW)❌ Rollback abgebrochen$(NC)"; \
	fi

sanitize: ## Sanitize Projekt für GitHub (entferne private Daten)
	@echo "$(GREEN)🧹 Sanitize für GitHub...$(NC)"
	@./scripts/sanitize.sh
	@echo "$(GREEN)✅ Sanitization abgeschlossen$(NC)"

github-prep: sanitize ## Bereite Projekt für GitHub vor
	@echo "$(GREEN)🐙 Bereite GitHub-Repo vor...$(NC)"
	@echo "$(YELLOW)📋 Nächste Schritte:$(NC)"
	@echo "1. cp -r /tmp/obsidian-date-migration ~/Development/projects/"
	@echo "2. cd ~/Development/projects/obsidian-date-migration"
	@echo "3. git init"
	@echo "4. git add -A"
	@echo "5. git commit -m 'Initial commit: Obsidian Date Migration Tool'"
	@echo "6. gh repo create obsidian-date-migration --public --source=."
	@echo "7. git push -u origin main"

clean: ## Reinige temporäre Dateien
	@echo "$(GREEN)🧹 Reinige temporäre Dateien...$(NC)"
	@rm -f scripts/*.log
	@rm -f tests/*.log
	@rm -rf tests/test_data/temp_*
	@echo "$(GREEN)✅ Bereinigung abgeschlossen$(NC)"

# Entwickler-Commands
dev-test: ## Führe Entwickler-Tests durch
	@echo "$(GREEN)🔧 Starte Entwickler-Tests...$(NC)"
	@./tests/test_suite.sh
	@echo "$(GREEN)✅ Entwickler-Tests abgeschlossen$(NC)"

stats: ## Zeige Vault-Statistiken
	@echo "$(GREEN)📊 Vault-Statistiken:$(NC)"
	@echo "Gesamt .md Dateien: $$(find $(VAULT_PATH) -name '*.md' | wc -l)"
	@echo "Mit YAML Front Matter: $$(find $(VAULT_PATH) -name '*.md' -exec grep -l '^---' {} \; | wc -l)"
	@echo "Mit created_at: $$(find $(VAULT_PATH) -name '*.md' -exec grep -l 'created_at:' {} \; | wc -l)"
	@echo "Mit updated_at: $$(find $(VAULT_PATH) -name '*.md' -exec grep -l 'updated_at:' {} \; | wc -l)"
	@echo "Mit creation date: $$(find $(VAULT_PATH) -name '*.md' -exec grep -l 'creation date:' {} \; | wc -l)"
	@echo "Mit modification date: $$(find $(VAULT_PATH) -name '*.md' -exec grep -l 'modification date:' {} \; | wc -l)"

# Default target
.DEFAULT_GOAL := help
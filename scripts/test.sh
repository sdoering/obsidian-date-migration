#!/bin/bash

# Obsidian Date Migration - Test Script
# Führt Dry-Run Test durch ohne echte Änderungen

set -euo pipefail

VAULT_PATH="${1:-$(HOME)/path/to/your/obsidian-vault}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 OBSIDIAN DATE MIGRATION - TEST${NC}"
echo "===================================="
echo ""
echo -e "${YELLOW}⚠️  DRY-RUN MODUS - Keine echten Änderungen${NC}"
echo ""

# Rufe Migrations-Script im Dry-Run Modus auf
"$SCRIPT_DIR/migrate.sh" "$VAULT_PATH" "true"

echo ""
echo -e "${GREEN}✅ Test abgeschlossen${NC}"
echo ""
echo -e "${YELLOW}💡 Nächste Schritte:${NC}"
echo "1. Prüfe die Logs in docs/MIGRATION_LOG.md"
echo "2. Wenn alles OK: make migrate"
echo "3. Bei Problemen: make rollback"
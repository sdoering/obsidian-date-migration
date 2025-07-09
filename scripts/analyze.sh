#!/bin/bash

# Obsidian Date Migration - Analyse Tool
# Analysiert den aktuellen Zustand der Datum-Felder im Vault

set -euo pipefail

VAULT_PATH="${1:-$HOME/path/to/your/obsidian-vault}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging-Funktion
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$SCRIPT_DIR/../docs/MIGRATION_LOG.md"
}

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 OBSIDIAN DATE MIGRATION - ANALYSE${NC}"
echo "========================================"
echo ""

log "## Analyse gestartet: $TIMESTAMP"
log "**Vault-Pfad:** $VAULT_PATH"
log ""

# Prüfe ob Vault existiert
if [ ! -d "$VAULT_PATH" ]; then
    echo -e "${RED}❌ Vault-Pfad existiert nicht: $VAULT_PATH${NC}"
    exit 1
fi

cd "$VAULT_PATH"

# Grundlegende Statistiken
echo -e "${BLUE}📊 Grundlegende Statistiken:${NC}"
TOTAL_MD=$(find . -name "*.md" | wc -l)
YAML_FILES=$(find . -name "*.md" -exec grep -l "^---" {} \; | wc -l)
echo "Gesamt .md Dateien: $TOTAL_MD"
echo "Mit YAML Front Matter: $YAML_FILES"
echo ""

log "### Grundlegende Statistiken"
log "- Gesamt .md Dateien: $TOTAL_MD"
log "- Mit YAML Front Matter: $YAML_FILES"
log ""

# Analysiere Datum-Felder
echo -e "${BLUE}📅 Datum-Feld-Analyse:${NC}"

# Temporary files für Analyse
TEMP_DIR="/tmp/obsidian_analysis_$$"
mkdir -p "$TEMP_DIR"

# Sammle alle YAML Front Matter Inhalte
find . -name "*.md" -print0 | xargs -0 -I {} sh -c '
    file="{}"
    if head -1 "$file" | grep -q "^---$"; then
        echo "=== FILE: $file ==="
        awk "/^---$/{f=1;next} /^---$/{f=0} f" "$file"
        echo ""
    fi
' > "$TEMP_DIR/yaml_content.txt"

# Analysiere jeden Feldtyp
analyze_field() {
    local field_name="$1"
    local pattern="$2"
    
    echo -e "${YELLOW}$field_name:${NC}"
    
    # Zähle Vorkommen
    local count=$(grep -E "^\\s*${pattern}\\s*:" "$TEMP_DIR/yaml_content.txt" | wc -l)
    echo "  Anzahl: $count"
    
    if [ "$count" -gt 0 ]; then
        # Zeige Beispiele
        echo "  Beispiele:"
        grep -E "^\\s*${pattern}\\s*:" "$TEMP_DIR/yaml_content.txt" | head -3 | sed 's/^/    /'
        
        # Zeige Formate
        echo "  Häufigste Formate:"
        grep -E "^\\s*${pattern}\\s*:" "$TEMP_DIR/yaml_content.txt" | \
            sort | uniq -c | sort -nr | head -3 | sed 's/^/    /'
    fi
    echo ""
    
    # Logge Ergebnisse
    log "#### $field_name"
    log "- Anzahl: $count"
    if [ "$count" -gt 0 ]; then
        log "- Beispiele:"
        grep -E "^\\s*${pattern}\\s*:" "$TEMP_DIR/yaml_content.txt" | head -3 | sed 's/^/  /'
        log ""
    fi
}

# Analysiere alle relevanten Felder
analyze_field "created_at" "created_at"
analyze_field "updated_at" "updated_at"
analyze_field "creation date" "creation date"
analyze_field "modification date" "modification date"
analyze_field "lastAnnotatedDate" "lastAnnotatedDate"
analyze_field "Date" "Date"
analyze_field "Created" "Created"
analyze_field "modified_at" "modified_at"
analyze_field "last_modified" "last_modified"

# Problematische Fälle
echo -e "${BLUE}⚠️  Problematische Fälle:${NC}"

# Invalid dates
INVALID_DATES=$(grep -c "Invalid date" "$TEMP_DIR/yaml_content.txt" || echo "0")
echo "Invalid dates: $INVALID_DATES"

# Leere Felder
EMPTY_FIELDS=$(grep -E "^\\s*(created_at|creation date|updated_at|modification date)\\s*:$" "$TEMP_DIR/yaml_content.txt" | wc -l)
echo "Leere Datum-Felder: $EMPTY_FIELDS"

# Templater-Code
TEMPLATER_CODE=$(grep -c "tp\\." "$TEMP_DIR/yaml_content.txt" || echo "0")
echo "Templater-Code: $TEMPLATER_CODE"

log "### Problematische Fälle"
log "- Invalid dates: $INVALID_DATES"
log "- Leere Datum-Felder: $EMPTY_FIELDS"
log "- Templater-Code: $TEMPLATER_CODE"
log ""

# Dateisystem-Metadaten Test
echo -e "${BLUE}🗂️  Dateisystem-Metadaten Test:${NC}"

# Teste 5 Dateien
echo "Teste Dateisystem-Metadaten (5 Beispiele):"
find . -name "*.md" | head -5 | while read file; do
    echo "  $file:"
    birth=$(stat -c '%w' "$file" 2>/dev/null || echo "N/A")
    modify=$(stat -c '%y' "$file" 2>/dev/null || echo "N/A")
    
    if [ "$birth" != "N/A" ] && [ "$birth" != "-" ]; then
        birth_formatted=$(date -d "$birth" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo "Format error")
        echo "    Birth: $birth_formatted"
    else
        echo "    Birth: Not available"
    fi
    
    modify_formatted=$(date -d "$modify" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo "Format error")
    echo "    Modify: $modify_formatted"
    echo ""
done

# Zähle Dateien mit birth time
BIRTH_AVAILABLE=$(find . -name "*.md" -exec stat -c '%w' {} \; 2>/dev/null | grep -v "^-$" | wc -l)
echo "Dateien mit birth time: $BIRTH_AVAILABLE von $TOTAL_MD"

log "### Dateisystem-Metadaten"
log "- Dateien mit birth time: $BIRTH_AVAILABLE von $TOTAL_MD"
log ""

# Migration-Empfehlungen
echo -e "${BLUE}💡 Migration-Empfehlungen:${NC}"
echo ""

# Berechne Migrations-Statistiken
NEED_CREATED_AT=$(find . -name "*.md" -exec grep -L "created_at:" {} \; | wc -l)
NEED_UPDATED_AT=$(find . -name "*.md" -exec grep -L "updated_at:" {} \; | wc -l)

echo "Dateien die created_at benötigen: $NEED_CREATED_AT"
echo "Dateien die updated_at benötigen: $NEED_UPDATED_AT"
echo ""

# Strategien
echo -e "${YELLOW}Empfohlene Strategie:${NC}"
echo "1. Backup erstellen: make backup"
echo "2. Test durchführen: make test"
echo "3. Migration starten: make migrate"
echo ""

if [ "$INVALID_DATES" -gt 0 ]; then
    echo -e "${RED}⚠️  Achtung: $INVALID_DATES Dateien haben 'Invalid date' - diese werden repariert${NC}"
fi

if [ "$EMPTY_FIELDS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Hinweis: $EMPTY_FIELDS Dateien haben leere Datum-Felder - diese werden aufgefüllt${NC}"
fi

log "### Migration-Empfehlungen"
log "- Dateien die created_at benötigen: $NEED_CREATED_AT"
log "- Dateien die updated_at benötigen: $NEED_UPDATED_AT"
log "- Invalid dates zu reparieren: $INVALID_DATES"
log "- Leere Felder zu füllen: $EMPTY_FIELDS"
log ""

# Cleanup
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✅ Analyse abgeschlossen${NC}"
echo "Detaillierte Logs siehe: docs/MIGRATION_LOG.md"
echo ""

log "## Analyse abgeschlossen: $(date '+%Y-%m-%d %H:%M:%S')"
log "---"
log ""
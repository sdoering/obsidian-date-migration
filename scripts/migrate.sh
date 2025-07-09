#!/bin/bash

# Obsidian Date Migration - Haupt-Migrations-Script
# Führt die eigentliche Migration der Datum-Felder durch

set -euo pipefail

VAULT_PATH="${1:-$(HOME)/path/to/your/obsidian-vault}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DRY_RUN="${2:-false}"

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

echo -e "${GREEN}🚀 OBSIDIAN DATE MIGRATION - MIGRATION${NC}"
echo "=========================================="
echo ""

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}⚠️  DRY-RUN MODUS - Keine echten Änderungen${NC}"
    echo ""
fi

log "## Migration gestartet: $TIMESTAMP"
log "**Vault-Pfad:** $VAULT_PATH"
log "**Dry-Run:** $DRY_RUN"
log ""

# Prüfe ob Vault existiert
if [ ! -d "$VAULT_PATH" ]; then
    echo -e "${RED}❌ Vault-Pfad existiert nicht: $VAULT_PATH${NC}"
    exit 1
fi

cd "$VAULT_PATH"

# Zähler für Statistiken
PROCESSED_FILES=0
CREATED_AT_ADDED=0
UPDATED_AT_ADDED=0
FIELDS_CONVERTED=0
ERRORS=0

# Temporary files
TEMP_DIR="/tmp/obsidian_migration_$$"
mkdir -p "$TEMP_DIR"

# Funktion: Konvertiere Datum zu Zielformat
convert_date() {
    local input_date="$1"
    local fallback_date="$2"
    
    # Entferne Anführungszeichen
    input_date=$(echo "$input_date" | sed "s/['\"]//g")
    
    # Verschiedene Formate verarbeiten
    case "$input_date" in
        # Bereits im Zielformat
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9])
            echo "$input_date"
            return 0
            ;;
        # Unix timestamp (nur Zahlen)
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*)
            date -d "@$input_date" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo "$fallback_date"
            ;;
        # ISO mit Timezone
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]*)
            date -d "$input_date" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo "$fallback_date"
            ;;
        # Nur Datum
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
            echo "${input_date}T00:00:00"
            ;;
        # Verbose Format (Tuesday 12th September 2023 18:43:02)
        *day*[0-9][0-9][0-9][0-9]*)
            date -d "$input_date" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo "$fallback_date"
            ;;
        # Deutscher Format (24.11.2023 15:45)
        [0-9][0-9].[0-9][0-9].[0-9][0-9][0-9][0-9]*)
            # Konvertiere DD.MM.YYYY zu YYYY-MM-DD
            day=$(echo "$input_date" | cut -d'.' -f1)
            month=$(echo "$input_date" | cut -d'.' -f2)
            year_time=$(echo "$input_date" | cut -d'.' -f3)
            year=$(echo "$year_time" | cut -d' ' -f1)
            time=$(echo "$year_time" | cut -d' ' -f2)
            if [ -n "$time" ]; then
                echo "${year}-${month}-${day}T${time}:00"
            else
                echo "${year}-${month}-${day}T00:00:00"
            fi
            ;;
        # Invalid date oder leer
        "Invalid date"|""|" ")
            echo "$fallback_date"
            ;;
        # Templater code
        *tp.*)
            echo "$fallback_date"
            ;;
        # Fallback
        *)
            date -d "$input_date" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo "$fallback_date"
            ;;
    esac
}

# Funktion: Erstelle Fallback-Datum aus Dateisystem
get_fallback_dates() {
    local file="$1"
    
    local birth_time=$(stat -c '%w' "$file" 2>/dev/null || echo "")
    local modify_time=$(stat -c '%y' "$file" 2>/dev/null || echo "")
    
    local birth_formatted=""
    local modify_formatted=""
    
    # Birth time formatieren
    if [ -n "$birth_time" ] && [ "$birth_time" != "-" ]; then
        birth_formatted=$(date -d "$birth_time" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo "")
    fi
    
    # Modify time formatieren
    if [ -n "$modify_time" ]; then
        modify_formatted=$(date -d "$modify_time" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo "")
    fi
    
    # Intelligente Fallback-Logik
    local created_fallback="$modify_formatted"
    local updated_fallback="$modify_formatted"
    
    if [ -n "$birth_formatted" ] && [ -n "$modify_formatted" ]; then
        # Prüfe ob birth time sinnvoll ist (birth <= modify)
        local birth_ts=$(date -d "$birth_time" '+%s' 2>/dev/null || echo "0")
        local modify_ts=$(date -d "$modify_time" '+%s' 2>/dev/null || echo "0")
        
        if [ "$birth_ts" -le "$modify_ts" ]; then
            created_fallback="$birth_formatted"
        else
            # Problematischer Fall: birth > modify (wahrscheinlich Backup-Wiederherstellung)
            created_fallback="$modify_formatted"
            updated_fallback="$birth_formatted"
        fi
    fi
    
    echo "$created_fallback|$updated_fallback"
}

# Funktion: Migriere einzelne Datei
migrate_file() {
    local file="$1"
    local temp_file="$TEMP_DIR/temp_$(basename "$file")"
    
    # Prüfe ob Datei YAML Front Matter hat
    if ! head -1 "$file" | grep -q "^---$"; then
        return 0
    fi
    
    echo -e "${BLUE}📄 Verarbeite: $file${NC}"
    
    # Hole Fallback-Daten
    local fallback_dates=$(get_fallback_dates "$file")
    local created_fallback=$(echo "$fallback_dates" | cut -d'|' -f1)
    local updated_fallback=$(echo "$fallback_dates" | cut -d'|' -f2)
    
    # Analysiere vorhandene Felder
    local yaml_content=$(awk '/^---$/{f=1;next} /^---$/{f=0} f' "$file")
    
    # Suche nach verschiedenen created_at Varianten
    local current_created_at=$(echo "$yaml_content" | grep -E "^\\s*created_at\\s*:" | head -1 | cut -d':' -f2- | xargs || echo "")
    local current_creation_date=$(echo "$yaml_content" | grep -E "^\\s*creation date\\s*:" | head -1 | cut -d':' -f2- | xargs || echo "")
    local current_last_annotated=$(echo "$yaml_content" | grep -E "^\\s*lastAnnotatedDate\\s*:" | head -1 | cut -d':' -f2- | xargs || echo "")
    
    # Suche nach verschiedenen updated_at Varianten
    local current_updated_at=$(echo "$yaml_content" | grep -E "^\\s*updated_at\\s*:" | head -1 | cut -d':' -f2- | xargs || echo "")
    local current_modification_date=$(echo "$yaml_content" | grep -E "^\\s*modification date\\s*:" | head -1 | cut -d':' -f2- | xargs || echo "")
    
    # Bestimme finales created_at
    local final_created_at=""
    if [ -n "$current_created_at" ]; then
        final_created_at=$(convert_date "$current_created_at" "$created_fallback")
    elif [ -n "$current_creation_date" ]; then
        final_created_at=$(convert_date "$current_creation_date" "$created_fallback")
    elif [ -n "$current_last_annotated" ]; then
        final_created_at=$(convert_date "$current_last_annotated" "$created_fallback")
    else
        final_created_at="$created_fallback"
        ((CREATED_AT_ADDED++))
    fi
    
    # Bestimme finales updated_at
    local final_updated_at=""
    if [ -n "$current_updated_at" ]; then
        final_updated_at=$(convert_date "$current_updated_at" "$updated_fallback")
    elif [ -n "$current_modification_date" ]; then
        final_updated_at=$(convert_date "$current_modification_date" "$updated_fallback")
    else
        final_updated_at="$updated_fallback"
        ((UPDATED_AT_ADDED++))
    fi
    
    # Erstelle neue Datei
    if [ "$DRY_RUN" = "false" ]; then
        # Kopiere Datei zum Bearbeiten
        cp "$file" "$temp_file"
        
        # Verarbeite YAML Front Matter
        {
            echo "---"
            
            # Erste Zeile nach --- bis zur schließenden ---
            awk '/^---$/{f=1;next} /^---$/{f=0} f' "$file" | while IFS= read -r line; do
                # Überspringe zu ersetzende Felder
                if echo "$line" | grep -qE "^\\s*(created_at|creation date|lastAnnotatedDate|updated_at|modification date|Date|Created|modified_at|last_modified)\\s*:"; then
                    continue
                fi
                echo "$line"
            done
            
            # Füge neue Felder hinzu
            echo "created_at: $final_created_at"
            echo "updated_at: $final_updated_at"
            echo "---"
            
            # Kopiere den Rest der Datei (nach dem YAML Front Matter)
            awk '/^---$/{f++} f>1' "$file"
        } > "$temp_file"
        
        # Ersetze Original
        mv "$temp_file" "$file"
        
        echo -e "${GREEN}  ✅ Migriert: created_at=$final_created_at, updated_at=$final_updated_at${NC}"
    else
        echo -e "${YELLOW}  🔍 Würde migrieren: created_at=$final_created_at, updated_at=$final_updated_at${NC}"
    fi
    
    ((PROCESSED_FILES++))
    
    # Logge Details
    log "- **$file**"
    log "  - created_at: $final_created_at"
    log "  - updated_at: $final_updated_at"
}

# Hauptschleife: Verarbeite alle Markdown-Dateien
echo -e "${BLUE}🔄 Starte Migration aller Markdown-Dateien...${NC}"
echo ""

log "### Migrierte Dateien"
log ""

while IFS= read -r -d '' file; do
    if migrate_file "$file"; then
        :
    else
        echo -e "${RED}❌ Fehler bei: $file${NC}"
        ((ERRORS++))
    fi
done < <(find . -name "*.md" -type f -print0)

# Abschluss-Statistiken
echo ""
echo -e "${GREEN}📊 Migration abgeschlossen${NC}"
echo "========================="
echo "Verarbeitete Dateien: $PROCESSED_FILES"
echo "created_at hinzugefügt: $CREATED_AT_ADDED"
echo "updated_at hinzugefügt: $UPDATED_AT_ADDED"
echo "Fehler: $ERRORS"
echo ""

log ""
log "### Migration-Statistiken"
log "- Verarbeitete Dateien: $PROCESSED_FILES"
log "- created_at hinzugefügt: $CREATED_AT_ADDED"
log "- updated_at hinzugefügt: $UPDATED_AT_ADDED"
log "- Fehler: $ERRORS"
log ""

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}⚠️  $ERRORS Fehler aufgetreten. Prüfe die Logs für Details.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Migration erfolgreich abgeschlossen!${NC}"
fi

# Cleanup
rm -rf "$TEMP_DIR"

log "## Migration abgeschlossen: $(date '+%Y-%m-%d %H:%M:%S')"
log "---"
log ""
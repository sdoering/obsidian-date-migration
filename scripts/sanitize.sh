#!/bin/bash

# Obsidian Date Migration - Sanitize Script
# Entfernt private/sensitive Daten für GitHub-Veröffentlichung

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧹 OBSIDIAN DATE MIGRATION - SANITIZE${NC}"
echo "=========================================="
echo ""

# Erstelle sanitized Version der Konfigurations-Dateien
sanitize_makefile() {
    echo -e "${BLUE}📝 Sanitize Makefile...${NC}"
    
    # Ersetze private Pfade mit Platzhaltern
    sed -i 's|/home/sdoering/obsidianVaultNew|$(HOME)/path/to/your/obsidian-vault|g' "$PROJECT_DIR/Makefile"
    
    echo -e "${GREEN}  ✅ Makefile sanitized${NC}"
}

sanitize_scripts() {
    echo -e "${BLUE}📝 Sanitize Scripts...${NC}"
    
    # Sanitize analyze.sh
    sed -i 's|/home/sdoering/obsidianVaultNew|$(HOME)/path/to/your/obsidian-vault|g' "$PROJECT_DIR/scripts/analyze.sh"
    
    # Sanitize migrate.sh
    sed -i 's|/home/sdoering/obsidianVaultNew|$(HOME)/path/to/your/obsidian-vault|g' "$PROJECT_DIR/scripts/migrate.sh"
    
    # Sanitize test.sh
    sed -i 's|/home/sdoering/obsidianVaultNew|$(HOME)/path/to/your/obsidian-vault|g' "$PROJECT_DIR/scripts/test.sh"
    
    echo -e "${GREEN}  ✅ Scripts sanitized${NC}"
}

sanitize_logs() {
    echo -e "${BLUE}📝 Sanitize Logs...${NC}"
    
    # Lösche vorhandene Logs mit privaten Daten
    if [ -f "$PROJECT_DIR/docs/MIGRATION_LOG.md" ]; then
        rm "$PROJECT_DIR/docs/MIGRATION_LOG.md"
    fi
    
    # Erstelle Template-Log
    cat > "$PROJECT_DIR/docs/MIGRATION_LOG.md" << 'EOF'
# Migration Log

Dieses Log wird automatisch während der Migration erstellt.

## Beispiel-Eintrag

```
## Analyse gestartet: 2025-01-15 10:30:00
**Vault-Pfad:** /path/to/your/obsidian-vault

### Grundlegende Statistiken
- Gesamt .md Dateien: 150
- Mit YAML Front Matter: 120

### Migration-Empfehlungen
- Dateien die created_at benötigen: 80
- Dateien die updated_at benötigen: 95
```

Die tatsächlichen Logs werden bei der Verwendung hier generiert.
EOF
    
    echo -e "${GREEN}  ✅ Logs sanitized${NC}"
}

create_example_files() {
    echo -e "${BLUE}📝 Erstelle Beispiel-Dateien...${NC}"
    
    mkdir -p "$PROJECT_DIR/examples/sample_files"
    
    # Beispiel-Datei mit verschiedenen Datum-Formaten
    cat > "$PROJECT_DIR/examples/sample_files/example-before.md" << 'EOF'
---
title: "Beispiel-Notiz"
creation date: 2025-01-15T10:30:00
modification date: Tuesday 16th January 2025 14:22:03
lastAnnotatedDate: '2025-01-10'
tags: ["example", "test"]
---

# Beispiel-Notiz

Dies ist eine Beispiel-Datei mit verschiedenen Datum-Formaten im YAML Front Matter.
EOF

    # Beispiel-Datei nach Migration
    cat > "$PROJECT_DIR/examples/sample_files/example-after.md" << 'EOF'
---
title: "Beispiel-Notiz"
tags: ["example", "test"]
created_at: 2025-01-15T10:30:00
updated_at: 2025-01-16T14:22:03
---

# Beispiel-Notiz

Dies ist eine Beispiel-Datei nach der Migration mit einheitlichen Datum-Formaten.
EOF
    
    echo -e "${GREEN}  ✅ Beispiel-Dateien erstellt${NC}"
}

create_test_suite() {
    echo -e "${BLUE}📝 Erstelle Test-Suite...${NC}"
    
    cat > "$PROJECT_DIR/tests/test_suite.sh" << 'EOF'
#!/bin/bash

# Test Suite für Obsidian Date Migration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Farben
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🧪 Test Suite für Obsidian Date Migration${NC}"
echo "========================================"
echo ""

# Test 1: Prüfe ob alle Scripts existieren
test_scripts_exist() {
    echo -e "${YELLOW}Test 1: Scripts existieren...${NC}"
    
    local scripts=("analyze.sh" "migrate.sh" "test.sh" "sanitize.sh")
    local all_exist=true
    
    for script in "${scripts[@]}"; do
        if [ ! -f "$PROJECT_DIR/scripts/$script" ]; then
            echo -e "${RED}❌ Script nicht gefunden: $script${NC}"
            all_exist=false
        fi
    done
    
    if [ "$all_exist" = true ]; then
        echo -e "${GREEN}✅ Alle Scripts vorhanden${NC}"
        return 0
    else
        return 1
    fi
}

# Test 2: Prüfe ob Scripts ausführbar sind
test_scripts_executable() {
    echo -e "${YELLOW}Test 2: Scripts ausführbar...${NC}"
    
    local scripts=("analyze.sh" "migrate.sh" "test.sh" "sanitize.sh")
    local all_executable=true
    
    for script in "${scripts[@]}"; do
        if [ ! -x "$PROJECT_DIR/scripts/$script" ]; then
            echo -e "${RED}❌ Script nicht ausführbar: $script${NC}"
            all_executable=false
        fi
    done
    
    if [ "$all_executable" = true ]; then
        echo -e "${GREEN}✅ Alle Scripts ausführbar${NC}"
        return 0
    else
        return 1
    fi
}

# Test 3: Prüfe Makefile
test_makefile() {
    echo -e "${YELLOW}Test 3: Makefile...${NC}"
    
    if [ ! -f "$PROJECT_DIR/Makefile" ]; then
        echo -e "${RED}❌ Makefile nicht gefunden${NC}"
        return 1
    fi
    
    # Prüfe wichtige Targets
    local targets=("help" "setup" "analyze" "test" "migrate" "rollback")
    local all_targets=true
    
    for target in "${targets[@]}"; do
        if ! grep -q "^$target:" "$PROJECT_DIR/Makefile"; then
            echo -e "${RED}❌ Makefile-Target nicht gefunden: $target${NC}"
            all_targets=false
        fi
    done
    
    if [ "$all_targets" = true ]; then
        echo -e "${GREEN}✅ Makefile OK${NC}"
        return 0
    else
        return 1
    fi
}

# Test 4: Prüfe Beispiel-Dateien
test_examples() {
    echo -e "${YELLOW}Test 4: Beispiel-Dateien...${NC}"
    
    if [ ! -f "$PROJECT_DIR/examples/sample_files/example-before.md" ]; then
        echo -e "${RED}❌ Beispiel-Datei nicht gefunden: example-before.md${NC}"
        return 1
    fi
    
    if [ ! -f "$PROJECT_DIR/examples/sample_files/example-after.md" ]; then
        echo -e "${RED}❌ Beispiel-Datei nicht gefunden: example-after.md${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Beispiel-Dateien OK${NC}"
    return 0
}

# Führe alle Tests aus
echo "Starte Tests..."
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    if $test_function; then
        ((TESTS_PASSED++))
    else
        ((TESTS_FAILED++))
    fi
    echo ""
}

run_test "Scripts existieren" test_scripts_exist
run_test "Scripts ausführbar" test_scripts_executable
run_test "Makefile" test_makefile
run_test "Beispiel-Dateien" test_examples

# Ergebnis
echo "=================================="
echo -e "${GREEN}Tests bestanden: $TESTS_PASSED${NC}"
echo -e "${RED}Tests fehlgeschlagen: $TESTS_FAILED${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}🎉 Alle Tests bestanden!${NC}"
    exit 0
else
    echo -e "${RED}❌ Einige Tests fehlgeschlagen${NC}"
    exit 1
fi
EOF
    
    chmod +x "$PROJECT_DIR/tests/test_suite.sh"
    
    echo -e "${GREEN}  ✅ Test-Suite erstellt${NC}"
}

create_license() {
    echo -e "${BLUE}📝 Erstelle LICENSE...${NC}"
    
    cat > "$PROJECT_DIR/LICENSE" << 'EOF'
MIT License

Copyright (c) 2025 Obsidian Date Migration Tool

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
    
    echo -e "${GREEN}  ✅ LICENSE erstellt${NC}"
}

create_gitignore() {
    echo -e "${BLUE}📝 Erstelle .gitignore...${NC}"
    
    cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Logs
*.log
docs/MIGRATION_LOG.md

# Temporary files
/tmp/
*.tmp
*.temp

# Backup files
*.bak
*~

# Test artifacts
tests/test_data/temp_*
tests/*.log

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Personal configurations
config.local
EOF
    
    echo -e "${GREEN}  ✅ .gitignore erstellt${NC}"
}

# Führe alle Sanitization-Schritte aus
echo "Starte Sanitization..."
echo ""

sanitize_makefile
sanitize_scripts
sanitize_logs
create_example_files
create_test_suite
create_license
create_gitignore

echo ""
echo -e "${GREEN}✅ Sanitization abgeschlossen${NC}"
echo ""
echo -e "${YELLOW}📋 Nächste Schritte:${NC}"
echo "1. Überprüfe alle Dateien auf weitere private Informationen"
echo "2. Teste das Projekt: make dev-test"
echo "3. Wenn OK: make github-prep"
echo ""
echo -e "${BLUE}💡 Bereit für GitHub-Veröffentlichung!${NC}"
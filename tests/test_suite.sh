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

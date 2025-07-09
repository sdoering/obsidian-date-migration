---
type: blogpost
status: draft
created_at: 2025-07-09T19:30:00
tags: [obsidian, automation, bash, migration, second-brain]
---

# Moin! Wie ich 2300+ Markdown-Dateien in meinem Obsidian Vault repariert habe

*9. Juli 2025*

Moin zusammen!

Heute mal ein Thema, das wahrscheinlich jeder kennt, der schon länger mit Obsidian arbeitet: **Datum-Chaos im Second Brain**. Ich hatte 2300+ Markdown-Dateien mit völlig unterschiedlichen Datum-Formaten in den YAML Front Matter Bereichen. Das war nicht nur unschön, sondern hat auch die Automatisierung meines Workflows behindert.

Nach Jahren der Obsidian-Nutzung sah mein Vault aus wie ein Datum-Schlachtfeld. Mal waren es Obsidian-eigene Felder, mal Kindle-Highlights, mal selbst erstellte Notizen mit verschiedenen Tools. Das Ergebnis: Ein komplettes Durcheinander.

**Das musste ich reparieren.** Und zwar automatisiert, denn 2300+ Dateien von Hand zu bearbeiten war keine Option.

## Das grundlegende Problem: Datum-Chaos überall

Hier mal ein paar Beispiele aus meinem Vault:

```yaml
# Obsidian Standard
creation date: 2025-01-26T19:36:00
modification date: Tuesday 12th September 2023 18:43:02

# Kindle Highlights (Import)
lastAnnotatedDate: '2023-03-04'
lastAnnotatedDate: Invalid date

# Eigene Notizen
created_at: "1716650237946"  # Unix timestamp
created_at: 2025-05-22T16:35:00

# Templater-Code (unausgeführt)
creation date: 2025-07-09 20:30
modification date: Wednesday 9th July 2025 20:30:59
```

**Das Ziel:** Alles vereinheitlichen zu einem sauberen Standard:
```yaml
created_at: 2025-01-15T10:30:00
updated_at: 2025-01-15T14:22:03
```

## Die Lösung: Intelligente Automatisierung

Manuell? Nein danke. Dafür bin ich zu faul. Also musste ein Script her. Aber nicht irgendein Script - sondern eines, das klug mit Edge Cases umgeht und sicheren Rollback bietet.

Die Idee: Was tun, wenn keine Datum-Felder vorhanden sind? Dateisystem-Metadaten nutzen!

Moderne Dateisysteme (ext4, APFS, NTFS) speichern nämlich Creation Time. Das kann ich als Fallback verwenden:

```bash
# Birth time (Erstellungszeit)
stat -c '%w' file.md  # 2025-05-27 22:02:15.963930273 +0200

# Modify time (letzte Änderung)  
stat -c '%y' file.md  # 2025-06-30 23:11:50.815815766 +0200
```

**Das Problem dabei:** Dateien aus Backups. Da ist `birth_time > modify_time` (weil die Datei ja beim Restore "neu erstellt" wurde). Das Script erkennt das und dreht die Logik um:

```bash
if [ "$birth_ts" -le "$modify_ts" ]; then
    created_at="$birth_formatted"
    updated_at="$modify_formatted"
else
    # Backup-Wiederherstellung erkannt
    created_at="$modify_formatted"  # Ursprüngliche Erstellungszeit
    updated_at="$birth_formatted"   # Wiederherstellungszeit
fi
```

Ich wollte das Tool sauber aufbauen. Daher: Makefile-driven Development. 

**Der Workflow:**
```bash
# Analyse des aktuellen Zustands
make analyze

# Test ohne Änderungen (Dry-Run)
make test

# Backup + echte Migration
make migrate

# Rollback falls nötig
make rollback
```

**Projekt-Struktur:**
```
obsidian-date-migration/
├── Makefile                 # Hauptsteuerung
├── scripts/
│   ├── analyze.sh          # Vault-Analyse
│   ├── migrate.sh          # Migrations-Script
│   ├── test.sh             # Dry-Run Tests
│   └── sanitize.sh         # GitHub-Sanitization
├── tests/
│   └── test_suite.sh       # Automatisierte Tests
└── docs/
    └── MIGRATION_LOG.md    # Automatisches Logging
```

## Das clevere Teil: Intelligente Datum-Konvertierung

Das Herzstück ist eine Bash-Funktion, die verschiedene Formate erkennt und konvertiert:

```bash
convert_date() {
    local input_date="$1"
    local fallback_date="$2"
    
    case "$input_date" in
        # Bereits im Zielformat
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9])
            echo "$input_date"
            ;;
        # Unix timestamp
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*)
            date -d "@$input_date" '+%Y-%m-%dT%H:%M:%S'
            ;;
        # Nur Datum
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
            echo "${input_date}T00:00:00"
            ;;
        # Deutscher Format (24.11.2023 15:45)
        [0-9][0-9].[0-9][0-9].[0-9][0-9][0-9][0-9]*)
            # Konvertiere DD.MM.YYYY zu YYYY-MM-DD
            # (Implementation ausgelassen)
            ;;
        # Fallback
        *)
            echo "$fallback_date"
            ;;
    esac
}
```

**Was mich gestört hat:** Templater-Code wie `2025-07-09` wird einfach mit dem Dateisystem-Fallback ersetzt. Das ist sauberer als zu versuchen, den Code auszuführen.

**Vorher (Analyse-Ergebnis):**
```
📊 Datum-Feld-Analyse:
- lastAnnotatedDate: 190 (44× "Invalid date")
- created_at: 49 (verschiedene Formate)
- creation date: 218 (46× leer)
- modification date: 96 (verschiedene Formate)
- updated_at: 7 (konsistent)
```

**Nachher (Migration-Ergebnis):**
```
✅ Migration erfolgreich:
- 2305 Dateien verarbeitet
- 2256 created_at hinzugefügt
- 2298 updated_at hinzugefügt
- 0 Fehler
```

**Dauer:** 3 Minuten 42 Sekunden für alle 2305 Dateien.

## Was ich dabei gelernt habe

### 1. Dateisystem-Metadaten sind Gold wert
Moderne Dateisysteme speichern Creation Time. Das macht intelligente Fallbacks möglich, ohne die Dateien selbst zu analysieren.

### 2. Test-First Development ist kritisch
Ohne `make test` (Dry-Run) hätte ich nie 2300+ Dateien blind migriert. Bei solchen Operationen ist Testing essentiell.

### 3. Backup-Strategien durchdenken
Git-Integration im Makefile war kritisch:
```bash
cd $(VAULT_PATH) && git add -A && git commit -m "Backup vor Migration"
```

### 4. Edge Cases systematisch dokumentieren
Die "birth > modify" Problematik hätte ich ohne systematische Analyse übersehen. Das war ein echter Haken an der Sache.

## Der Code

Das komplette Projekt ist auf GitHub verfügbar:
- **Repository**: [obsidian-date-migration](https://github.com/username/obsidian-date-migration)
- **Features**: Makefile-driven, Test-Suite, Rollback-fähig
- **Einsatzbereich**: Jeder Obsidian Vault mit Datum-Problemen

**Quick Start:**
```bash
# Projekt klonen
git clone https://github.com/username/obsidian-date-migration.git
cd obsidian-date-migration

# Vault-Pfad anpassen
export VAULT_PATH="/path/to/your/obsidian-vault"

# Analyse
make analyze

# Test
make test

# Migration
make migrate
```

## Wie lief's?

**Second Brain Maintenance** ist ein unterschätztes Thema. Nach 2+ Jahren Obsidian-Nutzung hatte ich ein Datum-Chaos, das manuelle Bereinigung unmöglich machte.

Die Lösung: **Automatisierung mit Intelligenz**. Nicht nur Pattern Matching, sondern echte Fallback-Strategien mit Dateisystem-Metadaten.

**Nächster Schritt**: Das Tool weiterentwickeln für andere YAML-Feld-Probleme (Tags, Links, etc.).

Bis dahin: Räumt euer Second Brain auf, lütt!

**Sven**
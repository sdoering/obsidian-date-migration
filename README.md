# Obsidian Date Migration Tool

Ein intelligentes Tool zur Vereinheitlichung von Datum-Feldern in Obsidian Vault YAML Front Matter.

## Problem

Obsidian Vaults enthalten oft verschiedene Datum-Feld-Formate:
- `creation date: 2025-01-26T19:36:00`
- `lastAnnotatedDate: '2023-03-04'`
- `created_at: "1716650237946"` (Unix timestamp)
- `modification date: Tuesday 12th September 2023 18:43:02`

## Lösung

Vereinheitlichung zu:
```yaml
created_at: 2025-05-27T22:03:00
updated_at: 2025-06-30T23:11:50
```

## Features

- **Intelligente Fallback-Strategie**: Nutzt Dateisystem-Metadaten wenn YAML-Felder fehlen
- **Sichere Migration**: Vollständiges Backup & Rollback
- **Testing**: Dry-run Modus vor echten Änderungen
- **Edge-Case Handling**: Behandelt problematische Fälle (z.B. Backup-Wiederherstellung)
- **Makefile**: Einfache Bedienung über `make` Commands

## Verwendung

```bash
# Projekt-Setup
make setup

# Analyse des aktuellen Zustands
make analyze

# Test-Lauf (keine Änderungen)
make test

# Echte Migration
make migrate

# Rollback falls nötig
make rollback
```

## Struktur

```
obsidian-date-migration/
├── Makefile                 # Hauptsteuerung
├── scripts/
│   ├── migrate.sh          # Haupt-Migrations-Script
│   ├── analyze.sh          # Analyse-Tool
│   ├── sanitize.sh         # Sanitization für GitHub
│   └── test.sh             # Test-Runner
├── tests/
│   ├── test_data/          # Test-Dateien
│   └── test_suite.sh       # Automatisierte Tests
├── docs/
│   └── MIGRATION_LOG.md    # Automatisches Logging
└── examples/
    └── sample_files/       # Beispiel-Dateien
```

## Technische Details

- **Zielformat**: `YYYY-MM-DDTHH:MM:SS` (ISO 8601 ohne Timezone)
- **Fallback-Strategie**: YAML → Dateisystem birth time → modify time
- **Backup**: Automatisches Git-Backup vor Migration
- **Logging**: Vollständige Dokumentation aller Änderungen

## Entwicklung

Dieses Tool entstand aus der Notwendigkeit, ein 2nd Brain (Obsidian Vault) mit 2300+ Markdown-Dateien zu bereinigen und zu vereinheitlichen.

## Contributing

Pull Requests willkommen! Bitte teste gründlich mit eigenen Daten.

## Lizenz

MIT License - Siehe LICENSE Datei.
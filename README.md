# Team Toolkit

Zentrale Sammlung von Konfigurationen, Skripten und Anleitungen für eine einheitliche Arbeitsumgebung im Team.

---

## Ziel

Dieses Repository dient als Referenz und Werkzeugkasten zur:

- Standardisierung von Arbeitsumgebungen
- Wiederverwendung bewährter Konfigurationen
- Automatisierung wiederkehrender Aufgaben
- strukturierten Bereitstellung von Wissen

---

## Struktur

```
team-toolkit/
├── README.md
├── docs/
│   ├── linux/
│   ├── windows/
│   ├── vscode/
│   └── general/
├── configs/
│   ├── linux/
│   │   └── bash/
│   ├── windows/
│   │   └── powershell/
│   └── vscode/
│       ├── linux/
│       ├── windows/
│       └── common/
├── scripts/
│   ├── linux/
│   ├── windows/
│   └── crossplatform/
├── examples/
│   ├── templates/
│   └── samples/
└── assets/
```

---

## Inhalte

### docs/
Anleitungen und HowTos, nach Plattform getrennt.

### configs/
Direkt nutzbare Konfigurationsdateien:
- VS Code Einstellungen
- Bash-Profile
- PowerShell-Profile

### scripts/
Automatisierungen und Tools:
- Linux (Shell)
- Windows (PowerShell)
- Plattformübergreifend

### examples/
Vorlagen und Beispielkonfigurationen.

### assets/
Bilder und unterstützende Dateien für die Dokumentation.

---

## Nutzung

Repository klonen:

```bash
git clone https://github.com/rudi922/team-toolkit.git
```

Die enthaltenen Dateien können lokal verwendet und angepasst werden.

---

## Regeln

- Repository ist öffentlich lesbar (Read-Only für externe Nutzer)
- Änderungen erfolgen durch den Maintainer
- Inhalte müssen dokumentiert sein
- klare und konsistente Struktur einhalten

---

## Namenskonventionen

- Kleinbuchstaben verwenden
- keine Leerzeichen
- sprechende technische Namen
- ISO-Datum bei Bedarf voranstellen (YYYY-MM-DD)

Beispiel:

```
2026-03-22_vscode_settings.json
```

---

## Hinweise

Dieses Repository ist als zentrale Referenz gedacht.  
Lokale Anpassungen sind erlaubt, sollten jedoch nachvollziehbar dokumentiert werden.

---

## Maintainer
2026-03-23 08:47:01
- rudi922

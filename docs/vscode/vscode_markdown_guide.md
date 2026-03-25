
# 🧭 VS Code Markdown-Arbeitsumgebung (kontrolliert & offline)

🧩 Diese Datei zeigt beschreibt die optimale Bearbeitung von Markdown-Dateien mit Visual Studio Code mit bestimmten VSIX-Erweiterungen und unter Beachtung der Einstellungen in setting.json.  
🧑‍🔬 Autor: Dipl.-Ing. Alfred Menzel  
🗓️ Version: 2026-03-25 11:27:29  

UTF-8 signal: ʘ‿ʘ Grüß Gott – Ça va? – ¿Qué tal? – Привет – 你好 – שלום – नमस्ते – مرحبا

---

## 📦 Verwendete Erweiterungen

- davidanson.vscode-markdownlint (0.61.1)
- takumii.markdowntable (0.13.0)
- yzhang.markdown-all-in-one (3.6.3)

---

## ⚙️ Grundprinzip der Konfiguration (settings.json)

Die settings.json ist klar ausgerichtet auf:

- ❌ Keine automatischen Änderungen beim Speichern
- ✅ Manuelle, bewusste Kontrolle
- ✅ Sichtbarkeit aller Zeichen (Whitespace, Unicode)
- ✅ Offline-Betrieb ohne Marketplace

---

## ✍️ Markdown schreiben (Editor-Verhalten)

### Zeilenumbruch

- wordWrap = on → nur visuell

### Einrückung

- 2 Leerzeichen
- keine Tabs

### WICHTIG

- formatOnSave = false
- markdownlint Auto-Fix = deaktiviert

➡️ Der Autor bestimmst jede Änderung selbst.

---

## 📐 markdownlint – Regeln verstehen und nutzen

### Ziel

Qualitätssicherung für Markdown

### Aktive Regeln (Auszug)

- MD013: deaktiviert → keine Zeilenlängenbegrenzung
- MD024: gleiche Überschriften erlaubt
- MD029: echte Nummerierung erforderlich

---

### Typischer Workflow

1. Datei schreiben
2. Hinweise ansehen (gelb/rot)
3. Entscheidung treffen:
   - korrigieren
   - bewusst ignorieren

➡️ KEIN Auto-Fix → volle Kontrolle

---

## 🔢 Listenverhalten (WICHTIG)

### Einstellung

**markdown-all-in-one:**

- automatische Nummerierung aktiv

**markdownlint:**

- erzwingt echte Nummern (MD029)

---

### Best Practice

**Beim Schreiben:**

``` list
1. Punkt
1. Punkt
1. Punkt
```

**Nach Korrektur:**

``` list
1. Punkt
2. Punkt
3. Punkt
```

➡️ Kombination ist korrekt und gewollt

---

## 📊 Tabellen (takumii.markdowntable)

### Tabelle erstellen

**Manuell beginnen:**

``` table
| Spalte1 | Spalte2 |
|---------|---------|
|         |         |
```

---

### Navigation

- TAB → nächste Zelle
- SHIFT+TAB → vorherige Zelle

---

### Spalten einfügen

**Command Palette:**

Markdown Table: Insert Column

---

### Formatierung

Tabellen werden sauber ausgerichtet (manuell triggern empfohlen)

---

## 📑 Markdown All in One

### Funktionen

- Listenverwaltung
- TOC (Inhaltsverzeichnis)
- Tabellenformatierung
- Shortcuts

---

### Inhaltsverzeichnis erstellen

**Command Palette:**

Markdown All in One: Create Table of Contents

---

### TOC Einstellungen

- GitHub-kompatibel
- Ebenen: H2–H4
- kein Auto-Update

➡️ bewusst manuell aktualisieren

---

## 🔍 Sichtbarkeit & Qualität

Aktiv:

- Whitespace sichtbar
- Unicode-Prüfung aktiv
- Steuerzeichen sichtbar

➡️ Vorteil:

- keine versteckten Fehler

---

## 🚫 Bewusst deaktiviert

- Auto-Formatierung
- Auto-Fix
- Marketplace
- Updates
- Telemetrie

➡️ maximale Stabilität

---

## 🧠 Empfohlenes Arbeitsmuster

### Schreiben

- strukturiert und manuell

### Prüfen

- markdownlint bewusst nutzen

### Formatieren

- nur gezielt ausführen

---

## 🎯 Fazit

Das Setup ist:

- stabil
- reproduzierbar
- offline-fähig
- kontrolliert

Die Arbeit erfolgt nicht automatisiert, sondern deterministisch.

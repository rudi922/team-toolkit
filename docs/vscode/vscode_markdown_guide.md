
# 🧭 VS Code Markdown - Arbeitsumgebung und Anleitung

🧩 Diese Datei beschreibt die optimale Bearbeitung von Markdown-Dateien mit Visual Studio Code mit bestimmten VSIX-Erweiterungen und unter Beachtung der Einstellungen in setting.json.  
🧑‍🔬 Autor: Dipl.-Ing. Alfred Menzel  
🗓️ Version: 2026-03-27 11:17:17  

UTF-8 signal: ʘ‿ʘ Grüß Gott – Ça va? – ¿Qué tal? – Привет – 你好 – שלום – नमस्ते – مرحبا

---

## 📦 Verwendete Erweiterungen

- davidanson.vscode-markdownlint (0.61.1)
- takumii.markdowntable (0.13.0)
- yzhang.markdown-all-in-one (3.6.3)

---

## ⚙️ Grundprinzip der Konfiguration (settings.json) für das Schreiben von Markdown (Editor-Verhalten)

Die settings.json ist klar ausgerichtet auf:

- ❌ Keine automatischen Änderungen beim Speichern
- ✅ Manuelle, bewusste Kontrolle
- ✅ Sichtbarkeit aller Zeichen (Whitespace, Unicode)
- ✅ Offline-Betrieb ohne Marketplace

### Zeilenumbruch

- wordWrap = virtueller Zeilenumbruch im Editor

### Einrückung

- 2 Leerzeichen
- keine Tabs

### WICHTIG

- formatOnSave = false
- markdownlint Auto-Fix = deaktiviert

💡 Der Autor bestimmt jede Änderung selbst.

---

## 📦 VSIX `markdownlint` – Qualitätssicherung für Markdown-Dateien

### Ziel

Durch die Verwendung von **`markdownlint`** wird die Validität von Markdown-Dateien gewährleistet.

### Aktive Regeln (Auszug) in der setting.json

- MD013: deaktiviert → keine Zeilenlängenbegrenzung
- MD024: gleiche Überschriften erlaubt
- MD029: echte Nummerierung erforderlich

### Typischer Workflow

1. Datei schreiben
2. Hinweise ansehen (gelb/rot)
3. Entscheidung treffen:
   - korrigieren
   - bewusst ignorieren

📌 Damit die Kontrolle über Änderungen behalten wird, ist Auto-Fix in der settings.json deaktiviert.

---

## 📦 VSIX `Markdown All in One` – Formatierungshilfe für Markdown-Dateien

### Ziel

`Markdown All in One` erleichtert das Schreiben von Markdown durch automatische Formatierungen und Shortcuts.

### Aufzählungen und Listenerstellung

**Schreiben (Vorgehen):**

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

👉 Die Aufzählungliste wird nach dem letzten Zeilenumbruch automatisch korrigiert.
Die Erstellung von Unterstrukturen in der Aufzählung ist möglich.

📌 Zur Harmonisierung der Funktionalität sind in der `settings.json` folgende Einstellungen aktiv.  

**Markdown All in One:**

- automatische Nummerierung aktiv

**markdownlint:**

- erzwingt echte Nummern (MD029)

### Markdown All in One: Weitere Funktionen, Schriftstile ändern u.a.

👉 Verwende hierfür die Befehlspalette `STRG+UMSCHALT+P` und die Zeichenfolge `Markdown All in One:`

---

## 📦 VSIX `Markdown Table` – Bearbeitungshilfe für Tabellen

### Ziel

Diese Erweiterung erleichtert die Handhabung und Formatierung von Tabellen.
Spalten werden sauber ausgerichtet und ggf. erweitert.

---

### Tabelle erstellen

**Manuell beginnen:**

``` table
| Spalte1 | Spalte2 |
|---------|---------|
|         |         |
```

👉 Verwende das Snippet `mzTable` um eine Standardtabelle zu erstellen.
Diese Standardtabelle kann im Anschluss beliebig geändert und erweitert werden.

---

### Navigation

- TAB → nächste Zelle
- SHIFT+TAB → vorherige Zelle

---

### Spalten einfügen

Verwende hierfür die Befehlspalette `STRG+UMSCHALT+P` und die Zeichenfolge `Markdown Table: Insert Column`

---

### Inhaltsverzeichnis erstellen

Verwende hierfür die Befehlspalette `STRG+UMSCHALT+P` und die Zeichenfolge `Markdown All in One: Create Table of Contents`

Das erstellte Inhaltsverzeichnis ist:

- GitHub-kompatibel
- enthält die Ebenen H2–H4
- verwendet kein Auto-Update

📌 Nach der Markdown Bearbeitung muss das Inhaltsverzeichnis manuell aktualisiert werden.

## Stilrichtlinien

### Tabellen Arbeitsanweisung, grundsätzliches

---

#### Zellinhalte, kurz und präzise

Tabellenzellen sollen möglichst kurze Inhalte enthalten:

- Kennzeichen
- Status
- Datum
- kurze Bezeichnungen
- knappe Bemerkungen

Nicht geeignet sind:

- lange Fließtexte
- ganze Absätze
- komplizierte Argumentationen

---

#### Mehrzeilige Inhalte

Echte mehrzeilige Tabellenzellen unterstützt Markdown nicht direkt.  
Zulässige Lösung:

``` markdown
| ID | Beschreibung |
|----|--------------|
| 1  | Zeile 1<br>Zeile 2<br>Zeile 3 |
```

Empfehlung:

- Für kurze Umbrüche: `<br>`
- Für längere Inhalte: Tabelle vermeiden oder auf mehrere Zeilen aufteilen

---

#### Listen innerhalb von Zellen

Wenn nötig, können Listen mit `<br>` angedeutet werden:

```markdown
| ID | Punkte |
|----|--------|
| 1  | - Punkt A<br>- Punkt B<br>- Punkt C |
```

---

#### Pipe-Zeichen in Zellen

Das Zeichen `|` trennt Spalten.  
Wenn es als Inhalt erscheinen soll, muss es maskiert oder vermieden werden.

Beispiel:

```markdown
\|
```

---

#### Basisverfahren der Tabellenbearbeitung

Empfohlenes Vorgehen:

1. Grundtabelle anlegen
2. Cursor in die Tabelle setzen
3. mit `Tab` zwischen Feldern springen
4. Datenzeilen durch Duplizieren erweitern
5. zusätzliche Spalten bei Bedarf mit der Erweiterung einfügen

---

### Datumsformat

Datumsangaben sollten im ISO-Format geschrieben werden:

```text
YYYY-MM-DD
```

Beispiel:

```text
2026-03-19
```

Begründung:

- maschinenfreundlich
- sortierbar
- eindeutig
- archivtauglich
- exporttauglich

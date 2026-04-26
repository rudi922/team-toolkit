# Verbindliche PowerShell-7-Entwicklungsrichtlinie

🪧 **Geltungsbereich:** Neue und überarbeitete PowerShell-7-Skripte  
🏷️ **Zielplattform:** PowerShell 7+  
📌 **Grundsatz:** Streng typisiert, klar benannt, modular aufgebaut, Unicode-fähig, reproduzierbar und technisch nachvollziehbar.  
🗓️ **Stand:** 2026-04-21 09:15:28  

UTF-8 signal: ʘ‿ʘ-Grüß Gott–Ça va?–¿Qué tal?–Привет–你好–שלום –नमस्ते–مرحبا
---

## 1. Zielsetzung

Diese Richtlinie definiert die verbindlichen Entwicklungsregeln für PowerShell-7-Skripte.  
Sie dient der einheitlichen Erstellung, Pflege und Prüfung von Skripten mit Schwerpunkt auf:

- Lesbarkeit
- Wartbarkeit
- technischer Robustheit
- reproduzierbarem Verhalten
- Crossplattform-Fähigkeit
- sauberer Fehlererkennung
- sicherer Unicode-Verarbeitung

---

## 2. Plattform und Version

- Zielplattform ist **PowerShell 7 oder höher**.
- PowerShell 5 ist **nicht** die primäre Zielplattform dieser Richtlinie.
- Falls ein Skript zwingend PowerShell 7 voraussetzt, soll dies früh geprüft werden.
- Bei nicht erfüllter Mindestversion soll das Skript **hart und eindeutig abbrechen**.

---

## 3. Variablenbenennung

### 3.1 Grundregel

Jede Variable erhält einen **typspezifischen Präfix**.  
Die Typinformation soll bereits im Variablennamen sichtbar sein.

### 3.2 Typische Präfixe

- `str...` = String
- `int...` = Integer / numerischer Ganzzahltyp
- `bln...` = Boolean
- `arr...` = Array
- `strArr...` = String-Array
- `obj...` = Objekt
- `ref...` = Referenzvariable / `[ref]`
- `htb...` = Hashtable oder Mapping-Struktur

### 3.3 Beispiele

```powershell
[string]   $strName = ''
[int]      $intCount = 0
[bool]     $blnSuccess = $false
[string[]] $strArrFiles = @()
[object]   $objResult = $null
```

### 3.4 Verbot

- **Keine Unicode-Zeichen in Variablennamen**
- keine unklaren oder generischen Bezeichner ohne Typbezug
- keine unnötig kryptischen Kurzformen

---

## 4. Typisierung

- Variablen sollen **explizit typisiert** werden.
- Typen sollen im Code deutlich sichtbar sein.
- Auch bei Collections und Rückgabestrukturen ist eine klare Typisierung anzustreben.
- Lose, implizite Typwechsel sind zu vermeiden.

Bevorzugt werden klare Typangaben wie zum Beispiel:

```powershell
[System.String]
[System.Boolean]
[System.Int32]
[System.Int64]
[System.String[]]
```

---

## 5. Deklarationsprinzip

- Variablen sollen **geordnet und sichtbar** deklariert werden.
- Globale oder scriptweite Variablen gehören in einen klaren Initialisierungsbereich.
- Lokale Variablen einer Funktion gehören in einen **Deklarationsblock am Beginn der Funktion**.
- Arbeitsvariablen dürfen nicht ungeordnet mitten im Programmfluss entstehen.
- Bereits deklarierte Variablen sollen nach Möglichkeit gezielt wiederverwendet werden.

**Hinweis:** Auch Schleifenvariablen müssen im Deklarationsblock deklariert werden.

**Zweck:**

- Die Deklaration im Deklarationsblock dient dem Auffinden von Late-Bindings die durch Schreibfehler entstehen.
- Deklarationsblöcke dienen als Übersichten, um das Refactoring zu ermöglichen und zu kontrollieren.

---

## 6. Skriptstruktur

Ein PowerShell-7-Skript soll eine klare technische Struktur besitzen.

Empfohlene Grundstruktur:

1. Headerblock
2. Synopsis / Description / Notes
3. Versionsangabe
4. Param-Block
5. Initialisierung
6. Hilfsfunktionen
7. Fachfunktionen / STEP-Funktionen
8. Hauptablauf / Entry Point
9. definierte Exit-Code-Behandlung

Monolithische, unstrukturierte Skripte sind zu vermeiden.

---

## 7. Header und Versionierung

Jedes Skript soll einen klaren Headerblock besitzen.

Zusätzlich soll eine sichtbare Versionszeile enthalten sein im Format:

```text
# Version: YYYY-MM-DD HH:MM
```

Ziel:

- eindeutige Identifikation der laufenden Fassung
- bessere Nachvollziehbarkeit
- saubere Unterstützung von Debugging und Betrieb

---

## 8. Fehlerverhalten

Fehler sollen früh, klar und reproduzierbar erkannt werden.

Verbindliche Grundsätze:

- `Set-StrictMode -Version Latest`
- `$ErrorActionPreference = 'Stop'`

Ziel:

- keine stillen Folgefehler
- keine verdeckten Null- oder Typfehler
- eindeutiger Abbruch bei technisch fehlerhaftem Zustand

---

## 9. Unicode und Kodierung

### 9.1 Grundsatz

PowerShell 7 ist Unicode-fähig.  
Es gibt **keinen generellen Grund**, in PowerShell-7-Crossplattform-Skripten auf Unicode in Konsolenausgaben zu verzichten.

### 9.2 Verbindliche Regel

- Unicode-Ausgaben in Konsole und Terminal sind **zulässig und fachlich gewollt**.
- Dies gilt insbesondere dann, wenn:
  - multilinguale Daten verarbeitet werden,
  - Datenbankinhalte Unicode enthalten,
  - die korrekte Zeichenkettenausgabe geprüft werden muss,
  - Terminal- oder Encoding-Probleme früh sichtbar gemacht werden sollen.

### 9.3 Wichtige Folgerung

Das **sichtbare Scheitern** einer Unicode-Ausgabe im Terminal ist ein relevanter technischer Hinweis und soll **nicht künstlich verborgen** werden.

Unicode-Dekorationen oder gezielte Unicode-Testausgaben können deshalb sinnvoll sein, wenn dadurch Encoding-Probleme oder Darstellungsfehler früh erkannt werden.

### 9.4 Dateikodierung

- Skripte sind bevorzugt als **UTF-8** abzulegen.
- Konsolenausgabe und Dateiausgabe sollen bewusst auf Unicode-Fähigkeit ausgelegt sein.
- Encoding-Probleme sollen nicht stillschweigend umgangen, sondern erkannt und sauber behandelt werden.

---

## 10. Konsolenausgabe

### 10.1 Normalbetrieb

- Die Konsole soll im Standardbetrieb **ruhig** bleiben.
- Es sollen nur die notwendigen Informationen ausgegeben werden.

### 10.2 Debugbetrieb

- Detaillierte technische Ausgaben gehören in den Debugmodus.
- Dafür sind bevorzugt PowerShell-Standardmechanismen zu verwenden.

### 10.3 Unicode-Ausgabe

- Unicode in Konsolenausgaben ist erlaubt.
- Dekorative oder diagnostische Unicode-Ausgaben sind zulässig, sofern sie dem technischen Zweck nicht entgegenstehen.
- Unicode darf nicht aus Prinzip unterdrückt werden.

---

## 11. PowerShell-Standardmechanismen

Eigene Sonderlogik ist zu vermeiden, wenn PowerShell bereits saubere Standardmechanismen bereitstellt.

Bevorzugt zu verwenden:

- `-Debug`
- `-WhatIf`
- `-Confirm:$false`
- `SupportsShouldProcess`

Ziel:

- erwartbares Verhalten
- gute Bedienbarkeit
- saubere Einbindung in Standard-Workflows

---

## 12. Logging

Logging ist Bestandteil professioneller Skriptführung.

Verbindliche Anforderungen:

- Logdatei mit klar bestimmtem Speicherort
- Zeitstempel in Logeinträgen
- Protokollierung von Start, Ende, Fehlern und wesentlichen Statusmeldungen
- Logging darf nicht durch Simulationsmodi unbrauchbar werden

Ein Skript soll auch dann noch technisch nachvollziehbar bleiben, wenn es im `WhatIf`-Modus läuft.

---

## 13. Modularisierung und STEP-Prinzip

Fachlogik ist in klar getrennte Verarbeitungsschritte aufzuteilen.

Bevorzugtes Muster:

- `Invoke-STEP01`
- `Invoke-STEP02`
- weitere `Invoke-STEPnn`
- übergeordnete Steuerfunktion, zum Beispiel `Invoke-MainOperation`

Ziel:

- bessere Testbarkeit
- bessere Wartbarkeit
- klare Verantwortlichkeiten im Code

---

## 14. Collections, Objekte und Referenzübergabe

Für komplexe Auflistungen und korrespondierende Datenstrukturen gilt:

- Daten sollen als zusammenhängende Objekte behandelt werden
- unnötige Zerlegung über die Pipeline ist zu vermeiden
- komplexe Sammlungen können bevorzugt per `[ref]` übergeben werden, wenn dies die Strukturwahrung verbessert

Ziel:

- keine unbeabsichtigte Umformung komplexer Daten
- klar kontrollierter Datenfluss
- robuste Architektur bei Mehrfachverwendung derselben Struktur

---

## 15. Datenmodelle

- Eigene Klassen sind zu verwenden, wenn ein fachlich stabiles Datenmodell vorliegt.
- Generische .NET-Collections sind losen Mischstrukturen vorzuziehen, wenn dadurch Typklarheit und Wartbarkeit steigen.
- Datenstrukturen sollen fachlich nachvollziehbar und technisch belastbar sein.

---

## 16. Exit-Codes

Ein Skript muss für Menschen und aufrufende Systeme eindeutig auswertbar sein.

- `exit 0` nur bei echtem Erfolg
- `exit != 0` bei technischem oder fachlichem Fehler
- Teilergebnisse dürfen nicht zu einem irreführenden Erfolgscode führen

Das ist besonders wichtig für:

- Automatisierung
- Scheduler
- CI/CD-nahe Abläufe
- Folgeprozesse

---

## 17. Sicherheit und Bestätigung

- Reale Änderungen sollen bei Bedarf durch Standardmechanismen absicherbar sein.
- Interaktive Sicherheitsabfragen sind sinnvoll, sofern sie sauber abschaltbar bleiben.
- Für unbeaufsichtigte Läufe müssen standardkonforme, kontrollierte Verfahren zur Unterdrückung möglich sein.

---

## 18. Debug- und Silent-Verhalten

### 18.1 Debug

- Ausführliche technische Informationen sollen über `-Debug` verfügbar sein.

### 18.2 Silent

- Wo fachlich sinnvoll, soll ein `-Silent`-Schalter vorgesehen werden, um Fortschrittsanzeigen oder nicht notwendige Ausgaben zu unterdrücken.

### 18.3 Grundsatz

- **Default = ruhig**
- **Debug = ausführlich**
- **Silent = minimal**

---

## 19. Crossplattform-Grundsätze

PowerShell-7-Skripte sollen grundsätzlich crossplattform gedacht werden.

Daraus folgen:

- Windows-Sonderlogik nur bei echtem Bedarf
- systemnahe Pfade möglichst plattformneutral ermitteln
- COM-spezifische Logik nur unter Windows und nur geschützt einsetzen
- keine unnötige Bindung an Windows-Verhalten in allgemeinen Skripten

---

## 20. Empfohlene Qualitätsmerkmale neuer Skripte

Ein neues Skript entspricht dieser Richtlinie, wenn es insbesondere folgende Merkmale erfüllt:

- PowerShell 7+
- klarer Headerblock
- typspezifische Variablenpräfixe
- explizite Typisierung
- geordnete Deklarationsblöcke
- Unicode-fähige Auslegung
- StrictMode und hartes Fehlerverhalten
- Nutzung von `-Debug`, `-WhatIf`, `-Confirm:$false`
- ruhiger Standardbetrieb
- Logging
- modularer STEP-Aufbau
- belastbare Exit-Codes
- Crossplattform-Ausrichtung
- gezielte Windows-Sonderbehandlung nur bei Bedarf

---

## 21. Kurzform der Leitlinie

Die PowerShell-7-Entwicklung erfolgt nach folgendem Leitbild:

**streng typisiert, klar benannt, modular aufgebaut, Unicode-fähig, PowerShell-nativ steuerbar, reproduzierbar dokumentiert und technisch belastbar.**

Der zentrale Stilmarker lautet:

**Jede Variable erhält einen typspezifischen Präfix, und Unicode wird in PowerShell 7 bewusst unterstützt statt pauschal vermieden.**

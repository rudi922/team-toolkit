<#
.SYNOPSIS
    🏷️ Muster-Skriptvorlage für PowerShell 7.
    📚 PowerShell 7 / UTF-8 ohne BOM

.DESCRIPTION
    🧩 Dieses Skript ist eine Vorlage mit folgender Funktionalität:
    - Sicherheitsabfrage vor der Skriptausführung, die für unbeaufsichtigte Läufe unterdrückt werden kann
    - Fehlerverfolgung
    - detaillierte Log-Ausgabe
    - Fortschrittsanzeige für Detailprozesse
    - Schalter für die Verwendung des System-Temp-Pfades für die Logdatei
    - Schalter für unbeaufsichtigte Skriptausführung über den Standardparameter -Confirm:$false
    - Schalter für ausführliche Debug-Ausgaben über den Standardparameter -Debug
    - Schalter für den Simulationsmodus über den Standardparameter -WhatIf

.NOTES
    ⚖️ Lizenz: Frei nutzbar, kopierbar und veränderbar, auf eigene Gefahr und ohne Gewährleistung.
    🧑‍🔬 Autor: Dipl.-Ing. Alfred Menzel
    📜 Historie:
          2026-04-02 16:35:00  Finale Bereinigung: ref-Uebergabe als Architekturprinzip fuer komplexe Auflistungen dokumentiert, Kommentare konsolidiert
          2026-04-02 16:20:00  Umstellung auf ref-Uebergabe fuer die Korrespondenz komplexer Auflistungen zwischen Prozeduren; Enumerationseffekte der Pipeline vermieden
          2026-04-02 16:00:00  Umstellung auf SortedList[Int64, clsDetailItem], Rückgabehärtung gegen Enumerationseffekte ergänzt
          2026-04-01 16:10:00  STEP02 als Folgefunktion ergänzt, Statusmodell vereinfacht, Kommentare auf echte Umlaute umgestellt
          2026-04-01 15:05:00  Vorlage auf echte PowerShell-7-Crossplatform-Basis umgestellt
          2026-03-31 14:30:54  Windows-Test abgeschlossen
          2026-03-31 08:19:29  Beispiele angelegt
    🛠️ ToDo: -

.EXAMPLE
    scriptname.ps1 -LogToTemp
    - optionaler Schalter
      Wenn der Schalter gesetzt ist, wird die Logdatei in den temporären Pfad
      des Systems geschrieben. Andernfalls wird die Logdatei im Ordner der
      Skriptdatei erstellt.
      Der Pfad zur Logdatei wird in der Abschlussmeldung angezeigt.

.EXAMPLE
    scriptname.ps1 -Confirm:$false
    - optionaler Standardparameter
    - unterdrückt die Sicherheitsabfrage mit Abbruchmöglichkeit
      Die Unterdrückung der Abfrage ermöglicht die unbeaufsichtigte Skriptausführung.

.EXAMPLE
    scriptname.ps1 -Debug
    - optionaler Standardparameter
      Es werden ausführliche Ausgaben zur Fehlersuche ausgegeben.

.EXAMPLE
    scriptname.ps1 -WhatIf
    - optionaler Standardparameter
    - simuliert die Ausführung des Skriptes.
      Es werden keinerlei Änderungen durchgeführt.
#>

# UTF-8 signal: ʘ‿ʘ Grüß Gott – Ça va? – ¿Qué tal? – Привет – 你好 – שלום – नमस्ते – مرحبا

# ---------------------------------------------------------------
# 🛡️ Skript-Ebene: ShouldProcess aktivieren
# ---------------------------------------------------------------
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Hier bei Bedarf weitere Skriptparameter anlegen.

    # Schalter: Logdatei im System-Temp-Pfad ablegen.
    # Wenn NICHT gesetzt: Logdatei im Verzeichnis der Skriptdatei ablegen.
    [Parameter(Mandatory = $false)]
    [switch] $LogToTemp
)

# ---------------------------------------------------------------
# 📦 Skript-Variablen, Teil 1 (~ Variablen für die frühe Initialisierung)
# ---------------------------------------------------------------
[System.String]  $script:strVersion       = '🗓️ 2026-04-01 16:10:00'
[System.Boolean] $script:blnShouldProcess = $false
[System.String]  $script:strMessage       = ''
[System.String]  $script:strAnswer        = 'N'

# ---------------------------------------------------------------
# 🟡 Vorwarnung des Skripts
# ---------------------------------------------------------------
$script:strMessage = @"
* Skriptvorlage *

Skriptablauf:
- STEP01: Inventarliste aufbauen
- STEP02: Folgeprozess je Detailobjekt ausführen

Das Skript schreibt eine Protokolldatei und zeigt deren Pfad nach dem Skriptende an.

👉 Tipp:
Verwende das Cmdlet Get-Help, um die möglichen Kommandozeilenparameter anzuzeigen.
> Get-Help scriptname.ps1 -Full

📌 Beachte: Nur mit PowerShell 7 lauffähig!
Version: $script:strVersion

"@
Write-Host $script:strMessage -ForegroundColor Yellow

# ---------------------------------------------------------------
# Sicherheitsabfrage
# - Default = No (Enter bricht ab)
# - keine Abfrage bei:
#   * -WhatIf
#   * -Confirm:$false
# ---------------------------------------------------------------
if (
    -not $WhatIfPreference -and
    $ConfirmPreference -ne 'None'
) {
    # Globale Abfrage: Es wird entweder ALLES oder NICHTS ausgeführt.
    $script:strAnswer = Read-Host 'Soll die Verarbeitung ausgeführt werden? (y/N)'

    if ($script:strAnswer -ne 'y') {
        $script:strMessage = 'Skript-Ausführung abgebrochen (Default = No).'
        Write-Host "🟡 $script:strMessage" -ForegroundColor Yellow
        exit 1
    }
}

# ---------------------------------------------------------------
# 🧩 Systemprüfungen
# ---------------------------------------------------------------

# Die Versionsprüfung ist vorsorglich für spätere Entwicklungen implementiert.
# Unter Windows/PowerShell 5 wird diese Prüfung in vielen Fällen gar nicht mehr
# erreicht, weil das Skript aufgrund des Encodings bereits vorher am Parser scheitern kann.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "FATAL: Requires PowerShell 7+. Current version: $($PSVersionTable.PSVersion)"
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    # UTF-8-Ausgabekodierung aktivieren.
    [System.Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
}
catch {
    throw 'FATAL: UTF-8 console output could not be enabled.'
}

# Diese Prüfung bleibt bewusst erhalten.
# Hintergrund:
# - Unter Windows ist es möglich, dass eine Konsole zwar startet, aber trotzdem
#   keine brauchbare UTF-8-Ausgabe liefert.
# - Unter Linux ist diese zusätzliche Prüfung im Regelfall unkritisch.
# - Die Redundanz unter Linux verschlechtert die Zuverlässigkeit nicht.
if ($IsWindows -and [System.Console]::OutputEncoding.WebName -ne 'utf-8') {
    throw 'FATAL: Console does not support UTF-8. Aborting.'
}

# ---------------------------------------------------------------
# 📦 Skript-Variablen, Teil 2
# ---------------------------------------------------------------
[System.String]  $script:strScriptPath  = $PSCommandPath
[System.String]  $script:strScriptName  = Split-Path -Leaf $PSCommandPath
[System.String]  $script:strScriptDir   = Split-Path -Parent $PSCommandPath
[System.String]  $script:strLogDir      = $script:strScriptDir
[System.String]  $script:strTimeStamp   = Get-Date -Format 'yyyyMMdd_HHmmss'
[System.String]  $script:strLogFileName = '{0}_{1}.log' -f [System.IO.Path]::GetFileNameWithoutExtension($script:strScriptName), $script:strTimeStamp
[System.String]  $script:strLogFile     = ''
[System.Boolean] $script:blnMainSuccess = $false

# Log-Verzeichnis bestimmen.
# Standard:
# - Logdatei im Verzeichnis der Skriptdatei
# Optional:
# - Logdatei im systemneutral ermittelten Temp-Pfad
#
# WICHTIG:
# [System.IO.Path]::GetTempPath() ist plattformneutral und liefert unter Windows,
# Linux und macOS den jeweils passenden temporären Basisordner.
# Damit vermeiden wir Betriebssystem-Sonderfälle wie nur $env:TEMP oder nur $env:TMPDIR.
if ($LogToTemp) {
    $script:strLogDir = [System.IO.Path]::GetTempPath()

    # Sicherheitsnetz:
    # Falls aus irgendeinem Grund ein leerer oder ungültiger Temp-Pfad geliefert wird,
    # wird auf das Skriptverzeichnis zurückgefallen.
    if ([System.String]::IsNullOrWhiteSpace($script:strLogDir)) {
        $script:strLogDir = $script:strScriptDir
    }
}

$script:strLogFile = Join-Path -Path $script:strLogDir -ChildPath $script:strLogFileName

# ---------------------------------------------------------------
# 📝 Logging-Funktionen
# - WhatIf wird bewusst übersteuert, damit Logging immer erfolgt
# ---------------------------------------------------------------
function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strLevel,

        [Parameter(Mandatory = $true)]
        [System.String] $strMessage
    )

    # Die Zielauflistung wird per [ref] an diese Prozedur uebergeben.
    # Dadurch entspricht die Datenuebergabe funktional einer ByRef-Uebergabe,
    # wie man sie aus Visual Basic kennt.

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strTime = ''
    [System.String] $strLine = ''

    # Zeitstempel für die Logzeile erzeugen.
    $strTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    # Eine Logzeile bleibt bewusst einzeilig.
    # Das erleichtert späteres Parsen, Filtern und Importieren.
    $strLine = '{0} [{1}] {2}' -f $strTime, $strLevel, $strMessage

    # Terminal-Ausgabe nur dann, wenn -Debug aktiv gesetzt wurde.
    Write-Debug $strLine

    # Logdatei wird unabhängig von -WhatIf aktualisiert.
    Add-Content -Path $script:strLogFile -Value $strLine -Encoding utf8 -WhatIf:$false
}

function Write-LogError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord] $objErrorRecord
    )

    # STEP02 verarbeitet die korrespondierende Auflistung direkt "in place".
    # Es erfolgt bewusst KEINE Rueckgabe der komplexen Auflistung ueber die
    # Pipeline. Das ist Teil des Architekturprinzips dieser Vorlage.

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strMsg = ''
    [System.String] $strStack = ''
    [System.String] $strContext = ''

    # Fehlerdetails extrahieren.
    $strMsg = 'Message: {0}' -f $objErrorRecord.Exception.Message
    $strStack = 'Stack:   {0}' -f $objErrorRecord.ScriptStackTrace

    # Optionaler Kontext, falls vorhanden.
    try {
        $strContext = [System.String] $objErrorRecord.Exception.Data['Context']
    }
    catch {
        $strContext = ''
    }

    if (-not [System.String]::IsNullOrWhiteSpace($strContext)) {
        Write-LogMessage -strLevel 'ERROR' -strMessage ('Context: {0}' -f $strContext)
    }

    # Terminal-Ausgabe nur dann, wenn -Debug aktiv gesetzt wurde.
    Write-Debug "ERROR $strMsg"
    Write-Debug "ERROR $strStack"

    # Fehler in die Logdatei schreiben.
    Write-LogMessage -strLevel 'ERROR' -strMessage $strMsg
    Write-LogMessage -strLevel 'ERROR' -strMessage $strStack
}

# ---------------------------------------------------------------
# 🧪 Integritätsprüfung des Skripts
# - Erkennt typische Fehler wie unvollständige Dateien oder falsche Versionen frühzeitig.
# ---------------------------------------------------------------
function Test-ScriptIntegrity {
    [CmdletBinding()]
    param()

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String[]] $strArrRequiredFunctions = @(
        'Invoke-STEP01',
        'Invoke-STEP02',
        'Invoke-MainOperation',
        'Write-LogMessage'
    )

    [System.String] $strFunc = ''
    [System.Boolean] $blnOk = $true

    foreach ($strFunc in $strArrRequiredFunctions) {
        if (-not (Get-Command -Name $strFunc -CommandType Function -ErrorAction SilentlyContinue)) {
            $blnOk = $false

            try {
                Write-LogMessage -strLevel 'FATAL' -strMessage ('INTEGRITY | Fehlende Funktion: {0}' -f $strFunc)
            }
            catch {
                # Wenn Logging nicht möglich ist, erfolgt zumindest eine Host-Ausgabe.
            }

            Write-Host ('🔴 INTEGRITY | Fehlende Funktion: {0}' -f $strFunc) -ForegroundColor Red
        }
    }

    if (-not $blnOk) {
        Write-Host '🔴 INTEGRITY | Skript ist unvollständig oder es wurde NICHT die erwartete Datei ausgeführt.' -ForegroundColor Red
        Write-Host ('🔴 INTEGRITY | Hinweis: Prüfe Pfad/Version im Log: ScriptPath=''{0}'' Version=''{1}''' -f $script:strScriptPath, $script:strVersion) -ForegroundColor Red
        exit 2
    }
}

# ---------------------------------------------------------------
# 🔄 Hilfsfunktionen
# ---------------------------------------------------------------
# - derzeit keine

# ---------------------------------------------------------------
# Klassen
# ---------------------------------------------------------------
class clsDetailItem {
    [System.String] $strIDx
    [System.String] $strProcessingStatus
    [System.String] $strErrorReason
}

# ---------------------------------------------------------------
# STEP01: Inventar aufbauen
# ---------------------------------------------------------------
function Invoke-STEP01 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ref] $refHtbDetailObjectList01
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strContext = 'Invoke-STEP01()'
    [System.String] $strLogLine = ''
    [System.String] $strMessageMode = ''

    [System.Int32] $intIdxItem = 0
    [System.Int32] $intTotal = 0
    [System.Int64] $intKeyItem = 0

    [System.Collections.Generic.SortedList[System.Int64, clsDetailItem]] $htbDetailObjectList01 = [System.Collections.Generic.SortedList[System.Int64, clsDetailItem]]::new()
    [clsDetailItem] $objDetailItem = $null

    try {
        $strMessageMode = if ($WhatIfPreference) { 'SIMULATED' } else { 'ACTIVE' }

        $strLogLine = '{0} START | Mode={1}' -f $strContext, $strMessageMode
        Write-LogMessage -strLevel 'INFO' -strMessage $strLogLine

        $intTotal = 10

        for ($intIdxItem = 1; $intIdxItem -le $intTotal; $intIdxItem++) {
            $intKeyItem = [System.Int64] $intIdxItem

            $objDetailItem = [clsDetailItem]::new()
            $objDetailItem.strIDx = [System.String] $intIdxItem
            $objDetailItem.strProcessingStatus = 'OK'
            $objDetailItem.strErrorReason = ''

            $htbDetailObjectList01.Add($intKeyItem, $objDetailItem)

            Start-Sleep -Milliseconds 250

            Write-Progress -Id 2 -Activity "👣 $strContext Inventaraufbau" -Status ('Item {0}/{1}' -f $intIdxItem, $intTotal) -PercentComplete ([System.Int32](100 * $intIdxItem / [System.Math]::Max(1, $intTotal)))
        }

        Write-Progress -Id 2 -Completed

        $refHtbDetailObjectList01.Value = $htbDetailObjectList01

        $strLogLine = '{0} ENDE | Count={1}' -f $strContext, $htbDetailObjectList01.Count
        Write-LogMessage -strLevel 'INFO' -strMessage $strLogLine
        return
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
    finally {
        # ---------------------------------------------------------------------
        # OPTIONALER COM-FREIGABEBLOCK
        # ---------------------------------------------------------------------
        # Diese Vorlage ist bewusst plattformneutral aufgebaut.
        # Daher wird hier standardmäßig KEIN COM-Objekt verwendet.
        #
        # Falls später in einem WINDOWS-SPEZIFISCHEN Skriptteil echte COM-Objekte
        # eingesetzt werden (z. B. Outlook, Excel, Word), kann folgender Block
        # aktiviert und an der passenden Stelle verwendet werden.
        #
        # WICHTIG:
        # - Nur unter Windows sinnvoll
        # - Nur für echte COM-Objekte sinnvoll
        # - In der allgemeinen Crossplatform-Vorlage deshalb bewusst deaktiviert
        #
        # if ($IsWindows -and $null -ne $comObject) {
        #     [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObject) | Out-Null
        # }
    }
}

# ---------------------------------------------------------------
# STEP02: Folgeprozess je Detailobjekt
# ---------------------------------------------------------------
function Invoke-STEP02 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.SortedList[System.Int64, clsDetailItem]] $htbDetailObjectList01
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strContext = 'Invoke-STEP02()'
    [System.String] $strLogLine = ''
    [System.String] $strMessageMode = ''
    [System.String] $strErrorText = ''

    [System.Int32] $intIdxItem = 0
    [System.Int32] $intTotal = 0
    [System.Int64] $intKeyItem = 0
    [System.Int64] $intLoopKeyItem = 0

    [clsDetailItem] $objDetailItem = $null

    try {
        $strMessageMode = if ($WhatIfPreference) { 'SIMULATED' } else { 'ACTIVE' }

        $strLogLine = '{0} START | Mode={1} | Count={2}' -f $strContext, $strMessageMode, $htbDetailObjectList01.Count
        Write-LogMessage -strLevel 'INFO' -strMessage $strLogLine

        $intTotal = $htbDetailObjectList01.Count

        foreach ($intLoopKeyItem in $htbDetailObjectList01.Keys) {
            $intIdxItem++
            $intKeyItem = $intLoopKeyItem
            $objDetailItem = $htbDetailObjectList01[$intKeyItem]

            if ($objDetailItem.strProcessingStatus -eq 'ERROR') {
                $strLogLine = '{0} SKIP | Key={1} | IDx={2} | Reason={3}' -f $strContext, $intKeyItem, $objDetailItem.strIDx, $objDetailItem.strErrorReason
                Write-LogMessage -strLevel 'WARN' -strMessage $strLogLine

                Write-Progress -Id 3 -Activity "👣 $strContext Folgeprozess" -Status ('Item {0}/{1} übersprungen' -f $intIdxItem, $intTotal) -PercentComplete ([System.Int32](100 * $intIdxItem / [System.Math]::Max(1, $intTotal)))
                continue
            }

            try {
                Start-Sleep -Milliseconds 250
                $objDetailItem.strProcessingStatus = 'OK'

                $strLogLine = '{0} OK | Key={1} | IDx={2}' -f $strContext, $intKeyItem, $objDetailItem.strIDx
                Write-LogMessage -strLevel 'INFO' -strMessage $strLogLine
            }
            catch {
                $strErrorText = [System.String] $_.Exception.Message
                $objDetailItem.strProcessingStatus = 'ERROR'
                $objDetailItem.strErrorReason = 'STEP02: {0}' -f $strErrorText

                $strLogLine = '{0} ERROR | Key={1} | IDx={2} | Reason={3}' -f $strContext, $intKeyItem, $objDetailItem.strIDx, $objDetailItem.strErrorReason
                Write-LogMessage -strLevel 'ERROR' -strMessage $strLogLine
            }

            Write-Progress -Id 3 -Activity "👣 $strContext Folgeprozess" -Status ('Item {0}/{1}' -f $intIdxItem, $intTotal) -PercentComplete ([System.Int32](100 * $intIdxItem / [System.Math]::Max(1, $intTotal)))
        }

        Write-Progress -Id 3 -Completed

        $strLogLine = '{0} ENDE | Count={1}' -f $strContext, $htbDetailObjectList01.Count
        Write-LogMessage -strLevel 'INFO' -strMessage $strLogLine
        return
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
    finally {
        # ---------------------------------------------------------------------
        # OPTIONALER COM-FREIGABEBLOCK
        # ---------------------------------------------------------------------
        # if ($IsWindows -and $null -ne $comObject) {
        #     [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObject) | Out-Null
        # }
    }
}

# ---------------------------------------------------------------
# 🧭 Hauptoperation (Orchestrator)
# ---------------------------------------------------------------
function Invoke-MainOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ref] $refHtbDetailObjectList01
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strContext = 'Invoke-MainOperation()'
    [System.String] $strMessageMode = ''
    [System.String] $strLogLine = ''
    [System.String] $strProgMainMessage = '🥁 Hauptprozess Invoke-MainOperation()'
    [System.String] $strProgMainStatus = ''

    [System.Int64] $intDetailsOk = 0
    [System.Int64] $intDetailsErr = 0
    [System.Int64] $intDetailsTotal = 0
    [System.Int64] $intLoopKeyItem = 0

    [System.Diagnostics.Stopwatch] $objSw = $null
    [System.Collections.Generic.SortedList[System.Int64, clsDetailItem]] $htbDetailObjectList01 = [System.Collections.Generic.SortedList[System.Int64, clsDetailItem]]::new()
    [clsDetailItem] $objDetailItem = $null

    # Architekturprinzip:
    # Die Hauptoperation steuert die Korrespondenz komplexer Auflistungen zwischen
    # Prozeduren ausschliesslich per [ref]. Dadurch bleibt die uebergebene .NET-
    # Auflistung als zusammenhaengendes Objekt erhalten und wird nicht durch die
    # PowerShell-Pipeline enumeriert oder implizit umgeformt.

    try {
        $strMessageMode = if ($WhatIfPreference) { 'SIMULATED' } else { 'ACTIVE' }

        $strLogLine = '{0} START | Mode={1} | LogToTemp=''{2}''' -f $strContext, $strMessageMode, $LogToTemp
        Write-LogMessage -strLevel 'INFO' -strMessage $strLogLine

        $strProgMainStatus = 'Hauptprozess initialisiert'
        Write-Progress -Id 1 -Activity $strProgMainMessage -Status $strProgMainStatus -PercentComplete 10

        if ($WhatIfPreference) {
            $strLogLine = '{0} START | WriteOnSystem=FALSE' -f $strContext
        }
        else {
            $strLogLine = '{0} START | WriteOnSystem=TRUE' -f $strContext
        }
        Write-LogMessage -strLevel 'INFO' -strMessage $strLogLine

        # -------------------------------------------------------
        # STEP01
        # -------------------------------------------------------
        $strLogLine = '{0} CALL STEP01' -f $strContext
        Write-LogMessage -strLevel 'INFO' -strMessage $strLogLine

        $objSw = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-STEP01 -refHtbDetailObjectList01 ([ref] $htbDetailObjectList01)
        $objSw.Stop()
        Write-LogMessage -strLevel 'INFO' -strMessage ('TIME STEP01 = {0}' -f $objSw.Elapsed)

        $strProgMainStatus = 'STEP01 abgeschlossen'
        Write-Progress -Id 1 -Activity $strProgMainMessage -Status $strProgMainStatus -PercentComplete 40

        # -------------------------------------------------------
        # STEP02
        # -------------------------------------------------------
        $strLogLine = '{0} CALL STEP02' -f $strContext
        Write-LogMessage -strLevel 'INFO' -strMessage $strLogLine

        $objSw = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-STEP02 -htbDetailObjectList01 $htbDetailObjectList01
        $objSw.Stop()
        Write-LogMessage -strLevel 'INFO' -strMessage ('TIME STEP02 = {0}' -f $objSw.Elapsed)

        $strProgMainStatus = 'STEP02 abgeschlossen'
        Write-Progress -Id 1 -Activity $strProgMainMessage -Status $strProgMainStatus -PercentComplete 70

        if ($null -ne $htbDetailObjectList01) {
            $intDetailsTotal = $htbDetailObjectList01.Count

            foreach ($intLoopKeyItem in $htbDetailObjectList01.Keys) {
                $objDetailItem = $htbDetailObjectList01[$intLoopKeyItem]

                if ($objDetailItem.strProcessingStatus -eq 'OK') {
                    $intDetailsOk++
                }
                elseif ($objDetailItem.strProcessingStatus -eq 'ERROR') {
                    $intDetailsErr++
                }
            }
        }

        Write-LogMessage -strLevel 'INFO' -strMessage ('SUMMARY | OK={0} | ERROR={1} | TOTAL={2}' -f $intDetailsOk, $intDetailsErr, $intDetailsTotal)

        Write-Progress -Id 1 -Activity $strProgMainMessage -Status 'Abgeschlossen' -PercentComplete 100
        Write-Progress -Id 1 -Completed

        # Ergebnis per [ref] an den Aufrufer zurueckgeben.
        # Auch hier bewusst KEINE Rueckgabe der komplexen Auflistung ueber die Pipeline.
        $refHtbDetailObjectList01.Value = $htbDetailObjectList01
        return
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
    finally {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        # ---------------------------------------------------------------------
        # OPTIONALER COM-FREIGABEBLOCK
        # ---------------------------------------------------------------------
        # if ($IsWindows -and $null -ne $comObject) {
        #     [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObject) | Out-Null
        # }
    }
}

# ---------------------------------------------------------------
# ▶ Skript-Einstiegspunkt
# ---------------------------------------------------------------
try {
    $script:strMessage = 'Script started.'

    Write-LogMessage -strLevel 'INFO' -strMessage ('ScriptPath=''{0}''' -f $script:strScriptPath)
    Write-LogMessage -strLevel 'INFO' -strMessage ('ScriptVersion=''{0}''' -f $script:strVersion)
    Test-ScriptIntegrity
    Write-LogMessage -strLevel 'INFO' -strMessage $script:strMessage

    # -------------------------------------------------------------------------
    # Deklarationen (EntryPoint)
    # -------------------------------------------------------------------------
    [System.Collections.Generic.SortedList[System.Int64, clsDetailItem]] $htbDetailObjectList01 = [System.Collections.Generic.SortedList[System.Int64, clsDetailItem]]::new()
    [System.Int32] $intDetailsErr = 0
    [System.Int64] $intLoopKeyItem = 0
    [clsDetailItem] $objDetailItem = $null

    # Hauptfunktion aufrufen.
    # Die komplexe korrespondierende Auflistung wird bewusst per [ref] uebergeben.
    # Das ist das festgelegte Architekturprinzip fuer diese Vorlage.
    Invoke-MainOperation -refHtbDetailObjectList01 ([ref] $htbDetailObjectList01)

    # Ergebnisbewertung:
    # - Auch wenn keine Exception auftritt, können in späteren Ausbaustufen in
    #   STEP01 .. STEPnn fachliche Detailfehler auftreten, die nur im Inventory
    #   markiert werden.
    # - In diesem Fall muss das Skript als FAILED gelten (ExitCode != 0), damit
    #   Aufrufer wie Aufgabenplanung, SQL Agent oder CI den Lauf korrekt bewerten.
    if ($null -eq $htbDetailObjectList01 -or $htbDetailObjectList01.Count -eq 0) {
        $intDetailsErr = 0
    }
    else {
        foreach ($intLoopKeyItem in $htbDetailObjectList01.Keys) {
            $objDetailItem = $htbDetailObjectList01[$intLoopKeyItem]

            if ($objDetailItem.strProcessingStatus -eq 'ERROR') {
                $intDetailsErr++
            }
        }
    }

    if ($intDetailsErr -gt 0) {
        $script:strMessage = 'Script finished with errors. ERROR={0}' -f $intDetailsErr
        Write-LogMessage -strLevel 'ERROR' -strMessage $script:strMessage
        Write-Host ('🔴 {0}' -f $script:strMessage) -ForegroundColor Red
        Write-Host ('📝 Logdatei: {0}' -f $script:strLogFile) -ForegroundColor Red
        exit 1
    }

    $script:strMessage = 'Hier die Zusammenfassung der Objektbearbeitung anzeigen.'
    Write-Host ('🟡 {0}' -f $script:strMessage) -ForegroundColor Yellow

    $script:strMessage = 'Script finished successfully.'
    Write-LogMessage -strLevel 'INFO' -strMessage $script:strMessage
    Write-Host ('🟢 {0}' -f $script:strMessage) -ForegroundColor Green

    $script:strMessage = 'Logfile: {0}' -f $script:strLogFile
    Write-Host $script:strMessage -ForegroundColor Yellow

    exit 0
}
catch {
    Write-LogError -objErrorRecord $_
    $script:strMessage = 'Script failed.'
    Write-LogMessage -strLevel 'FATAL' -strMessage $script:strMessage
    Write-Host ('🔴 {0}' -f $script:strMessage) -ForegroundColor Red
    Write-Host ('📝 Logdatei: {0}' -f $script:strLogFile) -ForegroundColor Red
    exit 1
}

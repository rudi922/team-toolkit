<#
.SYNOPSIS
    Zum Schutz personenbezogener Daten werden Namen und Bezeichnungen durch Platzhalter verschleiert.

    Konvertiert Markdown-Inhalte anhand einer zweispaltigen PSV-Mapping-Datei zwischen
    Klarbezeichnungen und Tokens.

.DESCRIPTION
    Für die Nutzung von Markdown-Dateien in Internetdiensten ermöglicht dieses Skript,
    schutzwürdige Textpassagen wie Personennamen, Aktenzeichen oder andere Bezeichnungen
    durch Platzhalter zu ersetzen und diese Platzhalter später wieder in die ursprünglichen
    Klarbezeichnungen zurückzuverwandeln.

    Die Zuordnung wird ausschließlich in einer PSV-Datei ohne Kopfzeile geführt.
    Jede verwertbare Mappingzeile besitzt exakt zwei Spalten:

        [[TOKEN]]|Klarbezeichnung

    Leerzeilen und Zeilen, die nach dem Trimmen mit # beginnen, werden ignoriert.
    Weitere PSV-Spalten sind nicht zulässig.

    Standardrichtung ohne -Clear:
        Klarbezeichnungen werden durch Tokens ersetzt.
        Ausgabedatei: <Eingangsdatei-ohne-.md>_foggy_yyyy-MM-dd_mmss.md

    Richtung mit -Clear:
        Tokens werden durch Klarbezeichnungen ersetzt.
        Ausgabedatei: <Eingangsdatei-ohne-.md>_clear_yyyy-MM-dd_mmss.md

    Die JSON-Konfiguration enthält die technisch erforderliche ConfigSchemaVersion sowie
    die vom Skript gepflegten Ausführungsinformationen LastExecutionDate und
    ExecuteDirection. ExecuteDirection enthält nach einem erfolgreichen realen Lauf
    den Wert foggy oder clear.

    Bei -Debug wird für jedes Mapping die Zuordnung von Token und Klarbezeichnung mit
    Write-Debug ausgegeben. Klarbezeichnungen werden bewusst nicht in die Logdatei
    geschrieben.

.PARAMETER InputMarkdownFile
    Pfad zur Markdown-Eingangsdatei.

    Ohne -Clear enthält die Datei Klarbezeichnungen, die durch Tokens ersetzt werden.
    Mit -Clear enthält die Datei Tokens, die durch Klarbezeichnungen ersetzt werden.

.PARAMETER MappingPsvFile
    Pfad zur PSV-Mapping-Datei ohne Kopfzeile. Jede verwertbare Zeile muss exakt dem
    Aufbau Token|Klarbezeichnung entsprechen.

.PARAMETER Clear
    Aktiviert die Rückumwandlung von Tokens in Klarbezeichnungen.
    Ohne -Clear: Klarbezeichnung -> Token und Ausgabesuffix _foggy_yyyy-MM-dd_mmss.md.
    Mit -Clear: Token -> Klarbezeichnung und Ausgabesuffix _clear_yyyy-MM-dd_mmss.md.

.PARAMETER Silent
    Unterdrückt Fortschrittsanzeigen und nicht zwingende Statusausgaben.
    Fehler-, Fatal- und sicherheitsrelevante Ausgaben bleiben sichtbar.

.PARAMETER LogTarget
    Steuert ausschließlich die Dateiprotokollierung.

    None:
    Keine Logdatei. Dies ist der Standardwert.

    ScriptDir:
    Die Logdatei wird im Skriptverzeichnis erzeugt.

    Output:
    Die Logdatei wird im fachlichen Ausgabeverzeichnis erzeugt. Ist dieses noch nicht
    bestimmbar, wird auf das System-Temp-Verzeichnis zurückgefallen.

    Temp:
    Die Logdatei wird im plattformneutral ermittelten System-Temp-Verzeichnis erzeugt.

.PARAMETER ConfigPath
    Optionaler vollständiger oder relativer Pfad zur JSON-Konfigurationsdatei.

    Ohne ConfigPath erwartet der normale Skriptlauf:
        <Skriptverzeichnis>/<Skriptname>.config.json

.PARAMETER InitializeConfig
    Erzeugt bewusst eine technisch gültige JSON-Konfigurationsvorlage.

    Ohne ConfigPath wird der Initialisierungspfad wie folgt bestimmt:
    - Linux: /var/tmp
    - sonstige Plattformen: $env:PUBLIC

    Vorhandene Konfigurationsdateien werden nicht überschrieben.
    Fehlende Elternverzeichnisse werden nicht automatisch erzeugt.

.EXAMPLE
    ./Convert-AnonymizedMarkdown.ps1 -InputMarkdownFile ./Sample_clear.md -MappingPsvFile ./Mapping_sample.psv -Confirm:$false

    Konvertiert Klarbezeichnungen in Tokens.

.EXAMPLE
    ./Convert-AnonymizedMarkdown.ps1 -InputMarkdownFile ./Sample_foggy.md -MappingPsvFile ./Mapping_sample.psv -Clear -Confirm:$false

    Konvertiert Tokens in Klarbezeichnungen.

.EXAMPLE
    ./Convert-AnonymizedMarkdown.ps1 -InputMarkdownFile ./Sample_clear.md -MappingPsvFile ./Mapping_sample.psv -Debug -Confirm:$false

    Führt die Konvertierung aus und zeigt jede Mappingzuordnung im Debugstrom.

.EXAMPLE
    ./Convert-AnonymizedMarkdown.ps1 -InputMarkdownFile ./Sample_clear.md -MappingPsvFile ./Mapping_sample.psv -WhatIf

    Simuliert die Verarbeitung. Weder Markdown-Ausgabe noch JSON-Konfiguration werden geändert.

.EXAMPLE
    ./Convert-AnonymizedMarkdown.ps1 -InitializeConfig -Confirm:$false

    Erzeugt eine technisch gültige Konfigurationsvorlage am Standard-Übergabeort.

.NOTES
    ⚖️ Lizenz: Frei nutzbar, kopierbar und veränderbar, auf eigene Gefahr und ohne Gewährleistung.
    🧑‍🔬 Autor: Dipl.-Ing. Alfred Menzel / erstellt mit ChatGPT
    🧩 Zielplattform: PowerShell 7+
    🗓️ Version Ps1DevGuide: 2026-09-17 14:29:14
    🗓️ Version Ps1STemplate: 2026-09-17 14:30:00

    📜 Historie:
          2026-09-17 15:27:05  Überarbeitung nach Ps1DevGuide 2026-09-17 14:29:14 und Ps1STemplate 2026-09-17 14:30:00; PSV auf zwei Spalten reduziert; JSON-Ausführungsstatus und Debugdiagnose ergänzt
          2026-05-31 16:28:19  Erstellung auf Basis der damaligen PowerShell-7-Entwicklungsrichtlinie und Crossplattform-Vorlage
#>

#requires -Version 7.0

# UTF-8 signal: ʘ‿ʘ Grüß Gott – Ça va? – ¿Qué tal? – Привет – 你好 – שלום – नमस्ते – مرحبا

# ---------------------------------------------------------------
# 🛡️ Skript-Ebene: ShouldProcess aktivieren
# ---------------------------------------------------------------
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [AllowEmptyString()]
    [System.String] $InputMarkdownFile = '',

    [Parameter(Mandatory = $false, Position = 1)]
    [AllowEmptyString()]
    [System.String] $MappingPsvFile = '',

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter] $Clear,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter] $Silent,

    [Parameter(Mandatory = $false)]
    [ValidateSet('None', 'ScriptDir', 'Output', 'Temp')]
    [System.String] $LogTarget = 'None',

    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [System.String] $ConfigPath = '',

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter] $InitializeConfig
)

# ---------------------------------------------------------------
# 📦 Skript-Variablen, Teil 1
# ---------------------------------------------------------------
[System.String]  $script:strVersion       = '🗓️ 2026-09-17 15:27:05'
[System.Boolean] $script:blnShouldProcess = $false
[System.String]  $script:strMessage       = ''
[System.String]  $script:strAnswer        = 'N'

# ---------------------------------------------------------------
# 🟡 Vorwarnung des Skripts
# ---------------------------------------------------------------
$script:strMessage = @"
* Convert-AnonymizedMarkdown *

Skriptablauf:
- JSON-Konfiguration technisch einlesen und anzeigen
- Markdown-Eingangsdatei und zweispaltige PSV-Mapping-Datei prüfen
- Klarbezeichnungen in Tokens oder Tokens in Klarbezeichnungen umwandeln
- konvertierte Markdown-Datei schreiben
- LastExecutionDate und ExecuteDirection nach einem erfolgreichen realen Lauf kontrolliert zurückschreiben

Mögliche Änderungen:
- Eine neue Markdown-Ausgabedatei wird im Eingangsverzeichnis erzeugt.
- Die produktive JSON-Konfiguration wird nach einem erfolgreichen realen Lauf aktualisiert.
- InitializeConfig erzeugt ausschließlich auf ausdrücklichen Aufruf eine neue Konfigurationsvorlage.

Sicherheitssteuerung:
- Default der Sicherheitsquittierung ist No.
- WhatIf sperrt Markdown-Ausgabe und jede Änderung der JSON-Konfiguration.
- Confirm:`$false unterdrückt die interaktive Sicherheitsquittierung.

Datenschutz:
- Klarbezeichnungen werden nicht in die Logdatei geschrieben.
- Mit -Debug werden Token und Klarbezeichnungen zur gezielten Fehlersuche im Debugstrom angezeigt.

Die Logging-Funktionalität ist immer aktiv.
Eine Logdatei wird nur bei LogTarget ScriptDir, Output oder Temp erzeugt.

📌 Beachte: Nur mit PowerShell 7 lauffähig!
Version: $script:strVersion
"@
Write-Host $script:strMessage -ForegroundColor Yellow

# ---------------------------------------------------------------
# Zentrale Sicherheitsquittierung
# ---------------------------------------------------------------
<#
.SYNOPSIS
    Führt die zentrale Sicherheitsquittierung des Skripts aus.

.DESCRIPTION
    Confirm-ScriptProcessing kapselt die verbindliche Fail-Safe-Abfrage. Die
    Funktion wird nach der Anwender-Funktionsbeschreibung und im normalen Lauf
    erneut nach der separaten Anzeige der JSON-Konfiguration aufgerufen.

    Bei -WhatIf und -Confirm:$false erfolgt keine interaktive Abfrage. Nur die
    ausdrückliche Eingabe y gibt einen interaktiven Lauf frei.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Confirm-ScriptProcessing {
    [CmdletBinding()]
    param()

    switch (
        (-not [System.Boolean] $WhatIfPreference) -and
        ($ConfirmPreference -ne 'None')
    ) {
        $true {
            $script:strAnswer = Read-Host 'Soll die Verarbeitung ausgeführt werden? (y/N)'

            switch ($script:strAnswer) {
                'y' {
                    # Verarbeitung ausdrücklich freigegeben.
                }

                default {
                    $script:strMessage = 'Skript-Ausführung abgebrochen (Default = No).'
                    Write-Host "🟡 $script:strMessage" -ForegroundColor Yellow
                    exit 1
                }
            }
        }

        $false {
            # Keine Sicherheitsabfrage bei -WhatIf oder -Confirm:$false.
        }

        default {
            throw 'Unerwarteter Zustand bei der Ermittlung der Sicherheitsabfrage.'
        }
    }
}

# Erste Sicherheitsquittierung nach der Anwender-Funktionsbeschreibung.
Confirm-ScriptProcessing

# ---------------------------------------------------------------
# 🧩 Systemprüfungen
# ---------------------------------------------------------------
switch ($PSVersionTable.PSVersion.Major -lt 7) {
    $true {
        throw "FATAL: Requires PowerShell 7+. Current version: $($PSVersionTable.PSVersion)"
    }

    $false {
        # Unterstützte PowerShell-Hauptversion.
    }

    default {
        throw 'Unerwarteter Zustand bei der PowerShell-Versionsprüfung.'
    }
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    [System.Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
}
catch {
    throw 'FATAL: UTF-8 console output could not be enabled.'
}

switch ($IsWindows -and [System.Console]::OutputEncoding.WebName -ne 'utf-8') {
    $true {
        throw 'FATAL: Console does not support UTF-8. Aborting.'
    }

    $false {
        # UTF-8-Ausgabe ist verwendbar oder die zusätzliche Windows-Prüfung ist nicht erforderlich.
    }

    default {
        throw 'Unerwarteter Zustand bei der UTF-8-Konsolenprüfung.'
    }
}

# ---------------------------------------------------------------
# Klassen und Datenmodelle
# ---------------------------------------------------------------
class clsConfigMaster {
    [System.String] $strConfigSchemaVersion
    [System.Nullable[System.DateTimeOffset]] $dtoLastExecutionDate
    [System.String] $strExecuteDirection
}

class clsMappingItem {
    [System.Int64]  $intRowNumber
    [System.String] $strToken
    [System.String] $strReplacement
    [System.Int64]  $intOccurrenceCount
    [System.String] $strProcessingStatus
    [System.String] $strErrorReason
}

# ---------------------------------------------------------------
# 📦 Skript-Variablen, Teil 2
# ---------------------------------------------------------------
[System.String]  $script:strScriptPath            = $PSCommandPath
[System.String]  $script:strScriptName            = Split-Path -Leaf $PSCommandPath
[System.String]  $script:strScriptDir             = Split-Path -Parent $PSCommandPath
[System.String]  $script:strScriptBaseName        = [System.IO.Path]::GetFileNameWithoutExtension($script:strScriptName)
[System.String]  $script:strOutputDirectory       = $null
[System.String]  $script:strLogDirectory          = $null
[System.String]  $script:strEffectiveLogTarget      = 'None'
[System.String]  $script:strLogTimeStamp          = $null
[System.String]  $script:strLogFileName           = $null
[System.String]  $script:strLogFile               = $null
[System.String]  $script:strConfigFile            = $null
[System.String]  $script:strConfigSchemaVersion   = '1.0'
[System.String]  $script:strInputMarkdownPath     = ''
[System.String]  $script:strMappingPsvPath        = ''
[System.String]  $script:strInputMarkdownDir      = ''
[System.String]  $script:strInputMarkdownBaseName = ''
[System.String]  $script:strOutputTimeStamp       = ''
[System.String]  $script:strOutputMarkdownPath    = ''
[System.String]  $script:strOutputSuffix          = ''
[System.String]  $script:strConversionDirection   = ''
[System.String]  $script:strExecuteDirection      = ''
[System.String]  $script:strMarkdownContent       = ''
[System.String]  $script:strFinalContent          = ''
[System.Int64]   $script:intTotalReplacementCount = 0
[System.Int64]   $script:intTokenTotal            = 0
[System.Int64]   $script:intTokenUsed             = 0
[System.Boolean] $script:blnMainSuccess           = $false
[System.Int32]   $script:intDetailsOk              = 0
[System.Int32]   $script:intDetailsErr             = 0
[System.Int32]   $script:intDetailsTotal           = 0
[System.String]  $script:strStatusReplacementLabel = ''
[clsConfigMaster] $script:objConfig               = $null
[clsMappingItem] $script:objMappingItem            = $null
[System.Collections.Generic.SortedList[System.Int64, clsMappingItem]] $script:htbMappingList = [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]]::new()

# Fachliches Ausgabeverzeichnis für LogTarget=Output soweit möglich früh bestimmen.
switch (-not [System.String]::IsNullOrWhiteSpace($InputMarkdownFile)) {
    $true {
        try {
            $script:strOutputDirectory = [System.IO.Path]::GetDirectoryName(
                [System.IO.Path]::GetFullPath($InputMarkdownFile)
            )
        }
        catch {
            $script:strOutputDirectory = $null
            Write-Debug ('Ausgabeverzeichnis konnte vorab nicht bestimmt werden: {0}' -f $_.Exception.ToString())
        }
    }

    $false {
        $script:strOutputDirectory = $null
    }

    default {
        throw 'Unerwarteter Zustand bei der frühen Bestimmung des Ausgabeverzeichnisses.'
    }
}

# ---------------------------------------------------------------
# 📝 Logging-Funktionen
# ---------------------------------------------------------------
<#
.SYNOPSIS
    Initialisiert die optionale Dateiprotokollierung.

.DESCRIPTION
    Initialize-LogFile wird nach der frühen Pfadinitialisierung aufgerufen und
    setzt abhängig von LogTarget den vollständigen Logdateipfad. Bei None werden
    bewusst weder Logverzeichnis noch Logdateiname erzeugt. Bei Output wird auf
    Temp zurückgefallen, wenn kein verwendbares fachliches Ausgabeverzeichnis
    verfügbar ist.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Initialize-LogFile {
    [CmdletBinding()]
    param()

    [System.String] $strEffectiveLogTarget = $LogTarget
    [System.String] $strTempDirectory = ''

    switch ($strEffectiveLogTarget) {
        'None' {
            $script:strLogDirectory = $null
            $script:strLogTimeStamp = $null
            $script:strLogFileName = $null
            $script:strLogFile = $null
        }

        'ScriptDir' {
            $script:strLogDirectory = $script:strScriptDir
        }

        'Output' {
            switch (
                (-not [System.String]::IsNullOrWhiteSpace($script:strOutputDirectory)) -and
                [System.IO.Directory]::Exists($script:strOutputDirectory)
            ) {
                $true {
                    $script:strLogDirectory = $script:strOutputDirectory
                }

                $false {
                    $strEffectiveLogTarget = 'Temp'
                    $strTempDirectory = [System.IO.Path]::GetTempPath()
                    $script:strLogDirectory = $strTempDirectory
                }

                default {
                    throw 'Unerwarteter Zustand beim Output-Fallback der Logdatei.'
                }
            }
        }

        'Temp' {
            $strTempDirectory = [System.IO.Path]::GetTempPath()
            $script:strLogDirectory = $strTempDirectory
        }

        default {
            throw "Unerwartetes LogTarget: '$strEffectiveLogTarget'"
        }
    }

    $script:strEffectiveLogTarget = $strEffectiveLogTarget

    switch ($strEffectiveLogTarget -ne 'None') {
        $true {
            switch (
                (-not [System.String]::IsNullOrWhiteSpace($script:strLogDirectory)) -and
                [System.IO.Directory]::Exists($script:strLogDirectory)
            ) {
                $true {
                    $script:strLogTimeStamp = [System.DateTimeOffset]::UtcNow.ToString(
                        'yyyyMMdd_HHmmss',
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )
                    $script:strLogFileName = '{0}_{1}.log' -f $script:strScriptBaseName, $script:strLogTimeStamp
                    $script:strLogFile = Join-Path -Path $script:strLogDirectory -ChildPath $script:strLogFileName
                    Write-Debug ('LogTarget={0} | LogFile={1}' -f $strEffectiveLogTarget, $script:strLogFile)
                }

                $false {
                    throw ('Logverzeichnis ist nicht verfügbar: {0}' -f $script:strLogDirectory)
                }

                default {
                    throw 'Unerwarteter Zustand bei der Prüfung des Logverzeichnisses.'
                }
            }
        }

        $false {
            # Dateiprotokollierung bleibt deaktiviert.
        }

        default {
            throw 'Unerwarteter Zustand bei der Erzeugung des Logdateinamens.'
        }
    }
}

<#
.SYNOPSIS
    Schreibt eine strukturierte Meldung in die optionale Logdatei.

.DESCRIPTION
    Write-LogMessage ist die zentrale Logging-Unterfunktion des Skripts. Bei
    LogTarget=None erfolgt bewusst kein Dateizugriff. Aktiviertes Dateilogging
    bleibt auch unter -WhatIf verfügbar.

    Aufrufer dürfen keine Klarbezeichnungen aus der PSV-Mapping-Datei in
    strMessage übergeben.

.PARAMETER strLevel
    Log-Level der Meldung, beispielsweise INFO, WARN, ERROR oder FATAL.

.PARAMETER strMessage
    Vollständiger zu protokollierender Meldungstext ohne Klarbezeichnungen.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strLevel,

        [Parameter(Mandatory = $true)]
        [System.String] $strMessage
    )

    [System.String] $strTime = ''
    [System.String] $strLine = ''

    switch ([System.String]::IsNullOrWhiteSpace($script:strLogFile)) {
        $true {
            return
        }

        $false {
            # Eine Logdatei ist konfiguriert; Verarbeitung wird fortgesetzt.
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung des Logdateipfads.'
        }
    }

    $strTime = [System.DateTimeOffset]::UtcNow.ToString(
        'yyyy-MM-ddTHH:mm:ss.fffZ',
        [System.Globalization.CultureInfo]::InvariantCulture
    )
    $strLine = '{0} [{1}] {2}' -f $strTime, $strLevel, $strMessage

    Write-Debug $strLine
    Add-Content -LiteralPath $script:strLogFile -Value $strLine -Encoding utf8 -WhatIf:$false
}

<#
.SYNOPSIS
    Protokolliert die verfügbare technische Diagnose eines PowerShell-Fehlers.

.DESCRIPTION
    Write-LogError wird von zentralen catch-Blöcken aufgerufen und überführt die
    technischen ErrorRecord-Informationen in die Loggingstruktur. Zeilenumbrüche
    werden für einzeilige Logdatensätze sichtbar escaped.

    Fehler innerhalb einer einzelnen Mapping-Ersetzung werden vor dem erneuten
    Auslösen bewusst auf Zeilennummer und Token reduziert, damit Klarbezeichnungen
    nicht über Exceptiontexte in die Logdatei gelangen.

.PARAMETER objErrorRecord
    Vollständiger PowerShell-ErrorRecord des aufgetretenen Fehlers.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Write-LogError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord] $objErrorRecord
    )

    [System.String] $strErrorRecord = ''
    [System.String] $strExceptionType = ''
    [System.String] $strExceptionMessage = ''
    [System.String] $strFullyQualifiedErrorId = ''
    [System.String] $strCategoryInfo = ''
    [System.String] $strPositionMessage = ''
    [System.String] $strScriptStackTrace = ''
    [System.String] $strExceptionStackTrace = ''
    [System.String] $strInnerException = ''
    [System.String] $strContext = ''

    $strErrorRecord = ([System.String] $objErrorRecord).Replace("`r", '\r').Replace("`n", '\n')
    $strExceptionType = $objErrorRecord.Exception.GetType().FullName
    $strExceptionMessage = ([System.String] $objErrorRecord.Exception.Message).Replace("`r", '\r').Replace("`n", '\n')
    $strFullyQualifiedErrorId = [System.String] $objErrorRecord.FullyQualifiedErrorId
    $strCategoryInfo = ([System.String] $objErrorRecord.CategoryInfo).Replace("`r", '\r').Replace("`n", '\n')
    $strPositionMessage = ([System.String] $objErrorRecord.InvocationInfo.PositionMessage).Replace("`r", '\r').Replace("`n", '\n')
    $strScriptStackTrace = ([System.String] $objErrorRecord.ScriptStackTrace).Replace("`r", '\r').Replace("`n", '\n')
    $strExceptionStackTrace = ([System.String] $objErrorRecord.Exception.StackTrace).Replace("`r", '\r').Replace("`n", '\n')

    switch ($null -ne $objErrorRecord.Exception.InnerException) {
        $true {
            $strInnerException = ([System.String] $objErrorRecord.Exception.InnerException.ToString()).Replace("`r", '\r').Replace("`n", '\n')
        }

        $false {
            $strInnerException = ''
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung der InnerException.'
        }
    }

    try {
        $strContext = [System.String] $objErrorRecord.Exception.Data['Context']
    }
    catch {
        $strContext = ''
    }

    switch (-not [System.String]::IsNullOrWhiteSpace($strContext)) {
        $true {
            Write-LogMessage -strLevel 'ERROR' -strMessage ('Context={0}' -f $strContext)
        }

        $false {
            # Kein zusätzlicher Fehlerkontext vorhanden.
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung des Fehlerkontexts.'
        }
    }

    Write-LogMessage -strLevel 'ERROR' -strMessage ('ErrorRecord={0}' -f $strErrorRecord)
    Write-LogMessage -strLevel 'ERROR' -strMessage ('ExceptionType={0}' -f $strExceptionType)
    Write-LogMessage -strLevel 'ERROR' -strMessage ('ExceptionMessage={0}' -f $strExceptionMessage)
    Write-LogMessage -strLevel 'ERROR' -strMessage ('FullyQualifiedErrorId={0}' -f $strFullyQualifiedErrorId)
    Write-LogMessage -strLevel 'ERROR' -strMessage ('CategoryInfo={0}' -f $strCategoryInfo)
    Write-LogMessage -strLevel 'ERROR' -strMessage ('PositionMessage={0}' -f $strPositionMessage)
    Write-LogMessage -strLevel 'ERROR' -strMessage ('ScriptStackTrace={0}' -f $strScriptStackTrace)
    Write-LogMessage -strLevel 'ERROR' -strMessage ('ExceptionStackTrace={0}' -f $strExceptionStackTrace)

    switch (-not [System.String]::IsNullOrWhiteSpace($strInnerException)) {
        $true {
            Write-LogMessage -strLevel 'ERROR' -strMessage ('InnerException={0}' -f $strInnerException)
        }

        $false {
            # Keine innere Exception zu protokollieren.
        }

        default {
            throw 'Unerwarteter Zustand bei der Protokollierung der InnerException.'
        }
    }

    Write-Debug ('ERROR {0}' -f $strExceptionMessage)
}

<#
.SYNOPSIS
    Gibt den Pfad der tatsächlich erzeugten Logdatei aus.

.DESCRIPTION
    Write-LogFilePath wird an kontrollierten Skriptabschlüssen aufgerufen. Bei
    deaktivierter Dateiprotokollierung oder noch nicht vorhandener Logdatei
    erfolgt keine Ausgabe.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Write-LogFilePath {
    [CmdletBinding()]
    param()

    switch ([System.String]::IsNullOrWhiteSpace($script:strLogFile)) {
        $true {
            return
        }

        $false {
            # Ein Logdateipfad ist gesetzt; Existenzprüfung folgt.
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung des Logdateipfads.'
        }
    }

    switch (Test-Path -LiteralPath $script:strLogFile -PathType Leaf) {
        $true {
            Write-Host ('📝 Logdatei: {0}' -f $script:strLogFile) -ForegroundColor Yellow
        }

        $false {
            return
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung der Logdateiexistenz.'
        }
    }
}

<#
.SYNOPSIS
    Gibt eine strukturierte Statusmeldung im Terminal aus.

.DESCRIPTION
    Write-StatusMessage wird von Haupt- und STEP-Verarbeitung für sichtbare
    Statusmeldungen verwendet. Silent unterdrückt INFO-, OK- und WARN-Meldungen,
    nicht jedoch ERROR oder FATAL.

.PARAMETER strLevel
    Statuslevel INFO, OK, WARN, ERROR oder FATAL.

.PARAMETER strMessage
    Anzuzeigender Meldungstext.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Write-StatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strLevel,

        [Parameter(Mandatory = $true)]
        [System.String] $strMessage
    )

    [System.String] $strPrefix = ''
    [System.ConsoleColor] $objColor = [System.ConsoleColor]::White
    [System.Boolean] $blnSuppress = $false

    switch ($Silent.IsPresent -and $strLevel -ne 'ERROR' -and $strLevel -ne 'FATAL') {
        $true {
            $blnSuppress = $true
        }

        $false {
            $blnSuppress = $false
        }

        default {
            throw 'Unerwarteter Zustand bei der Silent-Auswertung.'
        }
    }

    switch ($blnSuppress) {
        $true {
            return
        }

        $false {
            # Meldung wird ausgegeben.
        }

        default {
            throw 'Unerwarteter Zustand bei der Statusausgabe.'
        }
    }

    switch ($strLevel) {
        'OK' {
            $strPrefix = '🟢'
            $objColor = [System.ConsoleColor]::Green
        }

        'WARN' {
            $strPrefix = '🟡'
            $objColor = [System.ConsoleColor]::Yellow
        }

        'ERROR' {
            $strPrefix = '🔴'
            $objColor = [System.ConsoleColor]::Red
        }

        'FATAL' {
            $strPrefix = '🔴'
            $objColor = [System.ConsoleColor]::Red
        }

        'INFO' {
            $strPrefix = 'ℹ️'
            $objColor = [System.ConsoleColor]::White
        }

        default {
            throw "Unerwartetes Statuslevel: '$strLevel'"
        }
    }

    Write-Host ('{0} {1}' -f $strPrefix, $strMessage) -ForegroundColor $objColor
}

<#
.SYNOPSIS
    Kapselt die Fortschrittsanzeige unter Berücksichtigung von Silent.

.DESCRIPTION
    Write-ProgressSafe wird von Invoke-MainOperation aufgerufen. Bei Silent wird
    keine Fortschrittsanzeige erzeugt. Andernfalls wird Write-Progress mit den
    übergebenen Werten aufgerufen.

.PARAMETER intId
    ID der Fortschrittsanzeige.

.PARAMETER strActivity
    Beschreibung der Hauptaktivität.

.PARAMETER strStatus
    Aktueller Status der Verarbeitung.

.PARAMETER intPercentComplete
    Prozentualer Fortschritt von 0 bis 100.

.PARAMETER blnCompleted
    True beendet die Fortschrittsanzeige.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Write-ProgressSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Int32] $intId,

        [Parameter(Mandatory = $true)]
        [System.String] $strActivity,

        [Parameter(Mandatory = $true)]
        [System.String] $strStatus,

        [Parameter(Mandatory = $false)]
        [System.Int32] $intPercentComplete = 0,

        [Parameter(Mandatory = $false)]
        [System.Boolean] $blnCompleted = $false
    )

    switch ($Silent.IsPresent) {
        $true {
            return
        }

        $false {
            # Fortschrittsausgabe ist aktiviert.
        }

        default {
            throw 'Unerwarteter Zustand bei der Silent-Prüfung der Fortschrittsanzeige.'
        }
    }

    switch ($blnCompleted) {
        $true {
            Write-Progress -Id $intId -Activity $strActivity -Completed
        }

        $false {
            Write-Progress -Id $intId -Activity $strActivity -Status $strStatus -PercentComplete $intPercentComplete
        }

        default {
            throw 'Unerwarteter Zustand bei der Completed-Prüfung der Fortschrittsanzeige.'
        }
    }
}

# ---------------------------------------------------------------
# 🔄 Konfigurations- und Pfadfunktionen
# ---------------------------------------------------------------
<#
.SYNOPSIS
    Ermittelt den wirksamen JSON-Konfigurationspfad.

.DESCRIPTION
    Resolve-ConfigFilePath wird vor Import oder Initialisierung der Konfiguration
    aufgerufen. Ohne expliziten ConfigPath wird für normale Läufe der Pfad im
    Skriptverzeichnis und für InitializeConfig der definierte Übergabeort verwendet.

.PARAMETER strConfigPath
    Vom Benutzer übergebener Konfigurationspfad oder leerer String.

.PARAMETER blnInitializeConfig
    True für den Initialisierungsmodus, andernfalls False.

.OUTPUTS
    System.String mit dem aufgelösten Dateisystempfad.
#>
function Resolve-ConfigFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [System.String] $strConfigPath = '',

        [Parameter(Mandatory = $true)]
        [System.Boolean] $blnInitializeConfig
    )

    [System.String] $strCandidate = ''
    [System.String] $strDefaultDirectory = ''
    [System.String] $strDefaultFileName = ''
    [System.String] $strResolvedPath = ''

    switch (-not [System.String]::IsNullOrWhiteSpace($strConfigPath)) {
        $true {
            $strCandidate = $strConfigPath
        }

        $false {
            $strDefaultFileName = '{0}.config.json' -f $script:strScriptBaseName

            switch ($blnInitializeConfig) {
                $true {
                    switch ($IsLinux) {
                        $true {
                            $strDefaultDirectory = '/var/tmp'
                        }

                        $false {
                            $strDefaultDirectory = [System.String] $env:PUBLIC
                        }

                        default {
                            throw 'Unerwarteter Zustand bei der Plattformprüfung für InitializeConfig.'
                        }
                    }

                    switch ([System.String]::IsNullOrWhiteSpace($strDefaultDirectory)) {
                        $true {
                            throw 'FATAL: Standardpfad für die Konfigurationsinitialisierung konnte nicht ermittelt werden. Verwende -ConfigPath.'
                        }

                        $false {
                            # Initialisierungsverzeichnis wurde ermittelt.
                        }

                        default {
                            throw 'Unerwarteter Zustand bei der Prüfung des Initialisierungsverzeichnisses.'
                        }
                    }

                    $strCandidate = Join-Path -Path $strDefaultDirectory -ChildPath $strDefaultFileName
                }

                $false {
                    $strCandidate = Join-Path -Path $script:strScriptDir -ChildPath $strDefaultFileName
                }

                default {
                    throw 'Unerwarteter Zustand bei der Auswahl des Konfigurationsmodus.'
                }
            }
        }

        default {
            throw 'Unerwarteter Zustand bei der Auswertung von ConfigPath.'
        }
    }

    try {
        $strResolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($strCandidate)
    }
    catch {
        $_.Exception.Data['Context'] = 'Resolve-ConfigFilePath()'
        throw
    }

    switch ([System.String]::IsNullOrWhiteSpace($strResolvedPath)) {
        $true {
            throw 'FATAL: Der Konfigurationspfad konnte nicht aufgelöst werden.'
        }

        $false {
            return $strResolvedPath
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung des aufgelösten Konfigurationspfads.'
        }
    }
}

<#
.SYNOPSIS
    Prüft die technische Lesbarkeit einer Konfigurationsdatei.

.DESCRIPTION
    Test-ConfigReadAccess wird von Import-ScriptConfig aufgerufen, bevor der
    JSON-Inhalt gelesen wird. Eine fehlende Datei wird nicht automatisch erzeugt.

.PARAMETER strConfigFile
    Vollständiger Pfad der zu lesenden JSON-Konfigurationsdatei.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Test-ConfigReadAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strConfigFile
    )

    [System.IO.FileStream] $objFileStream = $null

    switch (Test-Path -LiteralPath $strConfigFile -PathType Leaf) {
        $true {
            # Datei ist vorhanden.
        }

        $false {
            throw "Konfigurationsdatei nicht gefunden: '$strConfigFile'. Erzeuge eine Vorlage mit -InitializeConfig oder gib mit -ConfigPath eine vorhandene Datei an."
        }

        default {
            throw 'Unerwarteter Zustand bei der Existenzprüfung der Konfigurationsdatei.'
        }
    }

    try {
        $objFileStream = [System.IO.File]::Open(
            $strConfigFile,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::Read
        )
    }
    catch {
        $_.Exception.Data['Context'] = 'Test-ConfigReadAccess()'
        throw
    }
    finally {
        switch ($null -ne $objFileStream) {
            $true {
                $objFileStream.Dispose()
                $objFileStream = $null
            }

            $false {
                # Keine Ressource zu bereinigen.
            }

            default {
                Write-Debug 'Unerwarteter Zustand bei der Bereinigung der Konfigurations-Leseprüfung.'
            }
        }
    }
}

<#
.SYNOPSIS
    Prüft den Zielpfad einer neuen Konfigurationsvorlage.

.DESCRIPTION
    Test-ConfigInitializationTarget wird im InitializeConfig-Zweig aufgerufen.
    Die Funktion verhindert das Überschreiben einer vorhandenen Datei und prüft,
    ob das Elternverzeichnis bereits existiert.

.PARAMETER strConfigFile
    Vollständiger Zielpfad der neu anzulegenden Konfigurationsdatei.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Test-ConfigInitializationTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strConfigFile
    )

    [System.String] $strParentDirectory = [System.IO.Path]::GetDirectoryName($strConfigFile)

    switch (Test-Path -LiteralPath $strConfigFile -PathType Leaf) {
        $true {
            throw "Konfigurationsdatei existiert bereits und wird nicht überschrieben: '$strConfigFile'"
        }

        $false {
            # Zieldatei existiert noch nicht.
        }

        default {
            throw 'Unerwarteter Zustand bei der Initialisierungs-Zieldateiprüfung.'
        }
    }

    switch (
        (-not [System.String]::IsNullOrWhiteSpace($strParentDirectory)) -and
        [System.IO.Directory]::Exists($strParentDirectory)
    ) {
        $true {
            # Elternverzeichnis ist vorhanden.
        }

        $false {
            throw "Elternverzeichnis der Konfigurationsdatei existiert nicht: '$strParentDirectory'"
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung des Konfigurations-Elternverzeichnisses.'
        }
    }
}

<#
.SYNOPSIS
    Prüft den Schreibzugriff auf das Elternverzeichnis der Konfiguration.

.DESCRIPTION
    Test-ConfigWriteAccess wird unmittelbar vor einer realen JSON-Schreiboperation
    aufgerufen. Die Funktion erzeugt eine temporäre Prüfdatei im Zielverzeichnis und
    entfernt sie sofort wieder. Unter -WhatIf wird sie nicht aufgerufen.

.PARAMETER strConfigFile
    Vollständiger Zielpfad der JSON-Konfigurationsdatei.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Test-ConfigWriteAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strConfigFile
    )

    [System.String] $strParentDirectory = [System.IO.Path]::GetDirectoryName($strConfigFile)
    [System.String] $strProbeFile = ''

    switch (
        (-not [System.String]::IsNullOrWhiteSpace($strParentDirectory)) -and
        [System.IO.Directory]::Exists($strParentDirectory)
    ) {
        $true {
            # Zielverzeichnis ist vorhanden.
        }

        $false {
            throw "Konfigurationsverzeichnis ist nicht verfügbar: '$strParentDirectory'"
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung des Konfigurationsverzeichnisses.'
        }
    }

    $strProbeFile = Join-Path -Path $strParentDirectory -ChildPath ('.config-write-test.{0}.tmp' -f [System.Guid]::NewGuid().ToString('N'))

    try {
        [System.IO.File]::WriteAllText($strProbeFile, '', [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Delete($strProbeFile)
    }
    catch {
        $_.Exception.Data['Context'] = 'Test-ConfigWriteAccess()'
        throw
    }
    finally {
        switch (Test-Path -LiteralPath $strProbeFile -PathType Leaf) {
            $true {
                try {
                    [System.IO.File]::Delete($strProbeFile)
                }
                catch {
                    Write-Debug ('Schreibprüfdatei konnte nicht entfernt werden: {0}' -f $_.Exception.ToString())
                }
            }

            $false {
                # Keine Prüfdatei zu bereinigen.
            }

            default {
                Write-Debug 'Unerwarteter Zustand bei der Bereinigung der Schreibprüfdatei.'
            }
        }
    }
}

<#
.SYNOPSIS
    Liest eine erforderliche String-Eigenschaft aus einem JSON-Knoten.

.DESCRIPTION
    Get-RequiredConfigString wird von ConvertFrom-ScriptConfigJson für technisch
    erforderliche Stringwerte der Konfiguration aufgerufen.

.PARAMETER objConfigNode
    JSON-Knoten, aus dem die Eigenschaft gelesen wird.

.PARAMETER strPropertyName
    Name der erforderlichen JSON-Eigenschaft.

.PARAMETER strContext
    Technischer Kontext für Fehlermeldungen.

.OUTPUTS
    System.String mit dem geprüften Eigenschaftswert.
#>
function Get-RequiredConfigString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object] $objConfigNode,

        [Parameter(Mandatory = $true)]
        [System.String] $strPropertyName,

        [Parameter(Mandatory = $true)]
        [System.String] $strContext
    )

    [System.Management.Automation.PSPropertyInfo] $objProperty = $null
    [System.Object] $objValue = $null
    [System.String] $strValue = ''

    $objProperty = $objConfigNode.PSObject.Properties[$strPropertyName]

    switch ($null -eq $objProperty) {
        $true {
            throw "${strContext}: Erforderliche JSON-Eigenschaft '$strPropertyName' fehlt."
        }

        $false {
            $objValue = $objProperty.Value
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung einer JSON-Eigenschaft.'
        }
    }

    switch ($objValue -is [System.String]) {
        $true {
            $strValue = [System.String] $objValue
        }

        $false {
            throw "${strContext}: JSON-Eigenschaft '$strPropertyName' muss vom Typ String sein."
        }

        default {
            throw 'Unerwarteter Zustand bei der Typprüfung einer JSON-Eigenschaft.'
        }
    }

    switch ([System.String]::IsNullOrWhiteSpace($strValue)) {
        $true {
            throw "${strContext}: JSON-Eigenschaft '$strPropertyName' darf nicht leer sein."
        }

        $false {
            return $strValue
        }

        default {
            throw 'Unerwarteter Zustand bei der Inhaltsprüfung einer JSON-Eigenschaft.'
        }
    }
}

<#
.SYNOPSIS
    Konvertiert einen Konfigurations-Zeitwert kontrolliert nach UTC.

.DESCRIPTION
    ConvertTo-UtcConfigDateTime wird von ConvertFrom-ScriptConfigJson für
    LastExecutionDate aufgerufen. Werte mit Z werden als UTC behandelt,
    explizite Offsets werden nach UTC normalisiert und Werte ohne Zeitzone werden
    als lokale Systemzeit interpretiert und anschließend nach UTC konvertiert.

.PARAMETER strValue
    Zu parsende ISO-8601-Zeitangabe.

.OUTPUTS
    System.DateTimeOffset in UTC.
#>
function ConvertTo-UtcConfigDateTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strValue
    )

    [System.String[]] $strArrUtcFormats = @(
        "yyyy-MM-dd'T'HH:mm:ss'Z'",
        "yyyy-MM-dd'T'HH:mm:ss.FFFFFFF'Z'"
    )
    [System.String[]] $strArrOffsetFormats = @(
        "yyyy-MM-dd'T'HH:mm:sszzz",
        "yyyy-MM-dd'T'HH:mm:ss.FFFFFFFzzz"
    )
    [System.String[]] $strArrLocalFormats = @(
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss.FFFFFFF"
    )
    [System.Globalization.CultureInfo] $objCulture = [System.Globalization.CultureInfo]::InvariantCulture
    [System.DateTimeOffset] $dtoParsed = [System.DateTimeOffset]::MinValue
    [System.DateTime] $dtmParsed = [System.DateTime]::MinValue
    [System.Boolean] $blnParsed = $false

    $blnParsed = [System.DateTimeOffset]::TryParseExact(
        $strValue,
        $strArrUtcFormats,
        $objCulture,
        [System.Globalization.DateTimeStyles]::AssumeUniversal,
        [ref] $dtoParsed
    )

    switch ($blnParsed) {
        $true {
            return $dtoParsed.ToUniversalTime()
        }

        $false {
            # Prüfung mit explizitem Offset folgt.
        }

        default {
            throw 'Unerwarteter Zustand beim UTC-Datumsparsing.'
        }
    }

    $blnParsed = [System.DateTimeOffset]::TryParseExact(
        $strValue,
        $strArrOffsetFormats,
        $objCulture,
        [System.Globalization.DateTimeStyles]::None,
        [ref] $dtoParsed
    )

    switch ($blnParsed) {
        $true {
            return $dtoParsed.ToUniversalTime()
        }

        $false {
            # Prüfung ohne Zeitzone folgt.
        }

        default {
            throw 'Unerwarteter Zustand beim Offset-Datumsparsing.'
        }
    }

    $blnParsed = [System.DateTime]::TryParseExact(
        $strValue,
        $strArrLocalFormats,
        $objCulture,
        [System.Globalization.DateTimeStyles]::None,
        [ref] $dtmParsed
    )

    switch ($blnParsed) {
        $true {
            $dtmParsed = [System.DateTime]::SpecifyKind($dtmParsed, [System.DateTimeKind]::Local)
            return [System.DateTimeOffset]::new($dtmParsed).ToUniversalTime()
        }

        $false {
            throw "Ungültiger ISO-8601-Zeitwert: '$strValue'"
        }

        default {
            throw 'Unerwarteter Zustand beim lokalen Datumsparsing.'
        }
    }
}

<#
.SYNOPSIS
    Konvertiert JSON in das typisierte Konfigurationsobjekt des Skripts.

.DESCRIPTION
    ConvertFrom-ScriptConfigJson wird von Import-ScriptConfig sowie zur technischen
    Prüfung einer temporär geschriebenen Konfigurationsdatei aufgerufen. Die Funktion
    validiert ConfigSchemaVersion, LastExecutionDate und ExecuteDirection.

.PARAMETER strJson
    Vollständiger JSON-Inhalt.

.PARAMETER strContext
    Technischer Kontext für Fehlermeldungen.

.PARAMETER refObjConfig
    Referenz auf das typisierte Konfigurationsobjekt des Aufrufers.

.OUTPUTS
    Keine Pipeline-Ausgabe. Das Ergebnis befindet sich in refObjConfig.Value.
#>
function ConvertFrom-ScriptConfigJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strJson,

        [Parameter(Mandatory = $true)]
        [System.String] $strContext,

        [Parameter(Mandatory = $true)]
        [ref] $refObjConfig
    )

    [System.Object] $objRawConfig = $null
    [System.String] $strSchemaVersion = ''
    [System.Management.Automation.PSPropertyInfo] $objLastExecutionProperty = $null
    [System.Management.Automation.PSPropertyInfo] $objExecuteDirectionProperty = $null
    [System.Object] $objLastExecutionValue = $null
    [System.Object] $objExecuteDirectionValue = $null
    [clsConfigMaster] $objConfigMaster = $null
    [System.DateTimeOffset] $dtoLastExecutionDate = [System.DateTimeOffset]::MinValue
    [System.String] $strExecuteDirection = ''

    try {
        switch ($PSVersionTable.PSVersion -ge [System.Version] '7.5.0') {
            $true {
                $objRawConfig = $strJson | ConvertFrom-Json -Depth 10 -DateKind String -ErrorAction Stop
            }

            $false {
                $objRawConfig = $strJson | ConvertFrom-Json -Depth 10 -ErrorAction Stop
            }

            default {
                throw 'Unerwarteter Zustand bei der Auswahl des JSON-Datumsparsers.'
            }
        }
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }

    switch ($null -eq $objRawConfig) {
        $true {
            throw "${strContext}: JSON enthält kein verwendbares Wurzelobjekt."
        }

        $false {
            # Wurzelobjekt ist vorhanden.
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung des JSON-Wurzelobjekts.'
        }
    }

    $strSchemaVersion = Get-RequiredConfigString -objConfigNode $objRawConfig -strPropertyName 'ConfigSchemaVersion' -strContext $strContext

    switch ($strSchemaVersion -eq $script:strConfigSchemaVersion) {
        $true {
            # Erwartete Schemaversion.
        }

        $false {
            throw "${strContext}: ConfigSchemaVersion '$strSchemaVersion' ist nicht kompatibel. Erwartet wird '$script:strConfigSchemaVersion'."
        }

        default {
            throw 'Unerwarteter Zustand bei der Prüfung der ConfigSchemaVersion.'
        }
    }

    $objLastExecutionProperty = $objRawConfig.PSObject.Properties['LastExecutionDate']
    $objExecuteDirectionProperty = $objRawConfig.PSObject.Properties['ExecuteDirection']

    switch ($null -eq $objLastExecutionProperty) {
        $true {
            throw "${strContext}: Erforderliche JSON-Eigenschaft 'LastExecutionDate' fehlt."
        }

        $false {
            $objLastExecutionValue = $objLastExecutionProperty.Value
        }

        default {
            throw 'Unerwarteter Zustand bei LastExecutionDate.'
        }
    }

    switch ($null -eq $objExecuteDirectionProperty) {
        $true {
            throw "${strContext}: Erforderliche JSON-Eigenschaft 'ExecuteDirection' fehlt."
        }

        $false {
            $objExecuteDirectionValue = $objExecuteDirectionProperty.Value
        }

        default {
            throw 'Unerwarteter Zustand bei ExecuteDirection.'
        }
    }

    $objConfigMaster = [clsConfigMaster]::new()
    $objConfigMaster.strConfigSchemaVersion = $strSchemaVersion

    switch ($null -eq $objLastExecutionValue) {
        $true {
            $objConfigMaster.dtoLastExecutionDate = [System.Nullable[System.DateTimeOffset]] $null
        }

        $false {
            switch ($objLastExecutionValue -is [System.String]) {
                $true {
                    $dtoLastExecutionDate = ConvertTo-UtcConfigDateTime -strValue ([System.String] $objLastExecutionValue)
                    $objConfigMaster.dtoLastExecutionDate = $dtoLastExecutionDate
                }

                $false {
                    switch ($objLastExecutionValue -is [System.DateTimeOffset]) {
                        $true {
                            $objConfigMaster.dtoLastExecutionDate = ([System.DateTimeOffset] $objLastExecutionValue).ToUniversalTime()
                        }

                        $false {
                            switch ($objLastExecutionValue -is [System.DateTime]) {
                                $true {
                                    switch (([System.DateTime] $objLastExecutionValue).Kind.ToString()) {
                                        'Utc' {
                                            $objConfigMaster.dtoLastExecutionDate = [System.DateTimeOffset]::new(([System.DateTime] $objLastExecutionValue)).ToUniversalTime()
                                        }

                                        'Local' {
                                            $objConfigMaster.dtoLastExecutionDate = [System.DateTimeOffset]::new(([System.DateTime] $objLastExecutionValue)).ToUniversalTime()
                                        }

                                        'Unspecified' {
                                            $objConfigMaster.dtoLastExecutionDate = [System.DateTimeOffset]::new(
                                                [System.DateTime]::SpecifyKind(
                                                    ([System.DateTime] $objLastExecutionValue),
                                                    [System.DateTimeKind]::Local
                                                )
                                            ).ToUniversalTime()
                                        }

                                        default {
                                            throw "${strContext}: Unbekannter DateTimeKind für LastExecutionDate."
                                        }
                                    }
                                }

                                $false {
                                    throw "${strContext}: LastExecutionDate muss null oder ein gültiger ISO-8601-Zeitwert sein."
                                }

                                default {
                                    throw 'Unerwarteter Zustand bei der DateTime-Typprüfung von LastExecutionDate.'
                                }
                            }
                        }

                        default {
                            throw 'Unerwarteter Zustand bei der DateTimeOffset-Typprüfung von LastExecutionDate.'
                        }
                    }
                }

                default {
                    throw 'Unerwarteter Zustand bei der Typprüfung von LastExecutionDate.'
                }
            }
        }

        default {
            throw 'Unerwarteter Zustand bei der Nullprüfung von LastExecutionDate.'
        }
    }

    switch ($null -eq $objExecuteDirectionValue) {
        $true {
            $objConfigMaster.strExecuteDirection = $null
        }

        $false {
            switch ($objExecuteDirectionValue -is [System.String]) {
                $true {
                    $strExecuteDirection = [System.String] $objExecuteDirectionValue

                    switch ($strExecuteDirection) {
                        'foggy' {
                            $objConfigMaster.strExecuteDirection = 'foggy'
                        }

                        'clear' {
                            $objConfigMaster.strExecuteDirection = 'clear'
                        }

                        default {
                            throw "${strContext}: ExecuteDirection muss null, 'foggy' oder 'clear' sein."
                        }
                    }
                }

                $false {
                    throw "${strContext}: ExecuteDirection muss null oder vom Typ String sein."
                }

                default {
                    throw 'Unerwarteter Zustand bei der Typprüfung von ExecuteDirection.'
                }
            }
        }

        default {
            throw 'Unerwarteter Zustand bei der Nullprüfung von ExecuteDirection.'
        }
    }

    $refObjConfig.Value = $objConfigMaster
}

<#
.SYNOPSIS
    Liest und validiert die JSON-Konfiguration.

.DESCRIPTION
    Import-ScriptConfig wird im normalen Skriptlauf nach der ersten
    Sicherheitsquittierung aufgerufen. Die Funktion liest die Datei und lässt
    den Inhalt durch ConvertFrom-ScriptConfigJson technisch validieren.

.PARAMETER strConfigFile
    Vollständiger Pfad der einzulesenden JSON-Konfigurationsdatei.

.PARAMETER refObjConfig
    Referenz auf das typisierte Konfigurationsobjekt des Aufrufers.

.OUTPUTS
    Keine Pipeline-Ausgabe. Das Ergebnis befindet sich in refObjConfig.Value.
#>
function Import-ScriptConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strConfigFile,

        [Parameter(Mandatory = $true)]
        [ref] $refObjConfig
    )

    [System.String] $strContext = 'Import-ScriptConfig()'
    [System.String] $strJson = ''

    try {
        Test-ConfigReadAccess -strConfigFile $strConfigFile
        Write-LogMessage -strLevel 'INFO' -strMessage ("CONFIG LOAD START | Path='$strConfigFile'")

        $strJson = [System.IO.File]::ReadAllText($strConfigFile, [System.Text.UTF8Encoding]::new($false, $true))
        ConvertFrom-ScriptConfigJson -strJson $strJson -strContext $strContext -refObjConfig $refObjConfig

        Write-LogMessage -strLevel 'INFO' -strMessage ("CONFIG LOAD OK | Path='$strConfigFile' | SchemaVersion='$($refObjConfig.Value.strConfigSchemaVersion)'")
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
}

<#
.SYNOPSIS
    Erzeugt das initiale typisierte Konfigurationsobjekt.

.DESCRIPTION
    New-ScriptConfig wird ausschließlich im InitializeConfig-Zweig aufgerufen.
    Die Funktion setzt ConfigSchemaVersion sowie die Initialwerte null für
    LastExecutionDate und ExecuteDirection. Sie schreibt selbst keine Datei.

.PARAMETER refObjConfig
    Referenz auf das neu zu erzeugende Konfigurationsobjekt des Aufrufers.

.OUTPUTS
    Keine Pipeline-Ausgabe. Das Initialobjekt befindet sich in refObjConfig.Value.
#>
function New-ScriptConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ref] $refObjConfig
    )

    [clsConfigMaster] $objConfigMaster = $null

    $objConfigMaster = [clsConfigMaster]::new()
    $objConfigMaster.strConfigSchemaVersion = $script:strConfigSchemaVersion
    $objConfigMaster.dtoLastExecutionDate = [System.Nullable[System.DateTimeOffset]] $null
    $objConfigMaster.strExecuteDirection = $null

    $refObjConfig.Value = $objConfigMaster
}

<#
.SYNOPSIS
    Zeigt die für den aktuellen Lauf verwendete JSON-Konfiguration an.

.DESCRIPTION
    Show-ScriptConfig wird nach erfolgreichem Import im normalen Skriptlauf
    aufgerufen. Die Anzeige ist vollständig von der Vorwarnung getrennt. Danach
    erfolgt die zweite Sicherheitsquittierung.

.PARAMETER strConfigFile
    Vollständiger Pfad der verwendeten Konfigurationsdatei.

.PARAMETER refObjConfig
    Referenz auf das typisierte Konfigurationsobjekt.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Show-ScriptConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strConfigFile,

        [Parameter(Mandatory = $true)]
        [ref] $refObjConfig
    )

    [System.String] $strLastExecutionDate = '<null>'
    [System.String] $strExecuteDirection = '<null>'
    [System.String] $strDisplay = ''

    switch ($null -ne $refObjConfig.Value.dtoLastExecutionDate) {
        $true {
            $strLastExecutionDate = $refObjConfig.Value.dtoLastExecutionDate.ToUniversalTime().ToString(
                'yyyy-MM-ddTHH:mm:ss.fffZ',
                [System.Globalization.CultureInfo]::InvariantCulture
            )
        }

        $false {
            # Initialwert bleibt <null>.
        }

        default {
            throw 'Unerwarteter Zustand bei der Anzeige von LastExecutionDate.'
        }
    }

    switch (-not [System.String]::IsNullOrWhiteSpace($refObjConfig.Value.strExecuteDirection)) {
        $true {
            $strExecuteDirection = $refObjConfig.Value.strExecuteDirection
        }

        $false {
            # Initialwert bleibt <null>.
        }

        default {
            throw 'Unerwarteter Zustand bei der Anzeige von ExecuteDirection.'
        }
    }

    $strDisplay = @"
* Verwendete JSON-Konfiguration *

Datei: $strConfigFile
ConfigSchemaVersion: $($refObjConfig.Value.strConfigSchemaVersion)
LastExecutionDate: $strLastExecutionDate
ExecuteDirection: $strExecuteDirection
"@

    Write-Host $strDisplay -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Aktualisiert die Ausführungsinformationen im Konfigurationsobjekt.

.DESCRIPTION
    Update-ScriptExecutionInfo wird nach einer erfolgreichen realen Konvertierung
    aufgerufen. Die Funktion setzt LastExecutionDate auf den aktuellen UTC-Zeitpunkt
    und ExecuteDirection auf foggy oder clear. Sie schreibt selbst keine Datei.

.PARAMETER refObjConfig
    Referenz auf das zu aktualisierende Konfigurationsobjekt.

.PARAMETER strExecuteDirection
    Fachliche Ausgaberichtung foggy oder clear.

.OUTPUTS
    Keine Pipeline-Ausgabe. Die Änderungen befinden sich in refObjConfig.Value.
#>
function Update-ScriptExecutionInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ref] $refObjConfig,

        [Parameter(Mandatory = $true)]
        [System.String] $strExecuteDirection
    )

    switch ($strExecuteDirection) {
        'foggy' {
            # Zulässige Richtung.
        }

        'clear' {
            # Zulässige Richtung.
        }

        default {
            throw "Ungültige ExecuteDirection: '$strExecuteDirection'"
        }
    }

    $refObjConfig.Value.dtoLastExecutionDate = [System.DateTimeOffset]::UtcNow
    $refObjConfig.Value.strExecuteDirection = $strExecuteDirection
}

<#
.SYNOPSIS
    Schreibt das typisierte Konfigurationsobjekt kontrolliert als JSON-Datei.

.DESCRIPTION
    Write-ScriptConfig ist die einzige technische Funktion des Skripts, die eine
    JSON-Konfigurationsdatei physisch schreibt, aktiviert oder ersetzt. Sie wird
    sowohl von InitializeConfig als auch beim normalen Zurückschreiben verwendet.

    Die neue Datei wird zuerst vollständig in eine temporäre Datei im selben
    Zielverzeichnis geschrieben und technisch validiert. Beim Ersetzen einer
    produktiven Datei wird genau eine .previous.json-Vorversion geführt.

.PARAMETER strConfigFile
    Vollständiger Zielpfad der JSON-Konfigurationsdatei.

.PARAMETER refObjConfig
    Referenz auf das zu persistierende typisierte Konfigurationsobjekt.

.PARAMETER blnCreateOnly
    True bei InitializeConfig. Eine bereits vorhandene Zieldatei darf dann nicht
    ersetzt werden. False beim kontrollierten Zurückschreiben.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Write-ScriptConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strConfigFile,

        [Parameter(Mandatory = $true)]
        [ref] $refObjConfig,

        [Parameter(Mandatory = $true)]
        [System.Boolean] $blnCreateOnly
    )

    [System.String] $strContext = 'Write-ScriptConfig()'
    [System.String] $strParentDirectory = ''
    [System.String] $strTargetFileName = ''
    [System.String] $strTargetBaseName = ''
    [System.String] $strPreviousFile = ''
    [System.String] $strTempFile = ''
    [System.String] $strJson = ''
    [System.String] $strValidationJson = ''
    [System.Object] $objSerializable = $null
    [System.Object] $objLastExecutionDate = $null
    [System.Object] $objExecuteDirection = $null
    [clsConfigMaster] $objValidationConfig = $null
    [System.Boolean] $blnCurrentMoved = $false
    [System.Boolean] $blnActivated = $false
    [System.Management.Automation.ErrorRecord] $objActivationError = $null

    switch ($script:blnShouldProcess) {
        $true {
            # Reale Schreiboperation ist zentral freigegeben.
        }

        $false {
            Write-LogMessage -strLevel 'INFO' -strMessage ("CONFIG WRITE SKIPPED WHATIF | Path='$strConfigFile'")
            return
        }

        default {
            throw 'Unerwarteter zentraler Ausführungsstatus beim Schreiben der Konfiguration.'
        }
    }

    $strParentDirectory = [System.IO.Path]::GetDirectoryName($strConfigFile)
    $strTargetFileName = [System.IO.Path]::GetFileName($strConfigFile)
    $strTargetBaseName = [System.IO.Path]::GetFileNameWithoutExtension($strConfigFile)

    switch ($null -ne $refObjConfig.Value.dtoLastExecutionDate) {
        $true {
            $objLastExecutionDate = $refObjConfig.Value.dtoLastExecutionDate.ToUniversalTime().ToString(
                'yyyy-MM-ddTHH:mm:ss.fffZ',
                [System.Globalization.CultureInfo]::InvariantCulture
            )
        }

        $false {
            $objLastExecutionDate = $null
        }

        default {
            throw 'Unerwarteter Zustand bei der Serialisierung von LastExecutionDate.'
        }
    }

    switch (-not [System.String]::IsNullOrWhiteSpace($refObjConfig.Value.strExecuteDirection)) {
        $true {
            switch ($refObjConfig.Value.strExecuteDirection) {
                'foggy' {
                    $objExecuteDirection = 'foggy'
                }

                'clear' {
                    $objExecuteDirection = 'clear'
                }

                default {
                    throw 'ExecuteDirection enthält vor der Serialisierung einen ungültigen Wert.'
                }
            }
        }

        $false {
            $objExecuteDirection = $null
        }

        default {
            throw 'Unerwarteter Zustand bei der Serialisierung von ExecuteDirection.'
        }
    }

    $objSerializable = [ordered]@{
        ConfigSchemaVersion = $refObjConfig.Value.strConfigSchemaVersion
        LastExecutionDate = $objLastExecutionDate
        ExecuteDirection = $objExecuteDirection
    }

    $strJson = $objSerializable | ConvertTo-Json -Depth 5
    $strPreviousFile = Join-Path -Path $strParentDirectory -ChildPath ('{0}.previous.json' -f $strTargetBaseName)
    $strTempFile = Join-Path -Path $strParentDirectory -ChildPath ('.{0}.{1}.tmp' -f $strTargetFileName, [System.Guid]::NewGuid().ToString('N'))

    try {
        switch ($blnCreateOnly -and (Test-Path -LiteralPath $strConfigFile -PathType Leaf)) {
            $true {
                throw "Konfigurationsdatei existiert bereits und wird nicht überschrieben: '$strConfigFile'"
            }

            $false {
                # Schreibvorgang darf fortgesetzt werden.
            }

            default {
                throw 'Unerwarteter Zustand bei der CreateOnly-Prüfung.'
            }
        }

        [System.IO.File]::WriteAllText(
            $strTempFile,
            ($strJson + [System.Environment]::NewLine),
            [System.Text.UTF8Encoding]::new($false)
        )

        $strValidationJson = [System.IO.File]::ReadAllText($strTempFile, [System.Text.UTF8Encoding]::new($false, $true))
        ConvertFrom-ScriptConfigJson -strJson $strValidationJson -strContext 'Write-ScriptConfig(temp validation)' -refObjConfig ([ref] $objValidationConfig)

        switch (Test-Path -LiteralPath $strConfigFile -PathType Leaf) {
            $true {
                switch (Test-Path -LiteralPath $strPreviousFile -PathType Leaf) {
                    $true {
                        [System.IO.File]::Delete($strPreviousFile)
                    }

                    $false {
                        # Keine ältere Vorversion vorhanden.
                    }

                    default {
                        throw 'Unerwarteter Zustand bei der Prüfung der vorhandenen Vorversion.'
                    }
                }

                [System.IO.File]::Move($strConfigFile, $strPreviousFile)
                $blnCurrentMoved = $true

                try {
                    [System.IO.File]::Move($strTempFile, $strConfigFile)
                    $blnActivated = $true
                }
                catch {
                    $objActivationError = $_

                    switch (
                        $blnCurrentMoved -and
                        (Test-Path -LiteralPath $strPreviousFile -PathType Leaf) -and
                        (-not (Test-Path -LiteralPath $strConfigFile -PathType Leaf))
                    ) {
                        $true {
                            try {
                                [System.IO.File]::Move($strPreviousFile, $strConfigFile)
                                $blnCurrentMoved = $false
                            }
                            catch {
                                Write-Debug ('Wiederherstellung der produktiven Konfiguration fehlgeschlagen: {0}' -f $_.Exception.ToString())
                            }
                        }

                        $false {
                            # Wiederherstellung ist nicht erforderlich oder technisch nicht möglich.
                        }

                        default {
                            Write-Debug 'Unerwarteter Zustand bei der Wiederherstellungsprüfung.'
                        }
                    }

                    throw $objActivationError
                }
            }

            $false {
                [System.IO.File]::Move($strTempFile, $strConfigFile)
                $blnActivated = $true
            }

            default {
                throw 'Unerwarteter Zustand bei der Aktivierungsprüfung der Konfiguration.'
            }
        }

        switch ($blnActivated) {
            $true {
                Write-LogMessage -strLevel 'INFO' -strMessage ("CONFIG WRITE OK | Path='$strConfigFile'")
            }

            $false {
                throw "${strContext}: Neue Konfiguration wurde nicht aktiviert."
            }

            default {
                throw 'Unerwarteter Zustand nach der Konfigurationsaktivierung.'
            }
        }
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
    finally {
        switch (
            (-not [System.String]::IsNullOrWhiteSpace($strTempFile)) -and
            (Test-Path -LiteralPath $strTempFile -PathType Leaf)
        ) {
            $true {
                try {
                    [System.IO.File]::Delete($strTempFile)
                }
                catch {
                    Write-Debug ('Temporäre JSON-Datei konnte nicht entfernt werden: {0}' -f $_.Exception.ToString())
                }
            }

            $false {
                # Keine temporäre Datei zu bereinigen.
            }

            default {
                Write-Debug 'Unerwarteter Zustand bei der Bereinigung der temporären JSON-Datei.'
            }
        }
    }
}

# ---------------------------------------------------------------
# STEP01: Eingaben prüfen, Ausgabepfad bestimmen und Markdown lesen
# ---------------------------------------------------------------
<#
.SYNOPSIS
    Prüft Eingabedateien, bestimmt die Konvertierungsrichtung und liest Markdown.

.DESCRIPTION
    Invoke-STEP01 ist die erste fachliche Verarbeitungsstufe von
    Invoke-MainOperation. Die Funktion validiert die öffentlichen Dateiparameter,
    prüft die Dateierweiterungen, bestimmt den Ausgabepfad und liest den gesamten
    Markdown-Inhalt als UTF-8.

.OUTPUTS
    Keine Pipeline-Ausgabe. Die Ergebnisse werden in den vorgesehenen
    scriptweiten Zustandsvariablen bereitgestellt.
#>
function Invoke-STEP01 {
    [CmdletBinding()]
    param()

    [System.String] $strContext = 'Invoke-STEP01()'
    [System.String] $strInputExtension = ''
    [System.String] $strMappingExtension = ''

    try {
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} START' -f $strContext)

        switch ([System.String]::IsNullOrWhiteSpace($InputMarkdownFile)) {
            $true {
                throw 'Der Parameter InputMarkdownFile ist für den normalen Skriptlauf erforderlich.'
            }

            $false {
                # Eingabepfad wurde angegeben.
            }

            default {
                throw 'Unerwarteter Zustand bei der Prüfung von InputMarkdownFile.'
            }
        }

        switch ([System.String]::IsNullOrWhiteSpace($MappingPsvFile)) {
            $true {
                throw 'Der Parameter MappingPsvFile ist für den normalen Skriptlauf erforderlich.'
            }

            $false {
                # Mappingpfad wurde angegeben.
            }

            default {
                throw 'Unerwarteter Zustand bei der Prüfung von MappingPsvFile.'
            }
        }

        $script:strInputMarkdownPath = [System.IO.Path]::GetFullPath($InputMarkdownFile)
        $script:strMappingPsvPath = [System.IO.Path]::GetFullPath($MappingPsvFile)

        switch ([System.IO.File]::Exists($script:strInputMarkdownPath)) {
            $true {
                # Eingabedatei vorhanden.
            }

            $false {
                throw ('Markdown-Eingangsdatei nicht gefunden: {0}' -f $script:strInputMarkdownPath)
            }

            default {
                throw 'Unerwarteter Zustand bei der Existenzprüfung der Markdown-Datei.'
            }
        }

        switch ([System.IO.File]::Exists($script:strMappingPsvPath)) {
            $true {
                # Mappingdatei vorhanden.
            }

            $false {
                throw ('PSV-Mappingdatei nicht gefunden: {0}' -f $script:strMappingPsvPath)
            }

            default {
                throw 'Unerwarteter Zustand bei der Existenzprüfung der Mappingdatei.'
            }
        }

        $strInputExtension = [System.IO.Path]::GetExtension($script:strInputMarkdownPath).ToLowerInvariant()
        $strMappingExtension = [System.IO.Path]::GetExtension($script:strMappingPsvPath).ToLowerInvariant()

        switch ($strInputExtension -eq '.md') {
            $true {
                # Erwartete Erweiterung.
            }

            $false {
                throw ('Die Eingangsdatei muss die Erweiterung .md besitzen: {0}' -f $script:strInputMarkdownPath)
            }

            default {
                throw 'Unerwarteter Zustand bei der Markdown-Erweiterungsprüfung.'
            }
        }

        switch ($strMappingExtension -eq '.psv') {
            $true {
                # Erwartete Erweiterung.
            }

            $false {
                throw ('Die Mappingdatei muss die Erweiterung .psv besitzen: {0}' -f $script:strMappingPsvPath)
            }

            default {
                throw 'Unerwarteter Zustand bei der PSV-Erweiterungsprüfung.'
            }
        }

        $script:strInputMarkdownDir = [System.IO.Path]::GetDirectoryName($script:strInputMarkdownPath)
        $script:strInputMarkdownBaseName = [System.IO.Path]::GetFileNameWithoutExtension($script:strInputMarkdownPath)

        switch ([System.String]::IsNullOrWhiteSpace($script:strInputMarkdownDir)) {
            $true {
                $script:strInputMarkdownDir = [System.IO.Directory]::GetCurrentDirectory()
            }

            $false {
                # Eingabeverzeichnis ist bereits bestimmt.
            }

            default {
                throw 'Unerwarteter Zustand bei der Bestimmung des Eingabeverzeichnisses.'
            }
        }

        $script:strOutputDirectory = $script:strInputMarkdownDir
        $script:strOutputTimeStamp = Get-Date -Format 'yyyy-MM-dd_mmss'

        switch ($Clear.IsPresent) {
            $true {
                $script:strOutputSuffix = 'clear'
                $script:strConversionDirection = 'FOGGY_TO_CLEAR'
                $script:strExecuteDirection = 'clear'
            }

            $false {
                $script:strOutputSuffix = 'foggy'
                $script:strConversionDirection = 'CLEAR_TO_FOGGY'
                $script:strExecuteDirection = 'foggy'
            }

            default {
                throw 'Unerwarteter Zustand bei der Ermittlung der Konvertierungsrichtung.'
            }
        }

        $script:strOutputMarkdownPath = Join-Path `
            -Path $script:strInputMarkdownDir `
            -ChildPath ('{0}_{1}_{2}.md' -f $script:strInputMarkdownBaseName, $script:strOutputSuffix, $script:strOutputTimeStamp)

        switch ([System.IO.File]::Exists($script:strOutputMarkdownPath)) {
            $true {
                throw ('Ausgabedatei existiert bereits. Kein Überschreiben: {0}' -f $script:strOutputMarkdownPath)
            }

            $false {
                # Ausgabedatei kann neu erzeugt werden.
            }

            default {
                throw 'Unerwarteter Zustand bei der Ausgabedateiprüfung.'
            }
        }

        $script:strMarkdownContent = [System.IO.File]::ReadAllText(
            $script:strInputMarkdownPath,
            [System.Text.UTF8Encoding]::new($false, $true)
        )

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | InputMarkdown=''{1}''' -f $strContext, $script:strInputMarkdownPath)
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | MappingPsv=''{1}''' -f $strContext, $script:strMappingPsvPath)
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | ConversionDirection={1}' -f $strContext, $script:strConversionDirection)
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | OutputMarkdown=''{1}''' -f $strContext, $script:strOutputMarkdownPath)
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} END' -f $strContext)
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
}

# ---------------------------------------------------------------
# STEP02: PSV-Mapping einlesen und prüfen
# ---------------------------------------------------------------
<#
.SYNOPSIS
    Liest die zweispaltige PSV-Mapping-Datei und baut die Mappingliste auf.

.DESCRIPTION
    Invoke-STEP02 ist die zweite fachliche Verarbeitungsstufe von
    Invoke-MainOperation. Jede verwertbare Zeile muss exakt zwei Spalten enthalten:
    Token und Klarbezeichnung. Eine Kopfzeile ist nicht vorgesehen.

    Die Klarbezeichnung wird nicht in die Logdatei geschrieben. Für gezielte
    Diagnose kann sie später in Invoke-STEP03 über Write-Debug sichtbar werden.

.PARAMETER refHtbMappingList
    Referenz auf die zentrale SortedList des Aufrufers, die von dieser Funktion
    vollständig aufgebaut wird.

.OUTPUTS
    Keine Pipeline-Ausgabe. Die Mappingliste befindet sich in refHtbMappingList.Value.
#>
function Invoke-STEP02 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ref] $refHtbMappingList
    )

    [System.String] $strContext = 'Invoke-STEP02()'
    [System.String[]] $strArrLines = @()
    [System.String] $strLine = ''
    [System.String[]] $strArrColumns = @()
    [System.Int64] $intLineIndex = 0
    [System.Int64] $intKeyItem = 0
    [System.Int64] $intColumnCount = 0
    [System.String] $strToken = ''
    [System.String] $strReplacement = ''
    [System.Collections.Generic.HashSet[System.String]] $htbTokenSet = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::Ordinal)
    [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]] $htbMappingList = [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]]::new()
    [clsMappingItem] $objMappingItem = $null

    try {
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} START' -f $strContext)

        $strArrLines = [System.IO.File]::ReadAllLines(
            $script:strMappingPsvPath,
            [System.Text.UTF8Encoding]::new($false, $true)
        )

        switch ($strArrLines.Count -eq 0) {
            $true {
                throw ('PSV-Datei ist leer: {0}' -f $script:strMappingPsvPath)
            }

            $false {
                # Datei enthält mindestens eine physische Zeile.
            }

            default {
                throw 'Unerwarteter Zustand bei der Prüfung der PSV-Datei.'
            }
        }

        :MappingLineLoop for ($intLineIndex = 0; $intLineIndex -lt $strArrLines.Count; $intLineIndex++) {
            $strLine = $strArrLines[$intLineIndex].Trim()

            switch (
                [System.String]::IsNullOrWhiteSpace($strLine) -or
                $strLine.StartsWith('#', [System.StringComparison]::Ordinal)
            ) {
                $true {
                    continue MappingLineLoop
                }

                $false {
                    # Verwertbare Mappingzeile wird verarbeitet.
                }

                default {
                    throw 'Unerwarteter Zustand bei der Zeilenfilterung der PSV-Datei.'
                }
            }

            $strArrColumns = @($strLine.Split('|') | ForEach-Object { $_.Trim() })
            $intColumnCount = $strArrColumns.Count

            switch ($intColumnCount -eq 2) {
                $true {
                    # Exakt erwartetes zweispaltiges Format.
                }

                $false {
                    throw ('Ungültige PSV-Zeile {0}. Erwartet werden exakt zwei Spalten: Token|Klarbezeichnung.' -f ($intLineIndex + 1))
                }

                default {
                    throw 'Unerwarteter Zustand bei der PSV-Spaltenprüfung.'
                }
            }

            $strToken = $strArrColumns[0]
            $strReplacement = $strArrColumns[1]

            switch ([System.String]::IsNullOrWhiteSpace($strToken)) {
                $true {
                    throw ('Leeres Token in PSV-Zeile {0}.' -f ($intLineIndex + 1))
                }

                $false {
                    # Token ist vorhanden.
                }

                default {
                    throw 'Unerwarteter Zustand bei der Token-Leerwertprüfung.'
                }
            }

            switch ([System.String]::IsNullOrWhiteSpace($strReplacement)) {
                $true {
                    throw ('Leere Klarbezeichnung in PSV-Zeile {0}.' -f ($intLineIndex + 1))
                }

                $false {
                    # Klarbezeichnung ist vorhanden.
                }

                default {
                    throw 'Unerwarteter Zustand bei der Klarbezeichnungs-Leerwertprüfung.'
                }
            }

            switch ($strToken -match '^\[\[[A-Za-z0-9_]+\]\]$') {
                $true {
                    # Token entspricht dem erwarteten Muster.
                }

                $false {
                    throw ('Ungültiges Token in PSV-Zeile {0}: {1} | Erwartetes Muster: [[A-Za-z0-9_]]' -f ($intLineIndex + 1), $strToken)
                }

                default {
                    throw 'Unerwarteter Zustand bei der Token-Musterprüfung.'
                }
            }

            switch ($htbTokenSet.Contains($strToken)) {
                $true {
                    throw ('Doppeltes Token in PSV-Datei: {0}' -f $strToken)
                }

                $false {
                    [void] $htbTokenSet.Add($strToken)
                }

                default {
                    throw 'Unerwarteter Zustand bei der Prüfung doppelter Tokens.'
                }
            }

            $objMappingItem = [clsMappingItem]::new()
            $objMappingItem.intRowNumber = [System.Int64] ($intLineIndex + 1)
            $objMappingItem.strToken = $strToken
            $objMappingItem.strReplacement = $strReplacement
            $objMappingItem.intOccurrenceCount = 0
            $objMappingItem.strProcessingStatus = 'OK'
            $objMappingItem.strErrorReason = ''

            $intKeyItem = [System.Int64] $htbMappingList.Count + 1
            $htbMappingList.Add($intKeyItem, $objMappingItem)
            $objMappingItem = $null
        }

        switch ($htbMappingList.Count -eq 0) {
            $true {
                throw ('PSV-Datei enthält keine Mapping-Datensätze: {0}' -f $script:strMappingPsvPath)
            }

            $false {
                # Mindestens ein Mappingdatensatz ist vorhanden.
            }

            default {
                throw 'Unerwarteter Zustand bei der Prüfung der Mappingliste.'
            }
        }

        $script:intTokenTotal = $htbMappingList.Count
        $refHtbMappingList.Value = $htbMappingList

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | MappingCount={1}' -f $strContext, $htbMappingList.Count)
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} END' -f $strContext)
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
}

# ---------------------------------------------------------------
# STEP03: Inhalte konvertieren und Plausibilitätsprüfung ausführen
# ---------------------------------------------------------------
<#
.SYNOPSIS
    Konvertiert den Markdown-Inhalt anhand der Mappingliste.

.DESCRIPTION
    Invoke-STEP03 ist die dritte fachliche Verarbeitungsstufe von
    Invoke-MainOperation. Längere Suchtexte werden zuerst verarbeitet. Ohne Clear
    werden Klarbezeichnungen durch Tokens ersetzt; mit Clear erfolgt die
    Rückumwandlung.

    Für jeden Mappingdatensatz werden bei aktivem -Debug Zeilennummer, Richtung,
    Token, Klarbezeichnung und Trefferzahl ausgegeben. Die Logdatei enthält dagegen
    ausdrücklich keine Klarbezeichnungen.

.PARAMETER refHtbMappingList
    Referenz auf die zentrale, bereits validierte Mappingliste. Die Funktion
    aktualisiert die Trefferzähler der enthaltenen Mappingobjekte und gibt die
    geänderte Collection ausschließlich über diese Referenz an den Aufrufer zurück.

.OUTPUTS
    Keine Pipeline-Ausgabe. Der konvertierte Inhalt wird in strFinalContent
    bereitgestellt; die aktualisierte Mappingliste befindet sich in refHtbMappingList.Value.
#>
function Invoke-STEP03 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ref] $refHtbMappingList
    )

    [System.String] $strContext = 'Invoke-STEP03()'
    [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]] $htbMappingList = [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]]::new()
    [clsMappingItem[]] $arrMappingItems = @()
    [clsMappingItem] $objMappingItem = $null
    [System.Int64] $intOccurrenceCount = 0
    [System.String] $strSourceText = ''
    [System.String] $strTargetText = ''
    [System.String] $strEscapedSourceText = ''
    [System.String] $strNoReplacementMessage = ''
    [System.Text.RegularExpressions.MatchCollection] $objUnresolvedMatches = $null
    [System.Text.RegularExpressions.Match] $objMatch = $null
    [System.Collections.Generic.HashSet[System.String]] $htbUnresolvedTokenSet = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::Ordinal)
    [System.String[]] $strArrUnresolved = @()
    [System.String] $strUnresolvedList = ''
    [System.Management.Automation.ErrorRecord] $objMappingError = $null
    [System.InvalidOperationException] $objSanitizedException = $null

    try {
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} START' -f $strContext)

        $htbMappingList = $refHtbMappingList.Value

        switch ($null -eq $htbMappingList -or $htbMappingList.Count -eq 0) {
            $true {
                throw 'Mappingliste ist leer.'
            }

            $false {
                # Mappingliste ist verwendbar.
            }

            default {
                throw 'Unerwarteter Zustand bei der Prüfung der Mappingliste.'
            }
        }

        $script:strFinalContent = $script:strMarkdownContent
        $script:intTotalReplacementCount = 0
        $script:intTokenUsed = 0

        switch ($Clear.IsPresent) {
            $true {
                $arrMappingItems = @(
                    $htbMappingList.Values |
                    Sort-Object -Property @{ Expression = { $_.strToken.Length }; Descending = $true }
                )
            }

            $false {
                $arrMappingItems = @(
                    $htbMappingList.Values |
                    Sort-Object -Property @{ Expression = { $_.strReplacement.Length }; Descending = $true }
                )
            }

            default {
                throw 'Unerwarteter Zustand bei der Sortierung der Mappingliste.'
            }
        }

        foreach ($objMappingItem in $arrMappingItems) {
            $intOccurrenceCount = 0
            $strSourceText = ''
            $strTargetText = ''
            $strEscapedSourceText = ''

            try {
                switch ($Clear.IsPresent) {
                    $true {
                        $strSourceText = $objMappingItem.strToken
                        $strTargetText = $objMappingItem.strReplacement
                    }

                    $false {
                        $strSourceText = $objMappingItem.strReplacement
                        $strTargetText = $objMappingItem.strToken
                    }

                    default {
                        throw 'Unerwarteter Zustand bei der Auswahl von Such- und Zieltext.'
                    }
                }

                Write-Debug (
                    'MAPPING | Row={0} | Direction={1} | Token={2} | ClearText={3}' -f
                    $objMappingItem.intRowNumber,
                    $script:strConversionDirection,
                    $objMappingItem.strToken,
                    $objMappingItem.strReplacement
                )

                $strEscapedSourceText = [System.Text.RegularExpressions.Regex]::Escape($strSourceText)
                $intOccurrenceCount = [System.Text.RegularExpressions.Regex]::Matches(
                    $script:strFinalContent,
                    $strEscapedSourceText
                ).Count

                $objMappingItem.intOccurrenceCount = $intOccurrenceCount

                Write-Debug (
                    'MAPPING RESULT | Row={0} | Direction={1} | Token={2} | ClearText={3} | Count={4}' -f
                    $objMappingItem.intRowNumber,
                    $script:strConversionDirection,
                    $objMappingItem.strToken,
                    $objMappingItem.strReplacement,
                    $intOccurrenceCount
                )

                switch ($intOccurrenceCount -gt 0) {
                    $true {
                        $script:intTokenUsed++
                        $script:intTotalReplacementCount += $intOccurrenceCount
                        $script:strFinalContent = $script:strFinalContent.Replace($strSourceText, $strTargetText)
                    }

                    $false {
                        # Für diesen Mappingdatensatz ist keine Ersetzung erforderlich.
                    }

                    default {
                        throw 'Unerwarteter Zustand bei der Trefferzahlprüfung.'
                    }
                }

                Write-LogMessage -strLevel 'INFO' -strMessage (
                    '{0} | Row={1} | Direction={2} | Token={3} | Count={4}' -f
                    $strContext,
                    $objMappingItem.intRowNumber,
                    $script:strConversionDirection,
                    $objMappingItem.strToken,
                    $intOccurrenceCount
                )
            }
            catch {
                $objMappingError = $_
                $objMappingItem.strProcessingStatus = 'ERROR'
                $objMappingItem.strErrorReason = 'Fehler bei der Mappingverarbeitung.'

                Write-Debug (
                    'MAPPING ERROR | Row={0} | Direction={1} | Token={2} | ClearText={3} | Count={4} | Error={5}' -f
                    $objMappingItem.intRowNumber,
                    $script:strConversionDirection,
                    $objMappingItem.strToken,
                    $objMappingItem.strReplacement,
                    $intOccurrenceCount,
                    $objMappingError.Exception.ToString()
                )

                $objSanitizedException = [System.InvalidOperationException]::new(
                    ('Fehler bei Mapping-Zeile {0}, Token {1}. Detaildiagnose mit -Debug.' -f $objMappingItem.intRowNumber, $objMappingItem.strToken),
                    $null
                )
                $objSanitizedException.Data['Context'] = ('{0} | Row={1} | Token={2}' -f $strContext, $objMappingItem.intRowNumber, $objMappingItem.strToken)
                throw $objSanitizedException
            }
        }

        switch ($script:intTotalReplacementCount -eq 0) {
            $true {
                switch ($Clear.IsPresent) {
                    $true {
                        $strNoReplacementMessage = 'Es wurde kein Token ersetzt. Prüfe Eingangsdatei und Mapping-Datei.'
                    }

                    $false {
                        $strNoReplacementMessage = 'Es wurde keine Klarbezeichnung ersetzt. Prüfe Eingangsdatei und Mapping-Datei.'
                    }

                    default {
                        throw 'Unerwarteter Zustand bei der Meldung ohne Ersetzungen.'
                    }
                }

                Write-LogMessage -strLevel 'WARN' -strMessage ('{0} | Keine Ersetzung durchgeführt.' -f $strContext)
                Write-StatusMessage -strLevel 'WARN' -strMessage $strNoReplacementMessage
            }

            $false {
                # Mindestens eine Ersetzung wurde durchgeführt.
            }

            default {
                throw 'Unerwarteter Zustand bei der Prüfung der Gesamtersetzungen.'
            }
        }

        switch ($Clear.IsPresent) {
            $true {
                $objUnresolvedMatches = [System.Text.RegularExpressions.Regex]::Matches(
                    $script:strFinalContent,
                    '\[\[[A-Za-z0-9_]+\]\]'
                )

                switch ($objUnresolvedMatches.Count -gt 0) {
                    $true {
                        foreach ($objMatch in $objUnresolvedMatches) {
                            [void] $htbUnresolvedTokenSet.Add($objMatch.Value)
                        }

                        $strArrUnresolved = @($htbUnresolvedTokenSet | Sort-Object)
                        $strUnresolvedList = [System.String]::Join(', ', $strArrUnresolved)
                        throw ('Nicht ersetzte Tokens nach Verarbeitung gefunden: {0}' -f $strUnresolvedList)
                    }

                    $false {
                        # Alle Tokens wurden aufgelöst.
                    }

                    default {
                        throw 'Unerwarteter Zustand bei der Resttoken-Prüfung.'
                    }
                }
            }

            $false {
                Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | Resttoken-Prüfung übersprungen, weil Tokens im Foggy-Ausgabeformat gewünscht sind.' -f $strContext)
            }

            default {
                throw 'Unerwarteter Zustand bei der Auswahl der Resttoken-Prüfung.'
            }
        }

        Write-LogMessage -strLevel 'INFO' -strMessage (
            '{0} | Direction={1} | MappingTotal={2} | MappingUsed={3} | ReplacementTotal={4}' -f
            $strContext,
            $script:strConversionDirection,
            $script:intTokenTotal,
            $script:intTokenUsed,
            $script:intTotalReplacementCount
        )

        $refHtbMappingList.Value = $htbMappingList
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} END' -f $strContext)
    }
    catch {
        switch ([System.String]::IsNullOrWhiteSpace([System.String] $_.Exception.Data['Context'])) {
            $true {
                $_.Exception.Data['Context'] = $strContext
            }

            $false {
                # Spezifischer Mappingkontext bleibt erhalten.
            }

            default {
                throw 'Unerwarteter Zustand bei der Fehlerkontextprüfung von STEP03.'
            }
        }

        throw
    }
}

# ---------------------------------------------------------------
# STEP04: Konvertierte Markdown-Datei schreiben
# ---------------------------------------------------------------
<#
.SYNOPSIS
    Schreibt die konvertierte Markdown-Datei.

.DESCRIPTION
    Invoke-STEP04 ist die vierte fachliche Verarbeitungsstufe von
    Invoke-MainOperation. Die Funktion schreibt den konvertierten Inhalt als
    UTF-8 ohne BOM, sofern der zentrale Ausführungsstatus die Änderung erlaubt.
    Unter -WhatIf wird die geplante Ausgabe lediglich protokolliert.

.OUTPUTS
    Keine Pipeline-Ausgabe.
#>
function Invoke-STEP04 {
    [CmdletBinding()]
    param()

    [System.String] $strContext = 'Invoke-STEP04()'
    [System.Text.UTF8Encoding] $objUtf8NoBom = [System.Text.UTF8Encoding]::new($false)

    try {
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} START' -f $strContext)

        switch ([System.String]::IsNullOrWhiteSpace($script:strFinalContent)) {
            $true {
                throw 'Konvertierter Markdown-Inhalt ist leer. Ausgabe wird nicht geschrieben.'
            }

            $false {
                # Inhalt kann geschrieben werden.
            }

            default {
                throw 'Unerwarteter Zustand bei der Prüfung des Ausgabeinhalts.'
            }
        }

        switch ($script:blnShouldProcess) {
            $true {
                [System.IO.File]::WriteAllText(
                    $script:strOutputMarkdownPath,
                    $script:strFinalContent,
                    $objUtf8NoBom
                )

                Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | Output written: {1}' -f $strContext, $script:strOutputMarkdownPath)
            }

            $false {
                Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | Output skipped by WhatIf: {1}' -f $strContext, $script:strOutputMarkdownPath)
            }

            default {
                throw 'Unerwarteter zentraler Ausführungsstatus beim Schreiben der Markdown-Datei.'
            }
        }

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} END' -f $strContext)
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
}

# ---------------------------------------------------------------
# Hauptoperation
# ---------------------------------------------------------------
<#
.SYNOPSIS
    Steuert die vier fachlichen Verarbeitungsstufen der Konvertierung.

.DESCRIPTION
    Invoke-MainOperation ist Eigentümer der zentralen Mappingliste und ruft
    Invoke-STEP01 bis Invoke-STEP04 lückenlos auf. Die Mappingliste wird von
    STEP02 über [ref] aufgebaut und anschließend von STEP03 verarbeitet.

.PARAMETER refHtbMappingList
    Referenz auf die zentrale Mappingliste des Skripteinstiegspunkts.

.OUTPUTS
    Keine Pipeline-Ausgabe. Die gefüllte Mappingliste befindet sich nach der
    Verarbeitung in refHtbMappingList.Value.
#>
function Invoke-MainOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ref] $refHtbMappingList
    )

    [System.String] $strContext = 'Invoke-MainOperation()'
    [System.String] $strMessageMode = ''
    [System.String] $strProgMainMessage = ''
    [System.Diagnostics.Stopwatch] $objSw = [System.Diagnostics.Stopwatch]::new()
    [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]] $htbMappingList = [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]]::new()

    try {
        switch ($WhatIfPreference) {
            $true {
                $strMessageMode = 'SIMULATED'
            }

            $false {
                $strMessageMode = 'ACTIVE'
            }

            default {
                throw 'Unerwarteter Zustand bei der Ermittlung des Ausführungsmodus.'
            }
        }

        switch ($Clear.IsPresent) {
            $true {
                $strProgMainMessage = 'Konvertierung Tokens zu Klarbezeichnungen'
            }

            $false {
                $strProgMainMessage = 'Konvertierung Klarbezeichnungen zu Tokens'
            }

            default {
                throw 'Unerwarteter Zustand bei der Ermittlung der Fortschrittsbeschreibung.'
            }
        }

        Write-LogMessage -strLevel 'INFO' -strMessage (
            '{0} START | Mode={1} | Clear={2} | Silent={3}' -f
            $strContext,
            $strMessageMode,
            $Clear.IsPresent,
            $Silent.IsPresent
        )

        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Initialisiert' -intPercentComplete 5

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} CALL STEP01' -f $strContext)
        $objSw.Restart()
        Invoke-STEP01
        $objSw.Stop()
        Write-LogMessage -strLevel 'INFO' -strMessage ('TIME STEP01 = {0}' -f $objSw.Elapsed)
        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Eingaben geprüft' -intPercentComplete 25

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} CALL STEP02' -f $strContext)
        $objSw.Restart()
        Invoke-STEP02 -refHtbMappingList ([ref] $htbMappingList)
        $objSw.Stop()
        Write-LogMessage -strLevel 'INFO' -strMessage ('TIME STEP02 = {0}' -f $objSw.Elapsed)
        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Mapping eingelesen' -intPercentComplete 50

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} CALL STEP03' -f $strContext)
        $objSw.Restart()
        Invoke-STEP03 -refHtbMappingList ([ref] $htbMappingList)
        $objSw.Stop()
        Write-LogMessage -strLevel 'INFO' -strMessage ('TIME STEP03 = {0}' -f $objSw.Elapsed)
        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Inhalte konvertiert' -intPercentComplete 75

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} CALL STEP04' -f $strContext)
        $objSw.Restart()
        Invoke-STEP04
        $objSw.Stop()
        Write-LogMessage -strLevel 'INFO' -strMessage ('TIME STEP04 = {0}' -f $objSw.Elapsed)
        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Abgeschlossen' -intPercentComplete 100
        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Abgeschlossen' -blnCompleted $true

        $refHtbMappingList.Value = $htbMappingList

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} END' -f $strContext)
    }
    catch {
        switch ([System.String]::IsNullOrWhiteSpace([System.String] $_.Exception.Data['Context'])) {
            $true {
                $_.Exception.Data['Context'] = $strContext
            }

            $false {
                # Ein spezifischer Unterfunktionskontext bleibt erhalten.
            }

            default {
                throw 'Unerwarteter Zustand bei der Fehlerkontextprüfung der Hauptoperation.'
            }
        }

        throw
    }
    finally {
        switch ($objSw.IsRunning) {
            $true {
                $objSw.Stop()
            }

            $false {
                # Stopwatch ist bereits gestoppt.
            }

            default {
                Write-Debug 'Unerwarteter Zustand bei der Stopwatch-Bereinigung.'
            }
        }
    }
}

# ---------------------------------------------------------------
# Technische Initialisierung nach Funktionsdefinitionen
# ---------------------------------------------------------------
try {
    Initialize-LogFile
    Write-LogMessage -strLevel 'INFO' -strMessage ('ScriptPath=''{0}''' -f $script:strScriptPath)
    Write-LogMessage -strLevel 'INFO' -strMessage ('ScriptVersion=''{0}''' -f $script:strVersion)
    Write-LogMessage -strLevel 'INFO' -strMessage ('LogTargetRequested=''{0}'' | LogTargetEffective=''{1}''' -f $LogTarget, $script:strEffectiveLogTarget)
    Write-LogMessage -strLevel 'INFO' -strMessage 'Script started.'
}
catch {
    Write-Host ('🔴 Logging-Initialisierung fehlgeschlagen: {0}' -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------
# ⚙️ JSON-Konfiguration vorbereiten
# ---------------------------------------------------------------
try {
    $script:strConfigFile = Resolve-ConfigFilePath `
        -strConfigPath $ConfigPath `
        -blnInitializeConfig ([System.Boolean] $InitializeConfig.IsPresent)

    switch ($InitializeConfig.IsPresent) {
        $true {
            Test-ConfigInitializationTarget -strConfigFile $script:strConfigFile

            $script:blnShouldProcess = -not [System.Boolean] $WhatIfPreference
            New-ScriptConfig -refObjConfig ([ref] $script:objConfig)

            switch ($script:blnShouldProcess) {
                $true {
                    Test-ConfigWriteAccess -strConfigFile $script:strConfigFile
                    Write-ScriptConfig `
                        -strConfigFile $script:strConfigFile `
                        -refObjConfig ([ref] $script:objConfig) `
                        -blnCreateOnly $true

                    Write-Host ('🟢 Konfigurationsvorlage erzeugt: {0}' -f $script:strConfigFile) -ForegroundColor Green
                    Write-LogFilePath
                    exit 0
                }

                $false {
                    Write-LogMessage -strLevel 'INFO' -strMessage ("CONFIG INIT WHATIF | Path='$script:strConfigFile'")
                    Write-Host ('🟡 WhatIf: Konfigurationsvorlage würde erzeugt werden: {0}' -f $script:strConfigFile) -ForegroundColor Yellow
                    Write-LogFilePath
                    exit 0
                }

                default {
                    throw "Unerwarteter Ausführungsstatus: '$script:blnShouldProcess'"
                }
            }
        }

        $false {
            Import-ScriptConfig `
                -strConfigFile $script:strConfigFile `
                -refObjConfig ([ref] $script:objConfig)

            Show-ScriptConfig `
                -strConfigFile $script:strConfigFile `
                -refObjConfig ([ref] $script:objConfig)

            Confirm-ScriptProcessing
            $script:blnShouldProcess = -not [System.Boolean] $WhatIfPreference
        }

        default {
            throw 'Unerwarteter Zustand bei der Auswertung von InitializeConfig.'
        }
    }
}
catch {
    Write-LogError -objErrorRecord $_
    $script:strMessage = 'Konfigurationsverarbeitung fehlgeschlagen: {0}' -f $_.Exception.Message
    Write-LogMessage -strLevel 'FATAL' -strMessage $script:strMessage
    Write-Host ('🔴 {0}' -f $script:strMessage) -ForegroundColor Red
    Write-Host ('🟡 Erwarteter/verwendeter Konfigurationspfad: {0}' -f $script:strConfigFile) -ForegroundColor Yellow
    Write-Host '🟡 Hinweis: Eine Initialisierungsvorlage kann mit -InitializeConfig erzeugt werden.' -ForegroundColor Yellow
    Write-LogFilePath
    exit 1
}

# ---------------------------------------------------------------
# Skript-Einstiegspunkt
# ---------------------------------------------------------------
try {
    Invoke-MainOperation -refHtbMappingList ([ref] $script:htbMappingList)

    $script:intDetailsOk = 0
    $script:intDetailsErr = 0
    $script:intDetailsTotal = $script:htbMappingList.Count

    foreach ($script:objMappingItem in $script:htbMappingList.Values) {
        switch ($script:objMappingItem.strProcessingStatus) {
            'OK' {
                $script:intDetailsOk++
            }

            'ERROR' {
                $script:intDetailsErr++
            }

            default {
                throw ("Unerwarteter Mappingstatus: '{0}'" -f $script:objMappingItem.strProcessingStatus)
            }
        }
    }

    $script:strMessage = 'SUMMARY | OK={0} | ERROR={1} | TOTAL={2}' -f $script:intDetailsOk, $script:intDetailsErr, $script:intDetailsTotal
    Write-LogMessage -strLevel 'INFO' -strMessage $script:strMessage
    Write-Host ('🟡 {0}' -f $script:strMessage) -ForegroundColor Yellow

    switch ($script:blnShouldProcess) {
        $true {
            Update-ScriptExecutionInfo `
                -refObjConfig ([ref] $script:objConfig) `
                -strExecuteDirection $script:strExecuteDirection

            Test-ConfigWriteAccess -strConfigFile $script:strConfigFile
            Write-ScriptConfig `
                -strConfigFile $script:strConfigFile `
                -refObjConfig ([ref] $script:objConfig) `
                -blnCreateOnly $false
        }

        $false {
            Write-LogMessage -strLevel 'INFO' -strMessage 'CONFIG UPDATE SKIPPED WHATIF'
        }

        default {
            throw 'Unerwarteter zentraler Ausführungsstatus nach der Hauptoperation.'
        }
    }

    $script:blnMainSuccess = $true

    switch ($Clear.IsPresent) {
        $true {
            $script:strStatusReplacementLabel = 'verwendete Klarbezeichnungen'
        }

        $false {
            $script:strStatusReplacementLabel = 'verwendete Tokens'
        }

        default {
            throw 'Unerwarteter Zustand bei der Abschlussbezeichnung.'
        }
    }

    switch ($WhatIfPreference) {
        $true {
            Write-StatusMessage -strLevel 'WARN' -strMessage 'Simulation abgeschlossen. Wegen -WhatIf wurden weder Markdown-Ausgabedatei noch JSON-Konfiguration geändert.'
        }

        $false {
            Write-StatusMessage -strLevel 'OK' -strMessage ('Konvertierte Datei geschrieben: {0}' -f $script:strOutputMarkdownPath)
        }

        default {
            throw 'Unerwarteter Zustand bei der WhatIf-Abschlussauswertung.'
        }
    }

    Write-StatusMessage -strLevel 'INFO' -strMessage ('Ersetzungen: {0} | {1}: {2}/{3}' -f $script:intTotalReplacementCount, $script:strStatusReplacementLabel, $script:intTokenUsed, $script:intTokenTotal)

    Write-LogMessage -strLevel 'INFO' -strMessage 'Script finished successfully.'
    Write-LogFilePath
    exit 0
}
catch {
    Write-LogError -objErrorRecord $_
    Write-LogMessage -strLevel 'FATAL' -strMessage 'Script failed.'
    Write-StatusMessage -strLevel 'FATAL' -strMessage 'Script failed.'
    Write-StatusMessage -strLevel 'ERROR' -strMessage $_.Exception.Message
    Write-LogFilePath
    exit 1
}

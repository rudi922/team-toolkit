<# 
.SYNOPSIS
    Zum Schutz personenbezogener Daten werden Namen und Bezeichnungen durch Platzhalter verschleiert.

Konvertiert Markdown-Inhalte anhand einer PSV-Mapping-Datei zwischen Klarbezeichnungen und Tokens.

.DESCRIPTION
    Für die Nutzung von .md Dateien in Internetdiensten (Übersetzungsprogramme u.ä.) ermöglicht dieses 
    Skript schutzwürdige Textpassagen (Personennamen, Aktenzeichen u.a. Bezeichnungen) durch Platzhalter zu ersetzen 
    und die Platzhalter wieder in die Originaltexte zurückzuersetzen.

    Die Auflistung der Klarbezeichnungen und Platzhalter-Token muss in einer PSV-Datei erfolgen.

    Standardrichtung ohne -Clear:
        Klarbezeichnungen werden durch Tokens ersetzt.
        Ausgabedatei: <Eingangsdatei-ohne-.md>_foggy_yyyy-MM-dd_mmss.md

    Richtung mit -Clear:
        Tokens werden durch Klarbezeichnungen ersetzt.
        Ausgabedatei: <Eingangsdatei-ohne-.md>_clear_yyyy-MM-dd_mmss.md

    Zulässiges PSV-Format mit Kopfzeile:
        Token|Klarbezeichnung|Kategorie|Kommentar
        [[PERSON_001]]|Max Mustermann|Person|Beispielkommentar

    Zulässiges PSV-Format ohne Kopfzeile:
        [[PERSON_001]]|Max Mustermann
        [[FIRMA_001]]|Muster GmbH

    Pflichtfelder:
        Spalte 1: Token
        Spalte 2: Klarbezeichnung

    Optionale Felder:
        Spalte 3: Kategorie
        Spalte 4: Kommentar

    Der Token muss dem Muster [[A-Za-z0-9_]] entsprechen, zum Beispiel:
        [[PERSON_001]]
        [[FIRMA_001]]
        [[AKTENZEICHEN_001]]

    Die Ausgabedatei wird im Ordner der Eingangsdatei erstellt.

    Die Logdatei wird standardmäßig im Ordner der Eingangsdatei erstellt.
    Mit -LogToTemp wird die Logdatei stattdessen im systemneutralen Temp-Pfad erstellt.

.PARAMETER strInputMarkdownFile
    Pfad zur Markdown-Eingangsdatei.

    Standardrichtung ohne -Clear:
        Die Datei enthält Klarbezeichnungen, die durch Tokens ersetzt werden.

    Richtung mit -Clear:
        Die Datei enthält anonymisierte Tokens, die durch Klarbezeichnungen ersetzt werden.

.PARAMETER strMappingPsvFile
    Pfad zur PSV-Mapping-Datei mit Token/Klarbezeichnung-Zuordnungen.

.PARAMETER Clear
    Aktiviert die Rückumwandlung von Tokens in Klarbezeichnungen.
    Ohne -Clear: Klarbezeichnung -> Token; Ausgabesuffix _foggy_yyyy-MM-dd_mmss.md.
    Mit -Clear: Token -> Klarbezeichnung; Ausgabesuffix _clear_yyyy-MM-dd_mmss.md.

.PARAMETER LogToTemp
    Legt die Logdatei im systemneutralen Temp-Pfad ab.
    Ohne diesen Schalter wird die Logdatei im Ordner der Eingangsdatei erstellt.

.PARAMETER Silent
    Unterdrückt Fortschrittsanzeigen und nicht zwingende Konsolenausgaben.
    Fehler- und Fatalmeldungen werden weiterhin ausgegeben.

.EXAMPLE
    ./Convert-AnonymizedMarkdown.ps1 ./Entwurf_klar.md ./Mapping_Klarbezeichnungen.psv -Confirm:$false

    Standardrichtung ohne -Clear: Klarbezeichnungen werden durch Tokens ersetzt.
    Die Ausgabedatei erhält den Suffix _foggy_yyyy-MM-dd_mmss.md.

.EXAMPLE
    ./Convert-AnonymizedMarkdown.ps1 -strInputMarkdownFile ./Entwurf_klar.md -strMappingPsvFile ./Mapping_Klarbezeichnungen.psv -WhatIf

    Simuliert die Standardrichtung ohne Schreiben der Ausgabedatei.

.EXAMPLE
    ./Convert-AnonymizedMarkdown.ps1 -strInputMarkdownFile ./Entwurf_foggy.md -strMappingPsvFile ./Mapping_Klarbezeichnungen.psv -Clear -Confirm:$false

    Richtung mit -Clear: Tokens werden durch Klarbezeichnungen ersetzt.
    Die Ausgabedatei erhält den Suffix _clear_yyyy-MM-dd_mmss.md.

.EXAMPLE
    ./Convert-AnonymizedMarkdown.ps1 -strInputMarkdownFile ./Entwurf_foggy.md -strMappingPsvFile ./Mapping_Klarbezeichnungen.psv -Clear -LogToTemp -Debug -Confirm:$false

    Führt die Rückumwandlung mit Debugausgaben aus und schreibt die Logdatei in den Temp-Pfad.

.NOTES
    🧑‍🔬 Autor: Dipl.-Ing. Alfred Menzel / erstellt mit ChatGPT
    ⚖️ Lizenz: Frei nutzbar, kopierbar und veränderbar, auf eigene Gefahr und ohne Gewährleistung.
    🧩 Zielplattform: PowerShell 7+
    🗓️ Version: 2026-05-31 16:27:54

    Historie:
        2026-05-31 16:28:19  Erstellung auf Basis der PowerShell-7-Entwicklungsrichtlinie und der Crossplattform-Vorlage.
#>

#requires -Version 7.0

# UTF-8 signal: ʘ‿ʘ Grüß Gott – Ça va? – ¿Qué tal? – Привет – 你好 – שלום – नमस्ते – مرحبا

# ---------------------------------------------------------------
# Skript-Ebene: ShouldProcess aktivieren
# ---------------------------------------------------------------
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Eingangsparameter 1:
    # Markdown-Datei mit Klarbezeichnungen oder mit anonymisierten Tokens bei -Clear.
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [System.String] $strInputMarkdownFile,

    # Eingangsparameter 2:
    # PSV-Datei mit Token/Klarbezeichnung-Zuordnungen.
    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [System.String] $strMappingPsvFile,

    # Schalter:
    # Klartextausgabe aktivieren: Tokens werden durch Klarbezeichnungen ersetzt.
    [Parameter(Mandatory = $false)]
    [switch] $Clear,

    # Schalter:
    # Logdatei im systemneutralen Temp-Pfad ablegen.
    # Wenn NICHT gesetzt: Logdatei im Verzeichnis der Eingangsdatei ablegen.
    [Parameter(Mandatory = $false)]
    [switch] $LogToTemp,

    # Schalter:
    # Fortschrittsanzeigen und nicht zwingende Konsolenausgaben unterdrücken.
    [Parameter(Mandatory = $false)]
    [switch] $Silent
)

# ---------------------------------------------------------------
# Strenges Fehlerverhalten
# ---------------------------------------------------------------
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------
# Klassen
# ---------------------------------------------------------------
class clsMappingItem {
    [System.Int64]  $intRowNumber
    [System.String] $strToken
    [System.String] $strReplacement
    [System.String] $strCategory
    [System.String] $strComment
    [System.Int64]  $intOccurrenceCount
    [System.String] $strProcessingStatus
    [System.String] $strErrorReason
}

# ---------------------------------------------------------------
# Skript-Variablen
# ---------------------------------------------------------------
[System.String]  $script:strVersion               = '2026-05-31 15:40'
[System.String]  $script:strScriptPath            = $PSCommandPath
[System.String]  $script:strScriptName            = ''
[System.String]  $script:strScriptDir             = ''
[System.String]  $script:strLogDir                = ''
[System.String]  $script:strLogTimeStamp          = Get-Date -Format 'yyyyMMdd_HHmmss'
[System.String]  $script:strLogFileName           = ''
[System.String]  $script:strLogFile               = ''
[System.String]  $script:strMessage               = ''
[System.String]  $script:strInputMarkdownPath     = ''
[System.String]  $script:strMappingPsvPath        = ''
[System.String]  $script:strInputMarkdownDir      = ''
[System.String]  $script:strInputMarkdownBaseName = ''
[System.String]  $script:strOutputTimeStamp       = ''
[System.String]  $script:strOutputMarkdownPath    = ''
[System.String]  $script:strOutputSuffix          = ''
[System.String]  $script:strConversionDirection   = ''
[System.String]  $script:strMarkdownContent       = ''
[System.String]  $script:strFinalContent          = ''
[System.Int64]   $script:intTotalReplacementCount = 0
[System.Int64]   $script:intTokenTotal            = 0
[System.Int64]   $script:intTokenUsed             = 0
[System.Boolean] $script:blnMainSuccess           = $false

# ---------------------------------------------------------------
# Frühe Initialisierung
# ---------------------------------------------------------------
if ([System.String]::IsNullOrWhiteSpace($script:strScriptPath)) {
    $script:strScriptPath = [System.IO.Path]::GetFullPath('.')
}

$script:strScriptName = Split-Path -Leaf $script:strScriptPath
$script:strScriptDir = Split-Path -Parent $script:strScriptPath

if ([System.String]::IsNullOrWhiteSpace($script:strScriptDir)) {
    $script:strScriptDir = [System.IO.Directory]::GetCurrentDirectory()
}

$script:strInputMarkdownPath = [System.IO.Path]::GetFullPath($strInputMarkdownFile)
$script:strInputMarkdownDir = [System.IO.Path]::GetDirectoryName($script:strInputMarkdownPath)

if ([System.String]::IsNullOrWhiteSpace($script:strInputMarkdownDir)) {
    $script:strInputMarkdownDir = [System.IO.Directory]::GetCurrentDirectory()
}

$script:strLogDir = $script:strInputMarkdownDir

if (-not [System.IO.Directory]::Exists($script:strLogDir)) {
    $script:strLogDir = [System.IO.Directory]::GetCurrentDirectory()
}

if ($LogToTemp) {
    $script:strLogDir = [System.IO.Path]::GetTempPath()

    if ([System.String]::IsNullOrWhiteSpace($script:strLogDir)) {
        $script:strLogDir = $script:strInputMarkdownDir
    }
}

$script:strLogFileName = '{0}_{1}.log' -f [System.IO.Path]::GetFileNameWithoutExtension($script:strScriptName), $script:strLogTimeStamp
$script:strLogFile = Join-Path -Path $script:strLogDir -ChildPath $script:strLogFileName

# ---------------------------------------------------------------
# Logging-Funktionen
# - WhatIf wird bewusst übersteuert, damit Logging immer erfolgt.
# ---------------------------------------------------------------
function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strLevel,

        [Parameter(Mandatory = $true)]
        [System.String] $strMessage
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strTime = ''
    [System.String] $strLine = ''

    $strTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $strLine = '{0} [{1}] {2}' -f $strTime, $strLevel, $strMessage

    Write-Debug $strLine
    Add-Content -Path $script:strLogFile -Value $strLine -Encoding utf8 -WhatIf:$false
}

function Write-LogError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord] $objErrorRecord
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strMsg = ''
    [System.String] $strStack = ''
    [System.String] $strContext = ''

    $strMsg = 'Message: {0}' -f $objErrorRecord.Exception.Message
    $strStack = 'Stack:   {0}' -f $objErrorRecord.ScriptStackTrace

    try {
        $strContext = [System.String] $objErrorRecord.Exception.Data['Context']
    }
    catch {
        $strContext = ''
    }

    if (-not [System.String]::IsNullOrWhiteSpace($strContext)) {
        Write-LogMessage -strLevel 'ERROR' -strMessage ('Context: {0}' -f $strContext)
    }

    Write-Debug "ERROR $strMsg"
    Write-Debug "ERROR $strStack"

    Write-LogMessage -strLevel 'ERROR' -strMessage $strMsg
    Write-LogMessage -strLevel 'ERROR' -strMessage $strStack
}

function Write-StatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $strLevel,

        [Parameter(Mandatory = $true)]
        [System.String] $strMessage
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strPrefix = ''
    [System.ConsoleColor] $objColor = [System.ConsoleColor]::White

    if ($Silent -and $strLevel -ne 'ERROR' -and $strLevel -ne 'FATAL') {
        return
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
        default {
            $strPrefix = 'ℹ️'
            $objColor = [System.ConsoleColor]::White
        }
    }

    Write-Host ('{0} {1}' -f $strPrefix, $strMessage) -ForegroundColor $objColor
}

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
        [switch] $Completed
    )

    if ($Silent) {
        return
    }

    if ($Completed) {
        Write-Progress -Id $intId -Activity $strActivity -Completed
    }
    else {
        Write-Progress -Id $intId -Activity $strActivity -Status $strStatus -PercentComplete $intPercentComplete
    }
}

# ---------------------------------------------------------------
# Integritätsprüfung des Skripts
# ---------------------------------------------------------------
function Test-ScriptIntegrity {
    [CmdletBinding()]
    param()

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String[]] $strArrRequiredFunctions = @(
        'Write-LogMessage',
        'Write-LogError',
        'Write-StatusMessage',
        'Write-ProgressSafe',
        'Test-PowerShellRuntime',
        'Invoke-STEP01',
        'Invoke-STEP02',
        'Invoke-STEP03',
        'Invoke-STEP04',
        'Invoke-MainOperation'
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

            Write-StatusMessage -strLevel 'FATAL' -strMessage ('INTEGRITY | Fehlende Funktion: {0}' -f $strFunc)
        }
    }

    if (-not $blnOk) {
        Write-StatusMessage -strLevel 'FATAL' -strMessage 'INTEGRITY | Skript ist unvollständig oder es wurde NICHT die erwartete Datei ausgeführt.'
        exit 2
    }
}

# ---------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------
function Test-PowerShellRuntime {
    [CmdletBinding()]
    param()

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strContext = 'Test-PowerShellRuntime()'
    [System.String] $strVersionFound = ''

    try {
        $strVersionFound = $PSVersionTable.PSVersion.ToString()
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | PowerShellVersion={1}' -f $strContext, $strVersionFound)

        if ($PSVersionTable.PSVersion.Major -lt 7) {
            throw ('PowerShell 7 oder höher erforderlich. Gefunden: {0}' -f $strVersionFound)
        }

        if ($IsWindows -and [System.Console]::OutputEncoding.WebName -ne 'utf-8') {
            throw 'Console OutputEncoding ist unter Windows nicht UTF-8. Bitte Terminal/Profil prüfen.'
        }
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
}

function Get-RequiredPropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object] $objRow,

        [Parameter(Mandatory = $true)]
        [System.String] $strPropertyName,

        [Parameter(Mandatory = $true)]
        [System.Int64] $intRowNumber
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strContext = 'Get-RequiredPropertyValue()'
    [System.String] $strValue = ''

    try {
        if (-not ($objRow.PSObject.Properties.Name -contains $strPropertyName)) {
            throw ('Pflichtspalte fehlt: {0}' -f $strPropertyName)
        }

        $strValue = [System.String] $objRow.$strPropertyName

        if ([System.String]::IsNullOrWhiteSpace($strValue)) {
            throw ('Leerer Pflichtwert in Zeile {0}, Spalte {1}' -f $intRowNumber, $strPropertyName)
        }

        return $strValue.Trim()
    }
    catch {
        $_.Exception.Data['Context'] = ('{0} | Row={1} | Property={2}' -f $strContext, $intRowNumber, $strPropertyName)
        throw
    }
}

function Get-OptionalPropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object] $objRow,

        [Parameter(Mandatory = $true)]
        [System.String] $strPropertyName
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strValue = ''

    if (-not ($objRow.PSObject.Properties.Name -contains $strPropertyName)) {
        return ''
    }

    $strValue = [System.String] $objRow.$strPropertyName

    if ([System.String]::IsNullOrWhiteSpace($strValue)) {
        return ''
    }

    return $strValue.Trim()
}

# ---------------------------------------------------------------
# STEP01: Eingaben prüfen, Ausgabepfad bestimmen und Markdown-Datei lesen
# ---------------------------------------------------------------
function Invoke-STEP01 {
    [CmdletBinding()]
    param()

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strContext = 'Invoke-STEP01()'
    [System.String] $strInputExtension = ''
    [System.String] $strMappingExtension = ''

    try {
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} START' -f $strContext)

        $script:strInputMarkdownPath = [System.IO.Path]::GetFullPath($strInputMarkdownFile)
        $script:strMappingPsvPath = [System.IO.Path]::GetFullPath($strMappingPsvFile)

        if (-not [System.IO.File]::Exists($script:strInputMarkdownPath)) {
            throw ('Markdown-Eingangsdatei nicht gefunden: {0}' -f $script:strInputMarkdownPath)
        }

        if (-not [System.IO.File]::Exists($script:strMappingPsvPath)) {
            throw ('PSV-Mappingdatei nicht gefunden: {0}' -f $script:strMappingPsvPath)
        }

        $strInputExtension = [System.IO.Path]::GetExtension($script:strInputMarkdownPath).ToLowerInvariant()
        $strMappingExtension = [System.IO.Path]::GetExtension($script:strMappingPsvPath).ToLowerInvariant()

        if ($strInputExtension -ne '.md') {
            throw ('Die Eingangsdatei muss die Erweiterung .md besitzen: {0}' -f $script:strInputMarkdownPath)
        }

        if ($strMappingExtension -ne '.psv') {
            throw ('Die Mappingdatei muss die Erweiterung .psv besitzen: {0}' -f $script:strMappingPsvPath)
        }

        $script:strInputMarkdownDir = [System.IO.Path]::GetDirectoryName($script:strInputMarkdownPath)
        $script:strInputMarkdownBaseName = [System.IO.Path]::GetFileNameWithoutExtension($script:strInputMarkdownPath)

        if ([System.String]::IsNullOrWhiteSpace($script:strInputMarkdownDir)) {
            $script:strInputMarkdownDir = [System.IO.Directory]::GetCurrentDirectory()
        }

        $script:strOutputTimeStamp = Get-Date -Format 'yyyy-MM-dd_mmss'

        if ($Clear) {
            $script:strOutputSuffix = 'clear'
            $script:strConversionDirection = 'FOGGY_TO_CLEAR'
        }
        else {
            $script:strOutputSuffix = 'foggy'
            $script:strConversionDirection = 'CLEAR_TO_FOGGY'
        }

        $script:strOutputMarkdownPath = Join-Path `
            -Path $script:strInputMarkdownDir `
            -ChildPath ('{0}_{1}_{2}.md' -f $script:strInputMarkdownBaseName, $script:strOutputSuffix, $script:strOutputTimeStamp)

        if ([System.IO.File]::Exists($script:strOutputMarkdownPath)) {
            throw ('Ausgabedatei existiert bereits. Kein Überschreiben: {0}' -f $script:strOutputMarkdownPath)
        }

        $script:strMarkdownContent = [System.IO.File]::ReadAllText(
            $script:strInputMarkdownPath,
            [System.Text.Encoding]::UTF8
        )

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | InputMarkdown=''{1}''' -f $strContext, $script:strInputMarkdownPath)
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | MappingPsv=''{1}''' -f $strContext, $script:strMappingPsvPath)
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | Clear={1}' -f $strContext, $Clear)
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
function Invoke-STEP02 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ref] $refHtbMappingList
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strContext = 'Invoke-STEP02()'
    [System.String[]] $strArrLines = @()
    [System.String] $strLine = ''
    [System.String] $strFirstDataLine = ''
    [System.String[]] $strArrColumns = @()
    [System.Int64] $intLineIndex = 0
    [System.Int64] $intFirstDataLineIndex = -1
    [System.Int64] $intMappingStartIndex = 0
    [System.Int64] $intKeyItem = 0
    [System.Int64] $intColumnCount = 0
    [System.Boolean] $blnHasHeader = $false
    [System.String] $strToken = ''
    [System.String] $strReplacement = ''
    [System.String] $strCategory = ''
    [System.String] $strComment = ''
    [System.Collections.Generic.HashSet[System.String]] $htbTokenSet = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::Ordinal)
    [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]] $htbMappingList = [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]]::new()
    [clsMappingItem] $objMappingItem = $null

    try {
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} START' -f $strContext)

        # WICHTIG:
        # ReadAllLines liest die Datei vollständig und gibt den Datei-Handle sofort wieder frei.
        # Keine Verwendung von [System.IO.File]::ReadLines(...) | Select-Object -First 1,
        # weil diese Konstruktion unter Windows zu einem offenen Datei-Handle führen kann.
        $strArrLines = [System.IO.File]::ReadAllLines(
            $script:strMappingPsvPath,
            [System.Text.Encoding]::UTF8
        )

        if ($strArrLines.Count -eq 0) {
            throw ('PSV-Datei ist leer: {0}' -f $script:strMappingPsvPath)
        }

        for ($intLineIndex = 0; $intLineIndex -lt $strArrLines.Count; $intLineIndex++) {
            $strLine = $strArrLines[$intLineIndex].Trim()

            if ([System.String]::IsNullOrWhiteSpace($strLine)) {
                continue
            }

            if ($strLine.StartsWith('#')) {
                continue
            }

            $strFirstDataLine = $strLine
            $intFirstDataLineIndex = $intLineIndex
            break
        }

        if ($intFirstDataLineIndex -lt 0) {
            throw ('PSV-Datei enthält keine verwertbaren Mapping-Zeilen: {0}' -f $script:strMappingPsvPath)
        }

        $strArrColumns = @($strFirstDataLine.Split('|') | ForEach-Object { $_.Trim() })

        if ($strArrColumns.Count -ge 2) {
            if (
                $strArrColumns[0].Equals('Token', [System.StringComparison]::OrdinalIgnoreCase) -and
                $strArrColumns[1].Equals('Klarbezeichnung', [System.StringComparison]::OrdinalIgnoreCase)
            ) {
                $blnHasHeader = $true
                $intMappingStartIndex = $intFirstDataLineIndex + 1
            }
            else {
                $blnHasHeader = $false
                $intMappingStartIndex = $intFirstDataLineIndex
            }
        }
        else {
            throw ('Ungültige erste PSV-Datenzeile. Erwartet: Token|Klarbezeichnung. Zeile {0}: {1}' -f ($intFirstDataLineIndex + 1), $strFirstDataLine)
        }

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | HasHeader={1}' -f $strContext, $blnHasHeader)

        for ($intLineIndex = $intMappingStartIndex; $intLineIndex -lt $strArrLines.Count; $intLineIndex++) {
            $strLine = $strArrLines[$intLineIndex].Trim()

            if ([System.String]::IsNullOrWhiteSpace($strLine)) {
                continue
            }

            if ($strLine.StartsWith('#')) {
                continue
            }

            $strArrColumns = @($strLine.Split('|') | ForEach-Object { $_.Trim() })
            $intColumnCount = $strArrColumns.Count

            if ($intColumnCount -lt 2) {
                throw ('Ungültige PSV-Zeile {0}. Erwartet mindestens: Token|Klarbezeichnung. Inhalt: {1}' -f ($intLineIndex + 1), $strLine)
            }

            if ($intColumnCount -gt 4) {
                throw ('Ungültige PSV-Zeile {0}. Es sind maximal 4 Spalten erlaubt: Token|Klarbezeichnung|Kategorie|Kommentar. Prüfe unerlaubte Pipe-Zeichen im Inhalt. Inhalt: {1}' -f ($intLineIndex + 1), $strLine)
            }

            $strToken = $strArrColumns[0]
            $strReplacement = $strArrColumns[1]
            $strCategory = ''
            $strComment = ''

            if ($intColumnCount -ge 3) {
                $strCategory = $strArrColumns[2]
            }

            if ($intColumnCount -ge 4) {
                $strComment = $strArrColumns[3]
            }

            if ([System.String]::IsNullOrWhiteSpace($strToken)) {
                throw ('Leeres Token in PSV-Zeile {0}.' -f ($intLineIndex + 1))
            }

            if ([System.String]::IsNullOrWhiteSpace($strReplacement)) {
                throw ('Leere Klarbezeichnung in PSV-Zeile {0}.' -f ($intLineIndex + 1))
            }

            if ($strToken -notmatch '^\[\[[A-Za-z0-9_]+\]\]$') {
                throw ('Ungültiges Token in PSV-Zeile {0}: {1} | Erwartetes Muster: [[A-Za-z0-9_]]' -f ($intLineIndex + 1), $strToken)
            }

            if ($htbTokenSet.Contains($strToken)) {
                throw ('Doppeltes Token in PSV-Datei: {0}' -f $strToken)
            }

            [void] $htbTokenSet.Add($strToken)

            $objMappingItem = [clsMappingItem]::new()
            $objMappingItem.intRowNumber = [System.Int64] ($intLineIndex + 1)
            $objMappingItem.strToken = $strToken
            $objMappingItem.strReplacement = $strReplacement
            $objMappingItem.strCategory = $strCategory
            $objMappingItem.strComment = $strComment
            $objMappingItem.intOccurrenceCount = 0
            $objMappingItem.strProcessingStatus = 'OK'
            $objMappingItem.strErrorReason = ''

            $intKeyItem = [System.Int64] $htbMappingList.Count + 1
            $htbMappingList.Add($intKeyItem, $objMappingItem)
        }

        if ($htbMappingList.Count -eq 0) {
            throw ('PSV-Datei enthält keine Mapping-Datensätze: {0}' -f $script:strMappingPsvPath)
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
function Invoke-STEP03 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]] $htbMappingList
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strContext = 'Invoke-STEP03()'
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

    try {
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} START' -f $strContext)

        if ($null -eq $htbMappingList -or $htbMappingList.Count -eq 0) {
            throw 'Mappingliste ist leer.'
        }

        $script:strFinalContent = $script:strMarkdownContent
        $script:intTotalReplacementCount = 0
        $script:intTokenUsed = 0

        # Längere Suchtexte zuerst ersetzen.
        # Das reduziert Seiteneffekte bei sich überschneidenden Token- oder Klarbezeichnungswerten.
        if ($Clear) {
            $arrMappingItems = @(
                $htbMappingList.Values |
                Sort-Object -Property @{ Expression = { $_.strToken.Length }; Descending = $true }
            )
        }
        else {
            $arrMappingItems = @(
                $htbMappingList.Values |
                Sort-Object -Property @{ Expression = { $_.strReplacement.Length }; Descending = $true }
            )
        }

        foreach ($objMappingItem in $arrMappingItems) {
            if ($Clear) {
                $strSourceText = $objMappingItem.strToken
                $strTargetText = $objMappingItem.strReplacement
            }
            else {
                $strSourceText = $objMappingItem.strReplacement
                $strTargetText = $objMappingItem.strToken
            }

            $strEscapedSourceText = [System.Text.RegularExpressions.Regex]::Escape($strSourceText)
            $intOccurrenceCount = [System.Text.RegularExpressions.Regex]::Matches(
                $script:strFinalContent,
                $strEscapedSourceText
            ).Count

            $objMappingItem.intOccurrenceCount = $intOccurrenceCount

            if ($intOccurrenceCount -gt 0) {
                $script:intTokenUsed++
                $script:intTotalReplacementCount += $intOccurrenceCount
                $script:strFinalContent = $script:strFinalContent.Replace($strSourceText, $strTargetText)
            }

            Write-LogMessage -strLevel 'INFO' -strMessage (
                '{0} | Direction={1} | Token={2} | Count={3}' -f
                $strContext,
                $script:strConversionDirection,
                $objMappingItem.strToken,
                $intOccurrenceCount
            )
        }

        if ($script:intTotalReplacementCount -eq 0) {
            if ($Clear) {
                $strNoReplacementMessage = 'Es wurde kein Token ersetzt. Prüfe Eingangsdatei und Mapping-Datei.'
            }
            else {
                $strNoReplacementMessage = 'Es wurde keine Klarbezeichnung ersetzt. Prüfe Eingangsdatei und Mapping-Datei.'
            }

            Write-LogMessage -strLevel 'WARN' -strMessage ('{0} | Keine Ersetzung durchgeführt.' -f $strContext)
            Write-StatusMessage -strLevel 'WARN' -strMessage $strNoReplacementMessage
        }

        if (-not $Clear) {
            Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | Resttoken-Prüfung übersprungen, weil Tokens im Foggy-Ausgabeformat gewünscht sind.' -f $strContext)
        }
        else {
            $objUnresolvedMatches = [System.Text.RegularExpressions.Regex]::Matches(
                $script:strFinalContent,
                '\[\[[A-Za-z0-9_]+\]\]'
            )

            if ($objUnresolvedMatches.Count -gt 0) {
                foreach ($objMatch in $objUnresolvedMatches) {
                    [void] $htbUnresolvedTokenSet.Add($objMatch.Value)
                }

                $strArrUnresolved = @($htbUnresolvedTokenSet | Sort-Object)
                $strUnresolvedList = [System.String]::Join(', ', $strArrUnresolved)

                throw ('Nicht ersetzte Tokens nach Verarbeitung gefunden: {0}' -f $strUnresolvedList)
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

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} END' -f $strContext)
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
}

# ---------------------------------------------------------------
# STEP04: Konvertierte Markdown-Datei schreiben
# ---------------------------------------------------------------
function Invoke-STEP04 {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param()

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strContext = 'Invoke-STEP04()'
    [System.Text.UTF8Encoding] $objUtf8NoBom = [System.Text.UTF8Encoding]::new($false)

    try {
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} START' -f $strContext)

        if ([System.String]::IsNullOrWhiteSpace($script:strFinalContent)) {
            throw 'Konvertierter Markdown-Inhalt ist leer. Ausgabe wird nicht geschrieben.'
        }

        if ($PSCmdlet.ShouldProcess($script:strOutputMarkdownPath, 'Konvertierte Markdown-Datei schreiben')) {
            [System.IO.File]::WriteAllText(
                $script:strOutputMarkdownPath,
                $script:strFinalContent,
                $objUtf8NoBom
            )

            Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | Output written: {1}' -f $strContext, $script:strOutputMarkdownPath)
        }
        else {
            Write-LogMessage -strLevel 'INFO' -strMessage ('{0} | Output skipped by ShouldProcess/WhatIf: {1}' -f $strContext, $script:strOutputMarkdownPath)
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
function Invoke-MainOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ref] $refHtbMappingList
    )

    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.String] $strContext = 'Invoke-MainOperation()'
    [System.String] $strMessageMode = ''
    [System.String] $strProgMainMessage = ''
    [System.Diagnostics.Stopwatch] $objSw = $null
    [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]] $htbMappingList = [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]]::new()

    try {
        $strMessageMode = if ($WhatIfPreference) { 'SIMULATED' } else { 'ACTIVE' }

        if ($Clear) {
            $strProgMainMessage = 'Konvertierung Tokens zu Klarbezeichnungen'
        }
        else {
            $strProgMainMessage = 'Konvertierung Klarbezeichnungen zu Tokens'
        }

        Write-LogMessage -strLevel 'INFO' -strMessage (
            '{0} START | Mode={1} | Clear={2} | LogToTemp={3} | Silent={4}' -f
            $strContext,
            $strMessageMode,
            $Clear,
            $LogToTemp,
            $Silent
        )

        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Initialisiert' -intPercentComplete 5

        # -------------------------------------------------------
        # STEP01
        # -------------------------------------------------------
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} CALL STEP01' -f $strContext)
        $objSw = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-STEP01
        $objSw.Stop()
        Write-LogMessage -strLevel 'INFO' -strMessage ('TIME STEP01 = {0}' -f $objSw.Elapsed)
        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Eingaben geprüft' -intPercentComplete 25

        # -------------------------------------------------------
        # STEP02
        # -------------------------------------------------------
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} CALL STEP02' -f $strContext)
        $objSw = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-STEP02 -refHtbMappingList ([ref] $htbMappingList)
        $objSw.Stop()
        Write-LogMessage -strLevel 'INFO' -strMessage ('TIME STEP02 = {0}' -f $objSw.Elapsed)
        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Mapping eingelesen' -intPercentComplete 50

        # -------------------------------------------------------
        # STEP03
        # -------------------------------------------------------
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} CALL STEP03' -f $strContext)
        $objSw = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-STEP03 -htbMappingList $htbMappingList
        $objSw.Stop()
        Write-LogMessage -strLevel 'INFO' -strMessage ('TIME STEP03 = {0}' -f $objSw.Elapsed)
        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Inhalte konvertiert' -intPercentComplete 75

        # -------------------------------------------------------
        # STEP04
        # -------------------------------------------------------
        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} CALL STEP04' -f $strContext)
        $objSw = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-STEP04
        $objSw.Stop()
        Write-LogMessage -strLevel 'INFO' -strMessage ('TIME STEP04 = {0}' -f $objSw.Elapsed)
        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Abgeschlossen' -intPercentComplete 100
        Write-ProgressSafe -intId 1 -strActivity $strProgMainMessage -strStatus 'Abgeschlossen' -Completed

        $refHtbMappingList.Value = $htbMappingList

        Write-LogMessage -strLevel 'INFO' -strMessage (
            'SUMMARY | Direction={0} | MappingTotal={1} | MappingUsed={2} | ReplacementTotal={3} | Output=''{4}''' -f
            $script:strConversionDirection,
            $script:intTokenTotal,
            $script:intTokenUsed,
            $script:intTotalReplacementCount,
            $script:strOutputMarkdownPath
        )

        Write-LogMessage -strLevel 'INFO' -strMessage ('{0} END' -f $strContext)
    }
    catch {
        $_.Exception.Data['Context'] = $strContext
        throw
    }
}

# ---------------------------------------------------------------
# Skript-Einstiegspunkt
# ---------------------------------------------------------------
try {
    # -------------------------------------------------------------------------
    # Deklarationen
    # -------------------------------------------------------------------------
    [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]] $htbMappingList = [System.Collections.Generic.SortedList[System.Int64, clsMappingItem]]::new()
    [System.String] $strStatusReplacementLabel = ''

    Write-LogMessage -strLevel 'INFO' -strMessage ('ScriptPath=''{0}''' -f $script:strScriptPath)
    Write-LogMessage -strLevel 'INFO' -strMessage ('ScriptVersion=''{0}''' -f $script:strVersion)
    Write-LogMessage -strLevel 'INFO' -strMessage 'Script started.'

    Test-ScriptIntegrity
    Test-PowerShellRuntime

    Invoke-MainOperation -refHtbMappingList ([ref] $htbMappingList)

    $script:blnMainSuccess = $true

    if ($Clear) {
        $strStatusReplacementLabel = 'verwendete Klarbezeichnungen'
    }
    else {
        $strStatusReplacementLabel = 'verwendete Tokens'
    }

    if ($WhatIfPreference) {
        Write-StatusMessage -strLevel 'WARN' -strMessage 'Simulation abgeschlossen. Wegen -WhatIf wurde keine Ausgabedatei geschrieben.'
    }
    else {
        Write-StatusMessage -strLevel 'OK' -strMessage ('Konvertierte Datei geschrieben: {0}' -f $script:strOutputMarkdownPath)
    }

    Write-StatusMessage -strLevel 'INFO' -strMessage ('Ersetzungen: {0} | {1}: {2}/{3}' -f $script:intTotalReplacementCount, $strStatusReplacementLabel, $script:intTokenUsed, $script:intTokenTotal)
    Write-StatusMessage -strLevel 'INFO' -strMessage ('Logdatei: {0}' -f $script:strLogFile)

    Write-LogMessage -strLevel 'INFO' -strMessage 'Script finished successfully.'
    exit 0
}
catch {
    Write-LogError -objErrorRecord $_
    Write-LogMessage -strLevel 'FATAL' -strMessage 'Script failed.'
    Write-StatusMessage -strLevel 'FATAL' -strMessage 'Script failed.'
    Write-StatusMessage -strLevel 'ERROR' -strMessage $_.Exception.Message
    Write-StatusMessage -strLevel 'ERROR' -strMessage ('Logdatei: {0}' -f $script:strLogFile)
    exit 1
}

<#
.SYNOPSIS
    Importiert Hilfsfunktionen fuer symmetrische OpenPGP-Dateiverschluesselung mit GnuPG.

.DESCRIPTION
    Diese Datei ist fuer Dot-Sourcing vorgesehen. Beim Laden werden nur Funktionen und optionale Kurzaliase bereitgestellt.
    Es wird keine Datei verschluesselt oder entschluesselt, solange keine der Funktionen aufgerufen wird.

    Die Funktionen kapseln folgende GnuPG-Grundbefehle:

    Verschluesseln:
        gpg --symmetric --cipher-algo AES256 --output Unterlagen.zip.gpg Unterlagen.zip

    Entschluesseln:
        gpg --output Unterlagen.zip --decrypt Unterlagen.zip.gpg

    Die Datei verwendet bewusst keine Protokollfunktionalitaet und schreibt keine Logdateien.

.NOTES
    Zielplattform: PowerShell 7 oder hoeher
    Voraussetzung: gpg muss im Suchpfad erreichbar sein.

    Dot-Sourcing-Beispiel:
        . ./scriptname.ps1

    Danach verfuegbare Befehle:
        Protect-GpgSymmetricFile Unterlagen.zip
        Unprotect-GpgSymmetricFile Unterlagen.zip.gpg
        pgpenc Unterlagen.zip
        pgpdec Unterlagen.zip.gpg

# Version: 2026-07-06 13:45
#>

#requires -Version 7.0

#region Initialisierung

[System.String]$script:strRequiredPowerShellVersion = '7.0'
[System.Version]$script:objRequiredPowerShellVersion = [System.Version]::new($script:strRequiredPowerShellVersion)

if ($PSVersionTable.PSVersion -lt $script:objRequiredPowerShellVersion) {
    throw "Dieses Skript benoetigt PowerShell $script:strRequiredPowerShellVersion oder hoeher. Aktuelle Version: $($PSVersionTable.PSVersion)"
}

#endregion Initialisierung

#region Hilfsfunktionen

function Get-GpgSymmetricCommand {
<#+
.SYNOPSIS
    Ermittelt den GnuPG-Befehl im Suchpfad.

.DESCRIPTION
    Die Funktion prueft, ob der Befehl gpg auf dem System verfuegbar ist.
    Sie liefert den gefundenen CommandInfo-Eintrag zurueck. Wird gpg nicht gefunden,
    bricht die Funktion mit einem klaren Fehler ab.

    Die Suche verwendet bewusst keinen festen CommandType-Filter. Dadurch werden
    auch Umgebungen abgedeckt, in denen gpg durch PowerShell anders aufgeloest wird
    als erwartet.

.EXAMPLE
    Get-GpgSymmetricCommand

    Prueft, ob gpg verfuegbar ist.

.NOTES
    Diese Hilfsfunktion wird intern verwendet.
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.CommandInfo])]
    param ()

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        [System.Management.Automation.CommandInfo]$objGpgCommand = $null
    }

    process {
        try {
            $objGpgCommand = Get-Command -Name 'gpg' -ErrorAction Stop | Select-Object -First 1
        }
        catch {
            throw 'GnuPG wurde nicht gefunden. Stelle sicher, dass gpg installiert ist und im Suchpfad liegt.'
        }

        if ($null -eq $objGpgCommand) {
            throw 'GnuPG wurde nicht gefunden. Stelle sicher, dass gpg installiert ist und im Suchpfad liegt.'
        }

        Write-Debug "Gefundener GPG-Befehl: Name=$($objGpgCommand.Name); Typ=$($objGpgCommand.CommandType); Quelle=$($objGpgCommand.Source)"

        return $objGpgCommand
    }
}

function Get-GpgSymmetricInputFile {
<#+
.SYNOPSIS
    Prueft und ermittelt eine Eingabedatei.

.DESCRIPTION
    Die Funktion prueft, ob der angegebene Pfad auf eine vorhandene Datei verweist.
    Bei Erfolg wird ein FileInfo-Objekt zurueckgegeben. Bei Fehlern wird eindeutig abgebrochen.

.PARAMETER strPath
    Pfad zur Eingabedatei.

.EXAMPLE
    Get-GpgSymmetricInputFile -strPath Unterlagen.zip

    Prueft die Datei Unterlagen.zip.

.NOTES
    Diese Hilfsfunktion wird intern verwendet.
#>
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('Path', 'LiteralPath')]
        [System.String]$strPath
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        [System.IO.FileInfo]$objInputFile = $null
    }

    process {
        if (-not (Test-Path -LiteralPath $strPath -PathType Leaf)) {
            throw "Eingabedatei nicht gefunden: $strPath"
        }

        $objInputFile = Get-Item -LiteralPath $strPath -ErrorAction Stop

        return $objInputFile
    }
}

function Invoke-GpgSymmetricCommand {
<#+
.SYNOPSIS
    Fuehrt einen GnuPG-Befehl aus.

.DESCRIPTION
    Die Funktion ruft gpg mit einer sauber getrennten Argumentliste auf.
    Dadurch bleiben Dateipfade mit Leerzeichen erhalten. Nach dem Aufruf wird der Exitcode ausgewertet.

.PARAMETER objGpgCommand
    Der zuvor ermittelte gpg-Befehl.

.PARAMETER strArrGpgArgument
    Argumentliste fuer den gpg-Aufruf.

.EXAMPLE
    Invoke-GpgSymmetricCommand -objGpgCommand $objGpgCommand -strArrGpgArgument $strArrGpgArgument

    Fuehrt gpg mit den uebergebenen Argumenten aus.

.NOTES
    Diese Hilfsfunktion wird intern verwendet.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.CommandInfo]$objGpgCommand,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]$strArrGpgArgument
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        [System.Int32]$intGpgExitCode = 0
        [System.String]$strGpgExecutablePath = ''
        [System.Management.Automation.PSPropertyInfo]$objPathProperty = $null
    }

    process {
        $objPathProperty = $objGpgCommand.PSObject.Properties['Path']

        if (($null -ne $objPathProperty) -and (-not [System.String]::IsNullOrWhiteSpace([System.String]$objPathProperty.Value))) {
            $strGpgExecutablePath = [System.String]$objPathProperty.Value
        }
        elseif (-not [System.String]::IsNullOrWhiteSpace($objGpgCommand.Source)) {
            $strGpgExecutablePath = $objGpgCommand.Source
        }
        else {
            $strGpgExecutablePath = $objGpgCommand.Name
        }

        Write-Debug "GPG-Ausfuehrungspfad: $strGpgExecutablePath"

        & $strGpgExecutablePath @strArrGpgArgument
        $intGpgExitCode = $LASTEXITCODE

        if ($intGpgExitCode -ne 0) {
            throw "GnuPG-Aufruf fehlgeschlagen. Exitcode: $intGpgExitCode"
        }
    }
}

#endregion Hilfsfunktionen

#region Fachfunktionen

function Protect-GpgSymmetricFile {
<#+
.SYNOPSIS
    Verschluesselt eine Datei symmetrisch mit GnuPG AES256.

.DESCRIPTION
    Die Funktion erzeugt aus einer vorhandenen Datei eine symmetrisch verschluesselte OpenPGP-Datei.
    Als Ausgabedatei wird automatisch der Name der Eingabedatei mit der Endung .gpg verwendet.

    Beispiel:
        Unterlagen.zip -> Unterlagen.zip.gpg

    Die Funktion entspricht fachlich folgendem Befehl:
        gpg --symmetric --cipher-algo AES256 --output Unterlagen.zip.gpg Unterlagen.zip

    Vorhandene Ausgabedateien werden ohne -Force nicht ueberschrieben.

.PARAMETER strPath
    Pfad zur Datei, die verschluesselt werden soll.

.PARAMETER Force
    Ueberschreibt eine vorhandene Ausgabedatei.

.PARAMETER Silent
    Unterdrueckt nicht notwendige Statusausgaben der Funktion.
    Ausgaben von gpg selbst werden dadurch nicht unterdrueckt.

.EXAMPLE
    Protect-GpgSymmetricFile Unterlagen.zip

    Erzeugt die Datei Unterlagen.zip.gpg.

.EXAMPLE
    Protect-GpgSymmetricFile Unterlagen.zip -Force

    Erzeugt die Datei Unterlagen.zip.gpg und ueberschreibt eine vorhandene Ausgabedatei.

.EXAMPLE
    Protect-GpgSymmetricFile Unterlagen.zip -WhatIf

    Zeigt an, welche Datei erzeugt wuerde, ohne gpg auszufuehren.

.EXAMPLE
    . ./scriptname.ps1
    pgpenc Unterlagen.zip

    Laedt die Funktionen per Dot-Sourcing und verschluesselt anschliessend die Datei ueber den Kurzbefehl.

.NOTES
    Fuer die Entschluesselung unter Windows kann Kleopatra/Gpg4win verwendet werden.
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Path', 'LiteralPath', 'FullName')]
        [System.String]$strPath,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Silent
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        [System.Management.Automation.CommandInfo]$objGpgCommand = Get-GpgSymmetricCommand
        [System.IO.FileInfo]$objInputFile = $null
        [System.String]$strInputPath = ''
        [System.String]$strOutputPath = ''
        [System.String]$strShouldProcessTarget = ''
        [System.String]$strShouldProcessAction = ''
        [System.String[]]$strArrGpgArgument = @()
    }

    process {
        $objInputFile = Get-GpgSymmetricInputFile -strPath $strPath
        $strInputPath = $objInputFile.FullName
        $strOutputPath = [System.String]::Concat($strInputPath, '.gpg')
        $strShouldProcessTarget = $strOutputPath
        $strShouldProcessAction = "Symmetrisch mit GnuPG AES256 verschluesseln aus Quelldatei: $strInputPath"

        if ((Test-Path -LiteralPath $strOutputPath -PathType Leaf) -and (-not $Force.IsPresent)) {
            throw "Ausgabedatei existiert bereits: $strOutputPath. Verwende -Force zum Ueberschreiben."
        }

        $strArrGpgArgument = @(
            '--symmetric',
            '--cipher-algo', 'AES256',
            '--output', $strOutputPath,
            $strInputPath
        )

        if ($Force.IsPresent) {
            $strArrGpgArgument = @('--yes') + $strArrGpgArgument
        }

        Write-Debug "GPG-Befehl: $($objGpgCommand.Source)"
        Write-Debug "GPG-Argumente: $($strArrGpgArgument -join ' ')"

        if ($PSCmdlet.ShouldProcess($strShouldProcessTarget, $strShouldProcessAction)) {
            Invoke-GpgSymmetricCommand -objGpgCommand $objGpgCommand -strArrGpgArgument $strArrGpgArgument

            if (-not (Test-Path -LiteralPath $strOutputPath -PathType Leaf)) {
                throw "Die erwartete Ausgabedatei wurde nicht gefunden: $strOutputPath"
            }

            if (-not $Silent.IsPresent) {
                Write-Host "🟢 Verschluesselung abgeschlossen: $strOutputPath"
            }
        }
    }
}

function Unprotect-GpgSymmetricFile {
<#+
.SYNOPSIS
    Entschluesselt eine symmetrisch verschluesselte GnuPG-Datei.

.DESCRIPTION
    Die Funktion entschluesselt eine OpenPGP-Datei mit der Endung .gpg.
    Als Ausgabedatei wird automatisch der Dateiname ohne die Endung .gpg verwendet.

    Beispiel:
        Unterlagen.zip.gpg -> Unterlagen.zip

    Die Funktion entspricht fachlich folgendem Befehl:
        gpg --output Unterlagen.zip --decrypt Unterlagen.zip.gpg

    Vorhandene Ausgabedateien werden ohne -Force nicht ueberschrieben.

.PARAMETER strPath
    Pfad zur .gpg-Datei, die entschluesselt werden soll.

.PARAMETER Force
    Ueberschreibt eine vorhandene Ausgabedatei.

.PARAMETER Silent
    Unterdrueckt nicht notwendige Statusausgaben der Funktion.
    Ausgaben von gpg selbst werden dadurch nicht unterdrueckt.

.EXAMPLE
    Unprotect-GpgSymmetricFile Unterlagen.zip.gpg

    Erzeugt die Datei Unterlagen.zip.

.EXAMPLE
    Unprotect-GpgSymmetricFile Unterlagen.zip.gpg -Force

    Erzeugt die Datei Unterlagen.zip und ueberschreibt eine vorhandene Ausgabedatei.

.EXAMPLE
    Unprotect-GpgSymmetricFile Unterlagen.zip.gpg -WhatIf

    Zeigt an, welche Datei erzeugt wuerde, ohne gpg auszufuehren.

.EXAMPLE
    . ./scriptname.ps1
    pgpdec Unterlagen.zip.gpg

    Laedt die Funktionen per Dot-Sourcing und entschluesselt anschliessend die Datei ueber den Kurzbefehl.

.NOTES
    Die Eingabedatei muss auf .gpg enden.
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Path', 'LiteralPath', 'FullName')]
        [System.String]$strPath,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Silent
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        [System.Management.Automation.CommandInfo]$objGpgCommand = Get-GpgSymmetricCommand
        [System.IO.FileInfo]$objInputFile = $null
        [System.String]$strInputPath = ''
        [System.String]$strOutputPath = ''
        [System.String]$strShouldProcessTarget = ''
        [System.String]$strShouldProcessAction = ''
        [System.String[]]$strArrGpgArgument = @()
    }

    process {
        $objInputFile = Get-GpgSymmetricInputFile -strPath $strPath
        $strInputPath = $objInputFile.FullName

        if (-not $strInputPath.EndsWith('.gpg', [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Die Eingabedatei muss auf .gpg enden: $strInputPath"
        }

        $strOutputPath = $strInputPath.Substring(0, $strInputPath.Length - 4)
        $strShouldProcessTarget = $strOutputPath
        $strShouldProcessAction = "Mit GnuPG entschluesseln aus Quelldatei: $strInputPath"

        if ((Test-Path -LiteralPath $strOutputPath -PathType Leaf) -and (-not $Force.IsPresent)) {
            throw "Ausgabedatei existiert bereits: $strOutputPath. Verwende -Force zum Ueberschreiben."
        }

        $strArrGpgArgument = @(
            '--output', $strOutputPath,
            '--decrypt', $strInputPath
        )

        if ($Force.IsPresent) {
            $strArrGpgArgument = @('--yes') + $strArrGpgArgument
        }

        Write-Debug "GPG-Befehl: $($objGpgCommand.Source)"
        Write-Debug "GPG-Argumente: $($strArrGpgArgument -join ' ')"

        if ($PSCmdlet.ShouldProcess($strShouldProcessTarget, $strShouldProcessAction)) {
            Invoke-GpgSymmetricCommand -objGpgCommand $objGpgCommand -strArrGpgArgument $strArrGpgArgument

            if (-not (Test-Path -LiteralPath $strOutputPath -PathType Leaf)) {
                throw "Die erwartete Ausgabedatei wurde nicht gefunden: $strOutputPath"
            }

            if (-not $Silent.IsPresent) {
                Write-Host "🟢 Entschluesselung abgeschlossen: $strOutputPath"
            }
        }
    }
}

#endregion Fachfunktionen

#region Aliase

Set-Alias -Name 'pgpenc' -Value 'Protect-GpgSymmetricFile' -Scope Global
Set-Alias -Name 'pgpdec' -Value 'Unprotect-GpgSymmetricFile' -Scope Global

#endregion Aliase

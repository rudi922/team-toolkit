<#
.SYNOPSIS
    Erstellt einen direkten VSIX-Downloadlink für den Visual Studio Marketplace.
.DESCRIPTION
    Ermittelt Publisher und Erweiterungsname aus der Marketplace-URL und bietet
    eine Auswahl der Version sowie der Zielplattform an.
    Es wird nur der Downloadlink erzeugt; es erfolgt kein Download.
    Der Offline-Download ist für VSCode-Installationen zweckmäßig, die nicht auf 
    das Internet zugreifen können.

    Für plattformunabhängige VSIX-Dateien wird kein targetPlatform-Parameter
    verwendet. Windows und Linux beziehen sich auf x64-Versionen.
.EXAMPLE
    ./scriptname.ps1

    Marketplace-URL: https://marketplace.visualstudio.com/items?itemName=naturaltheme.natural-theme
    Version: Bestimmte Version -> 1.0.1
    Zielplattform: Multiplattform

    Ergebnis:
    https://marketplace.visualstudio.com/_apis/public/gallery/publishers/naturaltheme/vsextensions/natural-theme/1.0.1/vspackage
.NOTES
    Lizenz: Frei nutzbar, kopierbar und veränderbar, auf eigene Gefahr und ohne Gewährleistung.
    Autor: Dipl.-Ing. Alfred Menzel / erstellt mit ChatGPT

    Historie:
        2026-11-02 07:47:24  Versions- und Plattformauswahl, Abbruch und Eingabeprüfung ergänzt.
        2026-10-31 19:09:14  Erstellt.
#>

$SCRIPT_VERSION = '2026-11-02 07:47:24'

$strMessage = @"
1. Marketplace im Browser öffnen: https://marketplace.visualstudio.com/
2. VSIX-Erweiterung auswählen und deren Marketplace-Seite öffnen.
3. URL aus der Browserzeile kopieren und nachfolgend einfügen.
"@
Write-Host $strMessage -BackgroundColor Black -ForegroundColor Yellow

$strMarketplaceUrl = Read-Host 'Marketplace-URL einfügen (Enter = Abbruch)'
if ([string]::IsNullOrWhiteSpace($strMarketplaceUrl)) {
    Write-Host 'Abbruch durch Benutzer' -ForegroundColor Yellow
    return
}

# Marketplace-URL und itemName prüfen.
$uriMarketplace = $null
if (-not [System.Uri]::TryCreate($strMarketplaceUrl.Trim(), [System.UriKind]::Absolute, [ref]$uriMarketplace) -or
    $uriMarketplace.Scheme -ne 'https' -or
    $uriMarketplace.Host -ne 'marketplace.visualstudio.com') {
    Write-Host 'Fehler: Keine gültige HTTPS-URL des Visual Studio Marketplace.' -ForegroundColor Red
    return
}

$matchItemName = [regex]::Match(
    $uriMarketplace.Query,
    '(?:^\?|&)itemName=([^&]+)',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)
$strItemName = [System.Uri]::UnescapeDataString($matchItemName.Groups[1].Value)
if ($strItemName -notmatch '^[A-Za-z0-9_-]+\.[A-Za-z0-9_.-]+$') {
    Write-Host 'Fehler: Die URL enthält keinen gültigen Parameter itemName=Publisher.Erweiterung.' -ForegroundColor Red
    return
}

$strPublisher, $strExtension = $strItemName -split '\.', 2

# Versionsauswahl: aktuelle Version ist voreingestellt.
Write-Host ''
Write-Host 'Hinweis: Eine bestimmte Version kann nur geladen werden, wenn sie im Marketplace verfügbar ist.' -ForegroundColor Yellow
$versionChoices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new('&Aktuellste Version', 'Empfohlen: latest verwenden.')
    [System.Management.Automation.Host.ChoiceDescription]::new('&Bestimmte Version', 'Versionsnummer manuell eingeben.')
)
$versionSelection = $Host.UI.PromptForChoice(
    'VSIX-Version',
    'Welche Version soll geladen werden?',
    $versionChoices,
    0
)

$strVersion = 'latest'
if ($versionSelection -eq 1) {
    do {
        $strVersionInput = ([string](Read-Host 'Versionsnummer eingeben (Enter = aktuellste Version)')).Trim()
        if ([string]::IsNullOrWhiteSpace($strVersionInput)) {
            break
        }
        if ($strVersionInput -match '^[A-Za-z0-9][A-Za-z0-9._+-]*$') {
            $strVersion = $strVersionInput
            break
        }
        Write-Host 'Ungültige Versionsnummer. Bitte erneut eingeben oder Enter für latest drücken.' -ForegroundColor Yellow
    } while ($true)
}

# Zielplattform auswählen; Multiplattform hat keinen URL-Abfrageparameter.
$platformChoices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new('&Multiplattform', 'Plattformunabhängig (Universal); kein targetPlatform-Parameter.')
    [System.Management.Automation.Host.ChoiceDescription]::new('&Windows', 'Windows x64: targetPlatform=win32-x64.')
    [System.Management.Automation.Host.ChoiceDescription]::new('&Linux', 'Linux x64: targetPlatform=linux-x64.')
)
$platformSelection = $Host.UI.PromptForChoice(
    'VSIX-Zielplattform',
    'Für welche Zielplattform soll der Downloadlink erstellt werden?',
    $platformChoices,
    0
)

$strPlatformName = 'Multiplattform (Universal)'
$strTargetPlatform = ''
switch ($platformSelection) {
    1 {
        $strPlatformName = 'Windows x64'
        $strTargetPlatform = 'win32-x64'
    }
    2 {
        $strPlatformName = 'Linux x64'
        $strTargetPlatform = 'linux-x64'
    }
}

# Downloadlink bilden. Verfügbarkeit von Version und Plattform wird nicht geprüft.
$strDownloadUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$strPublisher/vsextensions/$strExtension/$strVersion/vspackage"
if ($strTargetPlatform) {
    $strDownloadUrl += "?targetPlatform=$strTargetPlatform"
}

# Download-Link für VSIX-Datei wir ausgegeben
Write-Host ''
Write-Host "VSIX-Downloadlink (Version: $strVersion; Zielplattform: $strPlatformName):" -BackgroundColor Black -ForegroundColor Yellow
Write-Host $strDownloadUrl -BackgroundColor Black -ForegroundColor Green

#Requires -Version 5.1
<#
    Instalator AHK skriptov - bezi bez admin prav
    Postup: Git -> AutoHotkey -> klonovanie repo -> Startup skratky -> spustenie
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Pomocne funkcie na vypis ---

function Write-Krok  { param([string]$T) Write-Host "`n==> $T" -ForegroundColor Cyan }
function Write-OK    { param([string]$T) Write-Host "  [OK]    $T" -ForegroundColor Green }
function Write-Info  { param([string]$T) Write-Host "  [INFO]  $T" -ForegroundColor Yellow }
function Write-Chyba { param([string]$T) Write-Host "  [CHYBA] $T" -ForegroundColor Red }

# Docasny adresar pre stiahnte subory
$TempDir = Join-Path $env:TEMP 'ahk-install'
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null


# ======================================================
# KROK 1: Kontrola a instalacia Git
# ======================================================
Write-Krok 'Krok 1/6 - Git'

function Find-Git {
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $kandidati = @(
        "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe",
        "$env:APPDATA\Programs\Git\cmd\git.exe"
    )
    foreach ($p in $kandidati) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

$GitExe = Find-Git

if ($GitExe) {
    Write-OK "Git najdeny: $GitExe ($(& $GitExe --version))"
} else {
    Write-Info 'Git nie je nainstalovany. Instalujem cez winget (user scope)...'

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Chyba 'winget nie je dostupny. Nainštaluj Git manualne: https://git-scm.com/download/win'
        exit 1
    }

    winget install Git.Git --scope user --silent --accept-source-agreements --accept-package-agreements

    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'User') + ';' +
                [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')

    $GitExe = Find-Git
    if (-not $GitExe) {
        Write-Chyba 'Git sa nepodarilo nainstalovat. Skontroluj winget alebo nainštaluj manualne.'
        exit 1
    }
    Write-OK "Git nainstalovany: $GitExe"
}


# ======================================================
# KROK 2: Kontrola a instalacia AutoHotkey 1.1.x
# ======================================================
Write-Krok 'Krok 2/6 - AutoHotkey 1.1.x'

function Find-AHK {
    $kandidati = @(
        "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\AutoHotkey.exe",
        "$env:LOCALAPPDATA\Programs\AutoHotkey\AutoHotkey.exe"
    )
    foreach ($p in $kandidati) {
        if (Test-Path $p) {
            $ver = (Get-Item $p).VersionInfo.FileVersion
            if ($ver -match '^1\.1') { return $p }
        }
    }
    return $null
}

$AhkExe = Find-AHK

if ($AhkExe) {
    $ahkVer = (Get-Item $AhkExe).VersionInfo.FileVersion
    Write-OK "AutoHotkey 1.1.x najdeny: $AhkExe (v$ahkVer)"
} else {
    Write-Info 'AutoHotkey 1.1.x nie je nainstalovany.'

    $AhkDownloadBase = 'https://www.autohotkey.com/download/1.1/'
    Write-Info 'Zistujem najnovsiu verziu AutoHotkey 1.1.x...'
    $strankaObsah = (Invoke-WebRequest -Uri $AhkDownloadBase -UseBasicParsing).Content

    $zhody = [regex]::Matches($strankaObsah, 'AutoHotkey_([\d.]+)_setup\.exe')
    if ($zhody.Count -eq 0) {
        Write-Chyba 'Nepodarilo sa zistit najnovsiu verziu AHK zo stranky.'
        exit 1
    }
    $najnovsiaVerzia = $zhody |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object { [version]$_ } |
        Select-Object -Last 1

    Write-Info "Najnovsie verzia: $najnovsiaVerzia"

    $AhkSetupUrl  = "${AhkDownloadBase}AutoHotkey_${najnovsiaVerzia}_setup.exe"
    $AhkZipUrl    = "${AhkDownloadBase}AutoHotkey_${najnovsiaVerzia}.zip"
    $AhkSetupPath = Join-Path $TempDir 'AutoHotkey_setup.exe'
    $AhkUserDir   = "$env:LOCALAPPDATA\Programs\AutoHotkey"

    Write-Info "Stahujem AutoHotkey instalator (v$najnovsiaVerzia)..."
    Invoke-WebRequest -Uri $AhkSetupUrl -OutFile $AhkSetupPath -UseBasicParsing

    Write-Info 'Skusam tichu instaláciu do user profilu...'
    $null = Start-Process -FilePath $AhkSetupPath `
                          -ArgumentList "/S /D=`"$AhkUserDir`"" `
                          -Wait -PassThru -ErrorAction SilentlyContinue

    $AhkExe = Find-AHK

    if (-not $AhkExe) {
        Write-Info 'Instalator neuspel (pravdepodobne vyzaduje admin). Stahujem portable ZIP...'

        $AhkZipPath = Join-Path $TempDir 'AutoHotkey_portable.zip'
        Invoke-WebRequest -Uri $AhkZipUrl -OutFile $AhkZipPath -UseBasicParsing

        New-Item -ItemType Directory -Path $AhkUserDir -Force | Out-Null
        Expand-Archive -Path $AhkZipPath -DestinationPath $AhkUserDir -Force

        $AhkExe = Find-AHK
    }

    if (-not $AhkExe) {
        Write-Chyba 'AutoHotkey sa nepodarilo nainstalovat.'
        exit 1
    }
    Write-OK "AutoHotkey nainstalovany: $AhkExe"
}


# ======================================================
# KROK 3: Vyber cieloveho adresara
# ======================================================
Write-Krok 'Krok 3/6 - Cielovy adresar'

$DefaultParent = "C:\Users\$env:USERNAME\projekty"
$vyber = Read-Host "Kam chces ulozit repo? [Enter = $DefaultParent]"
$RepoParent = if ([string]::IsNullOrWhiteSpace($vyber)) { $DefaultParent } else { $vyber.Trim() }

if (-not (Test-Path $RepoParent)) {
    New-Item -ItemType Directory -Path $RepoParent -Force | Out-Null
    Write-OK "Adresar vytvoreny: $RepoParent"
} else {
    Write-OK "Adresar existuje: $RepoParent"
}

$RepoPath = Join-Path $RepoParent 'ahk-scripts'


# ======================================================
# KROK 4: Git clone
# ======================================================
Write-Krok 'Krok 4/6 - Git clone'

if (Test-Path $RepoPath) {
    Write-Info "Adresar '$RepoPath' uz existuje - klonovanie preskocene."
} else {
    Write-Info "Klonujem do: $RepoPath"
    & $GitExe clone 'https://github.com/yardstudio/ahk-scripts.git' $RepoPath
    Write-OK 'Repozitar naklonovany.'
}


# ======================================================
# KROK 5: Skratky v Shell:Startup
# ======================================================
Write-Krok 'Krok 5/6 - Skratky v Shell:Startup'

$StartupDir = [System.Environment]::GetFolderPath('Startup')
$Shell = New-Object -ComObject WScript.Shell

$Skripty = @(
    @{ Subor = 'CTRL + WIN + V.ahk';         Nazov = 'AHK - CTRL+WIN+V Paste Plain Text' },
    @{ Subor = 'CTRL+ALT+D-Insert Date.ahk'; Nazov = 'AHK - CTRL+ALT+D Insert Date' }
)

foreach ($s in $Skripty) {
    $ahkSubor = Join-Path $RepoPath $s.Subor

    if (-not (Test-Path $ahkSubor)) {
        Write-Chyba "Subor nenajdeny, skratka nevytvorena: $ahkSubor"
        continue
    }

    $lnk = $Shell.CreateShortcut((Join-Path $StartupDir "$($s.Nazov).lnk"))
    $lnk.TargetPath       = $AhkExe
    $lnk.Arguments        = "`"$ahkSubor`""
    $lnk.WorkingDirectory = $RepoPath
    $lnk.Description      = $s.Nazov
    $lnk.Save()

    Write-OK "Skratka: $($s.Nazov).lnk"
}


# ======================================================
# KROK 6: Okamzite spustenie skriptov
# ======================================================
Write-Krok 'Krok 6/6 - Spustanie skriptov'

foreach ($s in $Skripty) {
    $ahkSubor = Join-Path $RepoPath $s.Subor
    if (Test-Path $ahkSubor) {
        Start-Process -FilePath $AhkExe -ArgumentList "`"$ahkSubor`""
        Write-OK "Spusteny: $($s.Nazov)"
    }
}


# ======================================================
# Hotovo
# ======================================================
Write-Host ''
Write-Host '*** Instalacia dokoncena! ***' -ForegroundColor Green
Write-Host "  Repozitar : $RepoPath"
Write-Host "  Startup   : $StartupDir"
Write-Host '  Oba skripty bezia v systemovej liste a spustia sa automaticky po kazdom prihlaseni.'

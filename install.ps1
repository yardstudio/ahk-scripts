#Requires -Version 5.1
<#
    Inštalátor AHK skriptov - beží bez admin práv
    Postup: Git → AutoHotkey → klonovanie repo → Startup skratky → spustenie
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Pomocné funkcie na výpis ---

function Write-Krok  { param([string]$T) Write-Host "`n==> $T" -ForegroundColor Cyan }
function Write-OK    { param([string]$T) Write-Host "  [OK]    $T" -ForegroundColor Green }
function Write-Info  { param([string]$T) Write-Host "  [INFO]  $T" -ForegroundColor Yellow }
function Write-Chyba { param([string]$T) Write-Host "  [CHYBA] $T" -ForegroundColor Red }

# Dočasný adresár pre stiahnuté súbory
$TempDir = Join-Path $env:TEMP 'ahk-install'
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null


# ======================================================
# KROK 1: Kontrola a inštalácia Git
# ======================================================
Write-Krok 'Krok 1/6 — Git'

function Find-Git {
    # Skontroluje PATH aj bežné user-scope inštalačné cesty
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
    Write-OK "Git nájdený: $GitExe ($(& $GitExe --version))"
} else {
    Write-Info 'Git nie je nainštalovaný. Inštalujem cez winget (user scope)...'

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Chyba 'winget nie je dostupný. Nainštaluj Git manuálne: https://git-scm.com/download/win'
        exit 1
    }

    winget install Git.Git --scope user --silent --accept-source-agreements --accept-package-agreements

    # Refreshni PATH z prostredia (winget ho updatuje pre user scope)
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'User') + ';' +
                [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')

    $GitExe = Find-Git
    if (-not $GitExe) {
        Write-Chyba 'Git sa nepodarilo nainštalovať. Skontroluj winget alebo nainštaluj manuálne.'
        exit 1
    }
    Write-OK "Git nainštalovaný: $GitExe"
}


# ======================================================
# KROK 2: Kontrola a inštalácia AutoHotkey 1.1.x
# ======================================================
Write-Krok 'Krok 2/6 — AutoHotkey 1.1.x'

function Find-AHK {
    $kandidati = @(
        "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\AutoHotkey.exe",
        "$env:LOCALAPPDATA\Programs\AutoHotkey\AutoHotkey.exe"
    )
    foreach ($p in $kandidati) {
        if (Test-Path $p) {
            $ver = (Get-Item $p).VersionInfo.FileVersion
            # Akceptujeme iba verziu 1.1.x
            if ($ver -match '^1\.1') { return $p }
        }
    }
    return $null
}

$AhkExe = Find-AHK

if ($AhkExe) {
    $ahkVer = (Get-Item $AhkExe).VersionInfo.FileVersion
    Write-OK "AutoHotkey 1.1.x nájdený: $AhkExe (v$ahkVer)"
} else {
    Write-Info 'AutoHotkey 1.1.x nie je nainštalovaný.'

    # Dynamicky zisti najnovšiu verziu z download stránky
    $AhkDownloadBase = 'https://www.autohotkey.com/download/1.1/'
    Write-Info 'Zisťujem najnovšiu verziu AutoHotkey 1.1.x...'
    $strankaObsah = (Invoke-WebRequest -Uri $AhkDownloadBase -UseBasicParsing).Content

    # Nájdi všetky setup .exe súbory v HTML a vyber s najvyšším číslom verzie
    $zhody = [regex]::Matches($strankaObsah, 'AutoHotkey_([\d.]+)_setup\.exe')
    if ($zhody.Count -eq 0) {
        Write-Chyba 'Nepodarilo sa zistiť najnovšiu verziu AHK zo stránky.'
        exit 1
    }
    $najnovsiaVerzia = $zhody |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object { [version]$_ } |
        Select-Object -Last 1

    Write-Info "Najnovšia verzia: $najnovsiaVerzia"

    $AhkSetupUrl  = "${AhkDownloadBase}AutoHotkey_${najnovsiaVerzia}_setup.exe"
    $AhkZipUrl    = "${AhkDownloadBase}AutoHotkey_${najnovsiaVerzia}.zip"
    $AhkSetupPath = Join-Path $TempDir 'AutoHotkey_setup.exe'
    $AhkUserDir   = "$env:LOCALAPPDATA\Programs\AutoHotkey"

    Write-Info "Sťahujem AutoHotkey inštalátor (v$najnovsiaVerzia)..."
    Invoke-WebRequest -Uri $AhkSetupUrl -OutFile $AhkSetupPath -UseBasicParsing

    Write-Info 'Skúšam tichú inštaláciu do user profilu...'
    $proc = Start-Process -FilePath $AhkSetupPath `
                          -ArgumentList "/S /D=`"$AhkUserDir`"" `
                          -Wait -PassThru -ErrorAction SilentlyContinue

    $AhkExe = Find-AHK

    # Ak inštalátor zlyhal (napr. vyžaduje admin), použijeme portable ZIP
    if (-not $AhkExe) {
        Write-Info 'Inštalátor neuspel (pravdepodobne vyžaduje admin). Sťahujem portable ZIP...'

        $AhkZipPath = Join-Path $TempDir 'AutoHotkey_portable.zip'
        Invoke-WebRequest -Uri $AhkZipUrl -OutFile $AhkZipPath -UseBasicParsing

        New-Item -ItemType Directory -Path $AhkUserDir -Force | Out-Null
        Expand-Archive -Path $AhkZipPath -DestinationPath $AhkUserDir -Force

        $AhkExe = Find-AHK
    }

    if (-not $AhkExe) {
        Write-Chyba 'AutoHotkey sa nepodarilo nainštalovať.'
        exit 1
    }
    Write-OK "AutoHotkey nainštalovaný: $AhkExe"
}


# ======================================================
# KROK 3: Výber cieľového adresára
# ======================================================
Write-Krok 'Krok 3/6 — Cieľový adresár'

$DefaultParent = "C:\Users\$env:USERNAME\projekty"
$input = Read-Host "Kde chceš uložiť repo? [Enter = $DefaultParent]"
$RepoParent = if ([string]::IsNullOrWhiteSpace($input)) { $DefaultParent } else { $input.Trim() }

if (-not (Test-Path $RepoParent)) {
    New-Item -ItemType Directory -Path $RepoParent -Force | Out-Null
    Write-OK "Adresár vytvorený: $RepoParent"
} else {
    Write-OK "Adresár existuje: $RepoParent"
}

$RepoPath = Join-Path $RepoParent 'ahk-scripts'


# ======================================================
# KROK 4: Git clone
# ======================================================
Write-Krok 'Krok 4/6 — Git clone'

if (Test-Path $RepoPath) {
    Write-Info "Adresár '$RepoPath' už existuje — klonovanie preskočené."
} else {
    Write-Info "Klonujem do: $RepoPath"
    & $GitExe clone 'https://github.com/yardstudio/ahk-scripts.git' $RepoPath
    Write-OK 'Repozitár naklonovaný.'
}


# ======================================================
# KROK 5: Skratky v Shell:Startup
# ======================================================
Write-Krok 'Krok 5/6 — Skratky v Shell:Startup'

$StartupDir = [System.Environment]::GetFolderPath('Startup')
$Shell = New-Object -ComObject WScript.Shell

$Skripty = @(
    @{ Subor = 'CTRL + WIN + V.ahk';         Nazov = 'AHK - CTRL+WIN+V Paste Plain Text' },
    @{ Subor = 'CTRL+ALT+D-Insert Date.ahk'; Nazov = 'AHK - CTRL+ALT+D Insert Date' }
)

foreach ($s in $Skripty) {
    $ahkSubor = Join-Path $RepoPath $s.Subor

    if (-not (Test-Path $ahkSubor)) {
        Write-Chyba "Súbor nenájdený, skratka nevytvorená: $ahkSubor"
        continue
    }

    $lnk = $Shell.CreateShortcut((Join-Path $StartupDir "$($s.Nazov).lnk"))
    $lnk.TargetPath      = $AhkExe
    $lnk.Arguments       = "`"$ahkSubor`""
    $lnk.WorkingDirectory = $RepoPath
    $lnk.Description     = $s.Nazov
    $lnk.Save()

    Write-OK "Skratka: $($s.Nazov).lnk"
}


# ======================================================
# KROK 6: Okamžité spustenie skriptov
# ======================================================
Write-Krok 'Krok 6/6 — Spúšťanie skriptov'

foreach ($s in $Skripty) {
    $ahkSubor = Join-Path $RepoPath $s.Subor
    if (Test-Path $ahkSubor) {
        Start-Process -FilePath $AhkExe -ArgumentList "`"$ahkSubor`""
        Write-OK "Spustený: $($s.Nazov)"
    }
}


# ======================================================
# Hotovo
# ======================================================
Write-Host ''
Write-Host '*** Inštalácia dokončená! ***' -ForegroundColor Green
Write-Host "  Repozitár : $RepoPath"
Write-Host "  Startup   : $StartupDir"
Write-Host '  Oba skripty bežia v systémovej lište a spustia sa automaticky po každom prihlásení.'

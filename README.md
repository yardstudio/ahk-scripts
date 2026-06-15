# AHK Scripts — AutoHotkey utility scripts for Windows

> 🇸🇰 [Slovenská verzia](#sk) | 🇬🇧 [English version](#en)

---

<a name="sk"></a>
# 🇸🇰 Slovensky

Dva AutoHotkey v1 skripty pre zvýšenie produktivity na Windows, verzionované cez Git a distribuované s automatickým inštalátorom.

## Skripty

| Skratka | Súbor | Funkcia |
|---|---|---|
| `Ctrl+Win+V` | `CTRL + WIN + V.ahk` | Vloží obsah schránky ako čistý text (bez formátovania) |
| `Ctrl+Alt+D` | `CTRL+ALT+D-Insert Date.ahk` | Vloží aktuálny dátum a čas vo formáte `yyyy-MM-dd_HH-mm-ss` |

Oba skripty sa spúšťajú automaticky pri štarte Windows a bežia na pozadí (ikona `H` v system tray).

## Požiadavky

- Windows 10 / 11
- PowerShell 5.1+ (súčasť Windows)
- Internet (pri prvej inštalácii)
- Admin práva **nie sú potrebné**

## Inštalácia na novom PC

### Možnosť A — Jeden príkaz (odporúčané)

Otvor PowerShell (**nie** ako admin) a vlož:

```powershell
irm https://raw.githubusercontent.com/yardstudio/ahk-scripts/master/install.ps1 | iex
```

Inštalátor automaticky:
1. Skontroluje a nainštaluje Git (cez winget)
2. Skontroluje a nainštaluje AutoHotkey v1 (vždy najnovšia verzia)
3. Opýta sa kde uložiť repo (default: `C:\Users\MENO\projekty`)
4. Stiahne skripty z GitHubu (`git clone`)
5. Vytvorí Startup skratky (automatický štart po prihlásení)
6. Spustí oba skripty hneď

### Možnosť B — Manuálna inštalácia

1. Nainštaluj [AutoHotkey v1](https://www.autohotkey.com/download/1.1/)
2. Nainštaluj [Git pre Windows](https://git-scm.com/download/win)
3. Klonuj repo:
```powershell
git clone https://github.com/yardstudio/ahk-scripts.git C:\Users\%USERNAME%\projekty\ahk-scripts
```
4. Spusti oba `.ahk` súbory dvojklikom
5. Pre automatický štart skopíruj skratky do `shell:startup`

## Kontrolný zoznam pred inštaláciou

- [ ] Windows 10 alebo 11
- [ ] PowerShell otvorený **bez** admin práv
- [ ] Funkčné internetové pripojenie

## Kontrolný zoznam po inštalácii

- [ ] V system tray sú viditeľné dve zelené ikonky `H`
- [ ] `Ctrl+Alt+D` vloží dátum vo formáte `2026-06-15_14-30-05`
- [ ] `Ctrl+Win+V` vloží čistý text (otestuj na tučnom texte z webu)
- [ ] Po reštarte PC sa skripty spustia automaticky

## Aktualizácia na existujúcom PC

```powershell
cd C:\Users\%USERNAME%\projekty\ahk-scripts
git pull
```

Potom reštartuj AHK skripty: pravý klik na `H` v tray → Exit → spusti znova.

## Git workflow — úprava skriptov

```powershell
# Po zmene na tvojom PC:
cd C:\Users\%USERNAME%\projekty\ahk-scripts
git add *.ahk
git commit -m "Popis zmeny"
git push

# Na inom PC — stiahni zmeny:
git pull
```

## Riešenie problémov

**Skript sa nespustí / skratka nefunguje**
- Skontroluj zelenú `H` ikonku v system tray
- Skontroluj že máš AutoHotkey **verzia 1.x** (nie 2.x)
- Spusti skript ručne: dvojklik na `.ahk` súbor

**`irm ... | iex` hlási chybu ExecutionPolicy**
```powershell
Set-ExecutionPolicy -Scope CurrentUser Bypass -Force
```

**Git nie je rozpoznaný po inštalácii**
```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable('PATH','User') + ';' + [System.Environment]::GetEnvironmentVariable('PATH','Machine')
```

**`Ctrl+Win+V` nefunguje**
Skratku môže blokovať iná aplikácia. Skontroluj konflikty klávesových skratiek.

## Štruktúra repozitára

```
ahk-scripts/
├── CTRL + WIN + V.ahk          # Skript: vkladanie čistého textu
├── CTRL+ALT+D-Insert Date.ahk  # Skript: vkladanie dátumu
├── install.ps1                 # Automatický inštalátor
└── README.md                   # Dokumentácia
```

## Technické poznámky

- Skripty vyžadujú **AutoHotkey v1** — v2 má inú syntax
- `install.ps1` beží bez admin práv
- `.gitattributes` vynucuje CRLF pre `.ps1` a `.ahk` (kompatibilita PS 5.1)
- Repo je **Public** — inštalátor funguje bez prihlásenia

---

<a name="en"></a>
# 🇬🇧 English

Two AutoHotkey v1 productivity scripts for Windows, versioned via Git and distributed with an automatic installer.

## Scripts

| Shortcut | File | Function |
|---|---|---|
| `Ctrl+Win+V` | `CTRL + WIN + V.ahk` | Paste clipboard content as plain text (no formatting) |
| `Ctrl+Alt+D` | `CTRL+ALT+D-Insert Date.ahk` | Insert current date and time as `yyyy-MM-dd_HH-mm-ss` |

Both scripts start automatically with Windows and run in the background (green `H` icon in system tray).

## Requirements

- Windows 10 / 11
- PowerShell 5.1+ (built into Windows)
- Internet connection (first install only)
- Admin rights **not required**

## Installation on a new PC

### Option A — One command (recommended)

Open PowerShell (**not** as admin) and paste:

```powershell
irm https://raw.githubusercontent.com/yardstudio/ahk-scripts/master/install.ps1 | iex
```

The installer automatically:
1. Checks and installs Git (via winget)
2. Checks and installs AutoHotkey v1 (always latest version)
3. Asks where to store the repo (default: `C:\Users\NAME\projekty`)
4. Downloads scripts from GitHub (`git clone`)
5. Creates Startup shortcuts (auto-start on login)
6. Launches both scripts immediately

### Option B — Manual installation

1. Install [AutoHotkey v1](https://www.autohotkey.com/download/1.1/)
2. Install [Git for Windows](https://git-scm.com/download/win)
3. Clone the repo:
```powershell
git clone https://github.com/yardstudio/ahk-scripts.git C:\Users\%USERNAME%\projekty\ahk-scripts
```
4. Double-click both `.ahk` files to run them
5. For auto-start copy shortcuts to `shell:startup`

## Pre-installation checklist

- [ ] Windows 10 or 11
- [ ] PowerShell opened **without** admin rights
- [ ] Working internet connection

## Post-installation checklist

- [ ] Two green `H` icons visible in system tray
- [ ] `Ctrl+Alt+D` inserts date in format `2026-06-15_14-30-05`
- [ ] `Ctrl+Win+V` pastes plain text (test with bold text copied from web)
- [ ] After PC restart scripts launch automatically

## Updating on existing PC

```powershell
cd C:\Users\%USERNAME%\projekty\ahk-scripts
git pull
```

Then restart AHK scripts: right-click `H` in tray → Exit → run again.

## Git workflow — editing scripts

```powershell
# After making changes on your PC:
cd C:\Users\%USERNAME%\projekty\ahk-scripts
git add *.ahk
git commit -m "Description of change"
git push

# On another PC — pull changes:
git pull
```

## Troubleshooting

**Script won't start / shortcut not working**
- Check for green `H` icon in system tray
- Verify AutoHotkey **version 1.x** is installed (not 2.x)
- Run script manually: double-click the `.ahk` file

**`irm ... | iex` gives ExecutionPolicy error**
```powershell
Set-ExecutionPolicy -Scope CurrentUser Bypass -Force
```

**Git not recognized after installation**
```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable('PATH','User') + ';' + [System.Environment]::GetEnvironmentVariable('PATH','Machine')
```

**`Ctrl+Win+V` not working**
Another application may be capturing the shortcut. Check for keyboard shortcut conflicts.

## Repository structure

```
ahk-scripts/
├── CTRL + WIN + V.ahk          # Script: plain text paste
├── CTRL+ALT+D-Insert Date.ahk  # Script: date insert
├── install.ps1                 # Automatic installer
└── README.md                   # This documentation
```

## Technical notes

- Scripts require **AutoHotkey v1** — v2 has different syntax and will not run them
- `install.ps1` runs without admin rights — Git and AHK install to user profile
- `.gitattributes` enforces CRLF line endings for `.ps1` and `.ahk` (PS 5.1 compatibility)
- Repo is **Public** — installer works without GitHub login

---

*Project: YARD STUDIO s.r.o. | Banská Bystrica, Slovakia*

# NOTE:
#          _.-;;-._
#   '-..-'|   ||   |
#   '-..-'|_.-;;-._|
#   '-..-'|   ||   |
#   '-..-'|_.-''-._|

<#
.SYNOPSIS
    's Windows Setup Manifest
#>

# ------------------------------------------------------
# 1. SELF-ELEVATION & EXECUTION POLICY
# ------------------------------------------------------
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin)
{
    Write-Host ":: Running as Administrator." -ForegroundColor Cyan
    
    if ((Get-ExecutionPolicy) -ne 'Bypass')
    {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    }
} else
{
    Write-Host ":: Not running as Administrator." -ForegroundColor Yellow
    Write-Host ":: Attempting to request Admin privileges..." -ForegroundColor Gray
    
    try
    {
        # Relaunch as Admin with Bypass policy
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -ErrorAction Stop
        exit
    } catch
    {
        Write-Warning ":: Admin privileges denied."
        Write-Host ":: Continuing as Standard User..." -ForegroundColor Green
    }
}

# ------------------------------------------------------
# 2. WINGET (System Apps)
# ------------------------------------------------------
Write-Host ":: Checking System Apps..." -ForegroundColor Green

Write-Host ":: Updating Winget Sources..." -ForegroundColor Gray
winget source update --disable-interactivity

try
{
    winget install --id Microsoft.PowerShell -e --scope user --accept-package-agreements --accept-source-agreements
    winget install --id Microsoft.WindowsTerminal -e --scope user --accept-package-agreements --accept-source-agreements
    winget install --id Microsoft.PowerToys -e --scope user --accept-package-agreements --accept-source-agreements
    # Raycast
    winget install --id 9PFXXSHC64H3 -e --scope user --accept-package-agreements --accept-source-agreements
    if ($isAdmin)
    {
        winget install --id Microsoft.VisualStudio.2022.BuildTools --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" --accept-package-agreements --accept-source-agreements
    } else
    {
        Write-Warning ":: Skipping Visual Studio Build Tools (requires Administrator privileges)."
    }
} catch
{
    Write-Warning "Winget failed. Ensure App Installer is updated in the MS Store."
}

# ------------------------------------------------------
# 3. SCOOP (Package Manager)
# ------------------------------------------------------
if (-not (Test-Path "$env:USERPROFILE\scoop"))
{
    Write-Host ":: Installing Scoop..." -ForegroundColor Green
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
} else
{
    Write-Host ":: Scoop is already installed." -ForegroundColor Green
}

# Add buckets
scoop install git
scoop bucket add extras
scoop bucket add versions
scoop bucket add nerd-fonts
scoop update

# ------------------------------------------------------
# 4. BOOTSTRAP DEPENDENCIES
# ------------------------------------------------------
# We need these immediately for the script to function
$bootstrapApps = @("mise", "innounp-unicode", "psfzf", "psreadline", "terminal-icons")


Write-Host ":: Installing Bootstrap Dependencies..." -ForegroundColor Green
foreach ($app in $bootstrapApps)
{
    if (-not (Get-Command $app -ErrorAction SilentlyContinue))
    {
        scoop install $app
    }
}

# ------------------------------------------------------
# 5. INSTALL MISE
# ------------------------------------------------------
if (-not (Get-Command mise -ErrorAction SilentlyContinue))
{
    Write-Host ":: Installing Mise..." -ForegroundColor Green
    scoop install mise
}

# ACTIVATE MISE FOR THIS SESSION
# Critical: Allows us to use 'mise use' and access installed tools immediately
$env:MISE_YES = 1
Invoke-Expression "$(mise activate pwsh)"
mise use -g age@latest chezmoi@latest github-cli@latest

# ------------------------------------------------------
# 6. DOTFILES (Chezmoi)
# ------------------------------------------------------
Write-Host ":: Migrating dotfiles..." -ForegroundColor Green
Read-Host ":: Please put key.txt in ~/.config/. Press Enter to continue"
# Ensure we are in the home directory
Set-Location $env:USERPROFILE

if (-not (Test-Path "$env:USERPROFILE\.local\share\chezmoi"))
{
    chezmoi init --apply https://github.com/joncrangle/.dotfiles.git
} else
{
    chezmoi apply
}

# ------------------------------------------------------
# 7. INSTALL PACKAGES
# ------------------------------------------------------

# SYSTEM / GUI TOOLS (Scoop)
$scoopApps = @(
    "7zip", "bruno", "btop", "chafa", "curl", "dbeaver", "diffutils", "ffmpeg", "ghostscript", "glazewm",
    "gzip", "imagemagick", "IosevkaTerm-NF", "JetBrainsMono-NF", "krita", "lua", "luarocks", "make", "Maple-Mono",
    "Meslo-NF", "mingw-winlibs", "obsidian", "podman", "poppler", "python", "rustup-msvc", "sqlite", "topgrade", "unar",
    "unzip", "vlc", "vcredist2022", "wezterm-nightly", "win32yank", "wget", "zebar", "zed", "zoom"
) 

Write-Host ":: Installing System Apps via Scoop..." -ForegroundColor Green
scoop install $scoopApps

# DEV TOOLS (Mise)
# This uses the config.toml pulled down by chezmoi
Write-Host ":: Installing Dev Tools via Mise..." -ForegroundColor Green
mise lock
mise install --yes

# ------------------------------------------------------
# 8. CONFIGURATION & TWEAKS
# ------------------------------------------------------

# --- IDENTITY PROMPT ---
$DefaultName = "jonathancrangle"
$DefaultEmail = "94425204+joncrangle@users.noreply.github.com"

Write-Host ":: Configuring User Identity..." -ForegroundColor Green
$GitName = gum input --header "Git User Name" --value $DefaultName
$GitEmail = gum input --header "Git Email" --value $DefaultEmail

Write-Host ":: Configuring Git..." -ForegroundColor Green
git config --global credential.helper manager
git config --global user.name "$GitName"
git config --global user.email "$GitEmail"

if (gum confirm "Generate new SSH key for GitHub?")
{
    $sshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path $sshDir))
    { New-Item -Type Directory $sshDir -Force 
    }
    ssh-keygen -t ed25519 -C "$GitEmail" -f "$sshDir\id_ed25519"
}

# Github Auth
Write-Host ":: Authenticating GitHub..." -ForegroundColor Green
if (-not (gh auth status))
{
    gh auth login --web
}

# Fonts
Write-Host ":: Installing Fonts..." -ForegroundColor Green
$fontSource = "$env:USERPROFILE\.config\fonts"
$fontDest = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
if (Test-Path $fontSource)
{
    if (-not (Test-Path $fontDest))
    { New-Item -Type Directory $fontDest -Force 
    }
    Get-ChildItem $fontSource -Include *.ttf,*.otf -Recurse | ForEach-Object {
        $destFile = Join-Path $fontDest $_.Name
        if (-not (Test-Path $destFile))
        {
            Copy-Item $_.FullName $destFile
            New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $_.Name -Value $_.Name -Force
        }
    }
}

# Windows Terminal Settings
Write-Host ":: Configuring Windows Terminal..." -ForegroundColor Green
$wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$wtSource = "$env:USERPROFILE\.config\windows-terminal\settings.json"
if (Test-Path $wtSource)
{
    Copy-Item $wtSource $wtPath -Force
}

# Yazi / Bat / JJ Config
# (Assuming Mise installed them, we just configure)
if (Get-Command bat -ErrorAction SilentlyContinue)
{ bat cache --build 
}
if (Get-Command ya -ErrorAction SilentlyContinue)
{ ya pkg install; ya pkg update 
}
if (Get-Command jj -ErrorAction SilentlyContinue)
{
    jj config set --user user.name "$GitName"
    jj config set --user user.email "$GitEmail"
    @"
`n[ui]
pager = "delta"
editor = "nvim"
diff-editor = ["nvim", "-c", "DiffEditor `$left `$right `$output"]

[ui.diff]
format = "git"
"@ | Out-File -Append -FilePath (jj config path --user) -Encoding utf8
}

# Rust Setup (Mise installed rustup, we config it)
if (Get-Command rustup -ErrorAction SilentlyContinue)
{
    rustup default stable
    rustup update
}

# Python Registry Fix (PEP 514)
# This allows external tools to find the Mise-installed Python
$pyReg = "$env:USERPROFILE\scoop\apps\python\current\install-pep-514.reg" 
if (Test-Path $pyReg)
{ reg import $pyReg 
}

# Startup Shortcuts
Write-Host ":: Creating Startup Shortcuts..." -ForegroundColor Green
$startupDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcuts = @{
    "WezTerm" = "$env:USERPROFILE\scoop\apps\wezterm-nightly\current\wezterm-gui.exe"
    "GlazeWM" = "$env:USERPROFILE\scoop\apps\glazewm\current\glazewm.exe"
    "Microsoft Outlook" = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
}

$wshell = New-Object -ComObject WScript.Shell
foreach ($name in $shortcuts.Keys)
{
    $target = $shortcuts[$name]
    if (Test-Path $target)
    {
        $lnk = $wshell.CreateShortcut("$startupDir\$name.lnk")
        $lnk.TargetPath = $target
        $lnk.Save()
    }
}

# Build GlazeWM/Zebar
$zebarDir = "$env:USERPROFILE\.glzr\zebar\bar"
if (Test-Path $zebarDir)
{
    Write-Host ":: Building Zebar..." -ForegroundColor Green
    Push-Location $zebarDir
    bun install
    bun run build
    Pop-Location
}

# BTOP Config
Write-Host ":: Configuring BTOP..." -ForegroundColor Green
$btopConfigDir = "$env:USERPROFILE\scoop\persist\btop"
$btopThemesDir = "$btopConfigDir\themes"

if (!(Test-Path $btopConfigDir))
{ New-Item -Path $btopConfigDir -ItemType Directory -Force | Out-Null 
}
if (!(Test-Path $btopThemesDir))
{ New-Item -Path $btopThemesDir -ItemType Directory -Force | Out-Null 
}

$srcBtop = "$env:USERPROFILE\.config\btop\btop.conf"
$srcTheme = "$env:USERPROFILE\.config\btop\themes\catppuccin_mocha.theme"

if (Test-Path $srcBtop)
{ Copy-Item $srcBtop "$btopConfigDir\btop.conf" -Force 
}
if (Test-Path $srcTheme)
{ Copy-Item $srcTheme "$btopThemesDir\catppuccin_mocha.theme" -Force 
}

# Zen Browser Config
Write-Host ":: Configuring Zen Browser..." -ForegroundColor Green
$zenConfig = "$env:USERPROFILE\.config\zen-styles"
$zenAppData = "$env:APPDATA\zen"

if (Test-Path $zenConfig)
{
    if (Test-Path "$zenAppData\profiles.ini")
    {
        # Extract Path from profiles.ini (simple regex for the first Path= entry)
        $profileRel = Select-String -Path "$zenAppData\profiles.ini" -Pattern "^Path=(.*)" | Select-Object -First 1
        
        if ($profileRel)
        {
            # Convert forward slashes to backslashes for Windows path
            $relPath = $profileRel.Matches.Groups[1].Value.Replace("/", "\")
            $chromeDir = Join-Path $zenAppData "$relPath\chrome"
            
            if (-not (Test-Path $chromeDir))
            { New-Item -ItemType Directory -Path $chromeDir -Force | Out-Null 
            }
            
            Copy-Item "$zenConfig\*" "$chromeDir\" -Recurse -Force
            Write-Host "   Applied Zen Styles to $chromeDir" -ForegroundColor Gray
        }
    } else
    {
        Write-Warning "   Zen Browser profiles.ini not found. Skipping style application."
    }
}

# ------------------------------------------------------
# 9. ENVIRONMENT VARIABLES
# ------------------------------------------------------
Write-Host ":: Configuring Environment Variables..." -ForegroundColor Green

# 1. YAZI CONFIG (Essential for Yazi on Windows)
#    Yazi needs the 'file' command, which is bundled with Git but not in PATH.
$GitFileExe = "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe"

if (Test-Path $GitFileExe)
{
    [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $GitFileExe, [EnvironmentVariableTarget]::User)
    Write-Host "   Set YAZI_FILE_ONE -> $GitFileExe" -ForegroundColor Gray
} else
{
    Write-Warning "   Could not find 'file.exe' in Scoop Git installation. Yazi might malfunction."
}

# 2. PATH CLEANUP
#    Ensure the user's bin folder is in PATH (useful for scripts)
$UserBin = "$env:USERPROFILE\bin"
if (-not (Test-Path $UserBin))
{ New-Item -ItemType Directory -Path $UserBin -Force | Out-Null 
}

$CurrentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if ($CurrentPath -notlike "*$UserBin*")
{
    [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$UserBin", [EnvironmentVariableTarget]::User)
    Write-Host "   Added ~\bin to PATH" -ForegroundColor Gray
}

# ------------------------------------------------------
# 10. POST-INSTALL CONFIGS
# ------------------------------------------------------

# WinUtil Tweaks
if (Test-Path ".\WinUtilTweaks.ps1")
{
    Write-Host ":: Running WinUtil Tweaks..." -ForegroundColor Green
    .\WinUtilTweaks.ps1 Invoke-All
}

# ------------------------------------------------------
# 11. FINISH
# ------------------------------------------------------
. $PROFILE
Write-Host ":: Setup Complete!" -ForegroundColor Green
if (gum confirm "Restart computer now?")
{
    Restart-Computer
}
Write-Host "Configuration complete. Please restart the terminal."

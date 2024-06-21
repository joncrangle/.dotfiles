# NOTE:
#          _.-;;-._
#   '-..-'|   ||   |
#   '-..-'|_.-;;-._|
#   '-..-'|   ||   |
#   '-..-'|_.-''-._|

try {
    Write-Host "Installing PowerShell, Windows Terminal and Windows PowerToys..."
    winget install --id Microsoft.WindowsTerminal -e
    winget install --id Microsoft.Powershell --source winget
    winget install Microsoft.PowerToys --source winget
} catch {
# Prompt user to install PowerShell and Windows Terminal
    Write-Host "Please install PowerShell (https://apps.microsoft.com/detail/9mz1snwt0n5d?hl=en-US&gl=US), Windows Terminal (https://apps.microsoft.com/detail/9n0dx20hk701?hl=en-US&gl=US) and Windows PowerToys (https://apps.microsoft.com/detail/xp89dcgq3k6vld?hl=en-gb&gl=CA)."
        Write-Host "Once installed, press Enter to continue, or press Escape to exit."
        do {
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        } until ($key -eq 13 -or $key -eq 27)  # Enter key (13) or Escape key (27)

    if ($key -eq 27) {
# User pressed Escape, exit the script
        Write-Host "Exiting the script."
            exit
    }
}

Write-Host "Setting execution policy..."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Write-Host "Installing Scoop..."
$scoopDir = "$env:USERPROFILE\scoop"
if (!(Test-Path $scoopDir)) {
    Write-Host "Installing Scoop..."
    try {
        Invoke-RestMethod -Uri "https://get.scoop.sh" -ErrorAction Stop | Invoke-Expression
    } catch {
        Write-Host "An error occurred while installing Scoop."
    }
} else {
    Write-Host "Scoop is already installed."
}

Write-Host "Installing terminal apps..."
$appsToInstall = @(
    "age", "chezmoi", "fzf", "gh", "IosevkaTerm-NF", "Maple-Mono-NF",
    "psfzf", "psreadline", "starship", "terminal-icons", "zoxide"
)

try {
    scoop install git
    scoop bucket add extras
    scoop bucket add versions
    scoop bucket add nerd-fonts
    scoop update
    foreach ($app in $appsToInstall) {
        scoop install $app
    }
} catch {
    Write-Host "An error occurred while installing one or more terminal apps."
}

Write-Host "Configuring Git..."
try {
    git config --global credential.helper manager
    $regFilePath = Join-Path -Path $env:USERPROFILE -ChildPath 'scoop\apps\git\current\install-file-associations.reg'
    if (Test-Path -Path $regFilePath -PathType Leaf) {
        Start-Process -FilePath "regedit.exe" -ArgumentList "/s `"$regFilePath`"" -Wait
    }
    else {
        Write-Host "The file $regFilePath does not exist."
    }
    git config --global user.name "jonathancrangle"
    git config --global user.email "94425204+joncrangle@users.noreply.github.com"
} catch {
    Write-Host "An error occurred while configuring Git."
}

# Prompt user to run gh auth login
Read-Host "Please run 'gh auth login' to authenticate with GitHub. Press Enter to continue after you have completed the authentication."

Write-Host "Moving dotfiles..."
chezmoi init --apply https://github.com/joncrangle/.dotfiles.git

Write-Host "Configuring Windows Terminal..."
try {
    $windowsTerminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    $settingsJson = "$env:USERPROFILE\.config\windows-terminal\settings.json"
    Copy-Item $settingsJson -Destination $windowsTerminalDir -Force
} catch {
    Write-Host "An error occurred while configuring Windows Terminal."
}

Write-Host "Configuring PowerShell..."
try {
    if (-not (Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -ItemType File -Force
    }
    # Add content to $PROFILE
    $profileContent = @"
# Imports the terminal Icons into current Instance of PowerShell
Import-Module -Name Terminal-Icons 

#Fzf (Import the fuzzy finder and set a shortcut key to begin searching)
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

`$ENV:EDITOR = 'nvim'
`$ENV:VISUAL = 'nvim'
`$ENV:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"

# Set FZF_DEFAULT_COMMAND
`$env:FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"

# Set FZF_CTRL_T_COMMAND to FZF_DEFAULT_COMMAND
`$env:FZF_CTRL_T_COMMAND = `$env:FZF_DEFAULT_COMMAND

# Set FZF_DEFAULT_OPTS
`$ENV:FZF_DEFAULT_OPTS= " `
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 `
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc `
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# Set FZF_ALT_C_OPTS
`$env:FZF_ALT_C_OPTS = "--preview 'tree -C {} | Select-Object -First 10'"

# Set BAT_THEME
`$env:BAT_THEME="Catppuccin Mocha"

# Remove existing aliases before defining new ones
Remove-Item -Path Alias:cm -ErrorAction SilentlyContinue
Remove-Item -Path Alias:wez -ErrorAction SilentlyContinue
Remove-Item -Path Alias:vim -ErrorAction SilentlyContinue
Remove-Item -Path Alias:vi -ErrorAction SilentlyContinue
Remove-Item -Path Alias:v -ErrorAction SilentlyContinue
Remove-Item -Path Alias:c -ErrorAction SilentlyContinue
Remove-Item -Path Alias:ls -ErrorAction SilentlyContinue
Remove-Item -Path Alias:l -ErrorAction SilentlyContinue
Remove-Item -Path Alias:ll -ErrorAction SilentlyContinue
Remove-Item -Path Alias:la -ErrorAction SilentlyContinue
Remove-Item -Path Alias:tree -ErrorAction SilentlyContinue
Remove-Item -Path Alias:cd -ErrorAction SilentlyContinue
Remove-Item -Path Alias:cat -ErrorAction SilentlyContinue
Remove-Item -Path Alias:lazy -ErrorAction SilentlyContinue
Remove-Item -Path Alias:lg -ErrorAction SilentlyContinue
Remove-Item -Path Alias:lzg -ErrorAction SilentlyContinue
Remove-Item -Path Alias:lzd -ErrorAction SilentlyContinue

function Copy-Line {
    # Ensure rg, fzf, and bat are available
    $rgPath = Get-Command rg -ErrorAction SilentlyContinue
    $fzfPath = Get-Command fzf -ErrorAction SilentlyContinue
    $batPath = Get-Command bat -ErrorAction SilentlyContinue

    if (-not $rgPath) { Write-Host "rg (ripgrep) is not installed."; return }
    if (-not $fzfPath) { Write-Host "fzf is not installed."; return }
    if (-not $batPath) { Write-Host "bat is not installed."; return }

    # Run rg and pipe to fzf
    $selected = rg --line-number . | fzf --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}'

    # Extract the line content
    if ($selected) {
        $parts = $selected -split ':'
        $lineContent = $parts[2..($parts.Length - 1)] -join ':'
        $lineContent = $lineContent.Trim()

        # Copy to clipboard
        $lineContent | clip

        Write-Host "Selected line copied to clipboard."
    }
}

function ListWithIcons {
    eza --icons
}

function ListLongWithIcons {
    eza -l --icons
}

function ListAllWithIcons {
    eza -la --icons
}

function ListTreeWithIcons {
    eza -T --icons
}

function Open-At-Line {
    # Ensure rg, fzf, bat, and nvim are available
    $rgPath = Get-Command rg -ErrorAction SilentlyContinue
    $fzfPath = Get-Command fzf -ErrorAction SilentlyContinue
    $batPath = Get-Command bat -ErrorAction SilentlyContinue
    $nvimPath = Get-Command nvim -ErrorAction SilentlyContinue

    if (-not $rgPath) { Write-Host "rg (ripgrep) is not installed."; return }
    if (-not $fzfPath) { Write-Host "fzf is not installed."; return }
    if (-not $batPath) { Write-Host "bat is not installed."; return }
    if (-not $nvimPath) { Write-Host "nvim (Neovim) is not installed."; return }

    # Run rg and pipe to fzf
    $selected = rg --line-number . | fzf --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}'

    # Extract the line number and file path
    if ($selected) {
        $parts = $selected -split ':'
        $lineNumber = $parts[1]
        $filePath = $parts[0]
        
        # Open the file at the specified line number with nvim
        nvim "+$lineNumber" $filePath
    }
}

function scoop-upgrade {
    scoop update -a
    scoop cleanup -a
}

function Take {
    param (
        [string]$path
    )

    # Create the directory if it does not exist
    if (-Not (Test-Path -Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }

    # Change to the new directory
    Set-Location -Path $path
}


# Define aliases
New-Alias -Name cm -Value chezmoi
New-Alias -Name wez -Value wezterm
New-Alias -Name vim -Value nvim
New-Alias -Name vi -Value nvim
New-Alias -Name v -Value nvim
New-Alias -Name c -Value clear
New-Alias -Name ls -Value ListWithIcons
New-Alias -Name l -Value ListWithIcons
New-Alias -Name ll -Value ListLongWithIcons
New-Alias -Name la -Value ListAllWithIcons
New-Alias -Name tree -Value ListTreeWithIcons
New-Alias -Name cd -Value z
New-Alias -Name cat -Value bat
New-Alias -Name lazy -Value lazygit
New-Alias -Name lg -Value lazygit
New-Alias -Name lzg -Value lazygit
New-Alias -Name lzd -Value lazydocker

Write-Host "`e[38;5;80m         ___                                           `e[0m"
Write-Host "`e[38;5;80m     . -^   \`--,                                      `e[0m"
Write-Host "`e[38;5;80m    /# =========\`-_                                   `e[0m"
Write-Host "`e[38;5;80m   /# (--====___====\      d8b                         `e[0m"
Write-Host "`e[38;5;80m  /#   .- --.  . --.|      Y8P                         `e[0m"
Write-Host "`e[38;5;80m /##   |  * ) (   * ),                                 `e[0m"
Write-Host "`e[1;36m |##   \    /\ \   / |    8888  .d88b.  88888b.           `e[0m"
Write-Host "`e[1;36m |###   ---   \ ---  |    ``"888 d88``"``"88b 888 ``"88b  `e[0m"
Write-Host "`e[1;36m |####      ___)    #|     888 888  888 888  888          `e[0m"
Write-Host "`e[1;36m |######           ##|     888 Y88..88P 888  888          `e[0m"
Write-Host "`e[1;36m   `\##### ---------- `/     888  ``"Y88P``"  888  888    `e[0m"
Write-Host "`e[1;36m     `\####          `(      888                          `e[0m"
Write-Host "`e[1;36m      ``\###         |     d88P                           `e[0m"
Write-Host "`e[1;94m       `\###         |   888P``"                          `e[0m"
Write-Host "`e[1;94m         `\##       |                                     `e[0m"
Write-Host "`e[1;94m          `\###.   .`)                                    `e[0m"
Write-Host "`e[1;94m           ``======/                                      `e[0m"
Write-Host ""

Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })
"@
    $profileContent | Out-File -FilePath $PROFILE
} catch {
    Write-Host "An error occurred while configuring PowerShell."
}


# Install Scoop apps
Write-Host "Installing Scoop apps..."
$packages = @(
    "7zip", "bat", "biome", "bruno", "curl", "delta", "docker", "eza", "fastfetch", "fd",
    "ffmpeg", "glazewm", "glow", "go", "gzip", "JetBrainsMono-NF", "jq", "krita", "lazygit", 
    "lazydocker", "make", "mariadb", "Meslo-NF", "neovim", "nodejs", "obsidian", "pnpm",
    "postgresql", "python", "ripgrep", "tableplus", "tldr", "tree-sitter", "unzip", "vlc",
    "vcredist2022", "vscode", "wezterm-nightly", "wget", "yarn", "yq", "zig", "zoom"
)

foreach ($package in $packages) {
    try {
        scoop install $package
    } catch {
        Write-Host "An error occurred while installing $package."
    }
}

# Add apps to Windows startup
$links = @(
    @{ Path = "C:\Users\CrangleJon\scoop\apps\glazewm\current\GlazeWM.exe"; Name = "GlazeWM" },
    @{ Path = "C:\Program Files\Google\Chrome\Application\chrome.exe"; Name = "Google Chrome" },
    @{ Path = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"; Name = "Microsoft Outlook" },
    @{ Path = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"; Name = "Microsoft Edge" },
    @{ Path = "$env:USERPROFILE\scoop\apps\wezterm-nightly\current\wezterm-gui.exe"; Name = "WezTerm" }
)

# Path to the Startup folder
$startupFolderPath = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup")

# Function to create a shortcut
Write-Host "Creating startup shortcuts..."
function Create-Shortcut {
    param (
        [string]$targetPath,
        [string]$shortcutName
    )

    $shell = New-Object -ComObject WScript.Shell
    $shortcutPath = [System.IO.Path]::Combine($startupFolderPath, "$shortcutName.lnk")
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $targetPath
    $shortcut.Save()
}

# Loop through each program and create a shortcut
foreach ($link in $links) {
    try {
        Create-Shortcut -targetPath $program.Path -shortcutName $program.Name
    } catch {
        Write-Host "Failed to create shortcut for $($program.Name): $_"
    }
}

Write-Host "Configuration complete. Please restart the terminal."
. $PROFILE

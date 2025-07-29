# NOTE:
#          _.-;;-._
#   '-..-'|   ||   |
#   '-..-'|_.-;;-._|
#   '-..-'|   ||   |
#   '-..-'|_.-''-._|

Write-Host "Setting execution policy..."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

try
{
    Write-Host "Installing PowerShell, Windows Terminal and Windows PowerToys..."
    winget install --id Microsoft.WindowsTerminal -e --scope user
    winget install --id Microsoft.Powershell --source winget --scope user
    winget install Microsoft.PowerToys --source winget --scope user
} catch
{
    # Prompt user to install PowerShell and Windows Terminal
    Write-Host "Please install PowerShell (https://apps.microsoft.com/detail/9mz1snwt0n5d?hl=en-US&gl=US), Windows Terminal (https://apps.microsoft.com/detail/9n0dx20hk701?hl=en-US&gl=US) and Windows PowerToys (https://apps.microsoft.com/detail/xp89dcgq3k6vld?hl=en-gb&gl=CA)."
    Write-Host "Once installed, press Enter to continue, or press Escape to exit."
    do
    {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
    } until ($key -eq 13 -or $key -eq 27)  # Enter key (13) or Escape key (27)

    if ($key -eq 27)
    {
        # User pressed Escape, exit the script
        Write-Host "Exiting the script."
        exit
    }
}

Write-Host "Installing Scoop..."
$scoopDir = "$env:USERPROFILE\scoop"
if (!(Test-Path $scoopDir))
{
    Write-Host "Installing Scoop..."
    try
    {
        Invoke-RestMethod -Uri "https://get.scoop.sh" -ErrorAction Stop | Invoke-Expression
    } catch
    {
        Write-Host "An error occurred while installing Scoop."
    }
} else
{
    Write-Host "Scoop is already installed."
}

Write-Host "Installing terminal apps..."
$appsToInstall = @(
    "age", "chezmoi", "fzf", "gh", "innounp-unicode", "IosevkaTerm-NF",
    "Maple-Mono", "psfzf", "psreadline", "starship", "terminal-icons", "zoxide"
)

try
{
    scoop install git
    scoop bucket add extras
    scoop bucket add versions
    scoop bucket add nerd-fonts
    scoop update
    foreach ($app in $appsToInstall)
    {
        scoop install $app
    }
} catch
{
    Write-Host "An error occurred while installing one or more terminal apps."
}

Write-Host "Configuring Git..."
try
{
    git config --global credential.helper manager
    $regFilePath = Join-Path -Path $env:USERPROFILE -ChildPath 'scoop\apps\git\current\install-file-associations.reg'
    if (Test-Path -Path $regFilePath -PathType Leaf)
    {
        Start-Process -FilePath "regedit.exe" -ArgumentList "/s `"$regFilePath`"" -Wait
    } else
    {
        Write-Host "The file $regFilePath does not exist."
    }
    git config --global user.name "jonathancrangle"
    git config --global user.email "94425204+joncrangle@users.noreply.github.com"

    $confirm = Read-Host "Do you want to generate a new SSH key for GitHub? (y/n)"
    if ($confirm -eq "y")
    {
        Write-Host ":: Generating a new SSH key for GitHub..."
        try {
            $sshDirectoryPath = Join-Path -Path $env:USERPROFILE -ChildPath ".ssh"
            if (-not (Test-Path -Path $sshDirectoryPath)) {
                New-Item -ItemType Directory -Path $sshDirectoryPath -Force
            }
            $keyPath = Join-Path -Path $sshDirectoryPath -ChildPath "id_ed25519"
            ssh-keygen -t ed25519 -C "94425204+joncrangle@users.noreply.github.com" -f $keyPath
            if (Test-Path -Path $keyPath) {
                Write-Host "SSH key generated successfully at $keyPath"
            } else {
                Write-Host "Failed to generate SSH key"
            }
        } catch {
            Write-Host "An error occurred: $_"
        }
    } elseif ($confirm -eq "n")
    {
        Write-Host ":: Skipping SSH key generation."
    } else
    {
        Write-Host "Invalid input. Please enter 'y' or 'n'."
    }
} catch
{
    Write-Host "An error occurred while configuring Git."
}

# Prompt user to run gh auth login
Read-Host "Please run 'gh auth login --web' to authenticate with GitHub. Press Enter to continue after you have completed the authentication."
Read-Host ":: Please put key.txt in ~/.config/. Press Enter to continue"

Write-Host "Configuring environment variables..."
function Set-UserEnvironmentVariables
{
    param (
        [array]$variables
    )

    foreach ($variable in $variables)
    {
        $variableName = $variable.Name
        $variablePath = $variable.Path
        $variableValue = [System.IO.Path]::Combine($env:USERPROFILE, $variablePath)

        [Environment]::SetEnvironmentVariable($variableName, $variableValue, [EnvironmentVariableTarget]::User)
    }
}

$envVars = @(
    @{ Name = "YAZI_FILE_ONE"; Path = "scoop\apps\git\current\usr\bin\file.exe" },
    @{ Name = "XDG_CONFIG_HOME"; Path = "AppData\Local" },
    @{ Name = "XDG_DATA_HOME"; Path = "AppData\Local" },
)

Set-UserEnvironmentVariables -variables $envVars
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\AppData\Local"
Set-Location $env:XDG_CONFIG_HOME

Write-Host "Moving dotfiles..."
chezmoi init --apply https://github.com/joncrangle/.dotfiles.git

Write-Host "Configuring Windows Terminal..."
try
{
    $windowsTerminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    $settingsJson = "$env:USERPROFILE\.config\windows-terminal\settings.json"
    Copy-Item $settingsJson -Destination $windowsTerminalDir -Force
} catch
{
    Write-Host "An error occurred while configuring Windows Terminal."
}

Write-Host "Configuring PowerShell..."
try
{
    if (-not (Test-Path $PROFILE))
    {
        New-Item -Path $PROFILE -ItemType File -Force
    }
    # Add content to $PROFILE
    $profileContent = @"
# Imports the terminal Icons into current Instance of PowerShell
Import-Module -Name Terminal-Icons 

#Fzf (Import the fuzzy finder and set a shortcut key to begin searching)
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

`$env:EDITOR = "nvim"
`$env:VISUAL = "nvim"
`$env:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"
`$env:COREPACK_ENABLE_AUTO_PIN = "0"
`$env:GEMINI_API_KEY={{- .GeminiKey }}
# Add uv tools to PATH
`$env:PATH = "C:\Users\CRANGLJ\AppData\Local\..\bin;$env:PATH"

# FZF
`$env:FZF_DEFAULT_COMMAND="rg --files --no-ignore-vcs --hidden --follow --glob ""!.git/"" --glob ""!.jj/"""
`$env:FZF_DEFAULT_OPTS=" `
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 `
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc `
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 `
--color=selected-bg:#45475a `
--multi `
--border=rounded `
--bind 'ctrl-f:preview-page-down,ctrl-b:preview-page-up'"
`$env:FZF_ALT_C_OPTS="--walker-skip .git,node_modules,target,.jj --preview 'eza -T --icons --color=always {}'"
`$env:FZF_CTRL_T_OPTS="--walker-skip .git,node_modules,target,.jj --preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
`$env:FZF_CTRL_R_OPTS="--bind 'ctrl-y:execute-silent(echo {} | win32yank -i)+abort' --color header:italic"

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
Remove-Item -Path Alias:tg -ErrorAction SilentlyContinue

function cme
{
    Set-Location "`$env:XDG_CONFIG_HOME\chezmoi"
}

function cmu
{
    chezmoi update
    chezmoi apply
}

function copy-line
{
    # Ensure rg, fzf, and bat are available
    `$rgPath = Get-Command rg -ErrorAction SilentlyContinue
    `$fzfPath = Get-Command fzf -ErrorAction SilentlyContinue
    `$batPath = Get-Command bat -ErrorAction SilentlyContinue

    if (-not `$rgPath)
    { Write-Host "rg (ripgrep) is not installed."; return
    }
    if (-not `$fzfPath)
    { Write-Host "fzf is not installed."; return
    }
    if (-not `$batPath)
    { Write-Host "bat is not installed."; return
    }

    # Run rg and pipe to fzf
    `$selected = rg --line-number . | fzf --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}'

    # Extract the line content
    if (`$selected)
    {
        `$parts = `$selected -split ':'
        `$lineContent = `$parts[2..(`$parts.Length - 1)] -join ':'
        `$lineContent = `$lineContent.Trim()

        # Copy to clipboard
        `$lineContent | clip

        Write-Host "Selected line copied to clipboard."
    }
}

function ListWithIcons
{
    eza --icons
}

function ListLongWithIcons
{
    eza -l --icons
}

function ListAllWithIcons
{
    eza -la --icons
}

function ListTreeWithIcons
{
    eza -T --icons
}

function open-at-line
{
    # Ensure rg, fzf, bat, and nvim are available
    `$rgPath = Get-Command rg -ErrorAction SilentlyContinue
    `$fzfPath = Get-Command fzf -ErrorAction SilentlyContinue
    `$batPath = Get-Command bat -ErrorAction SilentlyContinue
    `$nvimPath = Get-Command nvim -ErrorAction SilentlyContinue

    if (-not `$rgPath)
    { Write-Host "rg (ripgrep) is not installed."; return
    }
    if (-not `$fzfPath)
    { Write-Host "fzf is not installed."; return
    }
    if (-not `$batPath)
    { Write-Host "bat is not installed."; return
    }
    if (-not `$nvimPath)
    { Write-Host "nvim (Neovim) is not installed."; return
    }

    # Run rg and pipe to fzf
    `$selected = rg --line-number . | fzf --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}'

    # Extract the line number and file path
    if (`$selected)
    {
        `$parts = `$selected -split ':'
        `$lineNumber = `$parts[1]
        `$filePath = `$parts[0]
        
        # Open the file at the specified line number with nvim
        nvim "+`$lineNumber" `$filePath
    }
}

function scoop-upgrade
{
    scoop update -a
    scoop cleanup -a
}

function take
{
    param (
        [string]`$path
    )

    # Create the directory if it does not exist
    if (-Not (Test-Path -Path `$path))
    {
        New-Item -ItemType Directory -Path `$path | Out-Null
    }

    # Change to the new directory
    Set-Location -Path `$path
}

function up
{
    param (
        [int]`$count = 1
    )

    if (`$count -lt 1)
    {
        Write-Host "The number of directories to go up must be a positive integer."
        return
    }

    `$path = ('..\' * `$count).TrimEnd('\')
    Set-Location `$path
}

function x
{
    exit
}

function yy
{
    `$tmp = [System.IO.Path]::GetTempFileName()
    yazi `$args --cwd-file="`$tmp"
    `$cwd = Get-Content -Path `$tmp
    if (-not [String]::IsNullOrEmpty(`$cwd) -and `$cwd -ne `$PWD.Path)
    {
        Set-Location -LiteralPath `$cwd
    }
    Remove-Item -Path `$tmp
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
New-Alias -Name tg -Value topgrade

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
Write-Host "`e[1;36m      `\###          |     d88P                           `e[0m"
Write-Host "`e[1;94m       `\###         |   888P``"                          `e[0m"
Write-Host "`e[1;94m         `\##       |                                     `e[0m"
Write-Host "`e[1;94m          `\###.   .`)                                    `e[0m"
Write-Host "`e[1;94m           ````======/                                      `e[0m"
Write-Host ""

`$prompt = ""
function Invoke-Starship-PreCommand {
    `$current_location = `$executionContext.SessionState.Path.CurrentLocation
    if (`$current_location.Provider.Name -eq "FileSystem")
    {
        `$ansi_escape = [char]27
        `$provider_path = `$current_location.ProviderPath -replace "\\", "/"
        `$prompt = "`$ansi_escape]7;file://`${env:COMPUTERNAME}/`${provider_path}`$ansi_escape\"
    }
    `$host.ui.Write(`$prompt)
}
function Invoke-Starship-TransientFunction {
    &starship module character
}
Invoke-Expression (&starship init powershell)
Enable-TransientPrompt
Invoke-Expression (& { (zoxide init powershell | Out-String) })
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
"@
    $profileContent | Out-File -FilePath $PROFILE
} catch
{
    Write-Host "An error occurred while configuring PowerShell."
}
. $PROFILE

# Install fonts
Write-Host "Installing fonts..."
$fontsDirectory = "$env:USERPROFILE\.config\fonts"
$fontFiles = Get-ChildItem -Path $fontsDirectory -Recurse -Include *.ttf, *.otf -File
$userFontsFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
if (-not (Test-Path -Path $userFontsFolder))
{
    New-Item -ItemType Directory -Path $userFontsFolder
}

foreach ($fontFile in $fontFiles)
{
    $fontName = [System.IO.Path]::GetFileNameWithoutExtension($fontFile.Name)
    $fontPath = $fontFile.FullName
    $destinationPath = Join-Path -Path $userFontsFolder -ChildPath $fontFile.Name
    
    # Copy the font to the user's local Fonts folder if it doesn't already exist
    if (-not (Test-Path -Path $destinationPath))
    {
        Copy-Item -Path $fontPath -Destination $destinationPath
        # Add the font to the current user's registry
        $fontRegistryPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        Set-ItemProperty -Path $fontRegistryPath -Name $fontName -Value $fontFile.Name

        # Notify the system of the font change
        [FontInstaller]::NotifyFontChange()
        Write-Output "Installed font - $fontName"
    } else
    {
        Write-Output "Font $fontName is already installed. Skipping copy."
    }
}
Write-Host "Fonts installed successfully."

# Install Scoop apps
Write-Host "Installing Scoop apps..."
$packages = @(
    "7zip", "bat", "biome", "bun", "bruno", "chafa", "charm-gum", "curl", "delta", "deno", "dbeaver", "diffutils",
    "eza", "fastfetch", "fd", "ffmpeg", "fnm", "ghostscript", "glazewm", "glow", "go", "gzip", "imagemagick",
    "JetBrainsMono-NF", "jj", "jq", "just", "krita", "lazygit", "lua", "luarocks", "make", "mariadb",
    "Meslo-NF", "mingw", "neovim", "obsidian", "podman", "poppler", "postgresql", "python", "ripgrep",
    "rustup-gnu", "sqlite", "tldr", "topgrade", "tree-sitter", "typst", "unar", "unzip", "uv", "vlc", "vcredist2022",
    "wezterm-nightly", "win32yank", "wget", "whkd", "xh", "yazi", "yq", "zebar", "zed", "zig", "zoom"
)

foreach ($package in $packages)
{
    try
    {
        scoop install $package
    } catch
    {
        Write-Host "An error occurred while installing $package."
    }
}

ya pack -i
ya pack -u
rustup update
rustup component add rust-analyzer
cargo install cargo-update
cargo install cargo-cache
cargo install --locked bacon
fnm install 22
fnm install 23
corepack enable pnpm
go install github.com/jorgerojas26/lazysql@latest
jj config set --user user.name "jonathancrangle"
jj config set --user user.email "94405204+joncrangle@users.noreply.github.com"
@"
`n[ui]
pager = "delta"
editor = "nvim"
diff-editor = ["nvim", "-c", "DiffEditor `$left `$right `$output"]

[ui.diff]
format = "git"
"@ | Out-File -Append -FilePath (jj config path --user) -Encoding utf8

# Add apps to Windows startup
$links = @(
    @{ Path = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"; Name = "Microsoft Outlook" },
    @{ Path = "$env:USERPROFILE\scoop\apps\wezterm-nightly\current\wezterm-gui.exe"; Name = "WezTerm" }
    @{ Path = "$env:USERPROFILE\scoop\apps\glazewm\current\glazewm.exe"; Name = "GlazeWM" }
)

# Path to the Startup folder
$startupFolderPath = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup")

# Function to create a shortcut
Write-Host "Creating startup shortcuts..."
function New-Shortcut
{
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
foreach ($link in $links)
{
    try
    {
        New-Shortcut -targetPath $link.Path -shortcutName $link.Name
    } catch
    {
        Write-Host "Failed to create shortcut for $($link.Name): $_"
    }
}

try
{
    $regFilePath = "$env:USERPROFILE\scoop\apps\python\current\install-pep-514.reg"
    if (Test-Path $regFilePath)
    {
        # Import the registry file
        reg import $regFilePath
    } else
    {
        Write-Error "Registry file for python not found: $regFilePath"
    }
} catch
{
    Write-Error "An error occurred: $_"
}

$configDestDir = "$env:USERPROFILE\scoop\persist\btop"
$themesDestDir = "$configDestDir\themes"
if (!(Test-Path -Path $configDestDir)) {
    New-Item -Path $configDestDir -ItemType Directory -Force
}
if (!(Test-Path -Path $themesDestDir)) {
    New-Item -Path $themesDestDir -ItemType Directory -Force
}
Copy-Item -Path "$env:USERPROFILE\.config\btop\btop.conf" -Destination "$configDestDir\btop.conf" -Force
Copy-Item -Path "$env:USERPROFILE\.config\btop\themes\catppuccin_mocha.theme" -Destination "$themesDestDir\catppuccin_mocha.theme" -Force
bat cache --build

$projectPath = "$env:USERPROFILE\.glzr\zebar\bar"
Write-Host "Building zebar bar..."
try
{
    Set-Location -Path $projectPath
    git init
    bun install
    bun run build
} catch
{
    Write-Host "Failed to run bun commands in ${projectPath}: $_"
} finally
{
    Set-Location -Path $PSScriptRoot
}

Write-Host "Configuration complete. Please restart the terminal."

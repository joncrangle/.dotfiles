# NOTE:
#          _.-;;-._
#   '-..-'|   ||   |
#   '-..-'|_.-;;-._|
#   '-..-'|   ||   |
#   '-..-'|_.-''-._|

# ------------------------------------------------------
# 0. HELPERS
# ------------------------------------------------------

function Test-Cmd
{
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Set-AliasIfExists
{
    param(
        [Parameter(Mandatory)] [string]$Alias,
        [Parameter(Mandatory)] [string]$Command
    )
    if (Get-Command $Command -ErrorAction SilentlyContinue)
    {
        if (Get-Alias $Alias -ErrorAction SilentlyContinue)
        {
            Remove-Item "alias:\$Alias" -Force -ErrorAction SilentlyContinue
        }
        Set-Alias -Name $Alias -Value $Command -Scope Global -Force
    }
}

# ------------------------------------------------------
# 1. MODULES (SAFE LOAD)
# ------------------------------------------------------

if (Get-Module -ListAvailable PSReadLine)
{
    Import-Module PSReadLine
}

# --- PowerShell 6/7+ ONLY Setup ---
if ($PSVersionTable.PSVersion.Major -ge 6)
{
    # mise activation
    $miseScript = (mise activate pwsh | Out-String)
    $miseScript = $miseScript -replace '\[Microsoft.PowerShell.PSConsoleReadLine\]::GetHistoryItems\(\)', '@()'
    Invoke-Expression $miseScript

    if (Get-Module -ListAvailable Terminal-Icons)
    {
        Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    }

    if (Get-Module -ListAvailable PSFzf)
    {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}

# ------------------------------------------------------
# 2. ENVIRONMENT
# ------------------------------------------------------

$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

$XDG = "$env:USERPROFILE\.config"

$env:OPENCODE_CONFIG_DIR = "$XDG\opencode"
$env:STARSHIP_CONFIG    = "$XDG\starship\starship.toml"
$env:BAT_THEME          = 'Catppuccin Mocha'
if (Test-Path "$HOME\.config\mise\gh_public.json")
{
    $json = Get-Content "$HOME\.config\mise\gh_public.json" | ConvertFrom-Json
    $env:MISE_GITHUB_TOKEN = $json.github_token
}

# ------------------------------------------------------
# 3. FZF
# ------------------------------------------------------

if (Test-Cmd rg)
{
    $env:FZF_DEFAULT_COMMAND = 'rg --files --no-ignore-vcs --hidden --follow --glob "!.git/" --glob "!.jj/"'
}

$env:FZF_DEFAULT_OPTS=" `
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 `
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc `
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 `
--color=selected-bg:#45475a `
--multi `
--border=rounded `
--bind 'ctrl-f:preview-page-down,ctrl-b:preview-page-up'"

$env:FZF_ALT_C_OPTS="--walker-skip .git,node_modules,target,.jj --preview 'eza -T --icons --color=always {}'"
$env:FZF_CTRL_T_OPTS="--walker-skip .git,node_modules,target,.jj --preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
$env:FZF_CTRL_R_OPTS="--bind 'ctrl-y:execute-silent(echo {} | win32yank -i)+abort' --color header:italic"


# ------------------------------------------------------
# 4. ALIASES
# ------------------------------------------------------

# Editors
Set-AliasIfExists vim nvim
Set-AliasIfExists vi  nvim
Set-AliasIfExists v   nvim

# Core replacements
Set-AliasIfExists cat bat
Set-AliasIfExists lazy lazygit
Set-AliasIfExists lg lazygit
Set-AliasIfExists lzg lazygit
Set-AliasIfExists lzd lazydocker
Set-AliasIfExists tg topgrade
Set-AliasIfExists oc opencode
Set-AliasIfExists cm chezmoi
Set-AliasIfExists wez wezterm

# Clear screen (native)
Set-Alias c Clear-Host -Force

# zoxide replaces cd
if (Get-Command z -ErrorAction SilentlyContinue)
{
    if (Get-Alias cd -ErrorAction SilentlyContinue)
    {
        Remove-Item alias:cd -Force -ErrorAction SilentlyContinue
    }
    Set-Alias cd z -Option AllScope
}

# ------------------------------------------------------
# 5. LISTING FUNCTIONS
# ------------------------------------------------------

if (Get-Command eza -ErrorAction SilentlyContinue)
{
    if (Get-Alias ls -ErrorAction SilentlyContinue)
    {
        Remove-Item alias:ls -Force -ErrorAction SilentlyContinue
    }
    
    function ls
    { eza --icons $args 
    }
    function l
    { eza --icons $args 
    }
    function ll
    { eza --icons -l $args 
    }
    function la
    { eza --icons -la $args 
    }
    function tree
    { eza -T --icons $args 
    }
}
# ------------------------------------------------------
# 6. CORE FUNCTIONS
# ------------------------------------------------------

function cme
{ Set-Location "$env:XDG_CONFIG_HOME\chezmoi" 
}

function cmu
{
    chezmoi update
    chezmoi apply
}

function export
{
    foreach ($arg in $args)
    {
        if ($arg -match '^([^=]+)=(.*)$')
        {
            $name = $Matches[1]
            $value = $Matches[2]
            Set-Content -Path "Env:$name" -Value $value
        }
    }
}

filter grep ($pattern)
{
    $_ | Select-String -Pattern $pattern
}

function oc
{
    opencode --agent orchestrator $args
}

function rip
{
    $selection = Get-Process | 
        Select-Object Id, ProcessName, CPU | 
        Out-String -Stream | 
        Select-Object -Skip 3 | 
        Where-Object { $_ -match '\S' } |
        fzf --header="[Kill] Enter to Terminate" --layout=reverse --multi

    if ($selection)
    {
        foreach ($line in $selection)
        {
            $pidToKill = ($line.Trim() -split '\s+')[0]
            if ($pidToKill -match '^\d+$')
            {
                Stop-Process -Id ([int]$pidToKill) -Force
                Write-Host ":: Terminated PID $pidToKill" -ForegroundColor Cyan
            }
        }
    }
}

function scoop-upgrade
{
    scoop update -a
    scoop cleanup -a
}

function take
{
    param([string]$Path)
    if (-not (Test-Path $Path))
    {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
    Set-Location $Path
}

function touch ($file)
{
    New-Item -ItemType File -Name $file -Force | Out-Null
}

function up
{
    param([ValidateRange(1,100)][int]$Count = 1)
    Set-Location (Resolve-Path ('..\' * $Count))
}

function which ($name)
{
    Get-Command $name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

function x
{ exit 
}

# ------------------------------------------------------
# 7. RIPGREP + FZF HELPERS
# ------------------------------------------------------

function Select-RgLine
{
    if (-not (Test-Cmd rg -and Test-Cmd fzf -and Test-Cmd bat))
    {
        Write-Warning 'Missing rg, fzf, or bat'
        return $null
    }

    rg --line-number . |
        fzf --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}'
}

function copy-line
{
    $sel = Select-RgLine
    if ($sel)
    {
        ($sel -split ':',3)[2].Trim() | clip
        Write-Host 'Line copied.' -ForegroundColor Green
    }
}

function open-at-line
{
    if (-not (Test-Cmd nvim))
    { return 
    }
    $sel = Select-RgLine
    if ($sel)
    {
        $p = $sel -split ':',3
        nvim "+$($p[1])" $p[0]
    }
}

# ------------------------------------------------------
# 8. GIT BACKUP
# ------------------------------------------------------

function git-backup
{

    git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0)
    {
        Write-Error 'Not inside a git repository.'
        return
    }

    if (-not (Test-Cmd gum))
    {
        Write-Error "'gum' is not installed."
        return
    }

    $root = git rev-parse --show-toplevel
    $default = Split-Path $root -Leaf
    $origin = git remote get-url origin 2>$null

    if (-not $origin)
    {
        Write-Error "Remote 'origin' not found."
        return
    }

    gum style --foreground 212 'Forgejo Backup Configurator'
    $repo = gum input --value $default --placeholder 'Repository name'
    if (-not $repo)
    { return 
    }

    git remote set-url --push origin $origin
    git remote set-url --add --push origin "forgejo:$env:USERNAME/$repo.git"

    gum style --foreground 10 '✓ Backup remote configured'
    git remote -v | gum format
}

# ------------------------------------------------------
# 9. YAZI
# ------------------------------------------------------

function yy
{
    $tmp = [IO.Path]::GetTempFileName()
    yazi --cwd-file="$tmp"
    $cwd = Get-Content $tmp
    if ($cwd -and $cwd -ne $PWD.Path)
    {
        Set-Location $cwd
    }
    Remove-Item $tmp
}

# ------------------------------------------------------
# 10. BANNER (ONCE)
# ------------------------------------------------------

if (-not $global:ProfileBannerShown -and $Host.Name -eq 'ConsoleHost')
{
    $global:ProfileBannerShown = $true
    $esc = [char]27
    Write-Host "$esc[38;5;80m          ___                                          $esc[0m"
    Write-Host "$esc[38;5;80m       . -^   \--,                                     $esc[0m"
    Write-Host "$esc[38;5;80m      /# =========\-_                                  $esc[0m"
    Write-Host "$esc[38;5;80m     /# (--====___====\       d8b                      $esc[0m"
    Write-Host "$esc[38;5;80m    /#   .- --.  . --.|       Y8P                      $esc[0m"
    Write-Host "$esc[38;5;80m   /##   |  * ) (   * ),                               $esc[0m"
    Write-Host "$esc[1;36m   |##     \    /\ \   / |     8888  .d88b.  88888b.      $esc[0m"
    Write-Host "$esc[1;36m   |###     ---   \ ---  |     `"888 d88`"`"88b 888 `"88b $esc[0m"
    Write-Host "$esc[1;36m   |####        ___)    #|      888 888  888 888  888     $esc[0m"
    Write-Host "$esc[1;36m   |######            ##|       888 Y88..88P 888  888     $esc[0m"
    Write-Host "$esc[1;36m     \##### ---------- /        888  `"Y88P`"  888  888   $esc[0m"
    Write-Host "$esc[1;36m       \####           (        888                       $esc[0m"
    Write-Host "$esc[1;36m        \###           |       d88P                       $esc[0m"
    Write-Host "$esc[1;94m         \###          |     888P`"                       $esc[0m"
    Write-Host "$esc[1;94m           \##        |                                   $esc[0m"
    Write-Host "$esc[1;94m            \###.    .)                                   $esc[0m"
    Write-Host "$esc[1;94m             ``======/                                    $esc[0m"
    Write-Host ""
}

# ------------------------------------------------------
# 11. PROMPT / TOOLS
# ------------------------------------------------------

function Invoke-Starship-TransientFunction
{
    &starship module character
}

if ($PSVersionTable.PSVersion.Major -ge 6)
{
    if (Get-Command starship -ErrorAction SilentlyContinue)
    {
        $prompt = ""
        function Invoke-Starship-PreCommand
        {
            $current_location = $executionContext.SessionState.Path.CurrentLocation
            if ($current_location.Provider.Name -eq "FileSystem")
            {
                $ansi_escape = [char]27
                $provider_path = $current_location.ProviderPath -replace "\\", "/"
                $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
            }
            $host.ui.Write($prompt)
        }
        Invoke-Expression (&starship init powershell)
        Enable-TransientPrompt
    }

    if (Test-Cmd zoxide)
    {
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
    }
}

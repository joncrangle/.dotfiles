<#
.SYNOPSIS
Selected WinUtil tweaks from ChrisTitusTech/winutil

.DESCRIPTION
This script contains various Windows tweaks and optimizations. 
Run with: .\WinUtilTweaks.ps1 <FunctionName> [additional parameters]

.EXAMPLE
.\WinUtilTweaks.ps1 Invoke-WinUtilNumLock
.\WinUtilTweaks.ps1 Invoke-All
#>

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator"))
{
    Write-Host "Restarting as administrator..." -ForegroundColor Yellow
    $argumentList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit", "-File", $PSCommandPath)
    if ($args)
    {
        foreach ($arg in $args)
        {
            $argumentList += $arg
        }
    }
    Start-Process pwsh -ArgumentList $argumentList -Verb RunAs
    Write-Host "Check the elevated PowerShell window for output." -ForegroundColor Green
    exit 0
}

#region Helpers

function Set-RegistryValueSafe
{
    param (
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "String"
    )
    if (-not (Test-Path $Path))
    {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
    Write-Host "  ✓ Set $Path\$Name = $Value" -ForegroundColor Green
}

function Set-WinUtilService
{
    param (
        $Name,
        $StartupType
    )
    try
    {
        # Check if the service exists
        $service = Get-Service -Name $Name -ErrorAction Stop

        # Service exists, proceed with changing properties
        if ($service.StartType -ne $StartupType)
        {
            $service | Set-Service -StartupType $StartupType -ErrorAction Stop
            Write-Host "  ✓ Set Service '$Name' to '$StartupType'" -ForegroundColor Green
        } else
        {
            Write-Host "  - Service '$Name' is already set to '$StartupType'" -ForegroundColor Gray
        }
    } catch [System.ServiceProcess.ServiceNotFoundException]
    {
        Write-Warning "Service $Name was not found"
    } catch
    {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $_.Exception.Message
    }
}

#endregion Helpers

#region Tweaks

function Invoke-WinUtilNumLock
{
    Write-Host "Enabling NumLock on startup..." -ForegroundColor Cyan
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
    Set-RegistryValueSafe -Path "HKU:\.Default\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value "2" -Type "String"
    Set-RegistryValueSafe -Path "HKCU:\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value "2" -Type "String"
    Write-Host "NumLock enabled successfully!" -ForegroundColor Green
}

function Invoke-WinUtilStickyKeys
{
    Write-Host "Disabling Sticky Keys..." -ForegroundColor Cyan
    Set-RegistryValueSafe -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "58" -Type "String"
    Write-Host "Sticky Keys disabled successfully!" -ForegroundColor Green
}

function Invoke-WinUtilHiddenFiles
{
    Write-Host "Enabling Hidden Files visibility..." -ForegroundColor Cyan
    Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type "DWord"
    Write-Host "Hidden files enabled successfully!" -ForegroundColor Green
}

function Invoke-WinUtilShowExt
{
    Write-Host "Showing file extensions..." -ForegroundColor Cyan
    Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type "DWord"
    Write-Host "File extensions enabled successfully!" -ForegroundColor Green
}

function Invoke-WinUtilDarkMode
{
    Write-Host "Enabling Dark Mode..." -ForegroundColor Cyan
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-RegistryValueSafe -Path $path -Name "AppsUseLightTheme" -Value 0 -Type "DWord"
    Set-RegistryValueSafe -Path $path -Name "SystemUsesLightTheme" -Value 0 -Type "DWord"
    Write-Host "Dark Mode enabled successfully!" -ForegroundColor Green
}

function Invoke-WinUtilDisablePSTelemetry
{
    Write-Host "Disabling PowerShell telemetry..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')
    Write-Host "PowerShell telemetry disabled successfully!" -ForegroundColor Green
}

function Invoke-WinUtilEnableEndTask
{
    Write-Host "Enabling End Task on taskbar..." -ForegroundColor Cyan
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
    if (-not (Test-Path $path))
    {
        New-Item -Path $path -Force | Out-Null
    }
    New-ItemProperty -Path $path -Name "TaskbarEndTask" -PropertyType DWord -Value 1 -Force | Out-Null
    Write-Host "End Task enabled successfully!" -ForegroundColor Green
}

function Invoke-WinUtilSetServicesManual
{
    Write-Host "Setting services based on WinUtilTweaks.json..." -ForegroundColor Cyan
    $jsonPath = Join-Path $PSScriptRoot "WinUtilTweaks.json"

    if (-not (Test-Path $jsonPath))
    {
        Write-Error "Error: WinUtilTweaks.json not found."
        return
    }

    $servicesData = Get-Content -Path $jsonPath | ConvertFrom-Json
    
    foreach ($service in $servicesData.service)
    {
        Set-WinUtilService -Name $service.Name -StartupType $service.StartupType
    }
    Write-Host "Finished setting services." -ForegroundColor Green
}

function Invoke-All
{
    Write-Host "Invoking all available tweaks..." -ForegroundColor Yellow
    $functionsToRun = Get-Command -CommandType Function | Where-Object { $_.Name -like 'Invoke-WinUtil*' }
    foreach ($func in $functionsToRun)
    {
        Write-Host "`nExecuting: $($func.Name)" -ForegroundColor Magenta
        Write-Host "===============================" -ForegroundColor Magenta
        & $func.ScriptBlock
    }
}

function Show-AvailableFunctions
{
    Write-Host "`nAvailable Functions:" -ForegroundColor Cyan
    Write-Host "- Invoke-All"
    Write-Host "- Invoke-WinUtilNumLock"
    Write-Host "- Invoke-WinUtilStickyKeys" 
    Write-Host "- Invoke-WinUtilHiddenFiles"
    Write-Host "- Invoke-WinUtilShowExt"
    Write-Host "- Invoke-WinUtilDarkMode"
    Write-Host "- Invoke-WinUtilDisablePSTelemetry"
    Write-Host "- Invoke-WinUtilEnableEndTask"
    Write-Host "- Invoke-WinUtilSetServicesManual"
    Write-Host ""
}

#endregion Tweaks

#region Main Execution

if ($args.Count -gt 0)
{
    $FunctionName = $args[0]
    $Parameters = $args[1..($args.Count-1)]
} else
{
    $FunctionName = ""
    $Parameters = @()
}

if (-not $FunctionName -or $FunctionName -eq "ShowMenu")
{
    Show-AvailableFunctions
    exit 0
}

if (-not (Get-Command $FunctionName -CommandType Function -ErrorAction SilentlyContinue))
{
    Write-Error "Function '$FunctionName' not found."
    Show-AvailableFunctions
    exit 1
}

# Special handling for Invoke-All, which doesn't need the standard header
if ($FunctionName -ne "Invoke-All")
{
    Write-Host "Executing: $FunctionName" -ForegroundColor Magenta
    Write-Host "===============================" -ForegroundColor Magenta
}

if ($Parameters.Count -gt 0)
{
    if ($FunctionName -eq "Invoke-WinUtilSetServicesManual")
    {
        $serviceList = @()
        foreach ($param in $Parameters)
        {
            $serviceList += $param -split ','
        }
        & $FunctionName -Services $serviceList
    } else
    {
        & $FunctionName $Parameters
    }
} else
{
    & $FunctionName
}

Write-Host "`nExecution completed!" -ForegroundColor Green

#endregion

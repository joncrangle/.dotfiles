@echo off
@REM Run komorebi with the specified configuration and log errors
pwsh -WindowStyle Hidden -Command Start-Process "$env:USERPROFILE\scoop\apps\komorebi\current\komorebic-no-console.exe" -ArgumentList "start", "--config", "$env:KOMOREBI_CONFIG_HOME\komorebi.json", "--whkd"

@REM Wait until komorebi is running before launching zebar
pwsh -WindowStyle hidden -Command ^
  while (-not (Get-Process -Name "komorebi" -ErrorAction SilentlyContinue)) { Start-Sleep -Seconds 5 }; ^

@REM Start zebar
start "" "zebar.exe" > nul 2>&1

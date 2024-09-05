@echo off
@REM Run komorebi with the specified configuration and log errors
pwsh -WindowStyle Hidden -Command Start-Process "$env:USERPROFILE\scoop\apps\komorebi\current\komorebic-no-console.exe" -ArgumentList "start", "--config", "$env:KOMOREBI_CONFIG_HOME\komorebi.json", "--whkd"

@REM Wait until komorebi is running before launching zebar
powershell -WindowStyle hidden -Command ^
  while (-not (Get-Process -Name "komorebi" -ErrorAction SilentlyContinue)) { Start-Sleep -Seconds 5 }; ^
  @REM Start hidden PowerShell script, which runs `zebar open bar --args ...` for every monitor
  powershell -WindowStyle hidden -Command ^
  $monitors = zebar monitors; ^
  foreach ($monitor in $monitors) { Start-Process -WindowStyle Hidden -FilePath \"zebar\" -ArgumentList \"open bar --args $monitor\" };

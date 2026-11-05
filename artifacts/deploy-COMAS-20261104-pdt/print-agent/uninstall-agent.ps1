[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$agentDirectory = Split-Path -Parent $PSCommandPath
$serviceName = "DNXPrintAgent"
$legacyTaskName = "DNX Print Agent"
$serviceExecutable = Join-Path $agentDirectory "dnx-print-agent-service.exe"

$principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Abre PowerShell como administrador para desinstalar el agente."
}

$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($service) {
    if ($service.Status -ne "Stopped") { Stop-Service -Name $serviceName -Force }
    if (Test-Path -LiteralPath $serviceExecutable) {
        & $serviceExecutable uninstall
        if ($LASTEXITCODE -ne 0) { throw "No se pudo quitar el servicio $serviceName." }
    }
    else {
        & sc.exe delete $serviceName | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "No se pudo quitar el servicio $serviceName." }
    }
}

$legacyTask = Get-ScheduledTask -TaskName $legacyTaskName -ErrorAction SilentlyContinue
if ($legacyTask) {
    if ($legacyTask.State -eq "Running") { Stop-ScheduledTask -TaskName $legacyTaskName }
    Unregister-ScheduledTask -TaskName $legacyTaskName -Confirm:$false
}

for ($attempt = 0; $attempt -lt 10; $attempt++) {
    $listener = Get-NetTCPConnection -LocalPort 5174 -State Listen -ErrorAction SilentlyContinue
    if (-not $listener) { break }
    Start-Sleep -Seconds 1
}
$remainingListeners = @(
    Get-NetTCPConnection -LocalPort 5174 -State Listen -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess -Unique
)
if ($remainingListeners.Count -gt 0) {
    throw "Se quitaron el servicio y la tarea, pero el puerto 5174 sigue ocupado por PID $($remainingListeners -join ', '). Revisa ese proceso antes de borrar la carpeta."
}

Remove-Item -LiteralPath (Join-Path $agentDirectory "dnx-print-agent-service.xml") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $serviceExecutable -Force -ErrorAction SilentlyContinue
Write-Host "Se quitaron el servicio y la tarea programada. Se conservaron agent.config.json, registros y archivos del agente." -ForegroundColor Green

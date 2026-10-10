[CmdletBinding()]
param(
    [string]$TaskName = "DNX Print Agent"
)

$ErrorActionPreference = "Stop"

$agentDirectory = Split-Path -Parent $PSCommandPath
$runner = Join-Path $agentDirectory "run-agent-background.ps1"
$node = Get-Command node -ErrorAction SilentlyContinue
$powershell = (Get-Command powershell.exe -ErrorAction Stop).Source

if (-not (Test-Path -LiteralPath $runner)) {
    throw "No se encontró el iniciador del agente: $runner"
}

if (-not $node) {
    throw "Node.js 20 o superior es necesario para iniciar el agente. Instálalo y vuelve a ejecutar este script."
}

$nodeMajorVersion = [int](($node.Version.ToString() -split "\.")[0])
if ($nodeMajorVersion -lt 20) {
    throw "Se detectó Node.js $($node.Version). El agente requiere Node.js 20 o superior."
}

$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$action = New-ScheduledTaskAction `
    -Execute $powershell `
    -Argument ('-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" -NodePath "{1}"' -f $runner, $node.Source) `
    -WorkingDirectory $agentDirectory
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Seconds 0) `
    -RestartCount 255 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -MultipleInstances IgnoreNew

$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask -and $existingTask.State -eq "Running") {
    Stop-ScheduledTask -TaskName $TaskName
}

Register-ScheduledTask `
    -TaskName $TaskName `
    -Description "Mantiene el agente local de impresión de DNX oculto en la sesión del usuario y lo inicia al ingresar a Windows." `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Force | Out-Null

Start-ScheduledTask -TaskName $TaskName

$healthUrl = "http://127.0.0.1:5174/health"
for ($attempt = 1; $attempt -le 10; $attempt++) {
    Start-Sleep -Seconds 1
    try {
        $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2
        if ($health.ok) {
            Write-Host "El agente quedó activo y se iniciará automáticamente con Windows." -ForegroundColor Green
            exit 0
        }
    }
    catch {
        if ($attempt -eq 10) {
            throw "La tarea se registró, pero el agente no respondió en $healthUrl. Revisa agent.config.json y el Visor de eventos del Programador de tareas."
        }
    }
}

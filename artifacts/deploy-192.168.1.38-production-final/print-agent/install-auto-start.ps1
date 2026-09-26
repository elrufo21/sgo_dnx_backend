[CmdletBinding()]
param(
    [string]$TaskName = "DNX Print Agent"
)

$ErrorActionPreference = "Stop"

$agentDirectory = Split-Path -Parent $PSCommandPath
$runner = Join-Path $agentDirectory "run-agent-service.cmd"
$node = Get-Command node -ErrorAction SilentlyContinue

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
    -Execute $env:ComSpec `
    -Argument ('/c ""{0}""' -f $runner) `
    -WorkingDirectory $agentDirectory
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Seconds 0) `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $TaskName `
    -Description "Inicia el agente local de impresión de DNX al ingresar a Windows y lo reinicia si se detiene." `
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

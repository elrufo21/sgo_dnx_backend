[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$agentDirectory = Split-Path -Parent $PSCommandPath
$serviceName = "DNXPrintAgent"
$legacyTaskName = "DNX Print Agent"
$serviceExecutable = Join-Path $agentDirectory "dnx-print-agent-service.exe"
$serviceConfig = Join-Path $agentDirectory "dnx-print-agent-service.xml"
$configPath = Join-Path $agentDirectory "agent.config.json"
$node = Get-Command node.exe -ErrorAction SilentlyContinue
$legacyTask = Get-ScheduledTask -TaskName $legacyTaskName -ErrorAction SilentlyContinue
$legacyTaskWasRunning = $legacyTask -and $legacyTask.State -eq "Running"
$serviceInstalledByScript = $false

function Test-AgentHealth {
    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:5174/health" -TimeoutSec 2
        return $health.ok -and $health.service -eq "dnx-print-agent"
    }
    catch {
        return $false
    }
}

function Wait-AgentPortFree {
    for ($attempt = 0; $attempt -lt 15; $attempt++) {
        $listener = Get-NetTCPConnection -LocalPort 5174 -State Listen -ErrorAction SilentlyContinue
        if (-not $listener) { return }
        Start-Sleep -Seconds 1
    }
    $processIds = @(
        Get-NetTCPConnection -LocalPort 5174 -State Listen -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty OwningProcess -Unique
    )
    throw "El puerto 5174 sigue ocupado por PID $($processIds -join ', '). Cierra el agente que ya está usando ese puerto y vuelve a ejecutar el instalador."
}

try {
    $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Abre PowerShell como administrador para instalar el servicio."
    }
    if (-not $node) { throw "Instala Node.js 20 o superior para todos los usuarios y vuelve a intentarlo." }
    $nodeMajorVersion = [int](($node.Version.ToString() -split "\.")[0])
    if ($nodeMajorVersion -lt 20) { throw "El agente requiere Node.js 20 o superior; se detectó $($node.Version)." }
    if (-not (Test-Path -LiteralPath $configPath)) { throw "Falta agent.config.json. Configúralo antes de instalar el servicio." }
    if (-not (Test-Path -LiteralPath (Join-Path $agentDirectory "node_modules\pdf-to-printer"))) {
        throw "Faltan las dependencias. Ejecuta npm ci en la carpeta del agente."
    }
    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        throw "El servicio ya existe. Ejecuta uninstall-agent.ps1 y luego vuelve a instalarlo."
    }

    if ($legacyTask -and $legacyTaskWasRunning) {
        Stop-ScheduledTask -TaskName $legacyTaskName
    }
    Wait-AgentPortFree

    $winSwUrl = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe"
    $winSwSha256 = "05B82D46AD331CC16BDC00DE5C6332C1EF818DF8CEEFCD49C726553209B3A0DA"
    if (-not (Test-Path -LiteralPath $serviceExecutable)) {
        Invoke-WebRequest -Uri $winSwUrl -OutFile $serviceExecutable
    }
    $actualHash = (Get-FileHash -LiteralPath $serviceExecutable -Algorithm SHA256).Hash
    if ($actualHash -ne $winSwSha256) {
        Remove-Item -LiteralPath $serviceExecutable -Force
        throw "La validación SHA-256 del instalador del servicio falló. No se instaló el servicio."
    }

    $nodePathXml = [System.Security.SecurityElement]::Escape($node.Source)
    $agentDirectoryXml = [System.Security.SecurityElement]::Escape($agentDirectory)
    $serverPathXml = [System.Security.SecurityElement]::Escape((Join-Path $agentDirectory "src\server.mjs"))
    @"
<service>
  <id>DNXPrintAgent</id>
  <name>DNX Print Agent</name>
  <description>Agente local para impresión silenciosa de DNX.</description>
  <executable>$nodePathXml</executable>
  <arguments>`"$serverPathXml`"</arguments>
  <workingdirectory>$agentDirectoryXml</workingdirectory>
  <startmode>Automatic</startmode>
  <onfailure action="restart" delay="5 sec" />
  <resetfailure>1 hour</resetfailure>
  <stoptimeout>15 sec</stoptimeout>
  <log mode="roll" />
</service>
"@ | Set-Content -LiteralPath $serviceConfig -Encoding UTF8

    & $serviceExecutable install
    if ($LASTEXITCODE -ne 0) { throw "WinSW no pudo registrar el servicio (código $LASTEXITCODE)." }
    $serviceInstalledByScript = $true
    Set-Service -Name $serviceName -StartupType Automatic
    & sc.exe failure $serviceName reset= 86400 actions= restart/5000/restart/10000/restart/30000 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Windows no pudo configurar la recuperación automática del servicio." }
    & $serviceExecutable start
    if ($LASTEXITCODE -ne 0) { throw "WinSW no pudo iniciar el servicio (código $LASTEXITCODE)." }

    $healthy = $false
    for ($attempt = 1; $attempt -le 15; $attempt++) {
        Start-Sleep -Seconds 1
        if (Test-AgentHealth) { $healthy = $true; break }
    }
    if (-not $healthy) { throw "El servicio se instaló, pero el agente no respondió en http://127.0.0.1:5174/health. Revisa los registros de WinSW." }

    if ($legacyTask) { Unregister-ScheduledTask -TaskName $legacyTaskName -Confirm:$false }
    Write-Host "DNX Print Agent quedó instalado como servicio automático y respondió correctamente." -ForegroundColor Green
}
catch {
    if ($serviceInstalledByScript) {
        try { & $serviceExecutable stop | Out-Null } catch {}
        try { & $serviceExecutable uninstall | Out-Null } catch {}
    }
    if ($legacyTaskWasRunning) {
        try { Start-ScheduledTask -TaskName $legacyTaskName } catch {}
    }
    throw
}

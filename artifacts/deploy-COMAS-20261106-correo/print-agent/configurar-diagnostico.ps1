[CmdletBinding()]
param([switch]$Desactivar)

$ErrorActionPreference = "Stop"
$serviceName = "DNXPrintAgent"
$principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Abre PowerShell como administrador."
}
$serviceInfo = Get-CimInstance Win32_Service -Filter "Name='$serviceName'"
if (-not $serviceInfo) { throw "DNXPrintAgent no esta instalado en esta PC." }

if ($serviceInfo.PathName -match '^"([^"]+)"') {
    $serviceExecutable = $Matches[1]
}
elseif ($serviceInfo.PathName -match '^(.*?\.exe)(?:\s|$)') {
    $serviceExecutable = $Matches[1]
}
else {
    throw "No se pudo identificar la carpeta real del servicio."
}
$agentDirectory = Split-Path -Parent $serviceExecutable
$configPath = Join-Path $agentDirectory "agent.config.json"
$sourceDirectory = Join-Path $PSScriptRoot "src"
$targetDirectory = Join-Path $agentDirectory "src"
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$files = @("config.mjs", "pdf.mjs", "print-job.mjs", "server.mjs")
foreach ($name in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $sourceDirectory $name))) {
        throw "Falta src\$name en el paquete extraido. Ejecuta el script desde el paquete completo."
    }
}

$backup = Join-Path $agentDirectory ("backup-diagnostico\" + (Get-Date -Format "yyyyMMdd-HHmmss-fff"))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
Copy-Item -LiteralPath $configPath -Destination $backup
Copy-Item -LiteralPath $targetDirectory -Destination $backup -Recurse

try {
    Stop-Service -Name $serviceName
    foreach ($name in $files) {
        $source = Join-Path $sourceDirectory $name
        $target = Join-Path $targetDirectory $name
        if ([IO.Path]::GetFullPath($source) -ne [IO.Path]::GetFullPath($target)) {
            Copy-Item -LiteralPath $source -Destination $target -Force
        }
        if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) {
            throw "No se pudo verificar la copia de $name."
        }
    }
    $enabled = -not $Desactivar.IsPresent
    $config | Add-Member -NotePropertyName diagnosticMode -NotePropertyValue $enabled -Force
    [IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
    New-Item -ItemType Directory -Force -Path (Join-Path $agentDirectory "diagnostics") | Out-Null
    Start-Service -Name $serviceName
    $port = if ($config.port) { [int]$config.port } else { 5174 }
    $healthy = $false
    for ($attempt = 0; $attempt -lt 15; $attempt++) {
        try {
            $health = Invoke-RestMethod -Uri "http://127.0.0.1:$port/health" -TimeoutSec 2
            if ($health.build -eq "20261021-diagnostics-v1" -and $health.diagnosticMode -eq $enabled) {
                $healthy = $true
                break
            }
        }
        catch {}
        Start-Sleep -Seconds 1
    }
    if (-not $healthy) { throw "El agente no confirmo la version y el modo solicitado." }
    Write-Host "Servicio: $agentDirectory"
    Write-Host "diagnosticMode: $enabled"
    Write-Host ("PDF y registros: " + (Join-Path $agentDirectory "diagnostics"))
    Write-Host "Copia anterior: $backup"
    if ($enabled) {
        Write-Host "DIAGNOSTICO ACTIVO: no se enviaran trabajos a la impresora." -ForegroundColor Yellow
    }
    else {
        Write-Host "Diagnostico desactivado: la impresion normal esta habilitada." -ForegroundColor Green
    }
}
catch {
    Stop-Service -Name $serviceName -ErrorAction SilentlyContinue
    throw
}

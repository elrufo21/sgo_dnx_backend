param(
    [string]$ServerName = "192.168.18.47",
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"

$backendRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$workspaceRoot = (Resolve-Path (Join-Path $backendRoot "..")).Path
$frontendRoot = Join-Path $workspaceRoot "sgo_dnx_frontend"
$extensionRoot = Join-Path $workspaceRoot "sgo_dnx_extension"
$printAgentRoot = Join-Path $workspaceRoot "dnx-print-agent"
$apiProject = Join-Path $backendRoot "src\Api\Ecommerce.Api.csproj"
$apiSettingsTemplate = Join-Path $backendRoot "deploy\server-new\appsettings.json"

if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $backendRoot ("artifacts\deploy-{0}-{1}" -f $ServerName.ToLowerInvariant(), (Get-Date -Format "yyyyMMdd-HHmmss"))
}

if (-not (Test-Path $frontendRoot)) { throw "No se encontró el frontend: $frontendRoot" }
if (-not (Test-Path $apiProject)) { throw "No se encontró el proyecto API: $apiProject" }
if (-not (Test-Path $apiSettingsTemplate)) { throw "No se encontró el appsettings seguro de despliegue." }
if (Test-Path $OutputDirectory) { throw "La carpeta de salida ya existe; usa otra ruta para evitar mezclar paquetes: $OutputDirectory" }
if (-not (Test-Path (Join-Path $frontendRoot "node_modules"))) {
    throw "Faltan dependencias del frontend. Ejecuta npm ci en $frontendRoot y vuelve a intentarlo."
}

$apiUrl = "http://${ServerName}:8081/api/v1"
$webOrigin = "http://${ServerName}:8080"
$databaseName = switch ($ServerName) {
    "192.168.1.38" { "DXN_ICA" }
    "192.168.18.47" { "DXNCOMAS" }
    default { "<base destino>" }
}
$apiOutput = Join-Path $OutputDirectory "api"
$webOutput = Join-Path $OutputDirectory "web"
$configurationOutput = Join-Path $OutputDirectory "configuration"
$extensionOutput = Join-Path $OutputDirectory "extension"
$printAgentOutput = Join-Path $OutputDirectory "print-agent"

New-Item -ItemType Directory -Path $apiOutput, $webOutput, $configurationOutput, $extensionOutput, $printAgentOutput -Force | Out-Null

$oldApiUrl = $env:VITE_API_BASE_URL
$oldPrintAgentUrl = $env:VITE_PRINT_AGENT_BASE_URL
$oldPrintAgentToken = $env:VITE_PRINT_AGENT_TOKEN
$oldPasswordExpirationLock = $env:VITE_PASSWORD_EXPIRATION_LOCK_ENABLED

try {
    $env:VITE_API_BASE_URL = $apiUrl
    $env:VITE_PRINT_AGENT_BASE_URL = "http://127.0.0.1:5174"
    $env:VITE_PASSWORD_EXPIRATION_LOCK_ENABLED = "true"

    $agentConfigPath = Join-Path $printAgentRoot "agent.config.json"
    if (-not (Test-Path $agentConfigPath)) { throw "Falta el agent.config.json con el token compartido del agente." }
    $agentConfig = Get-Content $agentConfigPath -Raw | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace([string]$agentConfig.token)) { throw "El token del agente de impresión está vacío." }
    $env:VITE_PRINT_AGENT_TOKEN = [string]$agentConfig.token

    Push-Location $frontendRoot
    try {
        npm run build:vercel
        if ($LASTEXITCODE -ne 0) { throw "Falló la compilación del frontend (npm run build:vercel)." }
    }
    finally {
        Pop-Location
    }

    $frontendDist = Join-Path $frontendRoot "dist"
    if (-not (Test-Path (Join-Path $frontendDist "index.html"))) {
        throw "La compilación no generó dist/index.html."
    }
    Copy-Item (Join-Path $frontendDist "*") $webOutput -Recurse -Force

    dotnet publish $apiProject --configuration Release --runtime win-x64 --self-contained false --output $apiOutput
    if ($LASTEXITCODE -ne 0) { throw "Falló la publicación de la API para Windows x64." }

    $deploymentSettings = Get-Content $apiSettingsTemplate -Raw | ConvertFrom-Json
    $deploymentSettings.LocalMedia.RootPath = "C:\SGO\media"
    $deploymentSettings.Cors.AllowedOrigins = @("http://localhost:8080", $webOrigin)
    $deploymentSettings.EmailSettings.DisplayName = if ($databaseName -eq "DXNCOMAS") { "DXN COMAS" } else { "DXN ICA" }
    $deploymentSettings | ConvertTo-Json -Depth 10 |
        Set-Content -Path (Join-Path $configurationOutput "appsettings.template.json") -Encoding UTF8
    Get-ChildItem -LiteralPath $apiOutput -Filter "appsettings*.json" -File | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Force
    }

    Get-ChildItem -LiteralPath $extensionRoot -Force | Where-Object {
        $_.Name -notin @(".git", "node_modules", "logs") -and $_.Name -notlike ".env*"
    } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $extensionOutput -Recurse -Force
    }
    Get-ChildItem $extensionOutput -Recurse -File | Where-Object {
        $_.Extension -in @(".js", ".json", ".md", ".html", ".css") -and $_.FullName -notmatch "\\.git\\"
    } | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $content = $content.Replace("http://SERVER-NEW:8080", $webOrigin)
        $content = $content.Replace("http://192.168.1.38:8080", $webOrigin)
        $content = $content.Replace("http://192.168.18.47:8080", $webOrigin)
        Set-Content -Path $_.FullName -Value $content -Encoding UTF8
    }
    $manifestPath = Join-Path $extensionOutput "manifest.json"
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    $newServerPattern = "http://SERVER-NEW:8080/*"
    $newWebPattern = "$webOrigin/*"
    $manifest.host_permissions = @($manifest.host_permissions | ForEach-Object {
        if ($_ -eq $newServerPattern) { $newWebPattern } else { $_ }
    } | Select-Object -Unique)
    foreach ($contentScript in $manifest.content_scripts) {
        if ($contentScript.js -contains "content-sgo.js") {
            $contentScript.matches = @($contentScript.matches | ForEach-Object {
                if ($_ -eq $newServerPattern) { $newWebPattern } else { $_ }
            } | Select-Object -Unique)
        }
    }
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8

    $agentFiles = Get-ChildItem $printAgentRoot -Force | Where-Object {
        $_.Name -notin @(".git", "node_modules", "logs", "agent.config.json") -and $_.Name -notlike ".env*" -and $_.Name -notlike "*.log"
    }
    foreach ($item in $agentFiles) {
        Copy-Item $item.FullName $printAgentOutput -Recurse -Force
    }
    $agentOrigins = @($agentConfig.allowedOrigins | Where-Object {
        $_ -notmatch "^http://(SERVER-NEW|192\.168\.\d{1,3}\.\d{1,3}):8080$"
    }) + $webOrigin | Select-Object -Unique
    [ordered]@{
        port = 5174
        defaultPrinter = ""
        token = [string]$agentConfig.token
        allowedOrigins = $agentOrigins
        maxPdfBytes = 10485760
    } | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $printAgentOutput "agent.config.json") -Encoding UTF8

    $listadosSqlRoot = Join-Path $backendRoot "scripts\sql\20261020_optimizacion_listados"
    $listadosSqlOutput = Join-Path $OutputDirectory "sql\20261020_optimizacion_listados"
    New-Item -ItemType Directory -Path $listadosSqlOutput -Force | Out-Null
    Copy-Item (Join-Path $listadosSqlRoot "*") $listadosSqlOutput -Force
    Copy-Item (Join-Path $backendRoot "scripts\sql\20261026_listaNotaPedido_web.sql") (Join-Path $OutputDirectory "sql\20261026_listaNotaPedido_web.sql") -Force

    $readme = @"
# Despliegue DNX para $ServerName

- Web: $webOrigin
- API: $apiUrl
- Paquete API: ASP.NET Core para Windows x64, framework-dependent (.NET 7 Hosting Bundle requerido).
- IIS: sitios SGO Web en puerto 8080 y SGO API en puerto 8081; grupos de aplicaciones sin código administrado.
- Base prevista: $databaseName. Conservar ``api/appsettings.json`` del servidor con su conexión y credenciales actuales.
- Medios: ``C:\SGO\media``; asignar permiso Modificar al grupo de aplicaciones de SGO API.

El paquete no contiene ``api/appsettings.json``: no reemplaza conexión, claves ni credenciales existentes. ``configuration/appsettings.template.json`` es solo una plantilla sin secretos para instalaciones nuevas; completarla antes de iniciar IIS. Conservar también las carpetas ``media`` y ``keys`` del servidor. Este paquete no ejecuta scripts SQL ni restaura bases de datos.

Antes de publicar esta API, el responsable SQL debe aplicar en la base destino los archivos 01, 02 y 03 de ``sql/20261020_optimizacion_listados/``, en ese orden. La carpeta incluye instrucciones y reversión; el archivo 04 es solo para revertir y no debe ejecutarse durante la actualización.

Para que el listado Nota Pedido muestre ConceptoOBS, el responsable SQL debe revisar y aplicar ``sql/20261026_listaNotaPedido_web.sql`` en $databaseName antes de publicar esta API. El script crea o actualiza únicamente ``dbo.listaNotaPedidoWEB``; conserva ``dbo.listaNotaPedido`` para el aplicativo de escritorio. Este paquete solo entrega el SQL, no lo ejecuta.

En el servidor instalar IIS, URL Rewrite y el .NET 7 Hosting Bundle. La IP estática de LAN usada en este paquete es $ServerName. La regla de firewall debe limitar los puertos de la aplicación a la subred local.

La extensión se publica aparte desde ``extension/``. Para impresión local, instalar el agente en cada estación que imprime y agregar ``$webOrigin`` a ``allowedOrigins`` de su ``agent.config.json``; el token debe coincidir con el incluido en la web.
"@
    Set-Content -Path (Join-Path $OutputDirectory "README.md") -Value $readme -Encoding UTF8

    $zipPath = "$OutputDirectory-final.zip"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($OutputDirectory, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    if ($ServerName -in @("192.168.18.47", "192.168.1.38")) {
        & (Join-Path $PSScriptRoot "verify-package.ps1") -PackagePath $zipPath -ServerName $ServerName
    }
    Write-Host "Paquete preparado: $OutputDirectory"
    Write-Host "ZIP: $zipPath"
    Write-Host "Web: $webOrigin"
    Write-Host "API: $apiUrl"
}
finally {
    $env:VITE_API_BASE_URL = $oldApiUrl
    $env:VITE_PRINT_AGENT_BASE_URL = $oldPrintAgentUrl
    $env:VITE_PRINT_AGENT_TOKEN = $oldPrintAgentToken
    $env:VITE_PASSWORD_EXPIRATION_LOCK_ENABLED = $oldPasswordExpirationLock
}

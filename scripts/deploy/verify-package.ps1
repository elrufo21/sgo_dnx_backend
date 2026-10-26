param(
    [Parameter(Mandatory = $true)][string]$PackagePath,
    [Parameter(Mandatory = $true)][ValidateSet("192.168.18.47", "192.168.1.38")][string]$ServerName
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$webOrigin = "http://${ServerName}:8080"
$apiUrl = "http://${ServerName}:8081/api/v1"
$otherServer = if ($ServerName -eq "192.168.1.38") { "192.168.18.47" } else { "192.168.1.38" }
$backendRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Assert-Package([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $PackagePath).Path)
try {
    $entries = @{}
    foreach ($entry in $archive.Entries) {
        $name = $entry.FullName.Replace('\', '/')
        Assert-Package (-not $entries.ContainsKey($name)) "Entrada duplicada en el ZIP."
        $entries[$name] = $entry
        Assert-Package ($name -notmatch '(^|/)(\.git|node_modules|tmp-build-[^/]*)(/|$)') "El ZIP contiene archivos de desarrollo."
        Assert-Package ($name -notmatch '(?i)\.log$|(^|/)\.env($|\.)') "El ZIP contiene logs o archivos de entorno."
        Assert-Package ($name -notmatch '(?i)^api/.*appsettings[^/]*\.json$') "El ZIP reemplazaria la configuracion del servidor."
    }
    function Read-PackageEntry([string]$Name) {
        Assert-Package ($entries.ContainsKey($Name)) "Falta un archivo requerido: $Name"
        $reader = New-Object System.IO.StreamReader($entries[$Name].Open())
        try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
    }

    $runtime = Read-PackageEntry 'api/Ecommerce.Api.runtimeconfig.json' | ConvertFrom-Json
    Assert-Package ($runtime.runtimeOptions.tfm -eq 'net7.0') "El paquete debe usar .NET 7."
    $dependencies = Read-PackageEntry 'api/Ecommerce.Api.deps.json' | ConvertFrom-Json
    Assert-Package ($dependencies.runtimeTarget.name -like '*/win-x64') "La API debe publicarse para Windows x64."
    foreach ($framework in @($runtime.runtimeOptions.frameworks)) {
        Assert-Package ($framework.version -like '7.*') "El runtime debe pertenecer a .NET 7."
    }
    $null = [xml](Read-PackageEntry 'api/web.config')
    $null = [xml](Read-PackageEntry 'web/web.config')
    $null = Read-PackageEntry 'web/index.html'

    $template = Read-PackageEntry 'configuration/appsettings.template.json' | ConvertFrom-Json
    Assert-Package ($template.Cors.AllowedOrigins -contains $webOrigin) "CORS no contiene el origen destino."
    Assert-Package (-not (@($template.Cors.AllowedOrigins) -match [regex]::Escape($otherServer))) "CORS contiene el otro servidor."
    Assert-Package ([string]::IsNullOrEmpty($template.ConnectionStrings.DefaultConnection)) "La plantilla contiene una conexion."
    foreach ($secret in @($template.JwtSettings.Key, $template.EmailSettings.Key, $template.CloudinarySettings.ApiSecret, $template.StripeSettings.SecretKey)) {
        Assert-Package ([string]::IsNullOrEmpty([string]$secret)) "La plantilla contiene un secreto."
    }
    Assert-Package ($template.LocalMedia.RootPath -eq 'C:\SGO\media') "La ruta de medios no corresponde al despliegue."

    $javascript = New-Object System.Text.StringBuilder
    foreach ($name in $entries.Keys | Where-Object { $_ -like 'web/*.js' -or $_ -like 'web/assets/*.js' }) {
        $null = $javascript.Append((Read-PackageEntry $name))
    }
    $webCode = $javascript.ToString()
    Assert-Package ($webCode.Contains($apiUrl)) "El frontend no contiene la API destino compilada."
    Assert-Package (-not $webCode.Contains($otherServer)) "El frontend contiene el otro servidor."

    $agent = Read-PackageEntry 'print-agent/agent.config.json' | ConvertFrom-Json
    Assert-Package ($agent.allowedOrigins -contains $webOrigin) "El agente no admite el frontend destino."
    Assert-Package (-not (@($agent.allowedOrigins) -match [regex]::Escape($otherServer))) "El agente contiene el otro servidor."
    Assert-Package (-not [string]::IsNullOrWhiteSpace($agent.token)) "Falta el token de impresion."
    Assert-Package ($webCode.Contains([string]$agent.token)) "El token del agente no coincide con el frontend."
    Assert-Package ($agent.port -eq 5174) "Puerto del agente inesperado."

    $manifest = Read-PackageEntry 'extension/manifest.json' | ConvertFrom-Json
    Assert-Package ($manifest.host_permissions -contains "$webOrigin/*") "La extension no admite el destino."
    Assert-Package (-not (@($manifest.host_permissions) -match [regex]::Escape($otherServer))) "La extension contiene el otro servidor."
    $sgoMatches = @($manifest.content_scripts | Where-Object { $_.js -contains 'content-sgo.js' } | ForEach-Object { $_.matches })
    Assert-Package ($sgoMatches -contains "$webOrigin/*") "El content script de SGO no admite el destino."

    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $backendRoot 'scripts/sql/20261020_optimizacion_listados') -File) {
        $packaged = Read-PackageEntry "sql/20261020_optimizacion_listados/$($file.Name)"
        $source = [System.IO.File]::ReadAllText($file.FullName)
        Assert-Package ($packaged -ceq $source) "Un SQL o su README no coincide con el archivo revisado."
    }
    $notaPedidoSql = Read-PackageEntry 'sql/20261026_listaNotaPedido_web.sql'
    $notaPedidoSqlSource = [System.IO.File]::ReadAllText((Join-Path $backendRoot 'scripts/sql/20261026_listaNotaPedido_web.sql'))
    Assert-Package ($notaPedidoSql -ceq $notaPedidoSqlSource) "El SQL de Nota Pedido no coincide con el archivo revisado."
    $readme = Read-PackageEntry 'README.md'
    Assert-Package ($readme.Contains($webOrigin) -and $readme.Contains($apiUrl)) "README con URLs incorrectas."
    Write-Host "OK: URLs, CORS, .NET 7, IIS, impresion, SQL y configuracion conservada ($ServerName)."
    Write-Host "SHA256: $((Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash)"
}
finally { $archive.Dispose() }

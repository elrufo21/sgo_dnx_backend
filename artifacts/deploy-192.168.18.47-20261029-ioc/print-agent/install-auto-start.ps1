$ErrorActionPreference = "Stop"
$installer = Join-Path (Split-Path -Parent $PSCommandPath) "install-service.ps1"
if (-not (Test-Path -LiteralPath $installer)) {
    throw "No se encontró install-service.ps1. Descarga la versión actual del agente."
}
Write-Warning "El agente ahora se instala como servicio de Windows; se requiere PowerShell como administrador."
& $installer

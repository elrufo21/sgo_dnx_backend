$ErrorActionPreference = 'Stop'

# Se registra para el usuario actual: el servicio no tiene escritorio interactivo.
$source = Join-Path $PSScriptRoot 'abrir-carpeta-descargas.vbs'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw 'No se encontro abrir-carpeta-descargas.vbs junto al instalador.'
}
$destination = Join-Path $env:LOCALAPPDATA 'DNX\VerCarpeta'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$scriptPath = Join-Path $destination 'abrir-carpeta-descargas.vbs'
Copy-Item -LiteralPath $source -Destination $scriptPath -Force

$protocol = 'HKCU:\Software\Classes\dnxdescargas'
$commandKey = Join-Path $protocol 'shell\open\command'
New-Item -Path $commandKey -Force | Out-Null
Set-Item -Path $protocol -Value 'URL:Carpeta de descargas DNX'
New-ItemProperty -Path $protocol -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
$wscript = Join-Path $env:SystemRoot 'System32\wscript.exe'
$command = '"{0}" "{1}" "%1"' -f $wscript, $scriptPath
Set-Item -Path $commandKey -Value $command
Write-Host 'Boton Ver carpeta instalado para el usuario actual.'
Write-Host 'Si otros usuarios de Windows usan esta PC, cada uno debe ejecutar este instalador.'

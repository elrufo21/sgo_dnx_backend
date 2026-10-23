[CmdletBinding()]
param(
    [ValidateSet('local', 'comas')]
    [string]$Target = 'local',
    [string]$OutputDirectory = ''
)
$ErrorActionPreference = 'Stop'
$sourceDirectory = Split-Path $PSScriptRoot -Parent
$targetLabel = if ($Target -eq 'comas') { 'COMAS' } else { 'Local' }
$targetOrigin = if ($Target -eq 'comas') { 'http://192.168.18.47:8080' } else { 'http://localhost:5173' }
$targetHost = ([System.Uri]$targetOrigin).Host
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $PSScriptRoot "..\..\sgo_dnx_backend\artifacts\firefox-$Target-20261021"
}
$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
$unpackedPath = Join-Path $outputPath "$Target-unpacked"
$utf8 = [System.Text.UTF8Encoding]::new($false)
New-Item -ItemType Directory -Path $unpackedPath -Force | Out-Null

$manifestText = Get-Content (Join-Path $sourceDirectory 'manifest.json') -Raw -Encoding UTF8
$manifest = $manifestText.Replace('http://localhost:5173', $targetOrigin) | ConvertFrom-Json
$manifest.name = "SGO DXN Capture - $targetLabel"
$manifest.description = "Captura ventas y resumenes de DXN OBS para SGO $targetLabel."
$manifest.version = '0.2.1'
$manifest.action.default_title = $manifest.name
$manifest.background = [pscustomobject]@{ scripts = @('background.js') }

function ConvertTo-FirefoxPattern([string]$Pattern) {
    $uri = [System.Uri]$Pattern
    return "{0}://{1}{2}" -f $uri.Scheme, $uri.Host, $uri.PathAndQuery
}

$manifest.host_permissions = @($manifest.host_permissions | ForEach-Object { ConvertTo-FirefoxPattern $_ })
foreach ($script in $manifest.content_scripts) {
    $originalPatterns = @($script.matches)
    $script.matches = @($originalPatterns | ForEach-Object { ConvertTo-FirefoxPattern $_ })
    # Globs retain the target port restriction without invalid Firefox match patterns.
    $script | Add-Member -NotePropertyName include_globs -NotePropertyValue $originalPatterns -Force
}
$manifest | Add-Member -NotePropertyName browser_specific_settings -NotePropertyValue ([pscustomobject]@{
    gecko = [pscustomobject]@{
        id = "sgo-dxn-capture-$Target@dxnventas.local"
        data_collection_permissions = [pscustomobject]@{
            required = @('financialAndPaymentInfo', 'personallyIdentifyingInfo', 'websiteContent')
        }
    }
}) -Force
[System.IO.File]::WriteAllText((Join-Path $unpackedPath 'manifest.json'), ($manifest | ConvertTo-Json -Depth 20), $utf8)
foreach ($name in @('background.js', 'content-dxn.js', 'content-sgo.js')) {
    $inputPath = Join-Path $sourceDirectory $name
    if ($Target -eq 'comas' -and $name -eq 'content-dxn.js') {
        $inputPath = Join-Path $sourceDirectory '..\sgo_dnx_extension\content-dxn.js'
    }
    $content = Get-Content $inputPath -Raw -Encoding UTF8
    if ($name -eq 'background.js') {
        $content = $content.Replace('http://localhost:5173', $targetOrigin).Replace('http://localhost/*', "http://$targetHost/*")
    }
    [System.IO.File]::WriteAllText((Join-Path $unpackedPath $name), $content, $utf8)
}
Copy-Item -LiteralPath (Join-Path $sourceDirectory "docs\firefox-$Target.md") -Destination (Join-Path $unpackedPath 'README.md') -Force
$zipPath = Join-Path $outputPath "SGO-DXN-Capture-Firefox-$Target-0.2.1.zip"
$xpiPath = Join-Path $outputPath "SGO-DXN-Capture-Firefox-$Target-0.2.1.xpi"
$files = @('manifest.json','background.js','content-dxn.js','content-sgo.js','README.md') | ForEach-Object { Join-Path $unpackedPath $_ }
Compress-Archive -LiteralPath $files -DestinationPath $zipPath -Force
Copy-Item -LiteralPath $zipPath -Destination $xpiPath -Force
Get-Item $xpiPath, (Join-Path $unpackedPath 'manifest.json') | Select-Object FullName, Length

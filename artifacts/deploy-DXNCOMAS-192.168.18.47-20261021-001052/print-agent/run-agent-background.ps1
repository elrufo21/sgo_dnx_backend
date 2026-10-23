[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$NodePath
)

$ErrorActionPreference = "Stop"
$agentDirectory = Split-Path -Parent $PSCommandPath
$stdoutPath = Join-Path $agentDirectory "agent.stdout.log"
$stderrPath = Join-Path $agentDirectory "agent.stderr.log"

while ($true) {
    try {
        $health = $null
        try {
            $health = Invoke-RestMethod -Uri "http://127.0.0.1:5174/health" -TimeoutSec 2
        }
        catch {
        }

        if ($health.ok -and $health.service -eq "dnx-print-agent") {
            Start-Sleep -Seconds 5
            continue
        }

        $process = Start-Process `
            -FilePath $NodePath `
            -ArgumentList "src/server.mjs" `
            -WorkingDirectory $agentDirectory `
            -WindowStyle Hidden `
            -PassThru `
            -Wait `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath
        Start-Sleep -Seconds 5
    }
    catch {
        Add-Content -LiteralPath $stderrPath -Value "[$(Get-Date -Format o)] $($_.Exception.Message)"
        Start-Sleep -Seconds 5
    }
}

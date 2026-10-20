param(
    [string]$ScriptDom = 'C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\IDE\Extensions\Application\Microsoft.SqlServer.TransactSql.ScriptDom.dll',
    [string]$Salida = (Join-Path $PSScriptRoot '../../artifacts/analisis-dxncomas-20261019/validacion_sintaxis_sql2008.json')
)
$ErrorActionPreference = 'Stop'
Add-Type -LiteralPath $ScriptDom
$parser = [Microsoft.SqlServer.TransactSql.ScriptDom.TSql100Parser]::new($true)
$package = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../sql/dxncomas-20261019'))
$report = [ordered]@{ parser = 'Microsoft ScriptDom TSql100Parser (SQL Server 2008)'; archivos = @(); errores = @(); motor_sql2008_real = $false }
function CheckSql([string]$Name, [string]$Sql) {
    [System.Collections.Generic.IList[Microsoft.SqlServer.TransactSql.ScriptDom.ParseError]]$errors = $null
    $reader = [IO.StringReader]::new($Sql)
    try { [void]$parser.Parse($reader, [ref]$errors) } finally { $reader.Dispose() }
    foreach ($error in $errors) {
        $report.errores += [ordered]@{ archivo = $Name; linea = $error.Line; columna = $error.Column; mensaje = $error.Message }
    }
    # Las llamadas a funciones nuevas pueden ser sintácticamente válidas como UDF.
    # Se comprueban también los nombres de funciones no disponibles en 2008.
    $withoutComments = [regex]::Replace($Sql, "N?'(?:''|[^'])*'|--[^\r\n]*|/\*[\s\S]*?\*/", [Text.RegularExpressions.MatchEvaluator]{
        param($match)
        if ($match.Value.StartsWith('--') -or $match.Value.StartsWith('/*')) { return '' }
        return $match.Value
    })
    $withoutStrings = [regex]::Replace($withoutComments, "N?'(?:''|[^'])*'", "''")
    foreach ($match in [regex]::Matches($withoutStrings, '(?i)\b(?:CONCAT|IIF|FORMAT|TRY_CAST|TRY_CONVERT|TRY_PARSE|STRING_AGG|STRING_SPLIT|EOMONTH|DATEFROMPARTS|DATETIMEFROMPARTS|ISJSON|JSON_VALUE|JSON_QUERY|OPENJSON)\s*\(')) {
        $report.errores += [ordered]@{ archivo = $Name; mensaje = 'Función posterior a SQL Server 2008: ' + $match.Value }
    }
    if ($withoutComments -match "(?i)HASHBYTES\s*\(\s*'SHA2_") {
        $report.errores += [ordered]@{ archivo = $Name; mensaje = 'SHA2 no está disponible en SQL Server 2008.' }
    }
}
CheckSql 'autocomprobacion' 'CREATE OR ALTER PROCEDURE dbo.NoCompatible AS SELECT CONCAT(1, 2);'
if ($report.errores.Count -eq 0) { throw 'El analizador no rechazó el ejemplo incompatible de control.' }
$report.errores = @()
foreach ($file in Get-ChildItem -LiteralPath $package -Filter '*.sql' | Sort-Object Name) {
    $sql = [IO.File]::ReadAllText($file.FullName)
    # Las directivas SQLCMD son del cliente, no pertenecen a la gramática T-SQL.
    $sql = [regex]::Replace($sql, '(?im)^\s*:(?:ON ERROR|r)\b[^\r\n]*', '-- directiva SQLCMD')
    $before = $report.errores.Count
    CheckSql $file.Name $sql
    $dynamicCount = 0
    foreach ($match in [regex]::Matches($sql, "(?is)\bEXEC(?:UTE)?\s*\(\s*N?'((?:''|[^'])*)'\s*\)")) {
        $dynamicCount++
        CheckSql "$($file.Name):SQL dinámico $dynamicCount" $match.Groups[1].Value.Replace("''", "'")
    }
    $report.archivos += [ordered]@{ archivo = $file.Name; sql_dinamicos_revisados = $dynamicCount; errores = $report.errores.Count - $before }
}
$report.resultado = if ($report.errores.Count -eq 0) { 'OK: sintaxis y funciones revisadas para SQL Server 2008. No equivale a ejecución en motor 2008.' } else { 'ERROR: existen incompatibilidades.' }
[IO.File]::WriteAllText([IO.Path]::GetFullPath($Salida), (ConvertTo-Json -InputObject $report -Depth 8), [Text.UTF8Encoding]::new($false))
if ($report.errores.Count -gt 0) {
    $report.errores | Select-Object -First 20 | ConvertTo-Json -Depth 5 | Write-Output
    throw "El análisis SQL 2008 detectó $($report.errores.Count) errores."
}
Write-Output $report.resultado

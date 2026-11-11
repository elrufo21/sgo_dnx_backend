Add-Type -Path 'C:/Users/User/.nuget/packages/microsoft.sqlserver.transactsql.scriptdom/161.8901.0/lib/net6.0/Microsoft.SqlServer.TransactSql.ScriptDom.dll'
$parser = [Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser]::new($true)
$opts = [Microsoft.SqlServer.TransactSql.ScriptDom.SqlScriptGeneratorOptions]::new()
$opts.KeywordCasing = [Microsoft.SqlServer.TransactSql.ScriptDom.KeywordCasing]::Uppercase
$opts.IndentationSize = 4
$opts.MultilineInsertTargetsList = $true
$opts.MultilineInsertSourcesList = $true
$opts.MultilineSetClauseItems = $true
$generator = [Microsoft.SqlServer.TransactSql.ScriptDom.Sql150ScriptGenerator]::new($opts)
Get-ChildItem 'scripts/sql/kardex-dxncomas0611-20261109/aplicacion' -Filter '*.sql' | ForEach-Object {
  $errors = $null
  $reader = [System.IO.StringReader]::new([System.IO.File]::ReadAllText($_.FullName))
  $fragment = $parser.Parse($reader, [ref]$errors)
  '{0}: {1} errores de análisis' -f $_.Name, $errors.Count
  $errors | Select-Object -First 3 | ForEach-Object { $_.Message }
}


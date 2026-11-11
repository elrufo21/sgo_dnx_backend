. ./tmp/inspeccionar-scriptdom.ps1
$errors=$null; $tree=$parser.Parse([System.IO.StringReader]::new([System.IO.File]::ReadAllText((Resolve-Path 'tmp/kardex-sin-comentarios/uspGuardarListaPreciosPdfWEB.sql'))),[ref]$errors); $formatted=$null; $generator.GenerateScript($tree,[ref]$formatted); $errors=$null; $check=$parser.Parse([System.IO.StringReader]::new($formatted),[ref]$errors)
$left=@($tree.ScriptTokenStream | Where-Object { $_.TokenType.ToString() -notin @('WhiteSpace','EndOfFile','Semicolon') -and $_.Text -inotmatch '^(AS|FROM)$' } | ForEach-Object {$_.Text.ToUpperInvariant()}); $right=@($check.ScriptTokenStream | Where-Object { $_.TokenType.ToString() -notin @('WhiteSpace','EndOfFile','Semicolon') -and $_.Text -inotmatch '^(AS|FROM)$' } | ForEach-Object {$_.Text.ToUpperInvariant()}); Compare-Object $left $right -SyncWindow 5 | Select-Object -First 25 | Format-Table | Out-String; $formatted.Substring(0,[Math]::Min(1600,$formatted.Length))



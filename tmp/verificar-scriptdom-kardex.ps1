. ./tmp/inspeccionar-scriptdom.ps1
$files = Get-ChildItem scripts/sql/kardex-dxncomas0611-20261109/sin-comentarios -Filter '*.sql'
foreach ($file in $files) {
    $errors = $null
    $tree = $parser.Parse([System.IO.StringReader]::new([System.IO.File]::ReadAllText($file.FullName)), [ref]$errors)
    if ($errors.Count) { throw "Error en $($file.Name): $($errors[0].Message)" }
    $comments = @($tree.ScriptTokenStream | Where-Object { $_.TokenType.ToString() -match 'Comment' })
    if ($comments.Count) { throw "Comentarios en $($file.Name)" }
    Write-Output "$($file.Name): sintaxis analizada, sin comentarios"
}

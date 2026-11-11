. ./tmp/inspeccionar-scriptdom.ps1
$target = (Resolve-Path 'scripts/sql/kardex-dxncomas0611-20261109/sin-comentarios').Path
$all = [System.Collections.Generic.List[string]]::new()
foreach ($file in (Get-ChildItem 'tmp/kardex-sin-comentarios' -Filter '*.sql' | Sort-Object Name)) {
    $errors = $null
    $tree = $parser.Parse([System.IO.StringReader]::new([System.IO.File]::ReadAllText($file.FullName)), [ref]$errors)
    if ($errors.Count -ne 0) { throw "Error analizando $($file.Name): $($errors[0].Message)" }
    $formatted = $null
    $generator.GenerateScript($tree, [ref]$formatted)
    $errors = $null
    $check = $parser.Parse([System.IO.StringReader]::new($formatted), [ref]$errors)
    if ($errors.Count -ne 0) { throw "Error en formato $($file.Name): $($errors[0].Message)" }
    $again = $null
    $generator.GenerateScript($check, [ref]$again)
    if ($formatted -cne $again) { throw "Formato inestable en $($file.Name)" }
    [System.IO.File]::WriteAllText((Join-Path $target $file.Name), $formatted.Trim() + "`r`n", [System.Text.UTF8Encoding]::new($false))
    $all.Add($formatted.Trim())
    "Generado y analizado: $($file.Name)"
}
if ($all.Count -ne 6) { throw 'Cantidad inesperada de procedimientos' }
[System.IO.File]::WriteAllText((Join-Path $target 'todos-los-procedimientos.sql'), ($all -join "`r`nGO`r`n`r`n") + "`r`nGO`r`n", [System.Text.UTF8Encoding]::new($false))




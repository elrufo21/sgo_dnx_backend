param(
    [string]$Servidor = 'localhost\SQLEXPRESS01',
    [string]$Salida = (Join-Path $PSScriptRoot '../../artifacts/analisis-dxncomas-20261019/validacion_paquete.json')
)
$ErrorActionPreference = 'Stop'
$package = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../sql/dxncomas-20261019'))
$snapshotFile = Join-Path $PSScriptRoot '../../artifacts/analisis-dxncomas-20261019/DXNCOMAS.json'
$snapshot = Get-Content -LiteralPath $snapshotFile -Raw | ConvertFrom-Json
$clone = 'DXNCOMAS_WEB_VALIDACION_' + [Guid]::NewGuid().ToString('N').Substring(0, 10)
$connection = [System.Data.SqlClient.SqlConnection]::new("Data Source=$Servidor;Initial Catalog=master;Integrated Security=True;Application Name=Validacion paquete COMAS en clon sin datos")
$connection.Open()
$created = $false
$report = [ordered]@{ base_origen = 'DXNCOMAS'; clon = $clone; scripts = @(); errores_compilacion = @(); resultado = 'NO COMPLETADO' }
function ExecuteSql([string]$Sql) {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = $Sql
    $cmd.CommandTimeout = 180
    try { [void]$cmd.ExecuteNonQuery() } finally { $cmd.Dispose() }
}
function ScalarSql([string]$Sql) {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = $Sql
    $cmd.CommandTimeout = 180
    try { return $cmd.ExecuteScalar() } finally { $cmd.Dispose() }
}
function QuoteName([string]$Value) { return '[' + $Value.Replace(']', ']]') + ']' }
function CreateEmptySchema {
    foreach ($table in $snapshot.tables) {
        $columns = @($snapshot.columns | Where-Object { $_.schema_name -eq $table.schema_name -and $_.table_name -eq $table.name } | Sort-Object column_id)
        $definitions = foreach ($column in $columns) {
            if ($column.is_computed) { throw 'Agregar soporte explícito para columnas calculadas antes de validar esta captura.' }
            $type = QuoteName $column.type_name
            if ($column.type_name -in @('varchar', 'nvarchar', 'char', 'nchar', 'varbinary', 'binary')) {
                $length = if ($column.max_length -eq -1) { 'max' } elseif ($column.type_name -in @('nvarchar', 'nchar')) { [string]($column.max_length / 2) } else { [string]$column.max_length }
                $type += "($length)"
            } elseif ($column.type_name -in @('decimal', 'numeric')) {
                $type += "($($column.precision),$($column.scale))"
            } elseif ($column.type_name -in @('time', 'datetime2', 'datetimeoffset')) {
                $type += "($($column.scale))"
            }
            $definition = (QuoteName $column.name) + ' ' + $type
            if ($column.collation_name) { $definition += ' COLLATE ' + $column.collation_name }
            if ($column.is_identity) { $definition += " IDENTITY($($column.identity_seed),$($column.identity_increment))" }
            $definition += $(if ($column.is_nullable) { ' NULL' } else { ' NOT NULL' })
            if ($column.default_definition) { $definition += ' DEFAULT ' + $column.default_definition }
            $definition
        }
        ExecuteSql ('CREATE TABLE ' + (QuoteName $table.schema_name) + '.' + (QuoteName $table.name) + ' (' + ($definitions -join ', ') + ');')
    }
    foreach ($group in ($snapshot.indexes | Group-Object schema_name, table_name, name)) {
        $first = $group.Group[0]
        $table = (QuoteName $first.schema_name) + '.' + (QuoteName $first.table_name)
        $keys = @($group.Group | Where-Object { $_.key_ordinal -gt 0 } | Sort-Object key_ordinal | ForEach-Object { (QuoteName $_.column_name) + $(if ($_.is_descending_key) { ' DESC' } else { ' ASC' }) }) -join ', '
        $kind = $first.type_desc.Replace('_', ' ')
        if ($first.is_primary_key -or $first.is_unique_constraint) {
            $constraint = if ($first.is_primary_key) { 'PRIMARY KEY' } else { 'UNIQUE' }
            ExecuteSql "ALTER TABLE $table ADD CONSTRAINT $(QuoteName $first.name) $constraint $kind ($keys);"
        } else {
            $unique = if ($first.is_unique) { 'UNIQUE ' } else { '' }
            $sql = "CREATE $unique$kind INDEX $(QuoteName $first.name) ON $table ($keys)"
            $include = @($group.Group | Where-Object is_included_column | ForEach-Object { QuoteName $_.column_name })
            if ($include.Count -gt 0) { $sql += ' INCLUDE (' + ($include -join ', ') + ')' }
            if ($first.filter_definition) { $sql += ' WHERE ' + $first.filter_definition }
            ExecuteSql ($sql + ';')
        }
    }
    foreach ($group in ($snapshot.foreign_keys | Group-Object schema_name, table_name, name)) {
        $first = $group.Group[0]
        $ordered = $group.Group | Sort-Object constraint_column_id
        $columns = @($ordered | ForEach-Object { QuoteName $_.column_name }) -join ', '
        $referenced = @($ordered | ForEach-Object { QuoteName $_.referenced_column }) -join ', '
        ExecuteSql "ALTER TABLE $(QuoteName $first.schema_name).$(QuoteName $first.table_name) ADD CONSTRAINT $(QuoteName $first.name) FOREIGN KEY ($columns) REFERENCES $(QuoteName $first.referenced_schema).$(QuoteName $first.referenced_table) ($referenced);"
    }
    $modules = @($snapshot.modules | Where-Object { $_.type.Trim() -ne 'P' }) + @($snapshot.modules | Where-Object { $_.type.Trim() -eq 'P' })
    foreach ($module in $modules) {
        ExecuteSql ('SET ANSI_NULLS ' + $(if ($module.uses_ansi_nulls) { 'ON' } else { 'OFF' }) + '; SET QUOTED_IDENTIFIER ' + $(if ($module.uses_quoted_identifier) { 'ON' } else { 'OFF' }) + ';')
        ExecuteSql $module.definition
    }
}
try {
    if ($clone -notmatch '^DXNCOMAS_WEB_VALIDACION_[a-f0-9]{10}$') { throw 'Nombre de clon no permitido.' }
    if ((ScalarSql "SELECT COUNT(*) FROM sys.databases WHERE name = N'$clone'") -ne 0) { throw 'El clon ya existe.' }
    $collation = $snapshot.database[0].collation_name
    if ($collation -notmatch '^[A-Za-z0-9_]+$') { throw 'Collation no permitida.' }
    ExecuteSql "CREATE DATABASE [$clone] COLLATE $collation;"
    $created = $true
    ExecuteSql "ALTER DATABASE [$clone] SET COMPATIBILITY_LEVEL = 100; USE [$clone];"
    CreateEmptySchema
    ExecuteSql "INSERT INTO dbo.Compania (CompaniaComercial, DiasMaxDep, RenovacionOSE, CompaniaUserSecun, ComapaniaPWD) VALUES ('VALIDACION_SINTETICA', 3, '20300101', 'USUARIO_SINTETICO', 'CLAVE_SINTETICA');"

    $files = @('00_compatibilidad_inserts_dxncomas.sql', '01_tablas_dxncomas.sql', '02_columnas_dxncomas.sql', '03_procedimientos_dxncomas.sql', '04_configuracion_inicial_dxncomas.sql', '06_indices_web_opcional.sql')
    $procedures = @()
    for ($pass = 1; $pass -le 2; $pass++) {
        ExecuteSql 'SET XACT_ABORT ON; BEGIN TRANSACTION;'
        foreach ($file in $files) {
            $sql = [IO.File]::ReadAllText((Join-Path $package $file))
            $uses = [regex]::Matches($sql, '(?im)^\s*USE\s+\[([^\]]+)\]\s*;?\s*$')
            if ($uses.Count -ne 1 -or $uses[0].Groups[1].Value -ne 'DXNCOMAS') { throw "USE inesperado en $file" }
            $sql = [regex]::Replace($sql, '(?im)^\s*USE\s+\[DXNCOMAS\]\s*;?\s*$', "USE [$clone];")
            if ($sql -match '(?i)\[DXNCOMAS\]\.|\bDXNCOMAS\.dbo\.') { throw "Referencia al origen fuera del USE en $file" }
            foreach ($batch in [regex]::Split($sql, '(?im)^\s*GO\s*$')) {
                if (-not [string]::IsNullOrWhiteSpace($batch)) { ExecuteSql $batch }
            }
            $report.scripts += "$pass`: $file OK"
            if ($pass -eq 1 -and $file -eq '03_procedimientos_dxncomas.sql') {
                $procedures = @([regex]::Matches($sql, '(?im)^\s*ALTER\s+PROC(?:EDURE)?\s+(?:\[?dbo\]?\.)?\[?(\w+)') | ForEach-Object { $_.Groups[1].Value })
            }
        }
        ExecuteSql "IF @@TRANCOUNT <> 1 BEGIN RAISERROR('Transacción inesperada en la validación del instalador.', 16, 1); RETURN; END; COMMIT TRANSACTION;"
        if ((ScalarSql 'SELECT COUNT(*) FROM dbo.Indicador') -ne 24) { throw 'La inicialización no dejó exactamente 24 indicadores para la compañía sintética.' }
        if ((ScalarSql "SELECT ValorNum FROM dbo.Indicador WHERE Descripcion = 'ASISTENCIA'") -ne 1) { throw 'La asistencia no quedó activa.' }
        if ((ScalarSql "SELECT ValorNum FROM dbo.Indicador WHERE Descripcion = 'TIPO_PROCESO_CPE'") -ne 3) { throw 'El entorno inicial debe ser beta.' }
        if ((ScalarSql "SELECT COUNT(*) FROM dbo.Indicador WHERE Descripcion = 'CPE_CERTIFICADO_PFX' AND ValorTexto1 IS NULL") -ne 1) { throw 'No se debe fabricar un certificado.' }
        if ((ScalarSql "SELECT COUNT(*) FROM dbo.Indicador WHERE Descripcion = 'RENOVACION_OSE' AND ValorTexto1 = '2030-01-01'") -ne 1) { throw 'No se conservó la renovación de COMAS.' }
        if ((ScalarSql "SELECT COUNT(*) FROM dbo.Indicador WHERE Descripcion = 'CORREOS_ADMIN' AND ValorTexto1 IS NULL") -ne 1 -and $pass -eq 1) { throw 'No se deben inventar destinatarios.' }
        if ($pass -eq 1) {
            ExecuteSql "UPDATE dbo.Indicador SET ValorTexto1 = 'conservar@example.invalid' WHERE Descripcion = 'CORREOS_ADMIN';"
        } elseif ((ScalarSql "SELECT COUNT(*) FROM dbo.Indicador WHERE Descripcion = 'CORREOS_ADMIN' AND ValorTexto1 = 'conservar@example.invalid'") -ne 1) {
            throw 'La segunda ejecución sobrescribió un valor configurado.'
        }
    }
    if ($procedures.Count -ne 44) { throw "Se esperaban 44 procedimientos y se encontraron $($procedures.Count)." }
    foreach ($name in $procedures) {
        try { ExecuteSql "EXEC sys.sp_refreshsqlmodule N'dbo.$name';" }
        catch { $report.errores_compilacion += [ordered]@{ procedimiento = $name; error = $_.Exception.Message } }
    }
    $report.procedimientos_verificados = $procedures.Count
    if ($report.errores_compilacion.Count -gt 0) { throw 'Existen errores al enlazar los procedimientos; revisar validacion_paquete.json.' }
    $diagnostic = [IO.File]::ReadAllText((Join-Path $package '05_diagnostico_dxncomas.sql'))
    $diagnostic = [regex]::Replace($diagnostic, '(?im)^\s*USE\s+\[DXNCOMAS\]\s*;?\s*$', "USE [$clone];")
    foreach ($batch in [regex]::Split($diagnostic, '(?im)^\s*GO\s*$')) {
        if (-not [string]::IsNullOrWhiteSpace($batch)) { ExecuteSql $batch }
    }
    $required = Import-Csv (Join-Path $PSScriptRoot '../../artifacts/analisis-dxncomas-20261019/web_objetos_confirmados.csv')
    $values = @($required | ForEach-Object { "(N'$($_.objeto)')" }) -join ', '
    $remaining = ScalarSql "SELECT COUNT(*) FROM (VALUES $values) v(nombre) WHERE OBJECT_ID(v.nombre) IS NULL;"
    if ($remaining -ne 9) { throw "Se esperaban solo los nueve contratos excluidos; faltan $remaining objetos." }
    $report.contratos_excluidos_pendientes = $remaining
    $report.resultado = 'OK: dos ejecuciones, configuración preservada y 44 procedimientos enlazados en clon sin datos.'
} catch {
    $report.resultado = $_.Exception.Message
    throw
} finally {
    try {
        if ($created) {
            ExecuteSql "IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; USE master; ALTER DATABASE [$clone] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$clone];"
            $report.clon_eliminado = $true
        }
    } finally {
        $connection.Dispose()
        $outputFile = [IO.Path]::GetFullPath($Salida)
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outputFile)) | Out-Null
        [IO.File]::WriteAllText($outputFile, (ConvertTo-Json -InputObject $report -Depth 8), [Text.UTF8Encoding]::new($false))
    }
}
Write-Output $report.resultado

param(
    [string]$Servidor = 'localhost\SQLEXPRESS01',
    [string]$Referencia = 'DXN_ICA15102026',
    [string]$Destino = 'DXNCOMAS',
    [string]$Salida = (Join-Path $PSScriptRoot '../../artifacts/analisis-dxncomas-20261018')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $Salida -Force | Out-Null
function Consultar($Conexion, $Sql) {
    $cmd = $Conexion.CreateCommand()
    $cmd.CommandText = $Sql
    $cmd.CommandTimeout = 60
    $reader = $cmd.ExecuteReader()
    $rows = [System.Collections.Generic.List[object]]::new()
    try {
        while ($reader.Read()) {
            $row = [ordered]@{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $row[$reader.GetName($i)] = if ($reader.IsDBNull($i)) { $null } else { $reader.GetValue($i) }
            }
            $rows.Add([pscustomobject]$row)
        }
    } finally { $reader.Dispose(); $cmd.Dispose() }
    return ,$rows.ToArray()
}
$consultas = [ordered]@{
    database = "SELECT DB_NAME() name, compatibility_level, collation_name, CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) server_version FROM sys.databases WHERE name=DB_NAME()"
    tables = "SELECT s.name schema_name,t.name name,t.object_id,SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) approximate_rows FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id LEFT JOIN sys.partitions p ON p.object_id=t.object_id WHERE t.is_ms_shipped=0 GROUP BY s.name,t.name,t.object_id ORDER BY s.name,t.name"
    columns = "SELECT s.name schema_name,t.name table_name,c.name name,c.column_id,ty.name type_name,c.max_length,c.precision,c.scale,c.is_nullable,c.is_identity,c.is_computed,c.collation_name,dc.definition default_definition,cc.definition computed_definition,CAST(ic.seed_value AS varchar(100)) identity_seed,CAST(ic.increment_value AS varchar(100)) identity_increment FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.columns c ON c.object_id=t.object_id JOIN sys.types ty ON ty.user_type_id=c.user_type_id LEFT JOIN sys.default_constraints dc ON dc.object_id=c.default_object_id LEFT JOIN sys.computed_columns cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id LEFT JOIN sys.identity_columns ic ON ic.object_id=c.object_id AND ic.column_id=c.column_id WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name,c.column_id"
    modules = "SELECT s.name schema_name,o.name name,o.object_id,o.type,o.type_desc,m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.is_ms_shipped=0 AND o.type IN ('P','V','FN','IF','TF','TR') ORDER BY s.name,o.name"
    parameters = "SELECT s.name schema_name,o.name object_name,p.name name,p.parameter_id,ty.name type_name,p.max_length,p.precision,p.scale,p.is_output FROM sys.parameters p JOIN sys.objects o ON o.object_id=p.object_id JOIN sys.schemas s ON s.schema_id=o.schema_id JOIN sys.types ty ON ty.user_type_id=p.user_type_id WHERE o.is_ms_shipped=0 ORDER BY s.name,o.name,p.parameter_id"
    dependencies = "SELECT OBJECT_SCHEMA_NAME(d.referencing_id) schema_name,OBJECT_NAME(d.referencing_id) object_name,d.referenced_server_name,d.referenced_database_name,d.referenced_schema_name,d.referenced_entity_name,d.referenced_id,d.referenced_minor_id,d.is_ambiguous FROM sys.sql_expression_dependencies d WHERE OBJECTPROPERTY(d.referencing_id,'IsMSShipped')=0"
    indexes = "SELECT s.name schema_name,t.name table_name,i.name name,i.type_desc,i.is_unique,i.is_primary_key,i.is_unique_constraint,i.is_disabled,i.has_filter,i.filter_definition,c.name column_name,ic.key_ordinal,ic.is_descending_key,ic.is_included_column FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.indexes i ON i.object_id=t.object_id AND i.index_id>0 JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name,i.name,ic.index_column_id"
    foreign_keys = "SELECT OBJECT_SCHEMA_NAME(f.parent_object_id) schema_name,OBJECT_NAME(f.parent_object_id) table_name,f.name,c.name column_name,OBJECT_SCHEMA_NAME(f.referenced_object_id) referenced_schema,OBJECT_NAME(f.referenced_object_id) referenced_table,rc.name referenced_column,fc.constraint_column_id,f.delete_referential_action_desc,f.update_referential_action_desc,f.is_disabled,f.is_not_trusted FROM sys.foreign_keys f JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id JOIN sys.columns c ON c.object_id=fc.parent_object_id AND c.column_id=fc.parent_column_id JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id AND rc.column_id=fc.referenced_column_id ORDER BY schema_name,table_name,f.name,fc.constraint_column_id"
    checks = "SELECT OBJECT_SCHEMA_NAME(parent_object_id) schema_name,OBJECT_NAME(parent_object_id) table_name,name,definition,is_disabled,is_not_trusted FROM sys.check_constraints ORDER BY schema_name,table_name,name"
    synonyms = "SELECT SCHEMA_NAME(schema_id) schema_name,name,base_object_name FROM sys.synonyms"
    user_types = "SELECT SCHEMA_NAME(schema_id) schema_name,name,is_table_type,max_length,precision,scale,is_nullable FROM sys.types WHERE is_user_defined=1"
    sequences = "SELECT SCHEMA_NAME(schema_id) schema_name,name,CAST(start_value AS varchar(100)) start_value,CAST(increment AS varchar(100)) increment_value FROM sys.sequences"
    readiness = @"
SELECT 'Companias' control, COUNT_BIG(*) cantidad FROM dbo.Compania
UNION ALL SELECT 'Usuarios_sin_personal', COUNT_BIG(*) FROM dbo.Usuarios u LEFT JOIN dbo.Personal p ON p.PersonalId=u.PersonalId WHERE p.PersonalId IS NULL
UNION ALL SELECT 'Personal_sin_compania', COUNT_BIG(*) FROM dbo.Personal p LEFT JOIN dbo.Compania c ON c.CompaniaId=p.CompaniaId WHERE c.CompaniaId IS NULL
UNION ALL SELECT 'RUC_no_11_digitos', COUNT_BIG(*) FROM dbo.Compania WHERE LEN(LTRIM(RTRIM(ISNULL(CompaniaRUC,''))))<>11 OR CompaniaRUC LIKE '%[^0-9]%'
UNION ALL SELECT 'Maquinas_sin_serie_factura', COUNT_BIG(*) FROM dbo.MAQUINAS WHERE NULLIF(LTRIM(RTRIM(SerieFactura)),'') IS NULL
UNION ALL SELECT 'Maquinas_nombre_duplicado', COUNT_BIG(*) FROM (SELECT UPPER(LTRIM(RTRIM(Maquina))) n FROM dbo.MAQUINAS GROUP BY UPPER(LTRIM(RTRIM(Maquina))) HAVING COUNT(*)>1) d
UNION ALL SELECT 'DetalleGuiaLiquida_fuera_numeric20', COUNT_BIG(*) FROM dbo.DetalleGuiaLiquida WHERE Idproducto>99999999999999999999 OR Idproducto< -99999999999999999999
UNION ALL SELECT 'TipoCodigo_mayor10', COUNT_BIG(*) FROM dbo.TipoComprobante WHERE DATALENGTH(RTRIM(TipoCodigo))>10
UNION ALL SELECT 'Huerfanos_DetalleCompra_Producto', COUNT_BIG(*) FROM dbo.DetalleCompra d LEFT JOIN dbo.Producto p ON p.IdProducto=d.IdProducto WHERE d.IdProducto IS NOT NULL AND p.IdProducto IS NULL
UNION ALL SELECT 'Huerfanos_DetalleGuiaInterna_Producto', COUNT_BIG(*) FROM dbo.DetalleGuiaInterna d LEFT JOIN dbo.Producto p ON p.IdProducto=d.IdProducto WHERE d.IdProducto IS NOT NULL AND p.IdProducto IS NULL
UNION ALL SELECT 'Huerfanos_DetalleGuiaLiquida_Producto', COUNT_BIG(*) FROM dbo.DetalleGuiaLiquida d LEFT JOIN dbo.Producto p ON p.IdProducto=d.Idproducto WHERE d.Idproducto IS NOT NULL AND p.IdProducto IS NULL
UNION ALL SELECT 'Huerfanos_DetallesPVS_NotaPedido', COUNT_BIG(*) FROM dbo.DetallesPVS d LEFT JOIN dbo.NotaPedido n ON n.NotaId=d.NotaId WHERE d.NotaId IS NOT NULL AND n.NotaId IS NULL
UNION ALL SELECT 'Producto_INV_S', COUNT_BIG(*) FROM dbo.Producto WHERE ProductoINV='S'
"@
}
foreach ($bd in @($Referencia, $Destino)) {
    $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $builder['Data Source'] = $Servidor
    $builder['Initial Catalog'] = $bd
    $builder['Integrated Security'] = $true
    $builder['Application Name'] = 'Diagnostico DXNCOMAS solo lectura'
    $conexion = [System.Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
    $conexion.Open()
    try {
        $resultado = [ordered]@{ captured_at = [DateTimeOffset]::Now.ToString('o') }
        foreach ($entry in $consultas.GetEnumerator()) { $resultado[$entry.Key] = Consultar $conexion $entry.Value }
        $resultado['indicator_keys'] = if ($resultado.tables.name -contains 'Indicador') {
            Consultar $conexion "SELECT CompaniaId,Area,TipoIndicador,Descripcion,COUNT(*) records FROM dbo.Indicador GROUP BY CompaniaId,Area,TipoIndicador,Descripcion ORDER BY CompaniaId,Area,TipoIndicador,Descripcion"
        } else { @() }
        $json = ConvertTo-Json -InputObject $resultado -Depth 12
        [IO.File]::WriteAllText((Join-Path ([IO.Path]::GetFullPath($Salida)) "$bd.json"), $json, [Text.UTF8Encoding]::new($false))
        Write-Output "$bd : $($resultado.tables.Count) tablas, $($resultado.modules.Count) modulos exportados."
    } finally { $conexion.Dispose() }
}

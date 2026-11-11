$source=Get-Content src/Api/Controllers/NotaController.cs -Raw
$start=$source.IndexOf('public async Task<IActionResult> ObtenerFacturaServicioEmitida(')
$end=$source.IndexOf('[HttpPatch("facturas-servicio/', $start)
$part=$source.Substring($start,$end-$start)
$template=[regex]::Match($part,'(?s)var sqlDetalle = \$"""(.*?)"""').Groups[1].Value
if (-not $template) { throw 'No se encontró la consulta de detalle' }
$configs=@(@{ Name='DNX'; Path='src/Api/appsettings.json'; Id=371747 },@{ Name='SGO'; Path='C:/Users/User/Desktop/desarrollo-sgo/BackEnd/src/Api/appsettings.json'; Id=0 })
foreach($target in $configs) {
  $cfg=Get-Content $target.Path -Raw | ConvertFrom-Json
  $connection=[System.Data.SqlClient.SqlConnection]::new($cfg.ConnectionStrings.DefaultConnection)
  try {
    $connection.Open()
    $cmd=$connection.CreateCommand(); $cmd.CommandText="SELECT COL_LENGTH('dbo.DetalleDocumento', 'DetalleDescripcion')"; $exists=$cmd.ExecuteScalar() -ne [DBNull]::Value
    if ($target.Id -eq 0) {
      $cmd=$connection.CreateCommand(); $cmd.CommandText="SELECT TOP 1 DocuId FROM dbo.DetalleDocumento WHERE NULLIF(LTRIM(RTRIM(DetalleDescripcion)), '') IS NOT NULL ORDER BY DetalleId DESC"; $id=$cmd.ExecuteScalar()
      if ($null -eq $id -or $id -eq [DBNull]::Value) { throw 'SGO no tiene detalles de muestra' }
    } else { $id=$target.Id }
    $expr=if($exists) { "COALESCE(NULLIF(LTRIM(RTRIM(dd.DetalleDescripcion)), ''), p.ProductoNombre, '')" } else { "COALESCE(p.ProductoNombre, '')" }
    $cmd=$connection.CreateCommand(); $cmd.CommandText=$template.Replace('{descripcionDetalle}', $expr); [void]$cmd.Parameters.AddWithValue('@DocuId',$id)
    $reader=$cmd.ExecuteReader(); $table=[System.Data.DataTable]::new(); $table.Load($reader)
    if ($table.Rows.Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$table.Rows[0]['DetalleDescripcion'])) { throw "Detalle sin descripción en $($target.Name)" }
    Write-Output "$($target.Name): consulta correcta; columna opcional=$exists; detalles=$($table.Rows.Count); descripción presente."
  } finally { $connection.Dispose() }
}

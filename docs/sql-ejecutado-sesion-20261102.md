# SQL ejecutado durante la sesión del 2 de noviembre de 2026

Destino de las ejecuciones directas: `DESKTOP-B6B71UA\SQLEXPRESS01`, base `DXNCOMAS2610`. Este registro agrupa las instrucciones distintas ejecutadas explícitamente durante la conversación; algunas se ejecutaron más de una vez. No pretende registrar todas las consultas internas generadas por el uso normal de la aplicación. Las consultas de verificación fueron de solo lectura.

## Scripts que modificaron objetos

Se ejecutaron los siguientes archivos completos, con autorización puntual. Cada uno creó el procedimiento indicado solo si aún no existía. Aunque el código de los procedimientos contiene `INSERT`, `UPDATE` o `DELETE`, durante su instalación no se ejecutaron esos procedimientos ni se modificaron filas.

1. [`20261101_instalar_usp_insertar_categoria_web.sql`](../scripts/sql/20261101_instalar_usp_insertar_categoria_web.sql): creó `dbo.uspInsertarCategoriaWeb`. El comentario histórico del propio archivo que dice «No se ha ejecutado este archivo» corresponde a antes de su ejecución en esta sesión.
2. [`20261102_instalar_usp_eliminar_categoria.sql`](../scripts/sql/20261102_instalar_usp_eliminar_categoria.sql): creó `dbo.uspEliminarCategoria`.
3. [`20261102_instalar_usp_eliminar_proveedor.sql`](../scripts/sql/20261102_instalar_usp_eliminar_proveedor.sql): creó `dbo.uspEliminarProveedor`.

No se modificaron otras bases durante estas instalaciones.

## Validaciones de categorías y proveedor

```sql
SET NOCOUNT ON;
SELECT @@SERVERNAME AS Servidor, DB_NAME() AS BaseDatos,
       OBJECT_ID(N'dbo.uspInsertarCategoriaWeb', N'P') AS ProcedimientoId,
       OBJECT_ID(N'dbo.Sublinea', N'U') AS TablaId;
SELECT c.name, t.name AS tipo, c.max_length, c.is_nullable, c.is_identity,
       OBJECT_DEFINITION(c.default_object_id) AS valor_predeterminado
FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
WHERE c.object_id=OBJECT_ID(N'dbo.Sublinea') ORDER BY c.column_id;
```

```sql
SET NOCOUNT ON;
SELECT DB_NAME() AS BaseDatos, SCHEMA_NAME(schema_id) AS Esquema,
       name AS Procedimiento, create_date AS Creado
FROM sys.procedures WHERE object_id=OBJECT_ID(N'dbo.uspInsertarCategoriaWeb', N'P');
SELECT name, TYPE_NAME(user_type_id) AS Tipo, max_length
FROM sys.parameters WHERE object_id=OBJECT_ID(N'dbo.uspInsertarCategoriaWeb', N'P');
```

```sql
SET NOCOUNT ON;
SELECT DB_NAME() AS BaseDatos, OBJECT_ID(N'dbo.uspEliminarCategoria',N'P') AS ProcedimientoId,
       OBJECT_ID(N'dbo.Sublinea',N'U') AS TablaId;
SELECT fk.name, OBJECT_SCHEMA_NAME(fk.parent_object_id) AS Esquema,
       OBJECT_NAME(fk.parent_object_id) AS Tabla,
       COL_NAME(fkc.parent_object_id,fkc.parent_column_id) AS Columna,
       fk.delete_referential_action_desc
FROM sys.foreign_keys fk JOIN sys.foreign_key_columns fkc ON fk.object_id=fkc.constraint_object_id
WHERE fk.referenced_object_id=OBJECT_ID(N'dbo.Sublinea');
```

```sql
SET NOCOUNT ON;
SELECT DB_NAME() AS BaseDatos, SCHEMA_NAME(schema_id) AS Esquema, name AS Procedimiento
FROM sys.procedures WHERE object_id=OBJECT_ID(N'dbo.uspEliminarCategoria', N'P');
SELECT name, TYPE_NAME(user_type_id) AS Tipo
FROM sys.parameters WHERE object_id=OBJECT_ID(N'dbo.uspEliminarCategoria', N'P');
```

```sql
SET NOCOUNT ON;
SELECT DB_NAME() AS BaseDatos, OBJECT_ID(N'dbo.uspEliminarProveedor', N'P') AS ProcedimientoId,
       OBJECT_ID(N'dbo.Proveedor',N'U') AS TablaId,
       COL_LENGTH(N'dbo.Proveedor', N'ProveedorId') AS ProveedorIdBytes;
SELECT fk.name, OBJECT_NAME(fk.parent_object_id) AS Tabla,
       COL_NAME(fkc.parent_object_id,fkc.parent_column_id) AS Columna,
       fk.delete_referential_action_desc AS Accion
FROM sys.foreign_keys fk JOIN sys.foreign_key_columns fkc ON fk.object_id=fkc.constraint_object_id
WHERE fk.referenced_object_id=OBJECT_ID(N'dbo.Proveedor');
```

```sql
SET NOCOUNT ON;
SELECT DB_NAME() AS BaseDatos, SCHEMA_NAME(schema_id) AS Esquema, name AS Procedimiento
FROM sys.procedures WHERE object_id=OBJECT_ID(N'dbo.uspEliminarProveedor',N'P');
SELECT name, TYPE_NAME(user_type_id) AS Tipo
FROM sys.parameters WHERE object_id=OBJECT_ID(N'dbo.uspEliminarProveedor',N'P');
```

## Computadoras y sublínea de productos

```sql
SET NOCOUNT ON;
SELECT 'Nombre' AS Campo, UPPER(LTRIM(RTRIM(Maquina))) AS Valor, COUNT(*) AS Cantidad
FROM dbo.MAQUINAS WHERE NULLIF(LTRIM(RTRIM(Maquina)),'') IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(Maquina))) HAVING COUNT(*)>1
UNION ALL
SELECT 'SerieFactura', UPPER(LTRIM(RTRIM(SerieFactura))), COUNT(*)
FROM dbo.MAQUINAS WHERE NULLIF(LTRIM(RTRIM(SerieFactura)),'') IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(SerieFactura))) HAVING COUNT(*)>1;
SELECT c.name, t.name AS Tipo, c.max_length, c.is_nullable, c.collation_name
FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
WHERE c.object_id=OBJECT_ID(N'dbo.MAQUINAS') AND c.name IN ('Maquina','SerieFactura');
```

```sql
SET NOCOUNT ON;
SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.MAQUINAS WHERE UPPER(LTRIM(RTRIM(SerieFactura))) = UPPER('fa01'))
  THEN 'PASS: serie repetida detectada' ELSE 'FAIL' END AS Verificacion
UNION ALL
SELECT CASE WHEN NOT EXISTS (
  SELECT 1 FROM dbo.MAQUINAS
  WHERE IdMaquina <> (SELECT TOP 1 IdMaquina FROM dbo.MAQUINAS ORDER BY IdMaquina)
    AND UPPER(LTRIM(RTRIM(Maquina))) = (SELECT TOP 1 UPPER(LTRIM(RTRIM(Maquina))) FROM dbo.MAQUINAS ORDER BY IdMaquina)
) THEN 'PASS: excluye la maquina editada' ELSE 'FAIL: nombre duplicado existente' END;
```

```sql
SET NOCOUNT ON;
SELECT IdSubLinea, NombreSublinea FROM dbo.Sublinea
WHERE NombreSublinea COLLATE Latin1_General_CI_AI = 'SUSTITUTO DE CAFE';
```

## Resumen PVS y clientes

Se probó el [SQL de referencia del resumen PVS](../scripts/sql/20261102_consulta_resumen_pvs.sql), cambiando en memoria `@ClienteId` de `1` a `0`, para obtener una consulta vacía. Después, una solicitud autenticada al reporte ejecutó la misma consulta parametrizada para cliente `31676`, del `2026-10-01` al `2026-11-30`. No se modificaron notas ni clientes.

```sql
SET NOCOUNT ON;
SELECT OBJECT_NAME(c.object_id) AS Tabla,c.name,TYPE_NAME(c.user_type_id) AS Tipo
FROM sys.columns c
WHERE (c.object_id=OBJECT_ID('dbo.NotaPedido') AND c.name IN ('NotaId','NotaFechaPago','NotaTransaccion','ClienteId','NotaEstado','NotaPagar'))
   OR (c.object_id=OBJECT_ID('dbo.DetallePedido') AND c.name IN ('NotaId','DetallePV','DetalleSV'))
   OR (c.object_id=OBJECT_ID('dbo.Cliente') AND c.name IN ('ClienteId','ClienteCodigo','ClienteRazon'))
ORDER BY Tabla,c.name;
```

```sql
SET NOCOUNT ON;
SELECT OBJECT_NAME(c.object_id),c.name,TYPE_NAME(c.user_type_id)
FROM sys.columns c WHERE c.object_id=OBJECT_ID('dbo.DetallePedido')
AND c.name IN ('NotaId','DetallePV','DetalleSV');
SELECT COUNT(*) AS TotalClientes FROM dbo.Cliente;
SELECT CASE WHEN OBJECT_ID(N'dbo.uspResumenPVS', N'P') IS NULL
  THEN 'Procedimiento heredado no instalado' ELSE 'Procedimiento heredado instalado' END;
SELECT OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspResumenPVS'));
```

```sql
SET NOCOUNT ON;
SELECT 'Cliente existe', COUNT(*) FROM dbo.Cliente WHERE ClienteId=31676;
SELECT 'Notas pagadas en rango',COUNT(*) FROM dbo.NotaPedido
WHERE ClienteId=31676 AND NotaEstado='CANCELADO' AND NotaFechaPago >= '20261001' AND NotaFechaPago <= '20261130';
SELECT 'Notas con detalle',COUNT(DISTINCT n.NotaId)
FROM dbo.NotaPedido n INNER JOIN dbo.DetallePedido d ON d.NotaId=n.NotaId
WHERE n.ClienteId=31676 AND n.NotaEstado='CANCELADO' AND n.NotaFechaPago >= '20261001' AND n.NotaFechaPago <= '20261130';
```

```sql
SET NOCOUNT ON;
SELECT ISNULL(NotaEstado,'(null)') AS Estado, COUNT(*) AS Cantidad,
       CONVERT(varchar(10),MIN(NotaFechaPago),120) AS PrimeraFechaPago,
       CONVERT(varchar(10),MAX(NotaFechaPago),120) AS UltimaFechaPago
FROM dbo.NotaPedido WHERE ClienteId=31676 GROUP BY NotaEstado;
SELECT 'Notas por fecha registro en rango',COUNT(*) FROM dbo.NotaPedido
WHERE ClienteId=31676 AND NotaFecha >= '20261001' AND NotaFecha < '20261201';
```

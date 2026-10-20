-- Diagnostico DXNCOMAS. Generado desde el codigo local; NO instala migraciones.
-- Servidor de la captura: localhost\SQLEXPRESS01. Solo consultas SELECT.
-- Los conteos normalizados y el analisis de alcance estan en el informe Markdown.
SELECT name, compatibility_level, collation_name FROM sys.databases
WHERE name IN (N'DXN_ICA15102026',N'DXNCOMAS');
GO
;WITH R AS (
 SELECT s.name esquema,t.name tabla FROM [DXN_ICA15102026].sys.tables t
 JOIN [DXN_ICA15102026].sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0
), D AS (
 SELECT s.name esquema,t.name tabla FROM [DXNCOMAS].sys.tables t
 JOIN [DXNCOMAS].sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0
)
SELECT COALESCE(R.esquema,D.esquema) esquema,COALESCE(R.tabla,D.tabla) tabla,
 CASE WHEN R.tabla IS NULL THEN 'Solo destino: conservar' ELSE 'Falta en DXNCOMAS' END estado
FROM R FULL JOIN D ON R.esquema=D.esquema AND R.tabla=D.tabla
WHERE R.tabla IS NULL OR D.tabla IS NULL;
GO
;WITH Requeridos(nombre) AS (SELECT nombre FROM (VALUES
    (N'dbo.anulardocumento'),
    (N'dbo.anulardocumentoweb'),
    (N'dbo.editarcompania'),
    (N'dbo.editarproductoweb'),
    (N'dbo.eliminarcompra'),
    (N'dbo.eliminarnotapedido'),
    (N'dbo.ingresarproductoweb'),
    (N'dbo.lddocumentos'),
    (N'dbo.lddocumentosweb'),
    (N'dbo.listanotapedido'),
    (N'dbo.listarcajafechaweb'),
    (N'dbo.listarcajaweb'),
    (N'dbo.listardetacajaweb'),
    (N'dbo.usp_area'),
    (N'dbo.usp_feriadoweb'),
    (N'dbo.usp_maquina'),
    (N'dbo.usp_permisoindicador'),
    (N'dbo.usp_personal'),
    (N'dbo.usp_usuario'),
    (N'dbo.uspasistencialistacsvbweb'),
    (N'dbo.uspbuscawebproducto'),
    (N'dbo.uspcajainsertacsvweb'),
    (N'dbo.uspcruzeobs'),
    (N'dbo.uspeditarconteocajaweb'),
    (N'dbo.uspeditarnotapedido'),
    (N'dbo.uspeditarrbweb'),
    (N'dbo.uspeliminarcajadetalleweb'),
    (N'dbo.uspeliminarcategoria'),
    (N'dbo.uspeliminarpagovweb'),
    (N'dbo.uspeliminarpersonal'),
    (N'dbo.uspeliminarproducto'),
    (N'dbo.uspeliminarproveedor'),
    (N'dbo.uspeliminarusuario'),
    (N'dbo.uspguardarcredencialessunatweb'),
    (N'dbo.uspguardarlistapreciospdfweb'),
    (N'dbo.uspguardarunidadmedidaproducto'),
    (N'dbo.uspingresarpersonal'),
    (N'dbo.uspingresarproducto'),
    (N'dbo.uspinsertarcategoria'),
    (N'dbo.uspinsertarconteocajaweb'),
    (N'dbo.uspinsertarcuentaproveedor'),
    (N'dbo.uspinsertarnc'),
    (N'dbo.uspinsertarnotabweb'),
    (N'dbo.uspinsertarpagovariosweb'),
    (N'dbo.uspinsertarproveedor'),
    (N'dbo.uspinsertarrbweb'),
    (N'dbo.uspinsertarusuario'),
    (N'dbo.usplistabajas'),
    (N'dbo.usplistaconteoweb'),
    (N'dbo.usplistadetalleconteoweb'),
    (N'dbo.usplistadocumentosweb'),
    (N'dbo.usplistarcomprasweb'),
    (N'dbo.usplistarpagovariosweb'),
    (N'dbo.usplistarproducto'),
    (N'dbo.usplistawebproducto'),
    (N'dbo.uspobtenercajaactivaweb'),
    (N'dbo.uspobtenercredencialessunatweb'),
    (N'dbo.uspobtenernotapedido'),
    (N'dbo.uspreenviarfactura'),
    (N'dbo.uspreenviarnotacredito'),
    (N'dbo.uspresumenfechaweb'),
    (N'dbo.uspretornaboletaporticketweb'),
    (N'dbo.uspretornarboletasweb'),
    (N'dbo.usptraercajerosweb'),
    (N'dbo.usptraergastosaweb'),
    (N'dbo.usptraergastosweb'),
    (N'dbo.usptraersecuenciaresumen'),
    (N'dbo.usptraetodasmonedasweb'),
    (N'dbo.uspvalidacantcajasweb'),
    (N'dbo.uspvalidararqueocajaweb'),
    (N'dbo.uspvalidarpagovarioscajafinalweb'),
    (N'dbo.uspvalidausuarioweb')
) v(nombre))
SELECT r.nombre,
 CASE WHEN s.object_id IS NULL THEN 'Ausente en referencia' ELSE 'Existe en referencia' END referencia,
 CASE WHEN d.object_id IS NULL THEN 'Ausente en DXNCOMAS' ELSE 'Existe en DXNCOMAS' END destino
FROM Requeridos r
LEFT JOIN [DXN_ICA15102026].sys.procedures s ON s.name=PARSENAME(r.nombre,1)
 AND s.schema_id=(SELECT schema_id FROM [DXN_ICA15102026].sys.schemas WHERE name=PARSENAME(r.nombre,2))
LEFT JOIN [DXNCOMAS].sys.procedures d ON d.name=PARSENAME(r.nombre,1)
 AND d.schema_id=(SELECT schema_id FROM [DXNCOMAS].sys.schemas WHERE name=PARSENAME(r.nombre,2))
ORDER BY r.nombre;
GO
SELECT s.name esquema,t.name tabla,c.name columna,ty.name tipo,c.max_length,c.precision,c.scale,c.is_nullable,
 CASE WHEN dt.object_id IS NULL THEN 'Tabla faltante' ELSE 'Columna faltante' END estado
FROM [DXN_ICA15102026].sys.tables t
JOIN [DXN_ICA15102026].sys.schemas s ON s.schema_id=t.schema_id
JOIN [DXN_ICA15102026].sys.columns c ON c.object_id=t.object_id
JOIN [DXN_ICA15102026].sys.types ty ON ty.user_type_id=c.user_type_id
LEFT JOIN [DXNCOMAS].sys.schemas ds ON ds.name=s.name
LEFT JOIN [DXNCOMAS].sys.tables dt ON dt.name=t.name AND dt.schema_id=ds.schema_id
LEFT JOIN [DXNCOMAS].sys.columns dc ON dc.object_id=dt.object_id AND dc.name=c.name
WHERE t.is_ms_shipped=0 AND dc.column_id IS NULL
ORDER BY s.name,t.name,c.column_id;
GO

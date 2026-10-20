/* Diagnóstico de COMAS para la web, solo lectura. No transmite ni corrige datos.
   Fuente: trazabilidad frontend -> endpoint -> SQL revisada el 2026-10-19.
   Ejecutar antes y después del paquete. Los contratos excluidos se informan como pendientes.
*/
USE [DXNCOMAS];
GO
SET NOCOUNT ON;
SELECT DB_NAME() Base, CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) VersionSQL,
       compatibility_level Compatibilidad
FROM sys.databases WHERE name = DB_NAME();

;WITH Requeridos(Objeto, Tipo, ContratoSinDefinicionInstalada) AS
(
    SELECT * FROM (VALUES
    (N'dbo.anulardocumento', 'P', 0),
    (N'dbo.anulardocumentoweb', 'P', 0),
    (N'dbo.apertura_almacen', 'U', 0),
    (N'dbo.aperturaobs', 'U', 0),
    (N'dbo.area', 'U', 0),
    (N'dbo.asistencia', 'U', 0),
    (N'dbo.caja', 'U', 0),
    (N'dbo.cajadetalle', 'U', 0),
    (N'dbo.cliente', 'U', 0),
    (N'dbo.compania', 'U', 0),
    (N'dbo.compras', 'U', 0),
    (N'dbo.conteomonedas', 'U', 0),
    (N'dbo.cuentaproveedor', 'U', 0),
    (N'dbo.depositoscentro', 'U', 0),
    (N'dbo.desincrectar', 'FN', 0),
    (N'dbo.detaliquidaventa', 'U', 0),
    (N'dbo.detalleapertura', 'U', 0),
    (N'dbo.detallecompra', 'U', 0),
    (N'dbo.detalleconteo', 'U', 0),
    (N'dbo.detalledocumento', 'U', 0),
    (N'dbo.detallepedido', 'U', 0),
    (N'dbo.detallepvarios', 'U', 0),
    (N'dbo.detallespvs', 'U', 0),
    (N'dbo.documentoventa', 'U', 0),
    (N'dbo.documentoventacpeweb', 'U', 0),
    (N'dbo.editarproductoweb', 'P', 0),
    (N'dbo.eliminarnotapedido', 'P', 0),
    (N'dbo.encriptar', 'FN', 0),
    (N'dbo.feriados', 'U', 0),
    (N'dbo.fnsplitstring', 'TF', 0),
    (N'dbo.genenerarnrofactura', 'FN', 0),
    (N'dbo.guialiquidacion', 'U', 0),
    (N'dbo.guiarelacion', 'U', 0),
    (N'dbo.indicador', 'U', 0),
    (N'dbo.ingresarproductoweb', 'P', 0),
    (N'dbo.kardex', 'U', 0),
    (N'dbo.lddocumentosweb', 'P', 0),
    (N'dbo.listanotapedido', 'P', 0),
    (N'dbo.listarcajafechaweb', 'P', 0),
    (N'dbo.listarcajaweb', 'P', 0),
    (N'dbo.listardetacajaweb', 'P', 0),
    (N'dbo.maquinas', 'U', 0),
    (N'dbo.moneda', 'U', 0),
    (N'dbo.monedas', 'U', 0),
    (N'dbo.notapedido', 'U', 0),
    (N'dbo.pagovarios', 'U', 0),
    (N'dbo.personal', 'U', 0),
    (N'dbo.producto', 'U', 0),
    (N'dbo.proveedor', 'U', 0),
    (N'dbo.resumenboletas', 'U', 0),
    (N'dbo.sublinea', 'U', 0),
    (N'dbo.tablaobs', 'U', 0),
    (N'dbo.temporalmoneda', 'U', 0),
    (N'dbo.temporalventa', 'U', 0),
    (N'dbo.ubigeo', 'U', 0),
    (N'dbo.unidadmedida', 'U', 0),
    (N'dbo.usp_area', 'P', 0),
    (N'dbo.usp_feriado', 'P', 0),
    (N'dbo.usp_feriadoweb', 'P', 0),
    (N'dbo.usp_maquina', 'P', 0),
    (N'dbo.usp_permisoindicador', 'P', 0),
    (N'dbo.usp_personal', 'P', 0),
    (N'dbo.usp_usuario', 'P', 0),
    (N'dbo.uspasistencialistacsvbweb', 'P', 0),
    (N'dbo.uspcajainsertacsvweb', 'P', 0),
    (N'dbo.uspcruzeobs', 'P', 0),
    (N'dbo.uspeditarconteocaja', 'P', 0),
    (N'dbo.uspeditarconteocajaweb', 'P', 0),
    (N'dbo.uspeditarnotapedido', 'P', 0),
    (N'dbo.uspeditarrbweb', 'P', 0),
    (N'dbo.uspeliminarcajadetalleweb', 'P', 0),
    (N'dbo.uspeliminarcategoria', 'P', 1),
    (N'dbo.uspeliminarpagovweb', 'P', 0),
    (N'dbo.uspeliminarproducto', 'P', 1),
    (N'dbo.uspeliminarproveedor', 'P', 1),
    (N'dbo.uspguardarcredencialessunatweb', 'P', 0),
    (N'dbo.uspguardarlistapreciospdfweb', 'P', 0),
    (N'dbo.uspguardarunidadmedidaproducto', 'P', 1),
    (N'dbo.uspinsertarcategoria', 'P', 1),
    (N'dbo.uspinsertarconteocajaweb', 'P', 0),
    (N'dbo.uspinsertarcuentaproveedor', 'P', 1),
    (N'dbo.uspinsertarnotabweb', 'P', 0),
    (N'dbo.uspinsertarpagovariosweb', 'P', 0),
    (N'dbo.uspinsertarproveedor', 'P', 1),
    (N'dbo.uspinsertarrbweb', 'P', 0),
    (N'dbo.uspinsertarusuario', 'P', 1),
    (N'dbo.usplistabajas', 'P', 0),
    (N'dbo.usplistaconteoweb', 'P', 0),
    (N'dbo.usplistadetalleconteoweb', 'P', 0),
    (N'dbo.usplistadocumentosweb', 'P', 0),
    (N'dbo.usplistarcomprasweb', 'P', 1),
    (N'dbo.usplistarpagovariosweb', 'P', 0),
    (N'dbo.uspobtenercredencialessunatweb', 'P', 0),
    (N'dbo.uspresumenfechaweb', 'P', 0),
    (N'dbo.uspretornarboletasweb', 'P', 0),
    (N'dbo.usptraercajerosweb', 'P', 0),
    (N'dbo.usptraergastosaweb', 'P', 0),
    (N'dbo.usptraergastosweb', 'P', 0),
    (N'dbo.usptraersecuenciaresumen', 'P', 0),
    (N'dbo.usptraetodasmonedasweb', 'P', 0),
    (N'dbo.uspvalidacantcajasweb', 'P', 0),
    (N'dbo.uspvalidararqueocajaweb', 'P', 0),
    (N'dbo.uspvalidarpagovarioscajafinalweb', 'P', 0),
    (N'dbo.uspvalidausuarioweb', 'P', 0),
    (N'dbo.usuarios', 'U', 0)
    ) v(Objeto, Tipo, ContratoSinDefinicionInstalada)
)
SELECT CASE WHEN ContratoSinDefinicionInstalada = 1 THEN 'CONTRATO PENDIENTE' ELSE 'ESTRUCTURA PENDIENTE' END Estado,
       Objeto, Tipo
FROM Requeridos WHERE OBJECT_ID(Objeto, Tipo) IS NULL ORDER BY Estado, Objeto;

;WITH Columnas(Tabla, Columna, Obligatoria) AS
(
    SELECT * FROM (VALUES
    (N'dbo.DetallePVarios', N'Deposito', 1),
    (N'dbo.DetallePVarios', N'Efectivo', 1),
    (N'dbo.DocumentoVentaCpeWeb', N'ClienteDni', 1),
    (N'dbo.DocumentoVentaCpeWeb', N'ClienteRazon', 1),
    (N'dbo.DocumentoVentaCpeWeb', N'ClienteRuc', 1),
    (N'dbo.DocumentoVentaCpeWeb', N'DireccionFiscal', 1),
    (N'dbo.DocumentoVentaCpeWeb', N'DocuCdrUrl', 1),
    (N'dbo.DocumentoVentaCpeWeb', N'DocuFechaPago', 1),
    (N'dbo.DocumentoVentaCpeWeb', N'DocuId', 1),
    (N'dbo.DocumentoVentaCpeWeb', N'DocuPdfUrl', 1),
    (N'dbo.DocumentoVentaCpeWeb', N'DocuXmlUrl', 1),
    (N'dbo.DocumentoVentaCpeWeb', N'FechaRegistro', 1),
    (N'dbo.Indicador', N'Area', 1),
    (N'dbo.Indicador', N'CompaniaId', 1),
    (N'dbo.Indicador', N'Descripcion', 1),
    (N'dbo.Indicador', N'FechaActualizacion', 1),
    (N'dbo.Indicador', N'Id', 1),
    (N'dbo.Indicador', N'IdIndicador', 1),
    (N'dbo.Indicador', N'TipoIndicador', 1),
    (N'dbo.Indicador', N'ValorDecimal', 1),
    (N'dbo.Indicador', N'ValorNum', 1),
    (N'dbo.Indicador', N'ValorTexto1', 1),
    (N'dbo.MAQUINAS', N'Registro', 1),
    (N'dbo.MAQUINAS', N'SerieBoleta', 1),
    (N'dbo.MAQUINAS', N'Tiketera', 1),
    (N'dbo.NotaPedido', N'Almacen', 0),
    (N'dbo.NotaPedido', N'Entrega', 1),
    (N'dbo.NotaPedido', N'Hora', 0),
    (N'dbo.Producto', N'AplicaINV', 1),
    (N'dbo.Producto', N'ProductoVentaB', 1),
    (N'dbo.Producto', N'UltimoINV', 1),
    (N'dbo.ResumenBoletas', N'CDRBase64', 1),
    (N'dbo.UnidadMedida', N'unidadImagen', 1),
    (N'dbo.Usuarios', N'FechaVencimientoClave', 1)
    ) v(Tabla, Columna, Obligatoria)
)
SELECT CASE WHEN Obligatoria = 1 THEN 'COLUMNA PENDIENTE' ELSE 'COLUMNA COMPLEMENTARIA' END Estado,
       Tabla, Columna
FROM Columnas WHERE COL_LENGTH(Tabla, Columna) IS NULL ORDER BY Tabla, Columna;

SELECT v.Procedimiento, N'INSERT posicional pendiente de compatibilidad' Estado
FROM (VALUES
    (N'dbo.ingresarProducto', N'insert into Producto values'),
    (N'dbo.ingresarUsuario', N'insert into Usuarios values'),
    (N'dbo.InsertarUM', N'insert into UnidadMedida values'),
    (N'dbo.uspinsertarNotaB', N'insert into NotaPedido values'),
    (N'dbo.uspInsertarPagoVarios', N'insert into DetallePVarios values'),
    (N'dbo.uspinsertarRB', N'insert into ResumenBoletas values')
) v(Procedimiento, Sentencia)
WHERE CHARINDEX(v.Sentencia, OBJECT_DEFINITION(OBJECT_ID(v.Procedimiento, N'P'))) > 0;

SELECT c.CompaniaId, c.CompaniaComercial, c.CompaniaRazonSocial, c.DiasMaxDep,
       CASE WHEN LEN(LTRIM(RTRIM(ISNULL(c.CompaniaRUC, '')))) = 11
                  AND c.CompaniaRUC NOT LIKE '%[^0-9]%' THEN 'OK' ELSE 'REVISAR RUC' END EstadoRuc,
       c.RenovacionOSE, c.RenovacionFirma, c.RenovacionSome
FROM dbo.Compania c;
SELECT COUNT(*) Usuarios, SUM(CASE WHEN Administrador = 1 THEN 1 ELSE 0 END) Administradores FROM dbo.Usuarios;
SELECT u.UsuarioID, N'Usuario sin Personal o compañía válida' Estado
FROM dbo.Usuarios u
LEFT JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
LEFT JOIN dbo.Compania c ON c.CompaniaId = p.CompaniaId
WHERE p.PersonalId IS NULL OR c.CompaniaId IS NULL;
SELECT CajaEstado, COUNT_BIG(*) Cantidad FROM dbo.Caja GROUP BY CajaEstado;

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
    SELECT N'CONFIGURACION PENDIENTE' Estado, N'Falta dbo.Indicador y su inicialización.' Detalle;
ELSE
BEGIN
    EXEC(N'
    SELECT CompaniaId, Area, TipoIndicador, Descripcion, COUNT(*) Cantidad
    FROM dbo.Indicador WHERE IdIndicador IS NULL
    GROUP BY CompaniaId, Area, TipoIndicador, Descripcion HAVING COUNT(*) > 1;
    SELECT CompaniaId, Area, Descripcion, ValorNum
    FROM dbo.Indicador WHERE IdIndicador IS NULL
      AND Descripcion IN (''ASISTENCIA'', ''MULTIPLES_CAJAS'', ''CAPTURA_HTML'', ''BOLETA_POR_LOTE'', ''TIPO_PROCESO_CPE'', ''DIAS_MAX_DEPOSITO'')
    ORDER BY CompaniaId, Area, Descripcion;
    SELECT c.CompaniaId, r.Descripcion,
           CASE WHEN EXISTS
           (SELECT 1 FROM dbo.Indicador i
            WHERE i.CompaniaId = c.CompaniaId AND i.Area = r.Area AND i.TipoIndicador = 3
              AND i.IdIndicador IS NULL AND i.Descripcion = r.Descripcion
              AND NULLIF(LTRIM(RTRIM(i.ValorTexto1)), '''') IS NOT NULL)
           THEN ''REGISTRADO: validar funcionamiento'' ELSE ''FALTA CONFIGURAR'' END Estado
    FROM dbo.Compania c
    CROSS JOIN (VALUES
        (''CORREO'', ''CORREOS_ADMIN''), (''CPE'', ''CPE_USUARIO_SOL''),
        (''CPE'', ''CPE_CLAVE_SOL''), (''CPE'', ''CPE_CERTIFICADO_PFX''),
        (''CPE'', ''CPE_CLAVE_CERTIFICADO''), (''SUNAT'', ''SUNAT_USUARIO_SOL''),
        (''SUNAT'', ''SUNAT_CLAVE_SOL''), (''SUNAT'', ''SUNAT_VALIDAR_CLIENT_ID''),
        (''SUNAT'', ''SUNAT_VALIDAR_CLIENT_SECRET''), (''SUNAT'', ''SUNAT_SIRE_CLIENT_ID''),
        (''SUNAT'', ''SUNAT_SIRE_CLIENT_SECRET'')
    ) r(Area, Descripcion);
    SELECT p.CompaniaId, p.AreaId, a.AreaNombre, COUNT(DISTINCT u.UsuarioID) UsuariosSinPerfilArea
    FROM dbo.Personal p
    JOIN dbo.Usuarios u ON u.PersonalId = p.PersonalId
    JOIN dbo.Area a ON a.AreaId = p.AreaId
    WHERE ISNULL(u.Administrador, 0) = 0
      AND NOT EXISTS (SELECT 1 FROM dbo.Indicador i WHERE i.CompaniaId = p.CompaniaId
                      AND i.Area = ''SEGURIDAD'' AND i.TipoIndicador = 90 AND i.IdIndicador IS NULL
                      AND i.Descripcion = ''PERMISOS_AREA_'' + CONVERT(varchar(20), CONVERT(int, p.AreaId)))
    GROUP BY p.CompaniaId, p.AreaId, a.AreaNombre;
    ');
END;

SELECT IdMaquina, Maquina, SerieFactura, SerieNC,
       CASE WHEN NULLIF(LTRIM(RTRIM(SerieFactura)), '') IS NULL THEN 'SIN SERIE FACTURA: revisar si emitirá' ELSE 'REVISAR ESTACION Y CORRELATIVOS' END Estado
FROM dbo.MAQUINAS;
IF COL_LENGTH(N'dbo.MAQUINAS', N'SerieBoleta') IS NOT NULL
    EXEC(N'SELECT IdMaquina, Maquina, SerieBoleta FROM dbo.MAQUINAS WHERE NULLIF(LTRIM(RTRIM(SerieBoleta)), '''') IS NULL;');

SELECT N'FUERA DE SQL' Estado, N'Validar conexión API a COMAS, CORS, URL frontend/extensión, JWT, EmailSettings SMTP, media, PFX, XML/CDR/PDF y agente de impresión. Registrar PFX real, verificar entorno CPE y permisos por área. Este diagnóstico no envía correo ni documentos SUNAT.' Detalle;
GO

/*
   Alinea Caja Web con el escritorio: las ventas OBS se consolidan desde
   TABLAOBS y no se suman directamente desde NotaPedido.Efectivo.
*/
CREATE OR ALTER PROCEDURE dbo.uspObtenerCajaActivaWEB
    @UsuarioId int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CajaId numeric(38);
    SELECT TOP (1) @CajaId = CajaId
      FROM dbo.Caja
     WHERE UsuarioId = @UsuarioId AND CajaEstado = 'ACTIVO'
     ORDER BY CajaId DESC;

    IF ISNULL(@CajaId, 0) = 0 RETURN;

    DECLARE @MontoInicial decimal(18,2), @VentasEfectivo decimal(18,2), @Tarjeta decimal(18,2),
            @Depositos decimal(18,2), @SistemaObs decimal(18,2), @IngresosCaja decimal(18,2), @Salidas decimal(18,2);

    SELECT @MontoInicial = ISNULL(MontoIniSOl, 0) FROM dbo.Caja WHERE CajaId = @CajaId;
    SELECT @VentasEfectivo = ISNULL(SUM(ISNULL(Efectivo, 0)), 0),
           @Tarjeta = ISNULL(SUM(CASE WHEN UPPER(ISNULL(NotaFormaPago, '')) LIKE '%TARJETA%' THEN ISNULL(Deposito, 0) ELSE 0 END), 0),
           @Depositos = ISNULL(SUM(CASE WHEN UPPER(ISNULL(NotaFormaPago, '')) NOT LIKE '%TARJETA%' THEN ISNULL(Deposito, 0) ELSE 0 END), 0)
      FROM dbo.NotaPedido
     WHERE CajaId = @CajaId AND ISNULL(NotaEstado, '') <> 'ANULADO';
    SELECT @Salidas = ISNULL(SUM(ISNULL(DetalleEfectivo, DetalleMonto)), 0)
      FROM dbo.CajaDetalle
     WHERE CajaId = @CajaId AND DetalleMovimiento = 'SALIDA' AND ISNULL(NotaId, 0) = 0;
    SELECT @SistemaObs = ISNULL(SUM(ISNULL(T.Importe, 0)), 0)
      FROM dbo.TABLAOBS T
      LEFT JOIN dbo.NotaPedido n ON n.NotaTransaccion = T.NotaTransaccion
     WHERE T.TipoVenta = 'OBS' AND n.CajaId = @CajaId;
    SELECT @IngresosCaja = ISNULL(SUM(ISNULL(DetalleMonto, 0)), 0)
      FROM dbo.CajaDetalle
     WHERE CajaId = @CajaId AND DetalleMovimiento = 'INGRESO' AND ISNULL(NotaId, 0) = 0
       AND ISNULL(DetalleConcepto, '') NOT IN ('TOTAL EFECTIVO', 'SENCILLO');

    SELECT CONVERT(bigint, c.CajaId) AS CajaId,
           CONVERT(varchar(19), c.CajaFecha, 126) AS FechaApertura,
           ISNULL(c.MontoIniSOl, 0) AS MontoInicial,
           ISNULL(c.CajaEncargado, '') AS Encargado,
           ISNULL(c.CajaUsuario, '') AS Usuario,
           ISNULL(c.Observacion, '') AS Observacion,
           @VentasEfectivo AS VentasEfectivo,
           @Tarjeta AS VentasTarjeta,
           @Depositos AS VentasDeposito,
           @Salidas AS Salidas,
           @MontoInicial + @SistemaObs - @Salidas + @IngresosCaja AS EfectivoEsperado
      FROM dbo.Caja c
     WHERE c.CajaId = @CajaId;

    SELECT Billete, ISNULL(Efectivo, 0) AS Cantidad
      FROM dbo.Monedas
     WHERE CajaId = @CajaId
     ORDER BY CONVERT(decimal(18,2), Billete) DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.uspCerrarCajaWEB
    @CajaId numeric(38),
    @UsuarioId int,
    @Observacion varchar(500) = NULL,
    @Conteo varchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.Caja WITH (UPDLOCK, HOLDLOCK) WHERE CajaId = @CajaId AND UsuarioId = @UsuarioId AND CajaEstado = 'ACTIVO')
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 'false';
        RETURN;
    END;

    DECLARE @Fila varchar(max), @Separador int, @Cantidad int, @Billete decimal(18,2);
    WHILE LEN(@Conteo) > 0
    BEGIN
        SET @Separador = CHARINDEX(';', @Conteo);
        IF @Separador = 0
        BEGIN
            SET @Fila = @Conteo;
            SET @Conteo = '';
        END
        ELSE
        BEGIN
            SET @Fila = SUBSTRING(@Conteo, 1, @Separador - 1);
            SET @Conteo = SUBSTRING(@Conteo, @Separador + 1, LEN(@Conteo));
        END;

        SET @Separador = CHARINDEX('|', @Fila);
        SET @Billete = CONVERT(decimal(18,2), SUBSTRING(@Fila, 1, @Separador - 1));
        SET @Cantidad = CONVERT(int, SUBSTRING(@Fila, @Separador + 1, LEN(@Fila)));
        IF @Cantidad < 0
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('La cantidad de billetes o monedas no puede ser negativa.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.Monedas SET Efectivo = @Cantidad, Monto = @Billete * @Cantidad
         WHERE CajaId = @CajaId AND CONVERT(decimal(18,2), Billete) = @Billete;
    END;

    DECLARE @MontoInicial decimal(18,2), @Ingresos decimal(18,2), @Depositos decimal(18,2),
            @SistemaObs decimal(18,2), @IngresosCaja decimal(18,2), @Salidas decimal(18,2), @Contado decimal(18,2);

    SELECT @MontoInicial = ISNULL(MontoIniSOl, 0) FROM dbo.Caja WHERE CajaId = @CajaId;
    SELECT @Depositos = ISNULL(SUM(ISNULL(Deposito, 0)), 0)
      FROM dbo.NotaPedido WHERE CajaId = @CajaId AND ISNULL(NotaEstado, '') <> 'ANULADO';
    SELECT @Salidas = ISNULL(SUM(ISNULL(DetalleEfectivo, DetalleMonto)), 0)
      FROM dbo.CajaDetalle WHERE CajaId = @CajaId AND DetalleMovimiento = 'SALIDA' AND ISNULL(NotaId, 0) = 0;
    SELECT @SistemaObs = ISNULL(SUM(ISNULL(T.Importe, 0)), 0)
      FROM dbo.TABLAOBS T
      LEFT JOIN dbo.NotaPedido n ON n.NotaTransaccion = T.NotaTransaccion
     WHERE T.TipoVenta = 'OBS' AND n.CajaId = @CajaId;
    SELECT @IngresosCaja = ISNULL(SUM(ISNULL(DetalleMonto, 0)), 0)
      FROM dbo.CajaDetalle
     WHERE CajaId = @CajaId AND DetalleMovimiento = 'INGRESO' AND ISNULL(NotaId, 0) = 0
       AND ISNULL(DetalleConcepto, '') NOT IN ('TOTAL EFECTIVO', 'SENCILLO');
    SELECT @Contado = ISNULL(SUM(ISNULL(Monto, 0)), 0) FROM dbo.Monedas WHERE CajaId = @CajaId;
    SET @Ingresos = @MontoInicial + @SistemaObs - @Salidas + @IngresosCaja;

    UPDATE dbo.Caja
       SET CajaCierre = CONVERT(varchar(19), GETDATE(), 120), CajaEstado = 'CERRADO',
           CajaIngresos = @Ingresos, CajaDeposito = @Depositos, CajaSalidas = @Salidas,
           CajaTotal = @Contado, Observacion = NULLIF(@Observacion, '')
     WHERE CajaId = @CajaId;

    COMMIT TRANSACTION;

    SELECT CONVERT(bigint, @CajaId) AS CajaId, @Ingresos AS EfectivoEsperado,
           @Contado AS EfectivoContado, @Contado - @Ingresos AS Diferencia;
END;
GO

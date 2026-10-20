/* Ejecutar desde esta carpeta con sqlcmd o SSMS en modo SQLCMD.
   Instala el paquete en una transacción; no resuelve los nueve contratos excluidos.
   Revisar 04_configuracion_inicial_dxncomas.sql y la documentación antes del pase.
*/
:ON ERROR EXIT
USE [DXNCOMAS];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
GO
:r 00_compatibilidad_inserts_dxncomas.sql
:r 01_tablas_dxncomas.sql
:r 02_columnas_dxncomas.sql
:r 03_procedimientos_dxncomas.sql
:r 04_configuracion_inicial_dxncomas.sql
IF @@TRANCOUNT <> 1
BEGIN
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    RAISERROR('La transacción del paquete quedó en un estado inesperado.', 16, 1);
    RETURN;
END;
COMMIT TRANSACTION;
GO
:r 05_diagnostico_dxncomas.sql

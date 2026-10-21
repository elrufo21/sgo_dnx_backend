/*
    Permite que varias máquinas tengan el mismo nombre de impresora/ticketera.
    SQL Server 2008 R2 compatible.

    Solo elimina índices/constraints UNIQUE cuya única columna clave sea
    dbo.MAQUINAS.Tiketera. Conserva índices compuestos y otras restricciones.
    Ejecutar por el administrador de SQL después de revisar el estado de la BD.
*/
SET NOCOUNT ON;

DECLARE @TablaId INT;
DECLARE @TiketeraId INT;
DECLARE @IndiceId INT;
DECLARE @Indice SYSNAME;
DECLARE @EsConstraint BIT;
DECLARE @Constraint SYSNAME;
DECLARE @Sql NVARCHAR(1000);
DECLARE @Schema SYSNAME;
DECLARE @Tabla SYSNAME;

SET @TablaId = OBJECT_ID(N'dbo.MAQUINAS', N'U');

IF @TablaId IS NULL
BEGIN
    RAISERROR('No existe la tabla dbo.MAQUINAS.', 16, 1);
    RETURN;
END;

SELECT @TiketeraId = column_id
FROM sys.columns
WHERE object_id = @TablaId
  AND name = N'Tiketera';

IF @TiketeraId IS NULL
BEGIN
    RAISERROR('No existe la columna dbo.MAQUINAS.Tiketera.', 16, 1);
    RETURN;
END;

SET @Schema = OBJECT_SCHEMA_NAME(@TablaId);
SET @Tabla = OBJECT_NAME(@TablaId);

DECLARE indices_impresora CURSOR LOCAL FAST_FORWARD FOR
    SELECT indice.index_id, indice.name, indice.is_unique_constraint
    FROM
    (
        SELECT
            i.index_id,
            i.name,
            i.is_unique_constraint,
            COUNT(*) AS cantidad_columnas_clave,
            MAX(ic.column_id) AS columna_clave
        FROM sys.indexes i
        INNER JOIN sys.index_columns ic
            ON ic.object_id = i.object_id
           AND ic.index_id = i.index_id
           AND ic.key_ordinal > 0
        WHERE i.object_id = @TablaId
          AND i.is_unique = 1
          AND i.is_primary_key = 0
          AND i.index_id > 0
        GROUP BY i.index_id, i.name, i.is_unique_constraint
    ) indice
    WHERE indice.cantidad_columnas_clave = 1
      AND indice.columna_clave = @TiketeraId;

OPEN indices_impresora;
FETCH NEXT FROM indices_impresora INTO @IndiceId, @Indice, @EsConstraint;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @EsConstraint = 1
    BEGIN
        SELECT @Constraint = kc.name
        FROM sys.key_constraints kc
        WHERE kc.parent_object_id = @TablaId
          AND kc.unique_index_id = @IndiceId;

        IF @Constraint IS NOT NULL
        BEGIN
            SET @Sql = N'ALTER TABLE ' + QUOTENAME(@Schema) + N'.' + QUOTENAME(@Tabla)
                     + N' DROP CONSTRAINT ' + QUOTENAME(@Constraint) + N';';
            EXEC sp_executesql @Sql;
            PRINT N'Se quitó la restricción UNIQUE ' + QUOTENAME(@Constraint) + N'.';
        END;
    END
    ELSE
    BEGIN
        SET @Sql = N'DROP INDEX ' + QUOTENAME(@Indice) + N' ON '
                 + QUOTENAME(@Schema) + N'.' + QUOTENAME(@Tabla) + N';';
        EXEC sp_executesql @Sql;
        PRINT N'Se quitó el índice UNIQUE ' + QUOTENAME(@Indice) + N'.';
    END;

    SET @Constraint = NULL;
    FETCH NEXT FROM indices_impresora INTO @IndiceId, @Indice, @EsConstraint;
END;

CLOSE indices_impresora;
DEALLOCATE indices_impresora;

SELECT
    i.name AS IndiceUnicoRestante,
    kc.name AS RestriccionUnicaRestante
FROM sys.indexes i
INNER JOIN sys.index_columns ic
    ON ic.object_id = i.object_id
   AND ic.index_id = i.index_id
   AND ic.key_ordinal > 0
LEFT JOIN sys.key_constraints kc
    ON kc.parent_object_id = i.object_id
   AND kc.unique_index_id = i.index_id
WHERE i.object_id = @TablaId
  AND i.is_unique = 1
  AND i.is_primary_key = 0
GROUP BY i.index_id, i.name, kc.name
HAVING COUNT(*) = 1
   AND MAX(ic.column_id) = @TiketeraId;

PRINT N'La unicidad del nombre de impresora quedó permitida si no aparecen filas en el resultado anterior.';

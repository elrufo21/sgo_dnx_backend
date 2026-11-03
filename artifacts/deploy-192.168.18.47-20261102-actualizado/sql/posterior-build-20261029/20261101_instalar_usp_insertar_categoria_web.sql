-- Instala una copia web de la definición de bdactual.sql solo si no existe.
-- El administrador debe seleccionar y verificar la base de destino y la estructura
-- de dbo.Sublinea antes de ejecutar. No se ha ejecutado este archivo.
-- Compatible con SQL Server 2008 R2. No reemplaza procedimientos existentes.
IF OBJECT_ID(N'dbo.Sublinea', N'U') IS NULL
   OR COL_LENGTH(N'dbo.Sublinea', N'IdSubLinea') IS NULL
   OR COL_LENGTH(N'dbo.Sublinea', N'NombreSublinea') IS NULL
   OR COL_LENGTH(N'dbo.Sublinea', N'CodigoSunat') IS NULL
   OR COLUMNPROPERTY(OBJECT_ID(N'dbo.Sublinea'), N'IdSubLinea', 'IsIdentity') <> 1
BEGIN
    RAISERROR('Revise dbo.Sublinea y sus columnas antes de instalar el procedimiento.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'dbo.uspInsertarCategoriaWeb', N'P') IS NULL
BEGIN
    EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarCategoriaWeb]    
@Data VARCHAR(MAX)    
AS    
BEGIN    

DECLARE @pos1 INT, @pos2 INT, @pos3 INT    
DECLARE @Id INT, @Nombre VARCHAR(300), @Codigo VARCHAR(40)    
DECLARE @NewId INT    

SET @Data = LTRIM(RTRIM(@Data))    

SET @pos1 = CHARINDEX(''|'',@Data,0)    
SET @pos2 = CHARINDEX(''|'',@Data,@pos1+1)    
SET @pos3 = LEN(@Data)+1    

SET @Id = CONVERT(INT,SUBSTRING(@Data,1,@pos1-1))    
SET @Nombre = SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1)    
SET @Codigo = SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1)    

IF(@Id=0)    
BEGIN    

    IF EXISTS(SELECT TOP 1 s.NombreSubLinea     
              FROM Sublinea s 
              WHERE s.NombreSubLinea=@Nombre)     
    BEGIN    
        SELECT ''existe''     
    END     

    ELSE     
    BEGIN     
        INSERT INTO Sublinea (NombreSublinea, CodigoSunat) 
        VALUES (@Nombre, @Codigo)    

        SET @NewId = SCOPE_IDENTITY()

        SELECT 
        CAST(@NewId AS VARCHAR) + ''|'' + @Nombre
    END    

END    

ELSE    

BEGIN  

    IF EXISTS(SELECT TOP 1 s.NombreSubLinea     
              FROM Sublinea s 
              WHERE s.NombreSubLinea=@Nombre 
              AND IdSubLinea<>@Id)     

    BEGIN    
        SELECT ''existe''     
    END  

    ELSE  

    BEGIN  

        UPDATE Sublinea     
        SET NombreSublinea = @Nombre, 
            CodigoSunat = @Codigo     
        WHERE IdSubLinea = @Id  

        SELECT 
        CAST(@Id AS VARCHAR) + ''|'' + @Nombre

    END  

END    

END');
    PRINT 'Se instaló dbo.uspInsertarCategoriaWeb.';
END
ELSE
    PRINT 'dbo.uspInsertarCategoriaWeb ya existe; no se modificó.';

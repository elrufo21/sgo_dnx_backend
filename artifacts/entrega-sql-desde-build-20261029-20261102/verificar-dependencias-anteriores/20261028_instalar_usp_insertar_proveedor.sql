-- Definición de referencia de bdactual.sql; no modifica un procedimiento existente.
IF OBJECT_ID(N'dbo.uspInsertarProveedor', N'P') IS NULL
BEGIN
    EXEC(N'create procedure [dbo].[uspInsertarProveedor] 
@Data varchar(max)  
as  
Begin  
  
Declare @Id int,   
        @ProveedorRazon varchar(250),  
        @ProveedorRuc varchar (20),  
        @ProveedorContacto varchar(140),  
        @ProveedorCelular varchar(140),  
        @ProveedorTelefono varchar(140),  
        @ProveedorCorreo varchar(140),  
        @ProveedorDireccion varchar(250),  
        @ProveedorEstado varchar(20)  
  
  
 Declare @pos1 int, @pos2 int,@pos3 int,    
   @pos4 int, @pos5 int,@pos6 int,  
   @pos7 int, @pos8 int,@pos9 int  
  
Set @Data= LTRIM(RTrim(@Data))    
Set @pos1=CharIndex(''|'',@Data,0)    
Set @pos2=CharIndex(''|'',@Data,@pos1+1)    
Set @pos3=CharIndex(''|'',@Data,@pos2+1)    
Set @pos4=CharIndex(''|'',@Data,@pos3+1)    
Set @pos5=CharIndex(''|'',@Data,@pos4+1)  
Set @pos6=CharIndex(''|'',@Data,@pos5+1)    
Set @pos7=CharIndex(''|'',@Data,@pos6+1)    
Set @pos8=CharIndex(''|'',@Data,@pos7+1)    
Set @pos9=Len(@Data)+1   
  
  
Set @Id=convert(int,SUBSTRING(@Data,1,@pos1-1))    
Set @ProveedorRazon=SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1)    
Set @ProveedorRuc=SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1)    
Set @ProveedorContacto=SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1)    
Set @ProveedorCelular=SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1)    
Set @ProveedorTelefono=SUBSTRING(@Data,@pos5+1,@pos6-@pos5-1)  
Set @ProveedorCorreo=SUBSTRING(@Data,@pos6+1,@pos7-@pos6-1)  
Set @ProveedorDireccion=SUBSTRING(@Data,@pos7+1,@pos8-@pos7-1)    
Set @ProveedorEstado=SUBSTRING(@Data,@pos8+1,@pos9-@pos8-1)    
  
if(@Id=0)    
 Begin  
  
 IF EXISTS(select top 1  p.ProveedorRuc   
    from Proveedor p where p.ProveedorRuc=@ProveedorRuc and p.ProveedorRuc<>'''')     
  begin    
    select ''existe RUC''     
  end  
 Else  
 Begin  
   
 INSERT INTO Proveedor (ProveedorRazon,ProveedorRuc,ProveedorContacto,  
    ProveedorCelular,ProveedorTelefono,ProveedorCorreo,  
    ProveedorDireccion,ProveedorEstado)   
  VALUES (@ProveedorRazon,@ProveedorRuc,@ProveedorContacto,  
    @ProveedorCelular,@ProveedorTelefono,@ProveedorCorreo,  
    @ProveedorDireccion,@ProveedorEstado)  
  
 select ''true''  
  
 End  
  
End  
Else  
Begin  
 IF EXISTS(select top 1  p.ProveedorRuc   
    from Proveedor p where p.ProveedorRuc=@ProveedorRuc and (p.ProveedorRuc<>'''' and p.ProveedorId<>@Id))     
  begin    
    select ''existe RUC''     
  end  
 Else  
 Begin  
  
   UPDATE Proveedor SET  
  ProveedorRazon = @ProveedorRazon,  
  ProveedorRuc = @ProveedorRuc,  
  ProveedorContacto = @ProveedorContacto,  
  ProveedorCelular = @ProveedorCelular,  
  ProveedorTelefono = @ProveedorTelefono,  
  ProveedorCorreo = @ProveedorCorreo,  
  ProveedorDireccion = @ProveedorDireccion,  
  ProveedorEstado = @ProveedorEstado  
  WHERE ProveedorId = @Id  
  
   select ''select true''     
  
 End  
  
End  
End');
END
ELSE
BEGIN
    PRINT 'dbo.uspInsertarProveedor ya existe; no se realizaron cambios.';
END
GO


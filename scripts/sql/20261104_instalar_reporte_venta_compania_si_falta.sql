/* Para revisión del responsable SQL. Instala el procedimiento heredado solo si no existe.
   No sobrescribe una versión existente. Verificar la definición de cada sede y sus reglas antes de aplicar.
   Fuente: scripts/sql/bdactual.sql, dbo.reporteVentaCompania. */
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'dbo.reporteVentaCompania', N'P') IS NULL
BEGIN
    EXEC(N'create procedure [dbo].[reporteVentaCompania]  
@Mes int,  
@Anno int  
as  
begin  
select top 2 isnull(b.CompaniaId,isnull(S.CompaniaId,isnull(d.CompaniaId,isnull(x.CompaniaId,z.CompaniaId)))) as CompaniaId,  
ISNULL(b.RazonSocial,isnull(S.RazonSocial,isnull(d.RazonSocial,isnull(x.RazonSocial,z.RazonSocial))))as RazonSocial,  
convert(varchar(50),cast((ISNULL(b.Monto,0))as money),1) as Ventas,  
convert(varchar(50),cast(((ISNULL(s.Monto,0)+ISNULL(d.Monto,0))-(ISNULL(x.Monto,0)+ISNULL(z.Monto,0)))as money),1) as Compras  
from  
(  
select top 2 c.CompaniaId,c.CompaniaRazonSocial as RazonSocial,  
sum(d.DocuTotal) as Monto--VENTASSS  
from DocumentoVenta d  
inner join Compania c  
on c.CompaniaId=d.CompaniaId  
where (month(d.DocuEmision)=@Mes and year(d.DocuEmision)=@Anno)and 
(d.DocuDocumento<>''PROFORMA V'' AND d.DocuDocumento<>''NOTA DE CREDITO'') and d.DocuAsociado=''''  
group by c.CompaniaId,c.CompaniaRazonSocial  
)b  
full join(  
select TOP 2 co.CompaniaId,co.CompaniaRazonSocial as RazonSocial,sum(c.CompraTotal) as Monto  
from Compras c--FACTURAS EN SOLES  
inner join Compania co  
on co.CompaniaId=c.CompaniaId  
where (month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo=''01'' and c.CompraMoneda=''SOLES'')  
group by co.CompaniaId,co.CompaniaRazonSocial  
)s on b.CompaniaId=s.CompaniaId  
full join  
(select TOP 2 co.CompaniaId,co.CompaniaRazonSocial as RazonSocial,cast(sum(c.CompraTotal*c.CompraTipoSunat)as decimal(18,2)) as Monto  
from Compras c--FACTURAS EN DOLARES  
inner join Compania co  
on co.CompaniaId=c.CompaniaId  
where(month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo=''01'' and c.CompraMoneda=''DOLARES'')  
group by co.CompaniaId,co.CompaniaRazonSocial  
)d on b.CompaniaId=d.CompaniaId  
full join(  
select TOP 2 co.CompaniaId,co.CompaniaRazonSocial as RazonSocial,cast(sum(c.CompraTotal*c.CompraTipoSunat)as decimal(18,2)) as Monto  
from Compras c--nota de credito en dolares  
inner join Compania co  
on co.CompaniaId=c.CompaniaId  
where(month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo=''07'' and c.CompraMoneda=''DOLARES'')  
group by co.CompaniaId,co.CompaniaRazonSocial  
)x on b.CompaniaId=x.CompaniaId  
full join (  
select TOP 2 co.CompaniaId,co.CompaniaRazonSocial as RazonSocial,sum(c.CompraTotal) as Monto  
from Compras c--nota de credito en soles  
inner join Compania co  
on co.CompaniaId=c.CompaniaId  
where(month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo=''07'' and c.CompraMoneda=''SOLES'')  
group by co.CompaniaId,co.CompaniaRazonSocial  
)z on b.CompaniaId=z.CompaniaId  
end');
END;
GO

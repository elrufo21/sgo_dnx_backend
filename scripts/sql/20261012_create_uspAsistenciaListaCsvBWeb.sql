CREATE OR ALTER PROCEDURE dbo.uspAsistenciaListaCsvBWeb
    @Data date
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        'Id|Fecha|PersonalId|Nombres|HoraIngreso|IngresoRefrigerio|RetornoRefrigerio|HoraSalida|NroMar|HoraING|HoraREF|CantidadTar¬90|100|100|220|125|125|125|125|70|90|90|90¬String|String|String|String|String|String|String|String|String|String|String|String¬' +
        ISNULL((
            SELECT STUFF((
                SELECT '¬' + CONVERT(varchar, a.Id) + '|' +
                       CONVERT(varchar, a.Fecha, 103) + '|' +
                       CONVERT(varchar, a.PersonalId) + '|' +
                       SUBSTRING(p.PersonalNombres + ' ', 1, CHARINDEX(' ', p.PersonalNombres + ' ') - 1) + ' ' +
                       SUBSTRING(p.PersonalApellidos + ' ', 1, CHARINDEX(' ', p.PersonalApellidos + ' ') - 1) + '|' +
                       ISNULL(SUBSTRING(CONVERT(varchar, a.HoraIngreso, 114), 1, 8), '') + '|' +
                       ISNULL(SUBSTRING(CONVERT(varchar, a.SalidaRefrigerio, 114), 1, 8), '') + '|' +
                       ISNULL(SUBSTRING(CONVERT(varchar, a.IngresoRefrigerio, 114), 1, 8), '') + '|' +
                       ISNULL(SUBSTRING(CONVERT(varchar, a.HoraSalida, 114), 1, 8), '') + '|' +
                       CONVERT(varchar, a.NroMarcacion) + '|' +
                       CASE WHEN a.Estado = 'T' THEN 'TARDANZA' ELSE 'ASISTIO' END + '|' +
                       CASE
                           WHEN CONVERT(time, a.IngresoRefrigerio) > DATEADD(minute, 60, CONVERT(time, a.SalidaRefrigerio)) THEN 'T'
                           ELSE 'A'
                       END + '|' + CONVERT(varchar, a.NroTardanza)
                FROM dbo.Asistencia AS a
                INNER JOIN dbo.Personal AS p ON p.PersonalId = a.PersonalId
                INNER JOIN dbo.Usuarios AS u ON u.PersonalId = p.PersonalId
                WHERE a.Fecha >= @Data
                  AND a.Fecha < DATEADD(day, 1, @Data)
                ORDER BY a.Id DESC
                FOR XML PATH('')
            ), 1, 1, '')
        ), '~') AS Resultado;
END;
GO

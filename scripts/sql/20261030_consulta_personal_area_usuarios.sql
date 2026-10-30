-- Referencia de la consulta de lectura usada por el listado de usuarios.
-- La API filtra los IDs de personal de la página con parámetros; no requiere
-- crear ni alterar objetos SQL. Sustituir el ID para una consulta individual.
DECLARE @PersonalId int = NULL;

SELECT p.PersonalId,
       LTRIM(RTRIM(ISNULL(p.PersonalNombres, '') + ' ' + ISNULL(p.PersonalApellidos, ''))) AS Nombre,
       a.AreaNombre AS Area
FROM dbo.Personal p
LEFT JOIN dbo.Area a ON a.AreaId = p.AreaId
WHERE p.PersonalId = @PersonalId;

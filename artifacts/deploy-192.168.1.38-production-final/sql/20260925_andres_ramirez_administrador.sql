/* Andrés Scot Ramírez Calla (UsuarioID 2): acceso total como administrador. */
UPDATE dbo.Usuarios
SET Administrador = 1
WHERE UsuarioID = 2
  AND UsuarioAlias = 'andre'
  AND UsuarioEstado = 'ACTIVO';

IF @@ROWCOUNT = 0
    PRINT 'El usuario ya tenía privilegios de administrador o no coincide con el usuario esperado.';
ELSE
    PRINT 'Privilegios de administrador confirmados para Andrés Ramírez.';

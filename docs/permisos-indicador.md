# Permisos en `Indicador`

El backend obtiene el contexto del usuario autenticado desde `Usuarios` y `Personal`: usuario, compañía, área y condición de administrador. Como la base actual puede devolver los identificadores numéricos como `decimal`, el repositorio los normaliza antes de crear el token.

El token de sesión incluye `userId`, `companiaId`, `areaId` e `isAdmin`. Para usuarios administradores, `isAdmin = 1` concede acceso total. Para los demás usuarios, `dbo.usp_PermisoIndicador` resuelve los permisos efectivos en `dbo.Indicador`.

Los endpoints de permisos requieren sesión autenticada. La administración de perfiles está permitida para administradores y para quien posea `CONFIGURACION.PERMISOS`; por eso el perfil completo de Gerencia y Administración puede gestionarlos sin elevar a todos sus usuarios como administradores.

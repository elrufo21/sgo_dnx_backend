# Permisos en `Indicador`

El backend obtiene el contexto del usuario autenticado desde `Usuarios` y `Personal`: usuario, compañía, área y condición de administrador. Como la base actual puede devolver los identificadores numéricos como `decimal`, el repositorio los normaliza antes de crear el token.

El token de sesión incluye `userId`, `companiaId`, `areaId` e `isAdmin`. Para usuarios administradores, `isAdmin = 1` concede acceso total. Para los demás usuarios, `dbo.usp_PermisoIndicador` resuelve los permisos efectivos en `dbo.Indicador`.

Los endpoints de permisos requieren sesión autenticada. La administración de perfiles está permitida para administradores y para quien posea `CONFIGURACION.PERMISOS`; por eso el perfil completo de Gerencia y Administración puede gestionarlos sin elevar a todos sus usuarios como administradores.

Las excepciones individuales pueden ser heredadas, permitidas o denegadas y se conservan al cambiar de área en la misma compañía. Para detalles, compatibilidad y orden de instalación ver `sgo_dnx_frontend/docs/permisos-area-usuario.md` y el script `scripts/sql/20261104_permisos_herencia.sql`. Los usuarios deben volver a iniciar sesión después de cambios de área o permisos para actualizar el contexto del menú.

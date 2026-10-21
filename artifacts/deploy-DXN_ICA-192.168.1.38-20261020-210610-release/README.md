# Actualización DXN_ICA

Este paquete actualiza el frontend y la API para la instalación DXN_ICA en la LAN.

- Frontend: http://192.168.1.38:8080/login
- API base: http://192.168.1.38:8081/api/v1
- Base de datos prevista: DXN_ICA
- API: ASP.NET Core framework-dependent para Windows x64, .NET 7. No cambiar el runtime de la instalación.

## Aplicación

1. Respaldar las carpetas actuales del sitio web, la API, la extensión y el agente de impresión.
2. Copiar el contenido de `web/` al sitio configurado para el puerto 8080 y `api/` al sitio configurado para el puerto 8081.
3. Conservar el `api/appsettings.json` que ya está en el servidor. El ZIP no incluye ese archivo para evitar reemplazar la conexión a DXN_ICA ni sus secretos. `configuration/appsettings.template.json` es solo una referencia para revisar valores; no copiarlo encima de la configuración existente.
4. Actualizar `extension/` y `print-agent/` solo si forman parte de la instalación. Conservar la configuración local del agente y verificar que su token coincida con el de la web.
5. Reiniciar el grupo de aplicaciones de la API y verificar el frontend, el preflight CORS y el inicio de sesión.

Este paquete no se desplegó y no modificó la base de datos.

## Scripts SQL incluidos

La carpeta `sql/` contiene los cuatro parches incrementales de hoy. No son un instalador completo. El responsable de SQL debe revisar el estado de DXN_ICA, respaldar y decidir su ejecución en el orden indicado en `sql/ORDEN_DXN_ICA.txt`.

El script de indicadores no borra filas ni modifica `ValorTexto1`, `ValorNum` o `ValorDecimal`; normaliza metadatos (`Area`, `TipoIndicador` e `IdIndicador`) después de validar duplicados y relaciones. Si detecta duplicados, aborta sin aplicar cambios. No ejecutarlo si la validación previa no es aceptable para el responsable de la BD.

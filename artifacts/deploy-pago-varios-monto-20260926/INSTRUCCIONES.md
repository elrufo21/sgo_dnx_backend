# Actualización: monto de Pago Varios

Este paquete corrige la lectura de montos como `1,234.56` en el listado de documentos pendientes de **Pago Varios**. La API ahora responde el importe numérico correcto.

## Despliegue

1. Detén el sitio o el pool de aplicaciones del backend en IIS.
2. Copia el contenido de `api` sobre la carpeta publicada de la API, sin copiar ni reemplazar `appsettings.json`.
3. Inicia nuevamente el sitio o pool de aplicaciones.
4. Copia el contenido de `web` sobre la carpeta publicada del frontend.
5. En Pago Varios, abre nuevamente el modal y verifica el documento afectado.

No requiere cambios ni scripts SQL.

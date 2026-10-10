# API: ingresos correctos y listado de Caja optimizado

Paquete solo de backend para IIS Windows x64 (.NET 7).

## Cambios

- Las cajas cerradas muestran **Ingresos** calculados como monto inicial + OBS + IOC - salidas + ingresos manuales, igual que el detalle, aunque el campo histórico `CajaIngresos` esté en cero.
- El cálculo de ingresos y diferencia agrupa los datos por caja en una consulta, evitando repetir agregaciones correlacionadas.
- Las cajas abiertas mantienen el valor persistido.

## Despliegue

1. Respaldar la carpeta actual de la API.
2. Detener el sitio o Application Pool de IIS.
3. Copiar el contenido de `api/` a la raíz física del sitio de la API, reemplazando los archivos.
4. Conservar los `appsettings*.json` y variables de entorno ya configurados en el servidor; no se incluyen en este paquete.
5. Iniciar el Application Pool y revisar el listado y detalle de Control de flujo de caja.

No requiere cambios en la web ni ejecutar scripts SQL.

## Verificación

La publicación Release compiló correctamente. La consulta fue optimizada estructuralmente, pero no se midió contra la base de producción.

# Optimizacion de listados: Caja y Facturas de servicio

## Proposito y alcance

Reducir el trabajo SQL previo a mostrar una pagina, manteniendo las reglas de negocio. El aumento de timeouts anterior no era una optimizacion: esta entrega lo reemplaza por consultas acotadas y paginacion real. Conserva .NET 7 y usa sintaxis SQL Server 2008 R2.

## Caja

Antes, la API ejecutaba `listarCajaFechaWEB`/`listarCajaWEB`, descargaba todas las cajas del rango y hacia otra consulta SQL para calcular diferencias. El procedimiento de rango convertia la columna de fecha a texto; el mensual aplicaba MONTH/YEAR sobre la columna. Los importes se formateaban como texto y luego se convertian otra vez a numeros.

Ahora `dbo.uspListarControlCajaWeb` compara directamente el rango sobre CajaFecha, materializa IDs filtrados y la pagina solicitada. Monedas, NotaPedido/TABLAOBS y CajaDetalle se agrupan exclusivamente para las cajas cerradas de esa pagina. La API lee metadatos y resultados de un solo comando. Se conserva el diferencial documentado en [flujo de calculos](../../sgo_dnx_frontend/docs/flujo-caja-calculos.md).

El GET sin `page` sigue devolviendo array para compatibilidad. La web nueva siempre manda pagina y tamano; una recarga posterior a guardar conserva los filtros aplicados.

## Facturas de servicio

Antes, el listado mezclaba agrupacion general de cabeceras/detalles, OUTER APPLY de notas de credito y filtros opcionales antes de devolver una pagina. El store solo solicitaba pagina 1 y ordenaba otra vez por ID, perdiendo el orden por emision.

Ahora `dbo.uspListarFacturasServicioWeb` separa el conjunto inicial de facturas del modo pendientes OSE. Clasifica los servicios antes de paginar y conserva los criterios SERVICIO, FACTURA_SERVICIO_OSE y detalles ZZ/productos segun la regla anterior. Los filtros de la consulta inicial usan OPTION(RECOMPILE) para simplificar condiciones opcionales con los parametros actuales. El recuento y la seleccion de pagina usan el mismo conjunto temporal de candidatos.

Tras materializar #Pagina, se cuentan detalles solo para esos IDs. Las referencias a NC se normalizan una vez en una temporal, solo si la pagina contiene anulados; dos joins indexados y UNION sustituyen el OR correlacionado por factura. Se conserva la preferencia por ENVIADO y mayor DocuId. Cliente y CPE se unen al final, usando la unicidad de DocumentoVentaCpeWeb.DocuId del esquema web.

La fecha final incluye el dia completo. El JSON agrega totalRows. Despacho OSE sigue consumiendo el mismo endpoint y exportando su conjunto completo; una pagina fallida no se trata como una pagina vacia correcta.

## Frontend compartido

Se reutiliza DataTable con su paginacion remota existente y una propiedad opcional manualFiltering, desactivada por defecto. Asi una busqueda remota no desactiva la paginacion ni vuelve a filtrar solo las filas descargadas. Las tablas existentes conservan su comportamiento local.

Caja y Facturas solicitan 50 filas inicialmente y aplican busqueda remota por palabras con espera de 300 ms. El helper createLatestRequest comparte una peticion identica en curso, cancela la anterior al cambiar parametros y permite ignorar resultados tardios incluso si la cancelacion no llega a tiempo al servidor. No introduce cache de datos financieros.

El comando SQL limita la espera a 15 segundos y el cliente a 20; los errores son visibles. Estos limites son protecciones, no objetivos de latencia ni una mejora de rendimiento por si mismos.

## SQL, aplicacion y reversion

Los archivos completos y el orden estan en [20261020_optimizacion_listados/README.md](../scripts/sql/20261020_optimizacion_listados/README.md). Aplicar indices y los dos procedimientos antes de publicar juntos API/frontend. No se ejecutaron scripts en ICA ni COMAS. La entrega no cambia tablas, Indicador ni estados de documentos. Los procedimientos anteriores quedan disponibles para el escritorio.

## Verificacion realizada

- Backend compilado con .NET 7 en salida temporal para no detener la API activa.
- SQL analizado con TSql100Parser sin conectar a una BD; destinos de DML limitados a temporales y columnas contrastadas con snapshots locales.
- Tests de los stores reales con transporte simulado: peticiones identicas, cancelacion, respuestas fuera de orden, metadatos, orden de filas y errores.
- Render de DataTable en modo local/remoto para verificar que la busqueda remota no oculte resultados del servidor.
- Build Vite del frontend en carpeta temporal. El typecheck completo sigue mostrando errores preexistentes en otros modulos; las rutas modificadas no reportan errores.

No se ejecutaron los procedimientos en una BD real y no se midio rendimiento en produccion. Los indices estan fundamentados en los filtros y joins del codigo, no en un plan real capturado del servidor.

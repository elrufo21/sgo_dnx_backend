# Informe de caja final

Módulo independiente de la apertura/cierre individual de `Caja`. Replica el cierre final del escritorio: arqueo por denominación, Sistema OBS, ingresos, salidas y diferencial.

El API está en `CierreCajaFinalController`. Lee los procedimientos existentes del escritorio y registra mediante `uspInsertarConteoCajaWEB`, un adaptador que delega a `uspInsertarConteoCaja` sin modificarlo. Los datos se conservan en `ConteoMonedas`, `DetalleConteo` y `Monedas`; no crea tablas nuevas.

La lectura replica el escritorio: de `usptraerCajeros` se usa solo el primer bloque y `uspTraeTodasMonedas` se interpreta como filas de monedas (sin cabeceras).

`GET /api/v1/CierreCajaFinal/{id}` usa `usplistaDetalleConteo` para recuperar un informe registrado. Es solo lectura y no modifica procedimientos ni datos existentes.

`GET /api/v1/CierreCajaFinal` recibe `fechaInicio` y `fechaFin` (`YYYY-MM-DD`) para listar informes dentro de ese rango inclusivo. Rechaza rangos donde la fecha inicial sea posterior a la final.

Al registrar un informe nuevo, el API verifica con `usplistaConteo` que no exista otro informe para esa fecha y valida la fecha con `uspValidarApertura`. Si el procedimiento devuelve `PAGO/VARIOS`, no registra el informe hasta que esos documentos se liquiden. La edición de un informe existente no ejecuta esas validaciones, igual que el flujo de edición del escritorio.

`POST /api/v1/Correo/enviar-informe-caja-final` recibe el PDF generado en el frontend y lo remite a los correos administrativos de la compañía del usuario que registró el informe. No crea ni modifica objetos de base de datos.

Antes de usarlo se debe ejecutar [20260831_informe_caja_final_web.sql](../scripts/sql/20260831_informe_caja_final_web.sql). Solo crea los adaptadores web del informe final.

El mismo script crea `uspEditarConteoCajaWEB`, que delega en el procedimiento de edición del escritorio sin modificarlo. El candado del informe habilita esa edición y al volver a bloquear descarta los cambios no guardados.

Al crear un informe, el procedimiento heredado devuelve su identificador numérico (por ejemplo, `98`), no la palabra `true`. El API reconoce ese identificador como éxito y lo devuelve como `id`; registrar el informe no abre, cierra ni modifica una `Caja`.

# Anulación de boletas y facturas

## Propósito

Evitar anulaciones fuera del plazo permitido antes de alterar inventario, caja o enviar una nota de crédito a SUNAT/OSE.

## Reglas

- El plazo se cuenta desde el día posterior a la emisión, excluyendo solo los domingos. Los sábados cuentan y el día de emisión también está permitido.
- Boleta (`TipoCodigo = 03`): puede anularse hasta dos días contados sin domingos después de la emisión, inclusive. Si se emitió el 01/09/2026, se permite hasta el 03/09/2026 y se bloquea desde el 04/09/2026. Si se emitió el viernes 04/09/2026, se permite hasta el lunes 07/09/2026.
- Factura (`TipoCodigo = 01`): puede anularse hasta seis días contados sin domingos después de la emisión, inclusive. Si se emitió el 01/09/2026, se permite hasta el 08/09/2026 y se bloquea desde el 09/09/2026 porque el domingo 06/09 no cuenta.
- Por compañía, `dbo.Indicador` permite configurar `DIAS_ANULACION_BOLETA` (2 por defecto), `DIAS_ANULACION_FACTURA` (6 por defecto) y `ANULACION_EXCLUIR_DOMINGOS` (1 por defecto; 0 incluye domingos). Los plazos admiten valores de 0 a 365 días; 0 permite solo el día de emisión. Si faltan indicadores o la tabla, se mantienen los valores predeterminados.
- Pago/Varios y las liquidaciones no bloquean la anulación.
- La reposición de stock no depende de `NotaEntrega` ni de que sea `INMEDIATA`; se aplica para cada detalle inventariable (`AplicaINV = S`).

## Alcance y uso

Las reglas se aplican en el backend a los endpoints `POST /api/v1/Nota/boleta/anular-individual`, `POST /api/v1/Nota/factura/anular-individual` y `POST /api/v1/Nota/anular-documento`. El backend lee los indicadores de la compañía del documento en cada intento, por lo que una actualización de `ValorNum` se aplica sin reiniciar la API. `POST /api/v1/Nota/anular/validar` devuelve si el plazo permite anular y la pantalla de venta oculta el botón **Anular** cuando el resultado es negativo. Las validaciones individuales se ejecutan antes de comunicarse con SUNAT/OSE. La ruta heredada comprueba el plazo antes de invocar el procedimiento de anulación local.

Las Proformas V envían el documento, nota y detalles a `POST /api/v1/Nota/anular-documento`. El backend invoca el procedimiento almacenado existente `dbo.anularDocumento`, igual que el escritorio. El procedimiento conserva los registros, marca `DocumentoVenta.DocuEstado` y `NotaPedido.NotaEstado` como `ANULADO`, gestiona caja y repone stock según la entrega. Los demás documentos continúan con su flujo de anulación vigente.

Al anular una boleta o proforma de mercadería emitida el mismo día, se elimina su movimiento automático de `CajaDetalle`. La anulación individual toma el concepto desde `NotaPedido.NotaConcepto`, que es el dato que usa el escritorio para aplicar esta regla. De ese modo una boleta anulada el mismo día deja de incrementar el efectivo de caja.

Cuando una regla bloquea la operación, la API devuelve `ok = false` y un mensaje explicativo. Los endpoints individuales responden `409 Conflict`; el endpoint heredado responde `400 Bad Request` con el mensaje devuelto por la capa de persistencia.

La comprobación mínima se ejecuta con `dotnet run --project scripts/verificar-reglas-anulacion/VerificarReglasAnulacion.csproj` desde la carpeta del backend.

## Configuración

Ejecutar [20260922_configurar_anulacion_indicador.sql](../scripts/sql/20260922_configurar_anulacion_indicador.sql) para crear los indicadores de cada compañía. Para cambiar un valor, actualizar `ValorNum` y `FechaActualizacion` del registro con el `CompaniaId` y la `Descripcion` deseados. Por ejemplo, `UPDATE dbo.Indicador SET ValorNum = 3, FechaActualizacion = SYSDATETIME() WHERE CompaniaId = 1 AND Descripcion = 'DIAS_ANULACION_BOLETA';` establece tres días para las boletas de la compañía 1. El flag de domingos acepta solo 0 o 1.

# Anulación de boletas y facturas

## Propósito

Evitar anulaciones fuera del plazo permitido antes de alterar inventario, caja o enviar una nota de crédito a SUNAT/OSE.

## Reglas

- La fecha de emisión cuenta como el primer día.
- Boleta (`TipoCodigo = 03`): se permite durante dos días calendario. Una boleta emitida el 20 puede anularse el 20 y 21; desde el 22 se bloquea.
- Factura (`TipoCodigo = 01`): se permite durante seis días calendario. Una factura emitida el 20 puede anularse hasta el 25; desde el 26 se bloquea.
- Pago/Varios y las liquidaciones no bloquean la anulación.
- La reposición de stock no depende de `NotaEntrega` ni de que sea `INMEDIATA`; se aplica para cada detalle inventariable (`AplicaINV = S`).

## Alcance y uso

Las reglas se aplican en el backend a los endpoints `POST /api/v1/Nota/boleta/anular-individual`, `POST /api/v1/Nota/factura/anular-individual` y `POST /api/v1/Nota/anular-documento`. Las validaciones individuales se ejecutan antes de comunicarse con SUNAT/OSE y la anulación local vuelve a comprobarlas dentro de la transacción.

Las Proformas V envían el documento, nota y detalles a `POST /api/v1/Nota/anular-documento`. El backend invoca el procedimiento almacenado existente `dbo.anularDocumento`, igual que el escritorio. El procedimiento conserva los registros, marca `DocumentoVenta.DocuEstado` y `NotaPedido.NotaEstado` como `ANULADO`, gestiona caja y repone stock según la entrega. Los demás documentos continúan con su flujo de anulación vigente.

Cuando una regla bloquea la operación, la API devuelve `ok = false` y un mensaje explicativo. Los endpoints individuales responden `409 Conflict`; el endpoint heredado responde `400 Bad Request` con el mensaje devuelto por la capa de persistencia.

La comprobación mínima se ejecuta con `dotnet run --project scripts/verificar-reglas-anulacion/VerificarReglasAnulacion.csproj` desde la carpeta del backend.

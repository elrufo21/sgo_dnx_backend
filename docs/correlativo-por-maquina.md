# Correlativo de ventas por máquina

## Objetivo

Las boletas y facturas creadas desde la web usan la serie configurada para la computadora que emite el documento, igual que el aplicativo de escritorio.

## Flujo

1. El agente local DNX responde el nombre de Windows en `GET /v1/system`.
2. La pantalla envía ese valor como `maquina` a `GET /api/v1/Nota/correlativo`.
3. La API busca `MAQUINAS.Maquina` sin distinguir mayúsculas y toma `SerieBoleta` o `SerieFactura` según el documento.
4. La API calcula la vista previa usando los documentos de la misma compañía, documento y serie.
5. Al guardar mediante `POST /api/v1/Nota/crearOrden`, la API vuelve a resolver la serie; ignora la serie enviada por el navegador. `uspinsertarNotaBweb` genera el número definitivo.

## Operación

Registrar cada PC en Mantenimiento > Máquinas con el mismo nombre que devuelve el agente. La serie de boleta y factura debe ser única. Si falta el agente o la configuración, la emisión se bloquea deliberadamente para evitar utilizar una serie equivocada.

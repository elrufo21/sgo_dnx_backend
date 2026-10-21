# Ajustes SQL para producción — 2026-10-20

Paquete incremental para SQL Server 2008 R2. No ejecutar scripts de instalación o migración completa junto con esta entrega.

## Parches de procedimientos

Ejecutar en la base de datos de producción correspondiente, solo si el procedimiento aún no tiene el cambio:

1. `01_uspListaDocumentosWEB_excluir_hoy.sql`
   Actualiza únicamente `dbo.uspListaDocumentosWEB`. Las boletas emitidas en la fecha actual no se incluyen en el resumen hasta el día siguiente. No modifica filas de documentos.
2. `02_usp_Maquina_permitir_series_repetidas.sql`
   Actualiza únicamente `dbo.usp_Maquina`. Permite que varias máquinas compartan series de factura, nota de crédito y boleta; el nombre de máquina sigue validándose como único. No modifica filas de máquinas.
3. `03_maquinas_permitir_impresora_repetida.sql`
   Elimina únicamente un índice o constraint UNIQUE cuya única columna clave sea `dbo.MAQUINAS.Tiketera`, si existe. Conserva la unicidad del nombre de máquina, las series y cualquier índice compuesto. Ejecutar solo si la BD tiene ese índice; devuelve las restricciones simples que sigan presentes.

Estos parches presuponen que existen las tablas y columnas que utilizan los procedimientos. Revisar primero el estado del procedimiento e índices en cada base (por ejemplo, ICA y COMAS) y aplicar solo donde falte el cambio.

## Script de configuración separado

`revisar_estado/normalizar_indicadores_configuracion.sql` actualiza metadatos de `dbo.Indicador` para opciones de configuración y conserva los valores de configuración. No ejecutarlo si ya fue aplicado en esa base. Revisar el resultado y el estado de cada base antes de decidir si hace falta.

## Ejecución en DXNCOMASWEB

El 2026-10-20, por solicitud expresa, se procesaron los cuatro scripts del paquete en la instancia local `DESKTOP-B6B71UA\SQLEXPRESS01`, base `DXNCOMASWEB`:

- `01_uspListaDocumentosWEB_excluir_hoy.sql`: aplicado; definición verificada.
- `02_usp_Maquina_permitir_series_repetidas.sql`: aplicado; definición verificada.
- `03_maquinas_permitir_impresora_repetida.sql`: ejecutado; no encontró índices ni restricciones UNIQUE de `Tiketera`, así que no hizo cambios.
- `revisar_estado/normalizar_indicadores_configuracion.sql`: ejecutado, pero abortó antes de iniciar la transacción de cambios porque encontró 11 descripciones duplicadas para `CompaniaId = 1`. No modificó filas. Resolver esos duplicados requiere revisar cuál registro conservar; no borrar ni combinar valores automáticamente.

Esta ejecución fue únicamente en la instancia local indicada, no en `SERVER-NEW` ni en la base `DXNCOMAS`. Las definiciones anteriores de los dos procedimientos aplicados están en `artifacts/entregas/rollback_DXNCOMASWEB_20261020/`.

## Fuera de alcance

No incluye restauraciones, creación de tablas, migraciones completas ni el script base de `uspListaDocumentosWEB` con ICBPER. No ejecutar los paquetes completos de DXNCOMAS para aplicar estos dos parches.

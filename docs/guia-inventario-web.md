# Guía del inventario permanente valorizado en la web

Actualizado el 10 de noviembre de 2026.

## Qué problema resolvimos

El proceso de escritorio requería cargar Kardex desde ventas y compras con `IngresarKardex.sql`, reunir ICA y COMAS en `InformeKardex` con `KardexUnion.sql` y después exportar a Excel. En la web, **Exportar seleccionados** integra esos pasos para el período y los productos elegidos. El reproceso se calcula durante la consulta y el resultado se entrega en un ZIP con un Excel por producto que tenga movimientos.

## Cómo se usa

1. Entra en **Contabilidad → Inventario permanente valorizado**.
2. Indica la fecha inicial y la fecha final del reporte.
3. Si corresponde, ingresa el **Último INV** de cada producto y presiona Enter o sal de la celda para guardarlo. El campo vacío y el valor cero usan saldo inicial cero en el Excel. Si borras un valor guardado, se actualiza a cero.
4. Marca los productos mediante sus casillas y pulsa **Exportar seleccionados**. El Excel incluye 22 columnas en la hoja **Kardex**. La pantalla avisa cuando un producto seleccionado se omite por falta de movimientos.

El saldo inicial se guarda por **código base y fecha inicial**. Por ejemplo, para `FB007` con fecha inicial **01/11/2026**, cambiar la fecha final conserva ese saldo. Cambiar la fecha inicial recupera el saldo guardado para la nueva fecha. **Stock vigente** muestra el stock del código local sin prefijo. Es un dato de consulta distinto del saldo inicial.

## Cómo se genera el Excel

- La API recibe los productos y el rango en una sola solicitud. Lee los documentos de ventas y compras una vez por sede en las bases configuradas de COMAS e ICA.
- Agrupa el código base con las variantes que empiezan con `191`, `201`, `211`, `221`, `231`, `241` y `251`. El prefijo `181` queda como código separado.
- Aplica las reglas de los SQL originales. Las compras tipo `01` generan entradas y las ventas emitidas con SUNAT enviado o pendiente y total distinto de cero generan salidas. El consolidado incluye productos con sublínea y excluye las notas de crédito. Calcula el costo del detalle dividiéndolo entre **1.18** y redondeándolo a dos decimales. El rango histórico definido por esos scripts es **2020–2026**.
- Ordena los movimientos por día y sede, con COMAS antes de ICA. Dentro de cada sede usa la fecha, el origen y el detalle como criterios de orden. Calcula el saldo de cada fila con **saldo anterior + entradas − salidas**, y el saldo valorizado multiplicando el saldo por el costo unitario de esa fila.

El Kardex reconstruido se usa para el Excel. El flujo conserva las tablas operativas `Kardex` e `InformeKardex` y guarda el saldo inicial en su propia tabla.

## Los dos SQL del flujo principal

| Archivo | Cuándo se usa |
| --- | --- |
| `20261110_inventario_saldo_inicial.sql` | El administrador lo ejecuta una vez en la base principal si falta `dbo.InventarioSaldoInicial`. En la copia `DXNCOMAS0611` ya está creada con la estructura actual. Si existe una versión antigua con `FechaFin`, el administrador debe revisar sus datos antes de migrarla. |
| `20261110_inventario_reprocesar_reporte.sql` | Se incluye como recurso del backend. La API lo ejecuta automáticamente en cada sede con los códigos y fechas elegidos. |

El ZIP de entrega contiene estos dos archivos sin comentarios. Para usar el flujo, el backend debe estar actualizado y tener configuradas las dos bases y acceso de lectura a sus documentos. La base principal necesita acceso a `InventarioSaldoInicial` para consultar y guardar los saldos.

Para consultar los movimientos manualmente en SQL Server Management Studio, abre la [versión para SSMS](../artifacts/20261111_inventario_reprocesar_reporte_ssms.sql) y selecciona la base de la sede. Edita `@Codigos` (XML con un elemento `<codigo>` por producto), `@Desde` y `@Hasta` (fechas en formato `AAAAMMDD`). Ejecuta el archivo completo en un mismo bloque para que la consulta tenga acceso a los parámetros. Devuelve los movimientos de esa sede y las fechas disponibles en sus documentos. La web reúne las dos sedes y genera el Excel.

## Qué validamos y cómo interpretar los avisos

En `DXNCOMAS0611` y `DXN_ICA0611` comparamos **334 movimientos** del reproceso web con una ejecución temporal de los dos SQL originales. Coincidieron movimientos, cantidades y costos. La muestra incluye FB007 y FB124 del 1 al 6 de noviembre y movimientos de ventas y compras del 30 de septiembre de 2026. Comprobamos además los saldos en los Excel generados para la muestra de noviembre.

Queda pendiente cotejar un Excel real del escritorio con el de la web usando el mismo período, los mismos productos y el mismo saldo inicial. El SQL antiguo podía dejar en distinto orden los movimientos con la misma fecha, lo que puede cambiar la posición de algunas filas y sus saldos intermedios.

Las dos copias tenían documentos hasta el **6 de noviembre de 2026** durante la validación. Si eliges una fecha final posterior, el aviso indica que el reporte cubre los movimientos disponibles en las copias. Para reportar hasta una fecha posterior, usa bases actualizadas que incluyan esos días.

Más detalles sobre permisos, configuración y las consultas de revisión en [Inventario permanente valorizado web](inventario-permanente-valorizado.md).

# SQL para inventario valorizado y Kardex

Comparación de solo lectura realizada el 20/11/2026 en `localhost\SQLEXPRESS01`, base `DXNCOMAS1111`.

## Procedimientos

`01_seis_procedimientos_kardex.sql` contiene las seis definiciones preparadas el 09/11/2026 para detener sus escrituras directas en Kardex. Los procedimientos de `DXNCOMAS1111` coinciden con las definiciones originales de las que partieron esos cambios al comparar tokens sin comentarios y sin distinguir mayúsculas. Los seis conservaban operaciones directas sobre Kardex al momento de la revisión.

El archivo contiene `anularDocumentoWEB`, `editarProductoWEB`, `ingresarProductoWEB`, `uspGuardarListaPreciosPdfWEB`, `uspinsertarNC` y `uspinsertarNotaBweb`. Seleccionar explícitamente `DXNCOMAS1111` en SQL Server Management Studio antes de una eventual aplicación. `uspinsertarNC` puede ser compartido por el escritorio y el cambio también afecta sus escrituras de Kardex.

## Saldos iniciales

`02_tabla_saldos_iniciales.sql` crea la tabla en la base principal del backend si aún no existe. En `DXNCOMAS1111` ya existe con las columnas y clave primaria esperadas, y tenía cero filas en esta revisión. Si la API usa otra base principal, revisar esa base antes de usar el script. El script se detiene si detecta la versión anterior con `FechaFin`.

## Consulta para el Excel

La consulta de reproceso forma parte del backend y recibe sus parámetros de la aplicación. Su fuente es `scripts/sql/20261110_inventario_reprocesar_reporte.sql` y la API consulta cada sede configurada. El período de los movimientos está limitado por la consulta a los años 2020 a 2026.

La revisión de ICA se limitó a comprobar que los seis procedimientos existen y tienen referencias a Kardex en `DXN_ICA0611`. No se compararon íntegramente sus definiciones con las de COMAS. No se ejecutaron cambios en bases de datos ni se validaron operaciones funcionales de negocio durante esta revisión.

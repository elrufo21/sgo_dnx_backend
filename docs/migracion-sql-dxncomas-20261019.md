# Paquete SQL de migración web para DXNCOMAS

Estos scripts preparan en `DXNCOMAS` los objetos requeridos por los flujos que el frontend actual alcanza y llama. La selección sigue la cadena frontend → endpoint → backend → SQL documentada en [el análisis de alcance](analisis-dxncomas-migracion-web-20261018.md); no toma todos los objetos que quedaron en el backend.

## Archivos y orden

1. `scripts/sql/dxncomas-20261019/01_tablas_dxncomas.sql`: crea `dbo.Indicador` y `dbo.DocumentoVentaCpeWeb`, con sus claves, relaciones e índices. Incluye las 20 columnas de esas dos tablas.
2. `scripts/sql/dxncomas-20261019/02_columnas_dxncomas.sql`: agrega 14 columnas faltantes a tablas existentes. `NotaPedido.Hora` y `NotaPedido.Almacen` son complementarias; la web comprueba si existen antes de usarlas.
3. `scripts/sql/dxncomas-20261019/03_procedimientos_dxncomas.sql`: instala 43 procedimientos definidos en `DXN_ICA15102026` y ausentes en `DXNCOMAS`, filtrados por llamadas alcanzables desde el frontend.

Ejecutar cada archivo en ese orden, conectado al servidor que aloja `DXNCOMAS`. Los archivos seleccionan esa base explícitamente y se pueden volver a ejecutar: las tablas/columnas/índices se verifican antes de crear y los procedimientos usan `CREATE OR ALTER` (SQL Server 2016 SP1 o posterior).

## Exclusiones solicitadas

El archivo de procedimientos **no contiene** estos diez procedimientos que la web llama pero faltan en ambas copias:

- `uspEliminarCategoria`
- `uspEliminarProducto`
- `uspEliminarProveedor`
- `uspGuardarUnidadMedidaProducto`
- `uspInsertarCategoria`
- `uspInsertarCuentaProveedor`
- `uspInsertarProveedor`
- `uspInsertarUsuario`
- `uspListaDocumentosWEB`
- `uspListarComprasweb`

Tampoco instala objetos que solo aparecen en el backend sin consumidor actual, ni crea `BLOQUE`, `DetalleBloque`, `Stock` o `RentaMensual`. `uspCruzeOBS` ya existe en COMAS; su diferencia de definición queda para revisión aparte y no se reemplaza automáticamente.

## Datos y compatibilidad

El paquete contiene estructura y definiciones SQL, no transfiere datos de ICA, indicadores, series, credenciales, certificados ni archivos. Después de crear `Indicador`, inicializar sus valores con configuración propia de COMAS y revisar las series/correlativos y las rutas de archivos CPE.

Si el sistema de escritorio seguirá usando esta base, antes de agregar columnas hay que revisar los seis procedimientos antiguos que usan `INSERT ... VALUES` sin lista de columnas: `ingresarProducto`, `ingresarUsuario`, `InsertarUM`, `uspinsertarNotaB`, `uspInsertarPagoVarios` y `uspinsertarRB`. Las columnas nuevas cambian el número de valores que esos INSERT deben proporcionar. El análisis está en `artifacts/analisis-dxncomas-20261018/inserts_posicionales_a_revisar.csv`.

El archivo de procedimientos toma las definiciones actuales de ICA, que deben validarse en una copia de ensayo de COMAS junto con las pantallas de la web antes de ponerlas en servicio. Los diez contratos excluidos siguen pendientes y requieren una definición validada o un cambio del backend/frontend que elimine esas llamadas. No se ejecutó ninguno de estos scripts en las bases.

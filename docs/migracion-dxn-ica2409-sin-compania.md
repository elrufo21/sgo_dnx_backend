# Migración de DXN_ICA2409 sin alterar Compania

Fuente comparada: `DXN_ICA`. Destino: `DXN_ICA2409`.

Ejecutar en este orden:

1. `scripts/sql/20260924_estructura_dxn_ica2409_sin_compania.sql`
2. `scripts/sql/20260924_configuracion_compania_indicador.sql`
3. `scripts/sql/20260922_procedimientos_web_produccion.sql`

El primer script crea las tablas, columnas, índices, restricciones y ajustes de tipo necesarios. No contiene operaciones DDL sobre `dbo.Compania`; las relaciones nuevas solo la referencian desde `dbo.Indicador`. También añade `ValorDecimal` a `Indicador`, requerido para `DESCUENTO_MAXIMO`.

El segundo script inicializa, sin sobrescribir valores existentes, la configuración de cada compañía dentro de `dbo.Indicador`: `FECHA_RENOVACION`, `DESCUENTO_MAXIMO`, `CORREO_SGO`, `PASSWORD_CORREO`, `CORREOS_ADMIN`, `TIPO_PROCESO_CPE`, `BOLETA_POR_LOTE`, `CAPTURA_HTML` y `MULTIPLES_CAJAS`.

El segundo script es estático, no consulta otra base y crea o actualiza las variantes WEB y los procedimientos nuevos requeridos. Para conservar el escritorio, los procedimientos existentes que diferían no se sobrescriben: la web llama a sus equivalentes con sufijo `WEB`.

La web, incluidos login, caja, correo y CPE, lee esta configuración desde `dbo.Indicador`. Los valores iniciales son descuento `0`, entorno `3`, boleta por lote `1`, captura `0` y una sola caja por compañía. La migración no agrega, actualiza ni elimina columnas o registros en `dbo.Compania`.

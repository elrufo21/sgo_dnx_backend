# DXNCOMAS: requisitos de la web actual

18 de octubre de 2026. **Informe corregido: el alcance lo determina lo que el frontend llama, no la mera existencia de código en el backend.** Reemplaza la clasificación inicial basada en referencias generales del backend.

No se modificaron bases de datos, código funcional ni conexiones. Se compararon `DXNCOMAS` y `DXN_ICA15102026` de `localhost\SQLEXPRESS01`; esta última es la configurada en `src/Api/appsettings.json`. Se examinó el código del árbol de trabajo local, incluidos cambios previos sin confirmar; no se comprobó la equivalencia con los binarios publicados.

## Criterio aplicado

**Pantalla/componente alcanzable desde la app → acción de store o cliente HTTP consumida → verbo y ruta del endpoint → controlador → repositorio/servicio → procedimiento o consulta SQL → dependencias SQL.**

Se siguieron imports desde `sgo_dnx_frontend/src/main.tsx`, las rutas de React, referencias a acciones de stores y callbacks de las pantallas. Se resolvieron URLs construidas con `API_BASE_URL`, `buildApiUrl`, constantes y condiciones. Los endpoints se emparejaron por verbo y ruta, incluyendo restricciones como `{id:long}`. En el backend se recorrieron métodos, dependencias inyectadas, helpers y filtros de permisos/asistencia.

Se inspeccionaron 188 archivos alcanzables del frontend y 168 sitios de llamadas HTTP. Se identificaron 134 combinaciones distintas de verbo/ruta del backend local. Se separaron diez sitios de llamadas sin consumidores actuales, clientes externos y alternativas heredadas. No quedaron URLs locales sin endpoint resuelto dentro del inventario examinado. Son resultados estáticos del código, no tráfico capturado ni estadísticas de producción.

La evidencia completa está en [web_endpoints_confirmados.csv](../artifacts/analisis-dxncomas-20261018/web_endpoints_confirmados.csv): archivo/línea del frontend, acción, referencias consumidoras, verbo, ruta y método backend. [web_objetos_confirmados.csv](../artifacts/analisis-dxncomas-20261018/web_objetos_confirmados.csv) continúa esa cadena hasta cada objeto SQL.

## Resultado que corresponde migrar

| Concepto | Resultado filtrado por frontend |
| --- | --- |
| Tablas ausentes necesarias | **2:** `Indicador` y `DocumentoVentaCpeWeb`. |
| Procedimientos de ICA ausentes en COMAS | **43:** 42 alcanzados desde endpoints usados y `usp_Feriado`, dependencia de `usp_FeriadoWEB`. |
| Contratos usados por la web ausentes en ambas copias | **10**, identificados individualmente más abajo. |
| Columnas faltantes en tablas existentes | **14 de alineación:** 12 para los contratos incluidos y 2 complementarias cuya ausencia el código tolera. |
| Columnas de las dos tablas nuevas | **20**, incluidas en la definición de las tablas, no veinte ALTER sobre tablas existentes. |
| Cambios de tipo dentro del alcance | Revisar `Producto.ProductoNombre`; su diferencia no demuestra por sí misma un bloqueo. |
| Procedimiento existente distinto dentro del alcance | `uspCruzeOBS`. |

El conteo general de 59 SP y 6 tablas faltantes es inventario entre bases; **no es la lista de instalación de esta web**. Los CSV generales se conservan como comparación técnica, pero el alcance válido es el de los archivos `web_*`.

## Tablas necesarias

| Tabla | Cadena de uso comprobada | Preparación |
| --- | --- | --- |
| `dbo.Indicador` | Login `/User/acceso`; permisos `/Permisos/perfil`; configuración de caja/ventas/facturación/SUNAT; filtros de asistencia, correo y emisión. | Crear con sus 10 columnas, índices, relaciones y CHECK. Inicializar configuraciones con los datos de COMAS. |
| `dbo.DocumentoVentaCpeWeb` | Venta HTML/POS y facturas de servicio → endpoints de `Nota` → consultas directas y `uspinsertarNotaBweb`; consulta/sincronización de archivos CPE. | Crear con sus 10 columnas; definir el llenado de información histórica de COMAS cuando corresponda. |

**Fuera del paquete web:** `BLOQUE`, `DetalleBloque`, `Stock` y `RentaMensual`. Están en ICA pero no se encontró la cadena de frontend que justifique crearlas para esta migración.

Conservar `GuiaInterna` y `DetalleInterna`, exclusivas de COMAS. El objetivo no es eliminar objetos de COMAS para igualar las bases.

## Columnas de tablas existentes

| Tabla | Columnas de referencia | Uso desde la web |
| --- | --- | --- |
| `DetallePVarios` | `Efectivo decimal(18,2) NULL`, `Deposito decimal(18,2) NULL` | Venta HTML → `/Nota/pago-varios` y detalle/eliminación → SQL de pagos y variantes WEB. |
| `MAQUINAS` | `Registro datetime NULL`, `SerieBoleta nvarchar(4) NULL`, `Tiketera varchar(300) NULL` | Computadoras → `/Maquina/list` y `/Maquina/registermaquina` → `usp_Maquina`; emisión por máquina. |
| `NotaPedido` | `Entrega varchar(20) NULL` | Anulación desde venta HTML/POS → `/Nota/anular-documento` → variante WEB y sus dependencias. |
| `Producto` | `UltimoINV decimal(18,2) NULL`, `ProductoVentaB decimal(18,2) NULL`, `AplicaINV varchar(1) NULL` | Formulario/importación de productos, facturas de servicios y detalle → SQL directo o variantes WEB. |
| `ResumenBoletas` | `CDRBase64 varchar(max) NULL` | Resúmenes → envío/consulta/fecha → procedimientos WEB y consulta del CDR. |
| `UnidadMedida` | `unidadImagen varchar(255) NULL` | `ProductFormBase` → `POST /Productos/unidad-medida` → contrato de `uspGuardarUnidadMedidaProducto`. |
| `Usuarios` | `FechaVencimientoClave date NULL` | Login y mantenimiento → `uspValidaUsuarioweb` y `usp_Usuario`. |

Las otras dos columnas son `NotaPedido.Almacen varchar(80) NULL` y `NotaPedido.Hora datetime NULL`. `NotaPedidoRepository.ActualizarCamposRegistroAsync` comprueba su existencia antes de actualizarlas: **son complementarias; no se presentan como bloqueos obligatorios**.

`UnidadMedida.unidadImagen` se sustenta además en la definición SQL de `sgo_dnx_frontend/docs/uspGuardarUnidadMedidaProducto.sql`, porque el SP llamado no está instalado en las copias. Es evidencia de contrato pendiente, no prueba de ejecución del SP en estas bases. Revisar longitud admitida para imágenes antes de instalarlo.

La evidencia por columna está en [web_columnas_con_trazabilidad.csv](../artifacts/analisis-dxncomas-20261018/web_columnas_con_trazabilidad.csv). Incluye las 20 columnas de las dos tablas nuevas.

**No incluir por simple paridad** los cambios de `DetalleGuiaLiquida.Idproducto` ni `TipoComprobante.TipoCodigo`: no aparecen en la cadena de esta web. Para `Producto.ProductoNombre`, COMAS tiene `varchar(300)` e ICA `varchar(max)`; evaluar la longitud admitida por formularios/importación antes de decidir ampliarlo.

No llenar indiscriminadamente las nuevas columnas de producto: COMAS ya tiene `ProductoINV`, `ProductoVenta` y precios en `UnidadMedida`; se necesita conservar el significado de sus datos.

## Procedimientos requeridos

Los 43 de ICA abarcan login/permisos, ventas/notas, resúmenes, credenciales CPE, PDT, caja/apertura/movimientos, arqueo/informe final, pagos varios, mantenimientos y reporte de asistencia.

La [matriz individual de procedimientos faltantes](../artifacts/analisis-dxncomas-20261018/web_procedimientos_faltantes.md) muestra **cada uno de los 43 y los diez contratos adicionales**, con endpoint, archivo/línea frontend y evidencia SQL. Los procedimientos existentes alcanzados por esas cadenas también están en el CSV de objetos; los del resto de la aplicación anterior no se incorporan al paquete.

### Diez contratos ausentes en ambas copias que sí llama el frontend

Estos diez se mantienen porque tienen una cadena actual comprobada. Los otros ocho nombres del análisis inicial se retiran como requisitos.

| Procedimiento | Cadena actual |
| --- | --- |
| `uspListaDocumentosWEB` | `boletasSummary.store.ts:999` → `POST /Nota/lista-documentos` → `NotaPedidoRepository.ListarDocumentosAsync`. Script candidato: `scripts/sql/20261016_uspListaDocumentosWEB_icbper.sql`. |
| `uspListarComprasweb` | `shopping.store.ts:266` y `PdtCompanyPage.tsx:703` → `GET /Compra/list` → `CompraRepository.ListarCrudAsync`. Script candidato: `scripts/sql/20260825_uspListarComprasweb.sql`. |
| `uspGuardarUnidadMedidaProducto` | `ProductFormBase.tsx:1329` → `POST /Productos/unidad-medida` → `ProductoRepository.GuardarUnidadMedidaProductoAsync`. Definición candidata: `sgo_dnx_frontend/docs/uspGuardarUnidadMedidaProducto.sql`. |
| `uspInsertarCategoria` | `categories.api.ts:93` / acciones usadas por `ProductFormBase` → `POST /Linea/registerlinea` → `LineaRepository.InsertarAsync`. |
| `uspEliminarCategoria` | `categories.api.ts:130` → `DELETE /Linea/maintenance/{id}` → `EliminarMantenimientoAsync` → `EliminarAsync`. Quitar la ruta antigua `/Linea/{id}` no elimina esta dependencia. |
| `uspInsertarProveedor` | `maintenance.store.ts:665,776` → `POST /Proveedor/register` → `ProveedorRepository.InsertarAsync`. |
| `uspEliminarProveedor` | `maintenance.store.ts:865` → `DELETE /Proveedor/{id}` → `ProveedorRepository.EliminarAsync`. |
| `uspInsertarCuentaProveedor` | `sendProviderAccounts`, usado por alta/edición de proveedor → `POST /Proveedor/registerCuenta` → `CuentaProveedorRepository.InsertarAsync`. |
| `uspEliminarProducto` | `products.store.ts:667` → `DELETE /Productos/{id}` → `ProductoRepository.EliminarAsync`. |
| `uspInsertarUsuario` | **`MainLayout.tsx:465` llama `updateUser`** → `users.store.ts:248` → `PUT /UsuariosCrud/{id}` → `EditarAsync` → `EjecutarUpsertAsync`. La edición desde ese modal lo necesita aunque el alta antigua no se use. |

Para los otros siete contratos se localizaron definiciones históricas individuales en `scripts/sql/bdactual.sql`. Se extrajo únicamente cada definición llamada, sin incorporar los demás objetos de ese archivo. Las fuentes exactas están en [web_definiciones_candidatas.csv](../artifacts/analisis-dxncomas-20261018/web_definiciones_candidatas.csv).

Estos contratos deben cubrirse con definiciones revisadas o cambios coordinados de la ruta realmente utilizada. Instalar un procedimiento con nombre parecido no resuelve automáticamente el contrato; encontrar una definición histórica tampoco la valida para producción. Tampoco se deduce que fallen en producción: el servidor publicado puede usar otra compilación o copia de BD.

## Qué se retira del alcance anterior

| Objeto/ruta | Motivo comprobado |
| --- | --- |
| `uspObtenerCajaActivaWEB` | `getActiveCashFlow` está en el store, pero no tiene consumidores; ninguna pantalla actual llama `GET /CashFlow/active/{usuarioId}`. |
| `uspRetornaBoletaPorTicketWEB` | El método del repositorio no es llamado por la cadena actual de consulta. El flujo sí llama `uspRetornarBoletasWEB`, que se mantiene. |
| `uspObtenerNotaPedido` | `fetchNoteDetail` contiene `/Nota/sp/{id}`, pero ninguna pantalla consume esa acción. La mera presencia de la URL en el store no lo convierte en requisito. |
| `uspIngresarPersonal`, `uspEliminarPersonal` | Altas/ediciones antiguas sin consumidores y eliminación antigua referida solo por una entrada de registro no instanciada. Las pantallas usan `/Personal/maintenance/...` → `usp_Personal`. |
| `uspEliminarUsuario` | `deleteUser` no tiene consumidores; el listado usa eliminación de mantenimiento → `usp_Usuario`. |
| `uspListaWebProducto`, `uspBuscaWebProducto` | `/Productos/listaPro` y `/Productos/buscaPro` no son llamados por esta web. |
| `uspListarProducto` | SP opcional: se captura su ausencia y se consulta la tabla directamente. No se exige crearlo. |
| `uspIngresarProducto` | Alternativa heredada cuando faltan `ingresarProductoWEB`/`editarProductoWEB`; no se requiere si se instala el contrato principal. |
| `BLOQUE`, `DetalleBloque`, `Stock`, `RentaMensual` | Sin cadena frontend dentro del alcance. |
| Cambios de tipo en `DetalleGuiaLiquida` y `TipoComprobante` | Diferencias generales, sin uso web que justifique modificarlas. |

La entrada `employees` de `listRegistry` no equivale a una pantalla activa: ninguna ruta instancia `GenericList` con `moduleKey` igual a `employees`. La ruta real usa `EmployeeListPage` y acciones de mantenimiento. `Personal/list` sí sigue usado por `UserFormBase`, pero esa lectura es SQL directo y no obliga a crear los SP antiguos de alta/eliminación.

Ver [web_llamadas_excluidas.csv](../artifacts/analisis-dxncomas-20261018/web_llamadas_excluidas.csv), [web_endpoints_sin_llamada.csv](../artifacts/analisis-dxncomas-20261018/web_endpoints_sin_llamada.csv) y [web_alternativas_no_obligatorias.csv](../artifacts/analisis-dxncomas-20261018/web_alternativas_no_obligatorias.csv).

## SQL directo y particularidades de la web

Clientes, depósitos, caja chica, captura OBS, ciertos reportes y parte de facturas de servicio usan SQL directo. Se conservaron esas dependencias aunque no tengan SP propio. Los filtros de asistencia y permisos también forman parte de la cadena del endpoint utilizado.

`Indicador` debe inicializarse con datos de COMAS: asistencia/caja, días de depósito, lote/captura, descuentos, renovaciones, CPE, correo, SUNAT/SIRE y permisos de sus áreas/usuarios. No copiar registros, IDs de áreas, certificados, credenciales ni series de ICA. Las fechas de renovación pueden copiarse desde `Compania` de COMAS sin eliminar sus columnas.

El perfilado detectó una máquina sin `SerieFactura`; además falta `SerieBoleta`. El frontend resuelve máquina y correlativos al emitir, así que esta preparación pertenece al alcance. Validar series y correlativos contra el historial de COMAS.

`GET /CashFlow/ventas-no-capturadas` llega a `uspCruzeOBS`, que difiere: ICA compara `FechaTransaccion = @Fecha`; COMAS convierte a texto y compara fechas. Es el único SP existente con diferencia de definición dentro del alcance filtrado. Revisar ese ajuste puntualmente, sin sobrescribir los otros diez SP distintos que quedaron fuera.

Filtrando índices y relaciones por tablas alcanzadas, quedan siete definiciones de índices sin equivalente de ICA en COMAS, cuatro FK y un CHECK. Incluyen PK/índices de las dos tablas nuevas, índices de documentos y relaciones de compras/`DetallesPVS`. Ver [web_indices_y_restricciones.csv](../artifacts/analisis-dxncomas-20261018/web_indices_y_restricciones.csv). Evaluar equivalencia y utilidad; por ejemplo, el índice no único de `DocumentoVentaCpeWeb.DocuId` puede solaparse con su PK.

La web actual también tiene una llamada a un backend externo: `ServiceInvoiceCreate.tsx:794` envía correo a `https://www.api-sgo.somee.com/api/v1/Correo/enviar-comprobante`. No se atribuye ese acceso a la BD local de COMAS. Revisar ese destino para el despliegue de la empresa; no se cambió. Consultas externas de DNI/RUC y agente de impresión tampoco agregan requisitos SQL de la app anterior.

## Orden de migración para este alcance

1. Preparar una copia de ensayo de COMAS y definir si seguirá usándose el escritorio.
2. Crear las dos tablas e incorporar las columnas adoptadas. Mantener fuera las cuatro tablas y cambios de tipo descartados.
3. Instalar los 43 procedimientos identificados de referencia y resolver los diez contratos adicionales. Aplicar índices/relaciones adoptados y revisar `uspCruzeOBS`.
4. Inicializar indicadores de COMAS, series, correlativos y almacenamiento de imágenes/XML/CDR/PDF.
5. Probar las pantallas de la matriz: login/permisos, mantenimientos, ventas, notas, pagos varios, caja/cierre, asistencia, OBS, resúmenes/CDR, PDT y SIRE.

Si el escritorio coexistirá, revisar los seis INSERT posicionales de `inserts_posicionales_a_revisar.csv` antes de ampliar sus tablas. Es compatibilidad por cambiar un esquema compartido; **no convierte esos procedimientos antiguos en procesos usados por la web**. Conservar sus reglas de COMAS al pasar a columnas explícitas.

Los scripts históricos del repo no son un instalador de COMAS: algunos tienen `USE` hacia ICA u otra copia y otros eliminan columnas. Este trabajo entrega diagnóstico y SQL de consulta; no ejecuta la migración.

## Archivos y reproducción

Todos los resultados están en `artifacts/analisis-dxncomas-20261018`:

- [web_endpoints_confirmados.csv](../artifacts/analisis-dxncomas-20261018/web_endpoints_confirmados.csv): frontend → HTTP → controlador.
- [web_objetos_confirmados.csv](../artifacts/analisis-dxncomas-20261018/web_objetos_confirmados.csv): endpoint → SQL y dependencias.
- [web_procedimientos_faltantes.md](../artifacts/analisis-dxncomas-20261018/web_procedimientos_faltantes.md): los 53 contratos faltantes, con evidencia individual.
- [web_columnas_con_trazabilidad.csv](../artifacts/analisis-dxncomas-20261018/web_columnas_con_trazabilidad.csv): columnas filtradas y clasificación.
- [diagnostico_solo_lectura.sql](../artifacts/analisis-dxncomas-20261018/diagnostico_solo_lectura.sql): consulta de existencia exclusivamente de objetos del alcance frontend.
- `web_metodos_alcanzados.csv`, `web_resumen.json`, exclusiones y alternativas: trazabilidad y comprobaciones.
- JSON de metadatos y CSV generales: inventario comparativo; no son por sí solos una lista de migración.

Desde la raíz del workspace, con Node/TypeScript del frontend, Python y SDK .NET 9:

```powershell
& ./sgo_dnx_backend/scripts/analizar-dxncomas/exportar.ps1
python ./sgo_dnx_backend/scripts/analizar-dxncomas/comparar.py
node ./sgo_dnx_backend/scripts/analizar-dxncomas/trazar-frontend.cjs
dotnet run --project ./sgo_dnx_backend/scripts/analizar-dxncomas/trazar-backend/Trazar.csproj -- 'C:/Users/User/Desktop/desarrollo_dnx/sgo_dnx_backend' 'C:/Users/User/Desktop/desarrollo_dnx/sgo_dnx_backend/artifacts/analisis-dxncomas-20261018/backend_metodos.json'
python ./sgo_dnx_backend/scripts/analizar-dxncomas/trazar_web.py
sqlcmd -S 'localhost\SQLEXPRESS01' -E -d master -b -i ./sgo_dnx_backend/artifacts/analisis-dxncomas-20261018/diagnostico_solo_lectura.sql
```

`comparar.py` genera el SQL general como `diagnostico_inventario_solo_lectura.sql`; `trazar_web.py` genera `diagnostico_solo_lectura.sql` con el filtro frontend. Las exclusiones manuales de acciones sin consumidores y la entrada no instanciada de `listRegistry` están explícitas en `trazar_web.py`; revisarlas si cambian las pantallas.

Se ejecutaron extractores AST, recorrido de métodos con comprobaciones internas y SQL filtrado con `sqlcmd -b`. No se inició la API, no se ejecutaron procedimientos de negocio y no se emitieron documentos. La inferencia estática incluye ramas condicionales del endpoint usado y contratos candidatos pendientes de instalar; validar en la copia de ensayo. No garantiza frecuencia de uso ni equivalencia con los binarios publicados.

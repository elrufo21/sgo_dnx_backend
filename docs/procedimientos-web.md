# Procedimientos usados por la web

El script `scripts/sql/20260922_procedimientos_web_produccion.sql` contiene las definiciones estáticas requeridas por la migración web. Es el archivo para producción. `scripts/sql/20260922_procedimientos_solo_web.sql` queda como alternativa que toma las definiciones desde `DXN_ICA`.

`listaNotaPedidoWEB` es exclusivo de la API y conserva intacto `dbo.listaNotaPedido` para el escritorio. El script estático y el paquete `scripts/sql/dxncomas-20261019/03_procedimientos_dxncomas.sql` ya lo definen con `ConceptoOBS`. Si se usa el script dinámico `20260922_procedimientos_solo_web.sql`, aplicar después `scripts/sql/20261026_listaNotaPedido_web.sql` para agregar ese campo. El responsable SQL debe verificar que el usuario de la API tenga permiso `EXECUTE` sobre el nuevo procedimiento antes de actualizar la API.

Después de instalar uno de esos dos archivos, ejecutar `scripts/sql/20261014_reparar_parser_uspinsertarNotaBweb.sql`, `scripts/sql/20261009_validar_arqueo_caja_web.sql`, `scripts/sql/20261009_validar_pago_varios_informe_caja_web.sql`, `scripts/sql/20261009_feriado_motivo_repetido_web.sql`, `scripts/sql/20261014_configurar_validacion_asistencia_indicador.sql` y `scripts/sql/20261016_uspListaDocumentosWEB_icbper.sql`. El reparador completa el parser de cabecera sin reemplazar el resto de `uspinsertarNotaBweb`; los otros scripts agregan variantes web sin alterar procedimientos del escritorio y configuran indicadores.

Ejecutar el archivo estático después de los scripts de estructura y configuración de `Indicador`. Apunta explícitamente a `DXN_ICA2409`, no consulta otra base, no modifica tablas ni datos de negocio y valida que se instalen los 55 objetos. Los procedimientos compartidos que difieren se crean como variantes `WEB`; los originales quedan intactos para el escritorio. Las variantes web leen `MULTIPLES_CAJAS`, `TIPO_PROCESO_CPE`, `DESCUENTO_MAXIMO`, `BOLETA_POR_LOTE` y `CAPTURA_HTML` desde `dbo.Indicador`.

| Original del escritorio | Variante usada por web |
| --- | --- |
| `uspEliminarCajaDetalle` | `uspEliminarCajaDetalleWEB` |
| `uspEliminarPagoV` | `uspEliminarPagoVWEB` |
| `uspInsertarConteoCaja` | `uspInsertarConteoCajaWEB` |
| `uspInsertarPagoVarios` | `uspInsertarPagoVariosWEB` |
| `usplistarPagoVarios` | `usplistarPagoVariosWEB` |
| `usptraerCajeros` | `usptraerCajerosWEB` |
| `uspTraerGastos` | `uspTraerGastosWEB` |
| `uspTraerGastosA` | `uspTraerGastosAWEB` |
| `uspTraeTodasMonedas` | `uspTraeTodasMonedasWEB` |
| `uspValidarApertura` | `uspValidarAperturaWEB` |

También se separan como variantes WEB: `anularDocumento`, `editarCompania`, `editarProducto`, `ingresarProducto`, `listarCaja`, `listarCajaFecha`, `listarDetaCaja`, `uspGuardarListaPreciosPdf`, `usplistaConteo`, `usplistaDetalleConteo`, `uspListaDocumentosWEB`, `uspRetornaBoletaPorTicket` y `uspRetornarBoletas`.

| Módulo web | Procedimientos incluidos |
| --- | --- |
| Login | `uspValidaUsuarioweb` |
| Ventas, pagos y resúmenes | `uspinsertarNotaBweb`, `uspEditarNotaPedido`, `listaNotaPedidoWEB`, `LDdocumentosweb`, `anularDocumento`, `uspListaDocumentosWEB`, `uspInsertarPagoVariosWEB`, `usplistarPagoVariosWEB`, `uspEliminarPagoVWEB`, `uspinsertarRBweb`, `uspEditarRBweb`, `uspResumenFechaweb`, `usptraerSecuenciaResumen`, `uspRetornaBoletaPorTicket`, `uspRetornarBoletas` |
| Caja y cierre | `listarCaja`, `listarCajaFecha`, `listarDetaCaja`, `uspObtenerCajaActivaWEB`, `uspValidaCantCajasWeb`, `uspCajaInsertaCsvWeb`, `uspValidarArqueoCajaWEB`, `uspValidarPagoVariosCajaFinalWEB`, `uspTraerGastosAWEB`, `uspEliminarCajaDetalleWEB`, `uspTraerGastosWEB`, `uspTraeTodasMonedasWEB`, `usptraerCajerosWEB`, `usplistaConteo`, `usplistaDetalleConteo`, `uspInsertarConteoCajaWEB`, `uspEditarConteoCajaWEB`, `uspValidarAperturaWEB` |
| Mantenimientos | `usp_Area`, `usp_Feriado`, `usp_FeriadoWEB`, `usp_Maquina`, `usp_Personal`, `usp_Usuario`, `editarCompania`, `ingresarProducto`, `editarProducto`, `uspGuardarListaPreciosPdf`, `uspListarComprasweb` |
| Configuración CPE | `uspObtenerCredencialesSunatweb`, `uspGuardarCredencialesSunatweb` |

Se excluyen `uspValidaUsuario`, `uspinsertarNotaB` y cualquier otro procedimiento del escritorio. También se excluyen procedimientos que el backend conserva como código heredado pero no existen en `DXN_ICA` o no son invocados por las rutas web actuales.

`uspListaDocumentosWEB` se instala con la definición estática de producción y puede aplicarse de forma independiente mediante `scripts/sql/20261016_uspListaDocumentosWEB_icbper.sql`. La variante reemplaza el listado web que antes invocaba `uspListaDocumentos` y serializa `ICBPER` nulo como cero para conservar todas las filas.

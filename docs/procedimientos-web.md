# Procedimientos usados por la web

El script `scripts/sql/20260922_procedimientos_web_produccion.sql` contiene las definiciones estáticas requeridas por la migración web. Es el archivo para producción. `scripts/sql/20260922_procedimientos_solo_web.sql` queda como alternativa que toma las definiciones desde `DXN_ICA`.

Después de instalar uno de esos dos archivos, ejecutar `scripts/sql/20261009_validar_arqueo_caja_web.sql`, `scripts/sql/20261009_validar_pago_varios_informe_caja_web.sql` y `scripts/sql/20261009_feriado_motivo_repetido_web.sql`. Estos agregan variantes web sin alterar procedimientos del escritorio.

Ejecutar el archivo estático después de los scripts de estructura y configuración de `Indicador`. Apunta explícitamente a `DXN_ICA2409`, no consulta otra base, no modifica tablas ni datos de negocio y valida que se instalen los 54 objetos. Los procedimientos compartidos que difieren se crean como variantes `WEB`; los originales quedan intactos para el escritorio. Las variantes web leen `MULTIPLES_CAJAS`, `TIPO_PROCESO_CPE`, `DESCUENTO_MAXIMO`, `BOLETA_POR_LOTE` y `CAPTURA_HTML` desde `dbo.Indicador`.

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

También se separan como variantes WEB: `anularDocumento`, `editarCompania`, `editarProducto`, `ingresarProducto`, `listarCaja`, `listarCajaFecha`, `listarDetaCaja`, `uspGuardarListaPreciosPdf`, `usplistaConteo`, `usplistaDetalleConteo`, `uspRetornaBoletaPorTicket` y `uspRetornarBoletas`.

| Módulo web | Procedimientos incluidos |
| --- | --- |
| Login | `uspValidaUsuarioweb` |
| Ventas, pagos y resúmenes | `uspinsertarNotaBweb`, `uspEditarNotaPedido`, `listaNotaPedido`, `LDdocumentosweb`, `anularDocumento`, `uspInsertarPagoVariosWEB`, `usplistarPagoVariosWEB`, `uspEliminarPagoVWEB`, `uspinsertarRBweb`, `uspEditarRBweb`, `uspResumenFechaweb`, `usptraerSecuenciaResumen`, `uspRetornaBoletaPorTicket`, `uspRetornarBoletas` |
| Caja y cierre | `listarCaja`, `listarCajaFecha`, `listarDetaCaja`, `uspObtenerCajaActivaWEB`, `uspValidaCantCajasWeb`, `uspCajaInsertaCsvWeb`, `uspValidarArqueoCajaWEB`, `uspValidarPagoVariosCajaFinalWEB`, `uspTraerGastosAWEB`, `uspEliminarCajaDetalleWEB`, `uspTraerGastosWEB`, `uspTraeTodasMonedasWEB`, `usptraerCajerosWEB`, `usplistaConteo`, `usplistaDetalleConteo`, `uspInsertarConteoCajaWEB`, `uspEditarConteoCajaWEB`, `uspValidarAperturaWEB` |
| Mantenimientos | `usp_Area`, `usp_Feriado`, `usp_FeriadoWEB`, `usp_Maquina`, `usp_Personal`, `usp_Usuario`, `editarCompania`, `ingresarProducto`, `editarProducto`, `uspGuardarListaPreciosPdf`, `uspListarComprasweb` |
| Configuración CPE | `uspObtenerCredencialesSunatweb`, `uspGuardarCredencialesSunatweb` |

Se excluyen `uspValidaUsuario`, `uspinsertarNotaB` y cualquier otro procedimiento del escritorio. También se excluyen procedimientos que el backend conserva como código heredado pero no existen en `DXN_ICA` o no son invocados por las rutas web actuales.

# Procedimientos usados por la web

El script `scripts/sql/20260922_procedimientos_web_produccion.sql` contiene las definiciones estáticas de los procedimientos alcanzados desde los endpoints activos del frontend. Es el archivo para producción. `scripts/sql/20260922_procedimientos_solo_web.sql` queda como alternativa que toma las definiciones desde `DXN_ICA`.

Ejecutar el archivo estático en la base destino después del script de tablas y columnas. No consulta otra base, no modifica tablas ni datos y valida que se instalen los 43 objetos. Los diez procedimientos compartidos que difieren, incluso solo en definición, se crean como variantes `WEB`; los originales quedan intactos para el escritorio.

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

| Módulo web | Procedimientos incluidos |
| --- | --- |
| Login | `uspValidaUsuarioweb` |
| Ventas, pagos y resúmenes | `uspinsertarNotaBweb`, `uspEditarNotaPedido`, `listaNotaPedido`, `LDdocumentosweb`, `anularDocumento`, `uspInsertarPagoVariosWEB`, `usplistarPagoVariosWEB`, `uspEliminarPagoVWEB`, `uspinsertarRBweb`, `uspEditarRBweb`, `uspResumenFechaweb`, `usptraerSecuenciaResumen`, `uspRetornaBoletaPorTicket`, `uspRetornarBoletas` |
| Caja y cierre | `listarCaja`, `listarCajaFecha`, `listarDetaCaja`, `uspObtenerCajaActivaWEB`, `uspValidaCantCajasWeb`, `uspCajaInsertaCsvWeb`, `uspTraerGastosAWEB`, `uspEliminarCajaDetalleWEB`, `uspTraerGastosWEB`, `uspTraeTodasMonedasWEB`, `usptraerCajerosWEB`, `usplistaConteo`, `usplistaDetalleConteo`, `uspInsertarConteoCajaWEB`, `uspEditarConteoCajaWEB`, `uspValidarAperturaWEB` |
| Mantenimientos | `usp_Area`, `usp_Feriado`, `usp_Maquina`, `usp_Personal`, `usp_Usuario`, `editarCompania`, `ingresarProducto`, `editarProducto`, `uspGuardarListaPreciosPdf`, `uspListarComprasweb` |
| Configuración CPE | `uspObtenerCredencialesSunatweb`, `uspGuardarCredencialesSunatweb` |

Se excluyen `uspValidaUsuario`, `uspinsertarNotaB` y cualquier otro procedimiento del escritorio. También se excluyen procedimientos que el backend conserva como código heredado pero no existen en `DXN_ICA` o no son invocados por las rutas web actuales.

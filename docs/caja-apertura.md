# Apertura de caja

Al abrir una caja, `CajaEncargado` y `CajaUsuario` almacenan el primer nombre y el apellido paterno del responsable seleccionado. La pantalla obtiene ese valor desde la relación `Usuarios`–`Personal` y lo envía en la apertura; el backend conserva el mismo texto en ambos campos.

El almacenamiento del encargado se aplica en el endpoint `POST /api/v1/CashFlow/open`; las cajas ya registradas no se modifican.

La validación del conteo general de efectivo del día anterior aplica cuando la compañía tiene activado **Permitir múltiples cajas abiertas** (`dbo.Indicador`, `Area = 'CAJA'`, `Descripcion = 'MULTIPLES_CAJAS'`, `ValorNum = 1`). Con una sola caja permitida, la API no bloquea la apertura, el cierre ni el cambio de estado por falta de ese conteo. Si la validación aplica y el día anterior es domingo, se revisa el viernes anterior, igual que en el escritorio; si no existe un conteo para esa fecha, la operación se permite cuando la fecha está registrada en `Feriados`, y en caso contrario la API responde que falta registrar el conteo. La regla de conteo la aplica `uspValidarArqueoCajaWEB`, una variante exclusiva de la web; los procedimientos existentes del escritorio no se modifican. El script para instalarla es `scripts/sql/20261009_validar_arqueo_caja_web.sql` y se ejecuta después de `20260922_procedimientos_web_produccion.sql`.

Las operaciones de escritura en los módulos de Caja requieren además que el usuario autenticado haya marcado asistencia hoy. El alcance y los módulos cubiertos están en [validación de asistencia en Caja](validacion-asistencia-modulos-caja.md).

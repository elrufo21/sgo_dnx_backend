# Depósitos principales de centros (web)

## Propósito y alcance

La pantalla web `Depósitos centros` registra y consulta los movimientos de `dbo.DepositosCentro`, con el registro de escritorio como referencia visual. Se integra en Caja y no modifica `Caja`, `CajaDetalle` ni las ventas.

Incluye búsqueda por rango de fechas y por texto en la tabla, resumen de cantidad e importe, alta con comprobante, consulta del comprobante, reemplazo del comprobante en registros existentes y eliminación confirmada. Al seleccionar un registro, sus datos quedan de solo lectura: el escritorio solo actualiza `RutaImagen`, así que la web conserva ese mismo límite. Los registros nuevos conservan el valor inicial `Estado = 'P'`; la pantalla no expone el estado porque el significado de los códigos existentes aún no está confirmado.

La pantalla también muestra la validación histórica del escritorio: cuenta todos los registros de `DepositosCentro` entre hoy menos `DiasMaxDep` y hoy, incluidos todos sus estados. La pantalla informa si el conteo es cero y cuántos registros están pendientes; no bloquea operaciones porque el punto exacto donde el escritorio aplica el resultado no está documentado.

## Uso

1. Abrir **Caja → Depósitos centros**.
2. Buscar por fechas; la primera carga muestra el mes actual. La búsqueda de la tabla filtra movimiento, entidad, operación, descripción y usuario.
3. Registrar movimiento, entidad/operación cuando corresponda, descripción, importe e imagen. Se aceptan JPG, PNG y WEBP hasta 5 MB.
4. Seleccionar una fila para consultar sus datos o adjuntar/reemplazar su comprobante. Los datos financieros existentes no se editan desde esta pantalla.
5. Eliminar requiere confirmación y permiso de gestión; elimina el registro y la imagen local asociada.

## API y acceso

- `GET /api/v1/DepositosCentro?desde=YYYY-MM-DD&hasta=YYYY-MM-DD`: lista registros y acepta `buscar` opcional.
- `POST /api/v1/DepositosCentro` (multipart): el identificador `0` crea; un identificador positivo solo actualiza la ruta de la imagen. El alta y la actualización requieren imagen.
- `DELETE /api/v1/DepositosCentro/{id}`: elimina un registro.
- `GET /api/v1/DepositosCentro/validacion`: devuelve la ventana de días por compañía, el total de registros del rango, pendientes y el booleano de validación.
- La consulta requiere `CAJA.VER`. Escritura y eliminación requieren además `CAJA.GESTIONAR`.

El backend valida movimiento, importe, entidad y duplicidad de número de operación por entidad dentro de una transacción serializable. En los registros nuevos, `Usuario` se obtiene del usuario de la sesión y se guarda como primer nombre más primer apellido de `Personal`; no se acepta ese dato desde el navegador. Las consultas usan parámetros SQL. No se agregan columnas ni procedimientos: la funcionalidad trabaja sobre las columnas existentes de `DepositosCentro`.

## Ventana de validación

`DiasMaxDep` se configura en **Configuración → Caja**, entre 0 y 3650. Su fuente web es `dbo.Indicador` con `Area = 'CAJA'`, `Descripcion = 'DIAS_MAX_DEPOSITO'`, `TipoIndicador = 2` y `ValorNum`. El script `scripts/sql/20260929_migrar_dias_max_deposito_a_indicador.sql` copia el valor actual de cada compañía (7 como valor por defecto). La columna `Compania.DiasMaxDep` se conserva sincronizada para el login del escritorio legado.

## Imágenes existentes

Las imágenes nuevas se guardan bajo `/media/depositos-centro/` en el almacenamiento local configurado para la API. Las rutas UNC del escritorio (por ejemplo `\\servidor\ArchivoSistema\ImagenesDepoCentros\...`) no son servidas por la web; el registro se muestra, pero su imagen requiere migración o acceso de almacenamiento compartido para visualizarse.

## Componentes web

La página está en `sgo_dnx_frontend/src/features/cashFlow/pages/DepositosCentroPage.tsx`; las rutas se agregan en `cashFlow/routes.tsx` y al menú Caja. Reutiliza `DataTable`, `HookFormInput`, `HookFormSelect`, `apiRequest`, el diálogo de confirmación y los permisos existentes.

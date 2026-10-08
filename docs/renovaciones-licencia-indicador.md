# Avisos de renovación de licencias

## Propósito

Mostrar al iniciar sesión las fechas próximas de renovación de OSE, firma digital y hosting SOME, y mantener esas fechas en `dbo.Indicador` por compañía.

## Datos

Las fechas usan `ValorTexto1` en formato `yyyy-MM-dd` para los indicadores `RENOVACION_OSE`, `RENOVACION_FIRMA` y `RENOVACION_SOME`, con área `CONFIGURACION` y tipo `3`. El inicio de sesión lee los tres indicadores y devuelve las fechas con una marca que confirma que se cargó la configuración.

Ejecutar [20261007_renovaciones_indicador.sql](../scripts/sql/20261007_renovaciones_indicador.sql) en la base activa de la API antes de publicarla. El script copia fechas existentes de `Compania`, conserva valores ya cargados en `Indicador`, crea los indicadores faltantes para cada compañía y elimina las tres columnas antiguas de `Compania`. El contrato de la API mantiene los campos de renovación al listar/guardar compañías, pero los lee y escribe en `Indicador`.

## Comportamiento del aviso

Al entrar al sistema, se muestra un modal si una fecha vence dentro de siete días o ya venció. El botón **Aceptar** cierra el aviso cuando el vencimiento es futuro. Si alguna licencia vence hoy o está vencida, **Aceptar** cierra la sesión y vuelve al login.

Si el inicio de sesión no encuentra los tres indicadores, la aplicación cierra la sesión para solicitar una nueva carga de datos. La tabla de indicadores conserva los registros aunque una fecha todavía no se haya configurado; esas fechas vacías no generan avisos.

# Publicación CPE en `Indicador`

Este paquete no altera la estructura ni los registros de `dbo.Compania`.

1. Detener el Application Pool del API.
2. En la base `DXN_ICA`, ejecutar `sql\20260924_configuracion_cpe_indicador.sql`.
3. Ejecutar `sql\20260924_procedimientos_cpe_web_indicador.sql`.
4. Reemplazar el contenido publicado del API con la carpeta `api` y reiniciar su Application Pool.
5. Reemplazar el contenido del sitio frontend con la carpeta `web`.

Al guardar el certificado desde Configuración > Facturación, el API guarda su Base64 completo en `Indicador`. Para firmar lo materializa temporalmente en `CPE_PFX_DIRECTORY`. Si esa variable no existe, intenta usar `D:\CPE\FIRMABETA`. El Application Pool del API necesita permiso de modificación sobre esa carpeta.

Los procedimientos modificados son únicamente `uspGuardarCredencialesSunatweb` y `uspObtenerCredencialesSunatweb`; los procedures del escritorio no se modifican.

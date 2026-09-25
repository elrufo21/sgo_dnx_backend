# Credenciales CPE web en `Indicador`

La web no modifica los campos CPE históricos de `dbo.Compania`, porque son utilizados por el aplicativo de escritorio. La configuración de facturación web se guarda por compañía en `dbo.Indicador`.

| Descripción | Valor |
|---|---|
| `CPE_USUARIO_SOL` | Usuario SOL. |
| `CPE_CLAVE_SOL` | Clave SOL. |
| `CPE_CERTIFICADO_PFX` | Contenido completo del archivo `.pfx` o `.p12` codificado en Base64. |
| `CPE_CLAVE_CERTIFICADO` | Clave privada del certificado. |
| `TIPO_PROCESO_CPE` | `1` producción, `2` homologación, `3` beta. |

## Instalación

Ejecutar en `DXN_ICA`, en este orden:

1. `scripts/sql/20260924_configuracion_cpe_indicador.sql`
2. `scripts/sql/20260924_procedimientos_cpe_web_indicador.sql`

El primer script amplía solamente `Indicador.ValorTexto1` a `varchar(max)` y copia valores existentes de `Compania` a `Indicador` cuando el indicador aún no existe; no altera ni actualiza la tabla `Compania`. El segundo sustituye únicamente los dos procedimientos con sufijo `web`.

## Certificado físico

Al registrar un certificado desde Configuración > Facturación, el backend guarda el Base64 completo en `CPE_CERTIFICADO_PFX`. Para firmar, lo materializa temporalmente en `CPE_PFX_DIRECTORY`; si la variable no está configurada, usa `D:\CPE\FIRMABETA`; si no puede crearla, usa `legacy-cpe\FIRMABETA` dentro de la publicación del API.

El usuario del Application Pool del API requiere lectura y escritura sobre esa carpeta. La web no descarga el certificado, ni recibe claves CPE al consultar la configuración.

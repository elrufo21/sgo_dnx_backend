# Configuración de indicadores desde la web

## Alcance

Las pantallas de Configuración editan valores conocidos por la aplicación; no permiten cambiar libremente `Area`, `TipoIndicador`, `Descripcion`, `Id` o `IdIndicador`. El backend determina la compañía desde el claim autenticado y conserva la relación de los indicadores hijos con su categoría.

Las opciones disponibles se agrupan así:

- **Ventas y boletas:** descuento máximo como importe en soles (no porcentaje), días para anular boletas y facturas, y exclusión de domingos.
- **Renovaciones:** fechas de OSE, firma digital y SOME.
- **Correo emisor:** una cuenta Gmail global para los correos del sistema, compartida por las compañías.
- **Facturación:** entorno CPE (BETA, HOMOLOGACIÓN o PRODUCCIÓN), junto con las credenciales y certificado existentes.
- **Caja y boletas:** las pantallas ya existentes mantienen sus flags y destinatarios por compañía.

La edición de ventas requiere `CONFIGURACION.VENTAS_BOLETAS`; renovaciones y facturación requieren `CONFIGURACION.FACTURACION`; el correo emisor global requiere `CONFIGURACION.PERMISOS`.

El descuento máximo se escribe en `ValorDecimal` y se interpreta como un monto en soles por venta, según la validación ya aplicada en el formulario de pagos. Los plazos de anulación se guardan como indicadores numéricos relacionados a la categoría `CONFIGURACION_VENTAS`; el flag de domingos usa `ValorNum` 0/1.

## Correo emisor global

La pantalla **Configuración > Correo emisor** solicita el correo Gmail y su contraseña de aplicación de Google. No debe usarse la contraseña normal de Gmail. Se guardan en `dbo.Indicador` como raíces globales (`CompaniaId IS NULL`, `Area = 'CORREO'`, `TipoIndicador = 3`, `IdIndicador IS NULL`) con las descripciones `SMTP_REMITENTE` y `SMTP_APP_PASSWORD`.

La contraseña se protege con ASP.NET Data Protection antes de guardarla. El API no la devuelve; la pantalla solo recibe si existe. Dejar el campo vacío conserva la clave actual. Si se cambia la cuenta, se debe ingresar la contraseña de aplicación nueva. Si todavía no hay indicadores globales, el API conserva compatibilidad con `EmailSettings` del servidor; cuando se guarda desde la web, los indicadores globales pasan a ser la fuente usada por todos los envíos.

El host Gmail, puerto, SSL y nombre del remitente siguen usando los valores de `EmailSettings` del servidor. El nombre de empresa mostrado en el correo continúa saliendo de los datos de la compañía.

En producción, configurar `DataProtection__KeysPath` con una ruta persistente fuera de la publicación (por ejemplo, `C:\SGO\keys`) y conceder lectura/escritura a la identidad del Application Pool del API. Conservar esa carpeta al publicar y respaldarla: sin el mismo anillo de claves, el API no podrá descifrar la contraseña guardada. No incluir credenciales SMTP en el frontend ni en el paquete de publicación.

## Entorno CPE

`TIPO_PROCESO_CPE` es por compañía y se guarda como `TipoIndicador = 2`, `ValorNum`: `1` producción, `2` homologación y `3` beta. Cambiar el entorno afecta los próximos envíos CPE de esa compañía; no modifica documentos que ya fueron enviados.

## Base de datos

No se requiere crear tablas ni modificar procedimientos almacenados para estas pantallas. Los indicadores globales del correo se crean al guardar por primera vez; los indicadores de compañía conservan la estructura y valores que ya consume la aplicación. El backend valida duplicados en las claves que edita y usa transacciones para guardar juntos los valores relacionados.

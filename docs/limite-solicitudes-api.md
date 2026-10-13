# Límite de solicitudes HTTP

## Propósito

Evitar ráfagas excesivas de solicitudes al backend sin que los usuarios autenticados que comparten una IP pública consuman la misma cuota.

## Alcance y uso

- El limitador global aplica a las solicitudes que continúan hacia la API después de CORS, archivos estáticos y autenticación.
- Las solicitudes autenticadas se agrupan por el claim `userId`; las anónimas usan la IP remota.
- Cada partición conserva el límite actual de 120 solicitudes por minuto y no encola excesos: los rechaza con HTTP 429.
- CORS responde primero a las solicitudes `OPTIONS` preflight, por lo que estas no consumen cuota ni pierden las cabeceras CORS al ser rechazadas.
- Los archivos estáticos se sirven antes del limitador y no consumen la cuota de API.

Revisar los conteos de HTTP 429 y el volumen real por usuario antes de cambiar el límite numérico. En despliegues detrás de proxy, configurar cabeceras reenviadas confiables si las rutas anónimas necesitan particionarse por la IP original.

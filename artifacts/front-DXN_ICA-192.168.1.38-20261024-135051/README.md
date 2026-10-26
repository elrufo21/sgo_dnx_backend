# Frontend DXN_ICA

- Sitio web: http://192.168.1.38:8080
- API compilada: http://192.168.1.38:8081/api/v1/
- Incluye la corrección responsive del modal Pago Varios: formulario desplazable y acciones visibles en escritorio de poca altura.
- Extraer y copiar el contenido de web/ a la raíz del sitio web del destino. Respaldar primero la web actual y recargar con Ctrl+F5.
- Paquete solo frontend. No incluye API, SQL, extensión ni agente. Conservar la configuración del servidor y las estaciones.
- Generado con npm run build:vercel. El build completo sigue bloqueado por los 272 errores TypeScript preexistentes documentados.
- Contiene el token compartido de impresión del frontend; transferir solo a destinos autorizados.
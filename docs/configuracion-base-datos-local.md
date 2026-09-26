# Conexión local a la base de datos

La API local usa la instancia `localhost\SQLEXPRESS01` y la copia de producción `DXN_ICA2509`. La conexión utiliza autenticación integrada de Windows; no se deben guardar usuarios ni contraseñas SQL en el archivo de configuración.

La cuenta de Windows que inicia la API debe tener acceso a `DXN_ICA2509`. Después de cambiar `appsettings.json`, reiniciar la API para que tome la nueva cadena de conexión.

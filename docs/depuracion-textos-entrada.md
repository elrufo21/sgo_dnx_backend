# Depuración de texto de entrada

## Propósito

Permitir que los campos acepten los caracteres `'`, `[`, `]`, `;`, `|`, `¬`, `{` y `}` mientras se escriben, y eliminarlos en el backend antes de que los datos se procesen o persistan.

## Alcance

El frontend deja escribir y pegar estos caracteres; no los elimina al editar los campos. El filtro global `DepurarTextoEntradaFilter` procesa los argumentos de las solicitudes POST, PUT y PATCH antes de ejecutar las acciones de los controladores. Esto incluye los modelos recibidos como JSON y los argumentos `JsonElement` que algunos endpoints procesan manualmente. Las propiedades relacionadas con contraseñas, claves, tokens y secretos se conservan intactas para no cambiar credenciales ni claves de acceso.

Los `JsonElement` opcionales que llegan en estado `Undefined` (por ejemplo, una propiedad omitida en el JSON) se convierten a `null` al depurarse, evitando que la serialización detenga la solicitud antes de ejecutar el controlador.

`EcommerceDbContext` vuelve a depurar todas las propiedades de texto de entidades agregadas o modificadas antes de guardar con Entity Framework, tanto en operaciones síncronas como asíncronas. Se excluyen los hashes y sellos internos de ASP.NET Identity.

## Uso y límites

La limpieza ocurre automáticamente; los controladores y repositorios no necesitan llamarla. Los valores se eliminan del texto, no se rechaza la solicitud. Las propiedades sensibles excluidas y escrituras externas que no pasan por los controladores ni por `EcommerceDbContext` quedan fuera del alcance.

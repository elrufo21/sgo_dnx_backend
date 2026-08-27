# Apertura de caja

Al abrir una caja, `CajaEncargado` y `CajaUsuario` almacenan el primer nombre y el apellido paterno del responsable seleccionado. El backend obtiene este dato desde la relación `Usuarios`–`Personal` usando `UsuarioId`, por lo que no depende del alias ni del texto enviado por la pantalla.

La regla se aplica en el endpoint `POST /api/v1/CashFlow/open`; las cajas ya registradas no se modifican.

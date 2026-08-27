# Apertura de caja

Al abrir una caja, `CajaEncargado` y `CajaUsuario` almacenan el primer nombre y el apellido paterno del responsable seleccionado. La pantalla obtiene ese valor desde la relación `Usuarios`–`Personal` y lo envía en la apertura; el backend conserva el mismo texto en ambos campos.

La regla se aplica en el endpoint `POST /api/v1/CashFlow/open`; las cajas ya registradas no se modifican.

# Apertura de caja

Al abrir una caja, `CajaEncargado` y `CajaUsuario` almacenan el mismo nombre completo del responsable seleccionado. Esto evita guardar el alias del usuario en `CajaUsuario`.

La regla se aplica en el endpoint `POST /api/v1/CashFlow/open`; las cajas ya registradas no se modifican.

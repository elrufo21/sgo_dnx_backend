# Permisos fijos de usuarios

Las altas y ediciones realizadas desde mantenimiento envían siempre `1` para envío de boleta, factura, nota de crédito, nota de débito y administrador. El repositorio aplica los mismos valores antes de ejecutar `dbo.usp_Usuario`, por lo que no dependen de campos ocultos ni de clientes externos.

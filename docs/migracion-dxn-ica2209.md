# Migración completa de DXN_ICA2209

El script `scripts/sql/20260922_migrar_dxn_ica2209_a_dxn_ica_completo.sql` adapta la estructura de una base virgen `DXN_ICA2209` a la versión vigente de `DXN_ICA`, inventariada el 22 de septiembre de 2026.

Incluye las tablas, columnas, defaults, restricciones, índices, claves foráneas y procedimientos almacenados que difieren. Es autocontenido: durante su ejecución no consulta `DXN_ICA` ni `DXN_CUSCO_D2108`.

No mueve datos de negocio. Antes de reducir un tipo de datos valida que no se vaya a truncar información; si encuentra incompatibilidades, revierte toda la ejecución y muestra el motivo.

Ejecutar el archivo completo en SSMS contra la instancia que contiene `DXN_ICA2209`. El script abre una transacción y confirma únicamente si todas las validaciones y objetos se aplican correctamente.

Para instalar únicamente la estructura añadida, sin procedimientos ni ajustes de objetos existentes, usar `scripts/sql/20260922_tablas_y_columnas_nuevas_dxn_ica2209.sql`. Incluye las dos tablas nuevas, las 23 columnas nuevas en tablas existentes y las claves e índices propios de `Indicador`.

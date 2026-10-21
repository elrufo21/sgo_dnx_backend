# Actualización DXNCOMAS

Paquete completo de actualización para COMAS. No usar en DXN_ICA.

- Frontend: http://192.168.18.47:8080/login
- API base: http://192.168.18.47:8081/api/v1
- Base de datos: DXNCOMAS
- API: ASP.NET Core framework-dependent para Windows x64, .NET 7.

## Aplicar el build

1. En el servidor, respaldar `C:\SGO\web`, `C:\SGO\api`, `C:\SGO\extension` y `C:\SGO\print-agent`.
2. Extraer el ZIP en una carpeta temporal y copiar el contenido de `web/` sobre `C:\SGO\web` y el contenido de `api/` sobre `C:\SGO\api`. No borrar directorios ni datos persistentes.
3. El ZIP omite `api/appsettings.json`. Conservar la configuración que ya existe en `C:\SGO\api\appsettings.json`; no copiar encima `configuration/appsettings.template.json`, pues es solo una referencia y no contiene credenciales reales.
4. Actualizar `extension/` y `print-agent/` del servidor solo si esa instalación los usa. Para impresión, instalar el agente en cada estación con impresora y cargar la extensión de producción en su navegador.
5. Reiniciar el Application Pool `SGO API` y verificar frontend, API, preflight CORS e inicio de sesión.

Este build no fue desplegado. No se ejecutó ni modificó SQL.

## SQL incluido

`sql/` contiene los cuatro parches incrementales del 2026-10-20, no un instalador. El responsable SQL debe revisarlos, respaldar y decidir su aplicación por separado en DXNCOMAS; ver `sql/ORDEN_DXNCOMAS.txt`.

El parche de indicadores no borra filas ni altera `ValorTexto1`, `ValorNum` o `ValorDecimal`. Solo normaliza `Area`, `TipoIndicador` e `IdIndicador`, tras validar duplicados y relaciones; si detecta inconsistencias, aborta antes de aplicar cambios.

## Instalación en PCs

En cada PC que imprime, instala Node.js 20 o superior y copia `print-agent/` a una ruta fija. Desde esa carpeta, en PowerShell ejecuta `npm.cmd ci`; luego abre PowerShell como administrador y ejecuta `powershell -ExecutionPolicy Bypass -File .\install-service.ps1`. Verifica con `Get-Service DNXPrintAgent` y `Invoke-WebRequest http://127.0.0.1:5174/health`.

En Brave abre `brave://extensions`; en Chrome abre `chrome://extensions`. Activa el modo desarrollador y usa **Cargar descomprimida**, seleccionando `extension/`. Instala ambas piezas desde este mismo paquete para conservar origen y token de COMAS.

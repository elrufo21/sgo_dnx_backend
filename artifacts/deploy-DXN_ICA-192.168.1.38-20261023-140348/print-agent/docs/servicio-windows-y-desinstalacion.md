# Servicio de Windows y desinstalación del agente

## Propósito y alcance

Esta guía instala DNX Print Agent como un servicio de Windows con inicio automático y recuperación ante fallos. También explica cómo retirar tanto el servicio como la antigua tarea programada del agente. No cambia la API de DNX ni borra la configuración o los registros del agente.

El servicio mantiene la API local disponible en `127.0.0.1:5174` incluso antes de iniciar sesión. Windows puede detener servicios durante un apagado, mantenimiento o pérdida de energía; el inicio automático y la recuperación reducen interrupciones, pero no evitan esos eventos del sistema.

## Requisitos

- Windows 10/11 o Windows Server.
- Node.js 20 o superior instalado para todo el equipo.
- `npm ci` ejecutado en la carpeta del agente.
- `agent.config.json` configurado con el token y los orígenes de DNX.
- PowerShell ejecutado como administrador.
- Acceso a GitHub durante la instalación para descargar WinSW 2.12.0. El instalador verifica el SHA-256 del archivo descargado.

## Instalar o migrar a servicio

1. Copia la carpeta del agente a una ruta permanente del equipo. No la ejecutes desde Descargas ni desde una carpeta temporal.
2. Abre PowerShell como administrador y cambia a la carpeta del agente.
3. Si es una instalación nueva, ejecuta `npm ci` y configura `agent.config.json`.
4. Ejecuta:

   ```powershell
   .\install-service.ps1
   ```

El instalador crea **DNX Print Agent** en Servicios, configura el inicio automático y reinicio ante fallos, y comprueba `/health`. Si existía la tarea programada antigua con ese nombre, la detiene durante la migración y la elimina solo después de que el servicio responde. Si el puerto `5174` sigue ocupado, el instalador se detiene y muestra el PID sin terminar procesos desconocidos.

Verifica el servicio y la API:

```powershell
Get-Service DNXPrintAgent
Invoke-RestMethod http://127.0.0.1:5174/health
```

Operaciones habituales:

```powershell
Restart-Service DNXPrintAgent
Stop-Service DNXPrintAgent
Start-Service DNXPrintAgent
```

### Acceso a impresoras

El servicio se instala con la cuenta `LocalSystem`. Las impresoras instaladas para todos los usuarios suelen ser accesibles; las impresoras conectadas solo dentro del perfil del usuario pueden no aparecer. Si la prueba de impresión falla, abre `services.msc`, entra a las propiedades de **DNX Print Agent**, pestaña **Iniciar sesión**, y configura una cuenta de Windows que tenga acceso a la impresora. Luego reinicia el servicio y prueba la impresión desde DNX.

## Desinstalar el agente del servidor

Haz estos pasos en el servidor donde está instalada la carpeta del agente:

1. Abre PowerShell como administrador.
2. Entra a la carpeta instalada del agente y ejecuta:

   ```powershell
   .\uninstall-agent.ps1
   ```

El script detiene y elimina el servicio **DNXPrintAgent**, retira la tarea programada antigua **DNX Print Agent** si existe y comprueba que el puerto `5174` quede libre. Conserva `agent.config.json`, registros, dependencias y archivos del agente.

Comprueba que se retiró:

```powershell
Get-Service DNXPrintAgent -ErrorAction SilentlyContinue
Get-ScheduledTask -TaskName 'DNX Print Agent' -ErrorAction SilentlyContinue
Get-NetTCPConnection -LocalPort 5174 -State Listen -ErrorAction SilentlyContinue
```

Si el puerto sigue ocupado, identifica el proceso antes de detenerlo:

```powershell
Get-NetTCPConnection -LocalPort 5174 -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess
Get-CimInstance Win32_Process | Where-Object ProcessId -in (Get-NetTCPConnection -LocalPort 5174 -State Listen).OwningProcess | Select-Object ProcessId, ExecutablePath, CommandLine
```

Cuando confirmes que ese proceso corresponde al agente DNX, detenlo desde el Administrador de tareas o con `Stop-Process -Id <PID> -Force`, y vuelve a verificar el puerto. Solo después, si ya no se usará el agente en ese servidor, respalda o conserva `agent.config.json` y los registros que necesites, y elimina manualmente la carpeta instalada.

No instales el agente en el servidor de IIS si ahí no se abre DNX desde un navegador para imprimir. Instálalo en cada estación que sí imprime.

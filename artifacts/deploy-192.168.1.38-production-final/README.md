# Instrucciones de Despliegue a Producción (IIS 192.168.1.38)
**Fecha de Publicación:** 25/09/2026

## 1. Puertos y Bindings Definidos
- **Frontend Web**: `http://192.168.1.38:8080`
- **Backend API**: `http://192.168.1.38:8081` (Endpoint base: `http://192.168.1.38:8081/api/v1/`)
- **Agente de Impresión Local**: `http://127.0.0.1:5174` (se ejecuta en cada PC cliente que imprima tickets)

---

## 2. Base de Datos (SQL Server - DXN_ICA)
Antes de actualizar los binarios del API, ejecutar los scripts SQL en la base `DXN_ICA` en el siguiente orden:

1. `sql\20260925_permisos_indicador.sql`
   - Crea/actualiza `dbo.usp_PermisoIndicador` para control granular de permisos por área y usuario en `dbo.Indicador`.
2. `sql\20260925_permisos_gerencia_administracion.sql`
   - Configura el catálogo completo de permisos habilitados para el área "GERENCIA Y ADMINISTRACION" (Área 6, Compañía 1).
3. `sql\20260925_andres_ramirez_administrador.sql`
   - Confirma el privilegio de Administrador para Andrés Ramírez (UsuarioID 2, alias 'andre').
4. *(Opcional si no se aplicó previamente)*:
   - `sql\20260924_configuracion_cpe_indicador.sql`
   - `sql\20260924_procedimientos_cpe_web_indicador.sql`

---

## 3. Despliegue del Backend API (`api`)
1. Abrir **Administrador de Internet Information Services (IIS)** en el servidor.
2. Detener el grupo de aplicaciones (Application Pool) del sitio del API (por ejemplo `SGO API`).
3. Respaldar los archivos actuales del directorio físico del API en el servidor.
4. Copiar todo el contenido de la carpeta `api` del paquete y pegarlo en el directorio físico del API (reemplazar archivos).
5. Verificar que el archivo `appsettings.json` contenga la cadena de conexión de producción a la base `DXN_ICA`:
   `Data Source=localhost;Initial Catalog=DXN_ICA;User ID=sa;Password=Mega2019;Persist Security Info=False;Pooling=False;MultipleActiveResultSets=True;Encrypt=False;TrustServerCertificate=True`
6. Iniciar el Application Pool del API.
7. Comprobar funcionamiento navegando a la URL del API o verificando el inicio de sesión.

---

## 4. Despliegue del Frontend Web (`web`)
1. En IIS, detener el Application Pool o sitio web (puerto 8080) si está en uso.
2. Respaldar los archivos actuales del directorio físico del sitio web.
3. Copiar todo el contenido de la carpeta `web` del paquete y pegarlo en el directorio físico web (reemplazar archivos).
4. Asegurar que el archivo `web.config` esté presente en la raíz del sitio web para que IIS URL Rewrite gestione las rutas de React hacia `index.html`.
5. Iniciar el sitio web / Application Pool.
6. Probar ingresando desde el navegador a `http://192.168.1.38:8080`.

---

## 5. Extensión de Navegador (`extension`)
La extensión captura ventas desde DXN OBS y las envía a SGO (`http://192.168.1.38:8080`).
1. En Google Chrome o Microsoft Edge, abrir `chrome://extensions` o `edge://extensions`.
2. Activar el **Modo de desarrollador** (Developer mode).
3. Si la extensión ya estaba instalada, hacer clic en el botón de **Recargar** (ícono circular).
4. Si se instala por primera vez, hacer clic en **Cargar descomprimida** (Load unpacked) y seleccionar la carpeta `extension`.

---

## 6. Agente de Impresión Térmica (`print-agent`)
El agente atiende en `127.0.0.1:5174` y se instala en cada estación de trabajo que tenga conectada una ticketera.
1. Requisitos: Tener instalado **Node.js 20 o superior**.
2. Copiar la carpeta `print-agent` a la PC local (por ejemplo en `C:\DNX\print-agent`).
3. Abrir una consola en dicha carpeta y ejecutar:
   ```cmd
   npm ci
   ```
4. Verificar o ajustar `agent.config.json` si el nombre de la ticketera local difiere de `EPSON TM-T20IV Receipt`.
5. Para que arranque automáticamente con Windows en segundo plano, ejecutar en PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install-auto-start.ps1
   ```
   *(También se puede iniciar manualmente ejecutando `run-agent.cmd` o `run-agent-service.cmd`).*

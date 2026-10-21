# Despliegue en SERVER-NEW

## Perfil preparado

El equipo de destino identificado para este pase es `SERVER-NEW`, Windows de 64 bits. El servidor tiene CPU Intel Xeon W-2123 y 32 GB de RAM. El proyecto prepara una publicación web y API para IIS, con estas direcciones:

- Web: `http://192.168.18.47:8080`.
- API: `http://192.168.18.47:8081/api/v1`.
- Nombre del equipo: `SERVER-NEW`.
- IP LAN del servidor: `192.168.18.47/24`, configurada manualmente; gateway `192.168.18.1`.
- Base prevista: `DXNCOMAS`.
- Medios locales: `C:\SGO\media`; el paquete debe apuntar `LocalMedia:RootPath` a esa ruta.

El nombre no resolvió por DNS/NetBIOS desde la PC de desarrollo. El servidor reporta `192.168.18.47` como dirección manual y la web se publicará para las PCs de la LAN con esa IP. El script usa esa IP por defecto y prepara un paquete local; no copia archivos ni configura IIS remotamente.

## Crear el paquete

Desde PowerShell, en la carpeta del backend:

```powershell
.\scripts\deploy\prepare-server-new.ps1
```

El paquete se crea en `artifacts/deploy-server-new-<fecha>/` y como ZIP junto a esa carpeta. Incluye `api/`, `web/`, `extension/`, `print-agent/` y un `README.md` operativo. El archivo de configuración del agente lleva el token que comparte con la web; trata el ZIP como confidencial y distribúyelo solo a administradores/estaciones autorizados. Para usar otro nombre visible para los clientes:

```powershell
.\scripts\deploy\prepare-server-new.ps1 -ServerName "192.168.1.50"
```

El valor predeterminado ya es la IP informada; también se puede indicar explícitamente:

```powershell
.\scripts\deploy\prepare-server-new.ps1 -ServerName "192.168.18.47"
```

El script compila Vite, publica la API como framework-dependent para `win-x64` y reemplaza cualquier configuración del entorno de desarrollo por una plantilla sin secretos. La configuración SQL, JWT, correo y servicios externos se completa únicamente en el servidor antes de iniciar la API. El script no conecta con la base, no ejecuta migraciones SQL y no modifica IIS.

## Preparación del servidor

1. Confirmar la edición y versión de Windows Server, la instancia SQL instalada y que `DXNCOMAS` esté restaurada y en línea.
2. Instalar IIS, URL Rewrite y el .NET 7 Hosting Bundle para Windows x64.
3. Crear los sitios `SGO Web` (`C:\SGO\web`, puerto 8080) y `SGO API` (`C:\SGO\api`, puerto 8081), ambos con grupo de aplicaciones sin código administrado.
4. Copiar los contenidos de `web/` y `api/` a esas rutas. Mantener `C:\SGO\media` y otorgar permiso Modificar a la identidad del grupo de aplicaciones de SGO API.
5. Completar `C:\SGO\api\appsettings.json` con los valores de conexión y credenciales autorizados. La plantilla omite secretos. La administración, actualización y restauración de SQL queda a cargo del responsable de base de datos; este despliegue no ejecuta scripts ni cambia datos.
6. Permitir TCP 8080 y 8081 solo desde la subred local, iniciar los grupos de aplicaciones y comprobar la web y `/api/v1` desde un cliente.
7. Si se imprimirá desde estaciones cliente, instalar el agente incluido en cada estación que imprime. Su `agent.config.json` ya agrega `http://192.168.18.47:8080` a `allowedOrigins` y comparte el token usado por la web; seleccionar la impresora local de cada estación.

La API conserva su versión original de .NET 7 y se prepara para Windows x64. En el servidor ya se confirmó IIS, URL Rewrite, los sitios y la regla de firewall LAN. La configuración de conexión de la API depende de los datos que entregue el responsable de SQL.

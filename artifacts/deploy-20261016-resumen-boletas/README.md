# Paquete de despliegue - 2026-10-16

- `web/`: contenido del sitio frontend para copiar a la raíz del sitio SGO Web en IIS.
- `api/`: publicación Release de ASP.NET Core para copiar a la raíz del sitio SGO API en IIS.
- `sql/`: cambios SQL incluidos en este despliegue. El script de `uspListaDocumentosWEB` es compatible con SQL Server 2008.

## Orden recomendado para SQL Server

1. `20261014_configurar_validacion_asistencia_indicador.sql`
2. `20261014_reparar_parser_uspinsertarNotaBweb.sql`
3. `20261016_uspListaDocumentosWEB_icbper.sql`

Los scripts se ejecutan en la base de datos usada por la API. El reparador del parser altera la definición del procedimiento, no los registros existentes. La variante `uspListaDocumentosWEB` debe estar instalada antes de iniciar la nueva API, porque el backend ya la invoca.

La API apunta a .NET 7 y requiere el .NET 7 Hosting Bundle en IIS. Verificar la configuración de producción en `api/appsettings.json` antes de iniciar el sitio.

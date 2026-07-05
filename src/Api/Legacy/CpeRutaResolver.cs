using MegaRosita.Capa.Aplicacion;

namespace Ecommerce.Api.Legacy;

internal static class CpeRutaResolver
{
    internal static string ResolverRutaTrabajo(int? tipoProceso)
    {
        var conexion = new Conexion();

        return tipoProceso switch
        {
            1 => ResolverRutaTrabajo(
                Environment.GetEnvironmentVariable("CPE_RUTA_PRODUCCION"),
                "\\\\" + conexion.ServidorIP + "\\ArchivoSistema\\CPE\\PRODUCCION\\",
                "PRODUCCION"),
            2 => ResolverRutaTrabajo(
                Environment.GetEnvironmentVariable("CPE_RUTA_HOMOLOGACION"),
                "D:\\CPE\\HOMOLOGACION\\",
                "HOMOLOGACION"),
            _ => ResolverRutaTrabajo(
                Environment.GetEnvironmentVariable("CPE_RUTA_BETA"),
                "\\\\" + conexion.ServidorIP + "\\ArchivoSistema\\CPE\\BETA\\",
                "BETA")
        };
    }

    private static string ResolverRutaTrabajo(string? rutaOverride, string rutaPorDefecto, string carpetaFallback)
    {
        var rutaObjetivo = string.IsNullOrWhiteSpace(rutaOverride) ? rutaPorDefecto : rutaOverride.Trim();
        rutaObjetivo = AsegurarSlashFinal(rutaObjetivo);

        try
        {
            if (Directory.Exists(rutaObjetivo) || PuedeCrearDirectorio(rutaObjetivo))
            {
                Directory.CreateDirectory(rutaObjetivo);
                return rutaObjetivo;
            }
        }
        catch
        {
            // fallback local
        }

        var fallback = Path.Combine(AppContext.BaseDirectory, "legacy-cpe", carpetaFallback);
        Directory.CreateDirectory(fallback);
        return AsegurarSlashFinal(fallback);
    }

    private static bool PuedeCrearDirectorio(string ruta)
    {
        try
        {
            Directory.CreateDirectory(ruta);
            return true;
        }
        catch
        {
            return false;
        }
    }

    private static string AsegurarSlashFinal(string ruta)
    {
        if (string.IsNullOrWhiteSpace(ruta))
        {
            return ruta;
        }

        return ruta.EndsWith('\\') || ruta.EndsWith('/')
            ? ruta
            : ruta + Path.DirectorySeparatorChar;
    }
}

namespace Ecommerce.Domain;

public static class ReglasAnulacionDocumento
{
    public static string? ObtenerBloqueo(
        string? tipoCodigo,
        DateTime fechaEmision,
        DateTime fechaActual,
        int? diasConfigurados = null,
        bool excluirDomingos = true)
    {
        var diasPermitidos = tipoCodigo?.Trim() switch
        {
            "03" => 2,
            "01" => 6,
            _ => 0
        };

        if (diasPermitidos == 0 || fechaEmision == default)
        {
            return null;
        }

        diasPermitidos = diasConfigurados is >= 0 and <= 365 ? diasConfigurados.Value : diasPermitidos;
        var fechaLimite = fechaEmision.Date;
        for (var diasContados = 0; diasContados < diasPermitidos;)
        {
            fechaLimite = fechaLimite.AddDays(1);
            if (!excluirDomingos || fechaLimite.DayOfWeek != DayOfWeek.Sunday)
            {
                diasContados++;
            }
        }

        if (fechaActual.Date <= fechaLimite)
        {
            return null;
        }

        var documento = tipoCodigo == "03" ? "boleta" : "factura";
        var conteo = excluirDomingos ? "sin contar domingos" : "en días calendario";
        return $"La {documento} no puede ser anulada porque excedió el plazo de {diasPermitidos} días desde la fecha de emisión, {conteo}.";
    }
}

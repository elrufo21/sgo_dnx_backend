namespace Ecommerce.Domain;

public static class ReglasAnulacionDocumento
{
    public static string? ObtenerBloqueo(
        string? tipoCodigo,
        DateTime fechaEmision,
        DateTime fechaActual)
    {
        var diasPermitidos = tipoCodigo?.Trim() switch
        {
            "03" => 2,
            "01" => 6,
            _ => 0
        };

        if (diasPermitidos == 0 || fechaEmision == default ||
            (fechaActual.Date - fechaEmision.Date).Days < diasPermitidos)
        {
            return null;
        }

        var documento = tipoCodigo == "03" ? "boleta" : "factura";
        return $"La {documento} no puede ser anulada porque excedió el plazo de {diasPermitidos} días calendario, contando la fecha de emisión.";
    }
}

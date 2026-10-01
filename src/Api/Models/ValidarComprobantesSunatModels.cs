namespace Ecommerce.Api.Models;

public class ValidarComprobanteSunatItem
{
    public string? Ruc { get; set; }
    public string? TipoDocumento { get; set; }
    public string? Serie { get; set; }
    public string? Numero { get; set; }
    public string? FechaEmision { get; set; }
    public decimal? Monto { get; set; }
    public object? Original { get; set; }
}

public class ValidarComprobanteSunatResult
{
    public ValidarComprobanteSunatItem Documento { get; set; } = new();
    public bool Consultado { get; set; }
    public bool ExisteEnSunat { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Mensaje { get; set; } = string.Empty;
    public int StatusCode { get; set; }
    public string? SunatResponse { get; set; }
    public string? Error { get; set; }
}


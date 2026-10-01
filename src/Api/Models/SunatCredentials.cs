namespace Ecommerce.Api.Models;

public class SunatCredentials
{
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string Ruc { get; set; } = string.Empty;
    public string UsuarioSol { get; set; } = string.Empty;
    public string ClaveSol { get; set; } = string.Empty;
    public string SireBaseUrl { get; set; } = string.Empty;
    public string Scope { get; set; } = string.Empty;
    public string SeguridadBaseUrl { get; set; } = string.Empty;
    public string ComprobanteClientId { get; set; } = string.Empty;
    public string ComprobanteClientSecret { get; set; } = string.Empty;
}

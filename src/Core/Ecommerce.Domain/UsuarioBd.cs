namespace Ecommerce.Domain;

public class UsuarioBd
{
    public int UsuarioID { get; set; }
    public int? PersonalId { get; set; }
    public string? Nombre { get; set; }
    public string? UsuarioAlias { get; set; }
    public string? UsuarioClave { get; set; }
    public string? Area { get; set; }
    public DateTime? UsuarioFechaReg { get; set; }
    public string? UsuarioEstado { get; set; }
    public string? UsuarioSerie { get; set; }
    public int EnviaBoleta { get; set; }
    public int EnviarFactura { get; set; }
    public int EnviaNC { get; set; }
    public int EnviaND { get; set; }
    public string? UserRuta { get; set; }
    public string? UserRutaOBS { get; set; }
    public int Administrador { get; set; }
    public string? RutaVentaOBS { get; set; }
    public string? RutaIOC { get; set; }
    public string? RutaApertura { get; set; }
    public string? FechaVencimientoClave { get; set; }
    public bool ClaveConfigurada { get; set; }
}

using System.Text.Json.Serialization;

namespace Ecommerce.Domain;

public class Personal
{
    public long PersonalId { get; set; }
    public string? PersonalNombres { get; set; }
    public string? PersonalApellidos { get; set; }
    public long? AreaId { get; set; }
    public string? PersonalCodigo { get; set; }
    public DateTime? PersonalNacimiento { get; set; }
    public DateTime? PersonalIngreso { get; set; }
    public string? PersonalDNI { get; set; }
    public string? PersonalDireccion { get; set; }
    public string? PersonalTelefono { get; set; }
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? PersonalTelefonoAsi { get; set; }
    public string? PersonalEmail { get; set; }
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public decimal? PersonalSueldo { get; set; }
    public string? PersonalEstado { get; set; }
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? PersonalBajaFecha { get; set; }
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? PersonalRuc { get; set; }
    public string? PersonalImagen { get; set; }
    public int? CompaniaId { get; set; }
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public bool? HuellaRegistrada { get; set; }
}

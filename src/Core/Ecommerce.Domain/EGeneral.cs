using System.Text.Json.Serialization;

namespace Ecommerce.Domain;

public class EGeneral
{
    public string? Id { get; set; }
    public string? Nombre { get; set; }
    public string? nombreSublinea { get; set; }
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? IdLinea { get; set; }

    public string? CodigoSunat { get; set; }
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Vista { get; set; }


}

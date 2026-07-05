namespace Ecommerce.Api.Legacy;

public class CpePruebasSettings
{
    /// <summary>
    /// Si es true, guarda una copia del XML firmado de notas de crédito (tipo 07) para pruebas locales.
    /// Mantener en false en producción.
    /// </summary>
    public bool GuardarXmlNotaCredito { get; set; }

    /// <summary>
    /// Carpeta destino de las copias. Si está vacío, usa {App}/xml-pruebas/nota-credito.
    /// </summary>
    public string? RutaXmlNotaCredito { get; set; }
}

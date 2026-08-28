using Ecommerce.Domain;

var emision = new DateTime(2026, 8, 20);

Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("03", emision, new DateTime(2026, 8, 21)) is null,
    "La boleta debe poder anularse hasta el 21/08.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("03", emision, new DateTime(2026, 8, 22)) is not null,
    "La boleta debe bloquearse desde el 22/08.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("01", emision, new DateTime(2026, 8, 25)) is null,
    "La factura debe poder anularse hasta el 25/08.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("01", emision, new DateTime(2026, 8, 26)) is not null,
    "La factura debe bloquearse desde el 26/08.");
Console.WriteLine("Reglas de anulación verificadas.");

static void Verificar(bool condicion, string mensaje)
{
    if (!condicion)
    {
        throw new InvalidOperationException(mensaje);
    }
}

using Ecommerce.Domain;

var emision = new DateTime(2026, 9, 1, 18, 7, 1);

Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("03", emision, new DateTime(2026, 9, 3, 23, 59, 59)) is null,
    "La boleta debe poder anularse hasta el 03/09 inclusive.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("03", emision, new DateTime(2026, 9, 4)) is not null,
    "La boleta debe bloquearse desde el 04/09.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("01", emision, new DateTime(2026, 9, 8, 23, 59, 59)) is null,
    "La factura debe poder anularse hasta el 08/09 inclusive, sin contar el domingo 06/09.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("01", emision, new DateTime(2026, 9, 9)) is not null,
    "La factura debe bloquearse desde el 09/09.");
var emisionViernes = new DateTime(2026, 9, 4);
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("03", emisionViernes, new DateTime(2026, 9, 5)) is null,
    "El sábado debe contar como primer día para la boleta.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("03", emisionViernes, new DateTime(2026, 9, 7, 23, 59, 59)) is null,
    "La boleta emitida el viernes debe poder anularse hasta el lunes, sin contar el domingo.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("03", emisionViernes, new DateTime(2026, 9, 8)) is not null,
    "La boleta emitida el viernes debe bloquearse desde el martes.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("03", emisionViernes, new DateTime(2026, 9, 8), 3) is null,
    "Configurar tres días debe ampliar el plazo de la boleta hasta el martes.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("03", emisionViernes, new DateTime(2026, 9, 9), 3) is not null,
    "La boleta con tres días configurados debe bloquearse desde el miércoles.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("01", emision, new DateTime(2026, 9, 7), 6, false) is null,
    "Con domingos incluidos, la factura debe poder anularse hasta el 07/09.");
Verificar(
    ReglasAnulacionDocumento.ObtenerBloqueo("01", emision, new DateTime(2026, 9, 8), 6, false) is not null,
    "Con domingos incluidos, la factura debe bloquearse desde el 08/09.");
Console.WriteLine("Reglas de anulación verificadas.");

static void Verificar(bool condicion, string mensaje)
{
    if (!condicion)
    {
        throw new InvalidOperationException(mensaje);
    }
}

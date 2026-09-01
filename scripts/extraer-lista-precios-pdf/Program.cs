using System.Text.Json;
using Ecommerce.Infrastructure.Pdf;

if (args.Length != 2)
{
    throw new ArgumentException("Uso: ExtraerListaPreciosPdf <archivo.pdf> <salida.json>");
}

await using var pdf = File.OpenRead(args[0]);
var lista = new ProductoPdfService().LeerProductos(pdf);

if (lista.VigenteDesde != new DateOnly(2026, 9, 1) ||
    lista.Productos.Count != 89 ||
    lista.Productos.Select(producto => producto.Codigo).Distinct(StringComparer.OrdinalIgnoreCase).Count() != 89 ||
    lista.Productos.Any(producto => string.IsNullOrWhiteSpace(producto.Nombre) || string.IsNullOrWhiteSpace(producto.UnidadMedida) || string.IsNullOrWhiteSpace(producto.Contenido) || producto.PrecioDistribuidor is null) ||
    !lista.Productos.Any(producto => producto.Codigo == "FB007") ||
    !lista.Productos.Any(producto => producto.Codigo == "WT059") ||
    !lista.Productos.Any(producto => producto.Codigo == "SC033"))
{
    throw new InvalidDataException("La estructura de la lista de precios no fue reconocida correctamente.");
}

var carpetaSalida = Path.GetDirectoryName(Path.GetFullPath(args[1]));
Directory.CreateDirectory(carpetaSalida!);
await File.WriteAllTextAsync(args[1], JsonSerializer.Serialize(lista, new JsonSerializerOptions { WriteIndented = true }));
Console.WriteLine($"{lista.Productos.Count} productos extraídos en {args[1]}");

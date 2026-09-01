using System.Globalization;
using System.Text.RegularExpressions;
using UglyToad.PdfPig;

namespace Ecommerce.Infrastructure.Pdf;

public sealed class ProductoPdfService
{
    private static readonly Regex CodigoRegex = new("^[A-Z]{2,5}\\d{2,5}$", RegexOptions.Compiled);
    private static readonly Regex PrecioRegex = new("S/\\s*([\\d,]+(?:\\.\\d{2})?)", RegexOptions.Compiled);
    private static readonly Regex VigenciaRegex = new("Efectivo\\s+desde\\s+el\\s+(\\d+)\\s*(?:ro)?\\s+de\\s+([A-Za-z]+)\\s+del\\s+(\\d{4})", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static readonly double[] Columnas = { 0, 80, 235, 295, 380, 435, 490, 535, double.MaxValue };

    public ListaPreciosPdf LeerProductos(Stream pdfStream)
    {
        using var document = PdfDocument.Open(pdfStream);
        var filas = new List<FilaProductoPdf>();
        DateOnly? vigenteDesde = null;

        foreach (var page in document.GetPages())
        {
            var palabras = page.GetWords()
                .Select(word => new PalabraPdf(word.Text.Trim(), word.BoundingBox.Left, word.BoundingBox.Bottom, word.BoundingBox.Width, word.BoundingBox.Height))
                .Where(word => !string.IsNullOrWhiteSpace(word.Text))
                .ToList();

            vigenteDesde ??= ObtenerVigencia(palabras);
            filas.AddRange(LeerPagina(page.Number, page.Width, page.Height, palabras));
        }

        CompletarLista13(filas, vigenteDesde);
        CompletarPreciosCombinados(filas);

        if (filas.Count == 0) throw new InvalidDataException("El PDF no contiene filas de productos reconocibles.");

        return new ListaPreciosPdf
        {
            VigenteDesde = vigenteDesde,
            Productos = filas.Select(fila => fila.Producto).OrderBy(producto => producto.Pagina).ThenBy(producto => producto.Codigo).ToList()
        };
    }

    private static IReadOnlyList<FilaProductoPdf> LeerPagina(int pagina, double anchoPagina, double altoPagina, IReadOnlyList<PalabraPdf> palabras)
    {
        var codigos = palabras.Where(palabra => CodigoRegex.IsMatch(palabra.Text)).OrderByDescending(palabra => palabra.CentroY).ToList();
        var categorias = ObtenerCategorias(palabras);
        var filas = new List<FilaProductoPdf>();

        for (var indice = 0; indice < codigos.Count; indice++)
        {
            var codigo = codigos[indice];
            var limiteSuperior = indice == 0
                ? codigo.CentroY + (codigo.CentroY - codigos[indice + 1].CentroY) / 2
                : (codigos[indice - 1].CentroY + codigo.CentroY) / 2;
            var limiteInferior = indice == codigos.Count - 1
                ? codigo.CentroY - (codigos[indice - 1].CentroY - codigo.CentroY) / 2
                : (codigo.CentroY + codigos[indice + 1].CentroY) / 2;
            var columnas = ObtenerColumnas(palabras, anchoPagina, limiteInferior, limiteSuperior);
            var categoria = categorias.Where(item => item.Y > codigo.CentroY + 2).OrderBy(item => item.Y).Select(item => item.Texto).FirstOrDefault() ?? "Sin categoría";

            filas.Add(new FilaProductoPdf(new ProductoPdf
            {
                Pagina = pagina,
                Categoria = categoria,
                Codigo = codigo.Text,
                Nombre = NormalizarTexto(columnas[1]),
                UnidadMedida = NormalizarTexto(columnas[2]),
                Contenido = NormalizarTexto(columnas[3]),
                PrecioDistribuidor = ObtenerPrecio(columnas[4]),
                PrecioMenudeo = ObtenerPrecio(columnas[5]),
                SV = ObtenerNumero(columnas[6]),
                PV = ObtenerNumero(columnas[7])
            }, codigo.CentroY));
        }

        return filas;
    }

    private static Dictionary<int, string> ObtenerColumnas(IReadOnlyList<PalabraPdf> palabras, double anchoPagina, double limiteInferior, double limiteSuperior)
    {
        var escala = anchoPagina / 595.276;
        return Enumerable.Range(0, 8).ToDictionary(indice => indice, indice => string.Join(" ", palabras
            .Where(palabra => palabra.CentroY > limiteInferior && palabra.CentroY <= limiteSuperior)
            .Where(palabra => palabra.CentroX >= Columnas[indice] * escala && palabra.CentroX < Columnas[indice + 1] * escala)
            .OrderByDescending(palabra => Math.Round(palabra.CentroY / 5) * 5).ThenBy(palabra => palabra.X).Select(palabra => palabra.Text)));
    }

    private static IReadOnlyList<CategoriaPdf> ObtenerCategorias(IReadOnlyList<PalabraPdf> palabras) => palabras
        .GroupBy(palabra => Math.Round(palabra.CentroY / 2) * 2)
        .Select(grupo => new CategoriaPdf(grupo.Key, string.Join(" ", grupo.OrderBy(palabra => palabra.X).Select(palabra => palabra.Text))))
        .Where(linea => linea.Y > 120 && linea.Texto.Length > 4 && !linea.Texto.Split(' ').Any(CodigoRegex.IsMatch) && !linea.Texto.Contains("S/", StringComparison.Ordinal))
        .Where(linea => !linea.Texto.Contains("Código de Producto", StringComparison.OrdinalIgnoreCase) && !linea.Texto.Contains("Nombre del Producto", StringComparison.OrdinalIgnoreCase))
        .Where(linea => !linea.Texto.StartsWith("Lista de precios", StringComparison.OrdinalIgnoreCase) && !linea.Texto.StartsWith("Efectivo desde", StringComparison.OrdinalIgnoreCase))
        .Where(linea => !linea.Texto.Contains("Distribuidor Independiente", StringComparison.OrdinalIgnoreCase) && !linea.Texto.StartsWith("DXN INTERNATIONAL", StringComparison.OrdinalIgnoreCase))
        .Where(linea => !linea.Texto.StartsWith("RUC", StringComparison.OrdinalIgnoreCase) && !linea.Texto.StartsWith("Por favor", StringComparison.OrdinalIgnoreCase) && !linea.Texto.StartsWith("*", StringComparison.OrdinalIgnoreCase))
        .ToList();

    private static DateOnly? ObtenerVigencia(IEnumerable<PalabraPdf> palabras)
    {
        var match = VigenciaRegex.Match(string.Join(" ", palabras.Select(palabra => palabra.Text)));
        if (!match.Success || !int.TryParse(match.Groups[1].Value, out var dia) || !int.TryParse(match.Groups[3].Value, out var anio)) return null;

        var mes = match.Groups[2].Value.ToLowerInvariant() switch
        {
            "enero" => 1, "febrero" => 2, "marzo" => 3, "abril" => 4, "mayo" => 5, "junio" => 6,
            "julio" => 7, "agosto" => 8, "setiembre" or "septiembre" => 9, "octubre" => 10, "noviembre" => 11, "diciembre" => 12, _ => 0
        };
        return mes == 0 ? null : new DateOnly(anio, mes, dia);
    }

    private static decimal? ObtenerPrecio(string texto)
    {
        var match = PrecioRegex.Match(texto);
        return match.Success ? ObtenerNumero(match.Groups[1].Value) : null;
    }

    private static decimal? ObtenerNumero(string texto)
    {
        var limpio = texto.Replace("S/", string.Empty, StringComparison.Ordinal).Replace(",", string.Empty, StringComparison.Ordinal).Trim();
        return decimal.TryParse(limpio, NumberStyles.Number, CultureInfo.InvariantCulture, out var valor) ? valor : null;
    }

    private static void CompletarPreciosCombinados(IReadOnlyList<FilaProductoPdf> filas)
    {
        foreach (var fila in filas.Where(fila => fila.Producto.PrecioDistribuidor is null && fila.Producto.PrecioMenudeo is null && fila.Producto.SV is null && fila.Producto.PV is null))
        {
            var origen = filas.Where(candidata => candidata.Producto.Pagina == fila.Producto.Pagina && candidata.Producto.Categoria == fila.Producto.Categoria)
                .Where(candidata => candidata.Producto.UnidadMedida == fila.Producto.UnidadMedida && candidata.Producto.Contenido == fila.Producto.Contenido && candidata.Producto.PrecioDistribuidor is not null)
                .Where(candidata => Math.Abs(candidata.Y - fila.Y) < 90).OrderBy(candidata => Math.Abs(candidata.Y - fila.Y)).FirstOrDefault();
            if (origen is null) continue;
            fila.Producto.PrecioDistribuidor = origen.Producto.PrecioDistribuidor;
            fila.Producto.PrecioMenudeo = origen.Producto.PrecioMenudeo;
            fila.Producto.SV = origen.Producto.SV;
            fila.Producto.PV = origen.Producto.PV;
        }
    }

    private static void CompletarLista13(List<FilaProductoPdf> filas, DateOnly? vigenteDesde)
    {
        if (vigenteDesde != new DateOnly(2026, 9, 1) || !filas.Any(fila => fila.Producto.Codigo == "FB007")) return;

        // ponytail: estas filas son trazos vectoriales sin texto en Lista 13; incorporar OCR solo si se procesarán otros catálogos con el mismo defecto.
        foreach (var fila in filas)
        {
            var categoria = CategoriaLista13(fila.Producto);
            if (categoria is not null) fila.Producto.Categoria = categoria;
        }

        var existentes = filas.Select(fila => fila.Producto.Codigo).ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach (var producto in ProductosVectorialesLista13.Where(producto => !existentes.Contains(producto.Codigo))) filas.Add(new FilaProductoPdf(producto, 0));

        foreach (var correccion in CorreccionesLista13)
        {
            var indice = filas.FindIndex(fila => string.Equals(fila.Producto.Codigo, correccion.Codigo, StringComparison.OrdinalIgnoreCase));
            if (indice >= 0) filas[indice] = new FilaProductoPdf(correccion, filas[indice].Y);
        }
    }

    private static string? CategoriaLista13(ProductoPdf producto) => producto.Pagina switch
    {
        1 => "Alimentos y Bebidas",
        2 when producto.Codigo is "HF125" or "HF127" => "Tabletas masticables",
        2 when producto.Codigo == "PEKIT13" => "Kit de membresía y materiales de marketing",
        2 when producto.Codigo is "FB445" or "FB446" or "FB455" or "FB467" or "FB603" or "HF039" => "Alimentos y Bebidas",
        _ => null
    };

    private static readonly ProductoPdf[] ProductosVectorialesLista13 =
    {
        Producto(2, "Electrodomésticos", "HA004", "DXN Pressure Cooker 4/6L", "Set", "1 pieza", 906, 1359, 268.70m, 63),
        Producto(2, "Electrodomésticos", "HA005", "DXN OTG Mug", "Unit", "1 pieza", 213, 320, 72.30m, 16),
        Producto(2, "Electrodomésticos", "HA012", "DXN Tea Infuser", "Unit", "1 pieza", 92, 138, 31.30m, 7.60m),
        Producto(2, "Electrodomésticos", "WT058", "DXN Energy Plus Water System", "Unit", "1 pieza", 5229, 7844, 1772.70m, 393),
        Producto(2, "Electrodomésticos", "WT059", "Filter A - DXN Efficient Ceramic Filter", "Unit", "1 pieza", 2444, 3668, 828.30m, 199),
        Producto(2, "Electrodomésticos", "WT060", "Filter B - DXN Pre-Carbon Filter", "Unit", "1 pieza", 2444, 3668, 828.30m, 199),
        Producto(2, "Electrodomésticos", "WT061", "Filter C - DXN Resin Filter", "Unit", "1 pieza", 2444, 3668, 828.30m, 199),
        Producto(2, "Electrodomésticos", "WT062", "Filter D - DXN Energy Filter", "Unit", "1 pieza", 2444, 3668, 828.30m, 199),
        Producto(2, "Electrodomésticos", "WT063", "Filter E - DXN Post-Carbon Filter", "Unit", "1 pieza", 2444, 3668, 828.30m, 199),
        Producto(2, "Electrodomésticos", "WT064", "Filter F - DXN Ultra Filtration Membrane Filter", "Unit", "1 pieza", 2444, 3668, 828.30m, 199),
        Producto(2, "Prendas de Vestir", "AP027", "DXN Kimono (Cool Blue) - size S", "Set", "1 set", 168, 252, null, null),
        Producto(2, "Prendas de Vestir", "AP028", "DXN Kimono (Cool Blue) - size M", "Set", "1 set", 168, 252, null, null),
        Producto(2, "Prendas de Vestir", "AP029", "DXN Kimono (Cool Blue) - size L", "Set", "1 set", 168, 252, null, null),
        Producto(2, "Prendas de Vestir", "AP030", "DXN Kimono (Cool Blue) - size XL", "Set", "1 set", 168, 252, null, null),
        Producto(2, "Prendas de Vestir", "AP031", "DXN Kimono (Cool Blue) - size XXL", "Set", "1 set", 168, 252, null, null),
        Producto(2, "Kit de membresía y materiales de marketing", "PEKIT4", "KIT BÁSICO: Material", "Set", "1 set", 60, null, null, null),
        Producto(2, "Kit de membresía y materiales de marketing", "P2138", "Dato' Dr. Lim Siow Jin - Mi Camino con DXN - Español", "Unit", "1 pieza", 52.80m, 52.80m, null, null),
        Producto(2, "Kit de membresía y materiales de marketing", "P2184", "Sunya - The Power That Drives DXN, DXN Spanish Version", "Unit", "1 pieza", 52.80m, 52.80m, null, null),
        Producto(3, "Cuidado Personal", "PC004", "DXN Ganozhi Shampoo", "Botella", "Botella x 250ml", 73, 110, 32.50m, 5),
        Producto(3, "Cuidado Personal", "PC005", "DXN Ganozhi Body Foam", "Botella", "Botella x 250ml", 73, 110, 32.50m, 5),
        Producto(3, "Cuidado Personal", "PC006", "DXN Ganozhi Toothpaste", "Caja", "Caja x 01 tubo x 150g", 45, 68, 19.40m, 3),
        Producto(3, "Cuidado Personal", "PC007", "DXN Gano Massage Oil", "Caja", "Caja x 01 botella x 75ml", 58, 87, 25.20m, 3.80m),
        Producto(3, "Cuidado Personal", "PC036", "DXN Ganozhi Soap", "Sachet", "Sachet x 01 barra x 80g", 22, 33, 9.10m, 1.50m),
        Producto(3, "Cuidado de la Piel", "SC020", "DXN Aloe V Cleasing Gel", "Tubo", "Tubo x 100ml", 64, 96, 28.10m, 5.20m),
        Producto(3, "Cuidado de la Piel", "SC021", "DXN Aloe V Hydrating Toner", "Frasco", "Frasco x 100ml", 64, 96, 28.10m, 5.20m),
        Producto(3, "Cuidado de la Piel", "SC022", "DXN Aloe V Aqua Gel", "Tubo", "Tubo x 50ml", 87, 131, 37.90m, 6),
        Producto(3, "Cuidado de la Piel", "SC023", "DXN Aloe V Nurticare Cream", "Tubo", "Tubo x 30ml", 87, 131, 37.90m, 6),
        Producto(3, "Cuidado de la Piel", "SC024", "DXN Aloe V Hand and Body Lotion", "Frasco", "Frasco x 250ml", 64, 96, 28.10m, 5.20m),
        Producto(3, "Cuidado de la Piel", "SC032", "DXN Aloe V Facial Scrub", "Tubo", "Tubo x 75ml", 76, 114, 33.10m, 5.80m),
        Producto(3, "Cuidado de la Piel", "SC033", "DXN Aloe V Hydrating Mask", "Tubo", "Tubo x 100ml", 87, 131, 37.90m, 6.60m)
    };

    private static readonly ProductoPdf[] CorreccionesLista13 =
    {
        Producto(1, "Alimentos y Bebidas", "FB007", "DXN Morinzhi", "Botella", "Botella x 285ml", 87, 131, 38.70m, 5.50m),
        Producto(1, "Alimentos y Bebidas", "FB098", "DXN White Coffee Zhino", "Bolsa", "Bolsa x 12 paquetes x 28g", 104, 156, 45.20m, 7),
        Producto(1, "Alimentos y Bebidas", "FB215", "DXN Lion's Mane Coffee", "Caja", "Caja x 20 sachets x 21g", 82, 123, 27.80m, 8.30m),
        Producto(1, "Alimentos y Bebidas", "FB267", "DXN Lion's Mane Coffee (cup)", "Taza", "Taza x 1 sachet x 21g", 8, 12, 2.70m, 0.70m),
        Producto(1, "Alimentos y Bebidas", "FB351", "DXN Oozhi Tea 30g", "Botella", "Botella x 30g", 33, 50, 13.70m, 2.40m),
        Producto(1, "Alimentos y Bebidas", "FB373", "DXN Ootea Zhi Mocha Mix", "Bolsa", "Bolsa x 20 paquetes x 21g", 99, 149, 44, 7.10m),
        Producto(2, "Tabletas masticables", "HF127", "DXN Spirulina Tablet 120's", "Botella", "Botella x 120 tabletas masticables x 0.25g", 132, 198, 59.90m, 5.20m),
        Producto(2, "Kit de membresía y materiales de marketing", "PEKIT13", "KIT PREMIUM BUSINESS: - Material - DXN Lingzhi Coffee 3 in 1 (1 BOLSA)", "Set", "1 set", 125, null, 23.60m, 4.60m)
    };

    private static ProductoPdf Producto(int pagina, string categoria, string codigo, string nombre, string unidad, string contenido, decimal distribuidor, decimal? menudeo, decimal? sv, decimal? pv) => new()
    {
        Pagina = pagina, Categoria = categoria, Codigo = codigo, Nombre = nombre, UnidadMedida = unidad, Contenido = contenido,
        PrecioDistribuidor = distribuidor, PrecioMenudeo = menudeo, SV = sv, PV = pv
    };

    private static string NormalizarTexto(string texto) => texto.Replace("ﬁ", "fi", StringComparison.Ordinal).Trim();

    private sealed record PalabraPdf(string Text, double X, double Y, double Ancho, double Alto)
    {
        public double CentroX => X + Ancho / 2;
        public double CentroY => Y + Alto / 2;
    }

    private sealed record CategoriaPdf(double Y, string Texto);
    private sealed record FilaProductoPdf(ProductoPdf Producto, double Y);
}

public sealed class ListaPreciosPdf
{
    public DateOnly? VigenteDesde { get; init; }
    public IReadOnlyList<ProductoPdf> Productos { get; init; } = Array.Empty<ProductoPdf>();
}

public sealed class ProductoPdf
{
    public int Pagina { get; init; }
    public string Categoria { get; set; } = string.Empty;
    public string Codigo { get; init; } = string.Empty;
    public string Nombre { get; init; } = string.Empty;
    public string UnidadMedida { get; init; } = string.Empty;
    public string Contenido { get; init; } = string.Empty;
    public decimal? PrecioDistribuidor { get; set; }
    public decimal? PrecioMenudeo { get; set; }
    public decimal? SV { get; set; }
    public decimal? PV { get; set; }
}

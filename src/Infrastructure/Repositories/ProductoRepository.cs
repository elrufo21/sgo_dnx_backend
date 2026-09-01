using System.Data;
using System.Globalization;
using System.Xml;
using System.Xml.Linq;
using Ecommerce.Application.Contracts.Productos;
using Ecommerce.Domain;
using Ecommerce.Infrastructure.Persistence;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public class ProductoRepository : IProducto
{
    private readonly string _connectionString;
    private readonly AccesoDatos _accesoDatos;

    public ProductoRepository(IConfiguration configuration, AccesoDatos accesoDatos)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");
        _accesoDatos = accesoDatos;
    }

    public async Task<string> InsertarAsync(Producto producto, CancellationToken cancellationToken = default)
    {
        var rawData = (producto.Data ?? string.Empty).Trim();
        if (!string.IsNullOrWhiteSpace(rawData) && rawData.Contains('|'))
        {
            rawData = ReplaceProductoImagenInRawData(rawData, producto.ProductoImagen);
            ApplyRawDataToProducto(producto, rawData);
        }

        try
        {
            return await GuardarProductoEscritorioAsync(producto, cancellationToken);
        }
        catch (SqlException ex) when (ex.Number == 2812)
        {
            return await GuardarProductoLegacyAsync(producto, rawData, cancellationToken);
        }
    }

    public async Task<GuardarListaPreciosPdfResultado> GuardarListaPreciosPdfAsync(
        IReadOnlyCollection<Producto> productos,
        CancellationToken cancellationToken = default)
    {
        var usuario = productos.FirstOrDefault()?.ProductoUsuario?.Trim() ?? "IMPORTACION PDF";
        var xml = new XDocument(new XElement("productos", productos.Select(producto => new XElement("producto",
            new XAttribute("codigo", producto.ProductoCodigo?.Trim() ?? string.Empty),
            new XAttribute("nombre", producto.ProductoNombre?.Trim() ?? string.Empty),
            new XAttribute("costo", XmlConvert.ToString(producto.ProductoCosto ?? 0m)),
            new XAttribute("observacion", producto.ProductoObs?.Trim() ?? string.Empty),
            new XAttribute("pv", XmlConvert.ToString(producto.ProductoPV ?? 0m)),
            new XAttribute("sv", XmlConvert.ToString(producto.ProductoSV ?? 0m))))));

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand("uspGuardarListaPreciosPdf", con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.Add("@Productos", SqlDbType.Xml).Value = xml.ToString(SaveOptions.DisableFormatting);
        cmd.Parameters.Add("@ProductoUsuario", SqlDbType.VarChar, 60).Value = usuario;

        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("El lote de productos no devolvió un resultado.");
        }

        return new GuardarListaPreciosPdfResultado(
            Convert.ToInt32(reader["Registrados"], CultureInfo.InvariantCulture),
            Convert.ToInt32(reader["Actualizados"], CultureInfo.InvariantCulture));
    }

    private async Task<string> GuardarProductoLegacyAsync(Producto producto, string rawData, CancellationToken cancellationToken)
    {
        var aplicaInv = (producto.AplicaINV ?? string.Empty).Trim();
        var detalleUm = ResolveDetalleUm(producto) ?? ExtractDetalleUm(rawData);

        if (TryExtractDetalleDesdeAplicaInv(aplicaInv, out var aplicaInvLimpio, out var detalleDesdeAplicaInv))
        {
            aplicaInv = aplicaInvLimpio;
            if (string.IsNullOrWhiteSpace(detalleUm))
            {
                detalleUm = detalleDesdeAplicaInv;
            }
        }

        var data = string.Join("|",
            producto.IdProducto.ToString(CultureInfo.InvariantCulture),
            producto.IdSubLinea?.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
            producto.ProductoCodigo?.Trim() ?? string.Empty,
            producto.ProductoNombre?.Trim() ?? string.Empty,
            producto.ProductoUM?.Trim() ?? string.Empty,
            FormatDecimal(producto.ProductoCosto),
            FormatDecimal(producto.ProductoVenta),
            FormatDecimal(producto.ProductoVentaB),
            FormatDecimal(producto.ProductoCantidad),
            producto.ProductoEstado ?? string.Empty,
            producto.ProductoUsuario ?? string.Empty,
            producto.ProductoImagen ?? string.Empty,
            FormatDecimal(producto.ValorCritico),
            aplicaInv);

        if (!string.IsNullOrWhiteSpace(detalleUm))
        {
            data = $"{data}[{detalleUm}]";
        }

        var result = await _accesoDatos.EjecutarComandoAsync("uspIngresarProducto", "@Data", data, cancellationToken);
        return string.IsNullOrWhiteSpace(result) ? "error" : result;
    }

    private async Task<string> GuardarProductoEscritorioAsync(Producto producto, CancellationToken cancellationToken)
    {
        var isEdit = producto.IdProducto > 0;
        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(isEdit ? "editarProducto" : "ingresarProducto", con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };

        await con.OpenAsync(cancellationToken);
        if (await ExisteCodigoProductoAsync(con, producto.ProductoCodigo, producto.IdProducto, cancellationToken))
        {
            return "existe Codigo";
        }

        if (isEdit)
        {
            AddDecimal(cmd, "@IdProducto", producto.IdProducto);
        }

        var aplicaInv = ResolveProductoInv(producto);
        AddDecimal(cmd, "@IdSubLinea", producto.IdSubLinea ?? 0);
        AddVarChar(cmd, "@ProductoCodigo", producto.ProductoCodigo);
        AddVarChar(cmd, "@ProductoNombre", producto.ProductoNombre);
        AddVarChar(cmd, "@ProductoMarca", producto.ProductoMarca);
        AddDecimal(cmd, "@ProductoTipoCambio", producto.ProductoTipoCambio ?? 0m);
        AddDecimal(cmd, "@ProductoCostoDolar", producto.ProductoCostoDolar ?? 0m);
        AddVarChar(cmd, "@ProductoUM", producto.ProductoUM);
        AddDecimal(cmd, "@ProductoCosto", producto.ProductoCosto ?? 0m);
        AddDecimal(cmd, "@ProductoVenta", producto.ProductoVenta ?? 0m);
        AddVarChar(cmd, "@ProductoINV", aplicaInv);
        AddNullableDecimal(cmd, "@AlmacenId", producto.AlmacenId);
        AddVarChar(cmd, "@ProductoUbicacion", producto.ProductoUbicacion);
        AddDecimal(cmd, "@ProductoCantidad", producto.ProductoCantidad ?? 0m);
        AddVarChar(cmd, "@ProductoObs", producto.ProductoObs);
        AddVarChar(cmd, "@ProductoEstado", ResolveEstadoProducto(producto.ProductoEstado));
        AddVarChar(cmd, "@ProductoUsuario", producto.ProductoUsuario);
        AddVarChar(cmd, "@ProductoImagen", producto.ProductoImagen);
        AddDecimal(cmd, "@ValorCritico", producto.ValorCritico ?? 0m);
        AddDecimal(cmd, "@ProductoPV", producto.ProductoPV ?? 0m);
        AddDecimal(cmd, "@ProductoSV", producto.ProductoSV ?? 0m);
        if (isEdit)
        {
            cmd.Parameters.Add("@AVISO", SqlDbType.Int).Value = 0;
        }
        AddDecimal(cmd, "@ProductoxCaja", producto.ProductoxCaja ?? 0m);
        AddVarChar(cmd, "@AplicaFB", string.IsNullOrWhiteSpace(producto.AplicaFB) ? "S" : producto.AplicaFB);

        if (isEdit)
        {
            await cmd.ExecuteNonQueryAsync(cancellationToken);
            return producto.IdProducto.ToString(CultureInfo.InvariantCulture);
        }

        var result = await cmd.ExecuteScalarAsync(cancellationToken);
        return Convert.ToString(result, CultureInfo.InvariantCulture) ?? "error";
    }

    private static async Task<bool> ExisteCodigoProductoAsync(
        SqlConnection con,
        string? codigo,
        long idProducto,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(codigo))
        {
            return false;
        }

        const string sql = """
            SELECT TOP 1 1
            FROM Producto
            WHERE ProductoCodigo = @ProductoCodigo
              AND IdProducto <> @IdProducto;
            """;

        await using var cmd = new SqlCommand(sql, con)
        {
            CommandTimeout = 30,
            CommandType = CommandType.Text
        };
        cmd.Parameters.AddWithValue("@ProductoCodigo", codigo.Trim());
        cmd.Parameters.AddWithValue("@IdProducto", idProducto);
        var result = await cmd.ExecuteScalarAsync(cancellationToken);
        return result is not null && result != DBNull.Value;
    }

    public async Task<bool> EliminarAsync(long id, CancellationToken cancellationToken = default)
    {
        const string sql = "uspEliminarProducto";
        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.AddWithValue("@Id", id);
        await con.OpenAsync(cancellationToken);
        return await cmd.ExecuteNonQueryAsync(cancellationToken) > 0;
    }

    public async Task<Producto?> ObtenerPorIdAsync(long id, CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT *
            FROM Producto
            WHERE IdProducto = @Id;
            """;

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddWithValue("@Id", id);
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? MapProducto(reader) : null;
    }

    public async Task<Producto?> ObtenerPorCodigoAsync(string codigo, CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT TOP 1 * FROM Producto WHERE ProductoCodigo = @Codigo;";

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddWithValue("@Codigo", codigo.Trim());
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? MapProducto(reader) : null;
    }

    public async Task<string> ListarCrudRawAsync(string? estado = "ACTIVO", CancellationToken cancellationToken = default)
    {
        try
        {
            return estado is null
                ? await _accesoDatos.EjecutarComandoAsync("uspListarProducto", cancellationToken: cancellationToken)
                : await _accesoDatos.EjecutarComandoAsync("uspListarProducto", "@Estado", estado, cancellationToken);
        }
        catch (SqlException ex) when (ex.Number == 2812)
        {
            return await TableExistsAsync("Producto", cancellationToken)
                ? await ListarProductoTableRawAsync(estado, cancellationToken)
                : await ListarProductsRawAsync(estado, cancellationToken);
        }
    }

    public async Task<IReadOnlyList<Producto>> ListarCrudAsync(string? estado = "ACTIVO", int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
    {
        var result = await ListarCrudRawAsync(estado, cancellationToken);

        var lista = string.IsNullOrWhiteSpace(result) ? new List<Producto>() : ParseProductosCrud(result);
        return ApplyPagination(lista, page, pageSize);
    }

    public async Task<IReadOnlyList<Producto>> ListarServiciosAsync(
        string? estado = "ACTIVO",
        string? nombre = null,
        int page = 1,
        int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        var result = await ListarCrudRawAsync(estado, cancellationToken);
        var lista = string.IsNullOrWhiteSpace(result) ? new List<Producto>() : ParseProductosCrud(result);

        var servicios = lista
            .Where(producto => !string.Equals(
                (producto.AplicaINV ?? string.Empty).Trim(),
                "S",
                StringComparison.OrdinalIgnoreCase));

        if (!string.IsNullOrWhiteSpace(nombre))
        {
            var termino = nombre.Trim();
            servicios = servicios.Where(producto =>
                (producto.ProductoNombre ?? string.Empty).Contains(termino, StringComparison.OrdinalIgnoreCase) ||
                (producto.ProductoCodigo ?? string.Empty).Contains(termino, StringComparison.OrdinalIgnoreCase));
        }

        return ApplyPagination(servicios.ToList(), page, pageSize);
    }

    public async Task<IReadOnlyList<EListaProducto>> ListarAsync(int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
    {
        var result = await _accesoDatos.EjecutarComandoAsync("uspListaWebProducto", cancellationToken: cancellationToken);
        var lista = string.IsNullOrWhiteSpace(result) ? new List<EListaProducto>() : Cadena.AlistaCamposPro(result);
        return ApplyPagination(lista, page, pageSize);
    }

    public async Task<IReadOnlyList<EListaProducto>> BuscarProductoAsync(string nombre, int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
    {
        var result = await _accesoDatos.EjecutarComandoAsync("uspBuscaWebProducto", "@Descripcion", nombre, cancellationToken);
        var lista = string.IsNullOrWhiteSpace(result) ? new List<EListaProducto>() : Cadena.AlistaCamposPro(result);
        return ApplyPagination(lista, page, pageSize);
    }

    public async Task<long> GuardarUnidadMedidaProductoAsync(GuardarUnidadMedidaProductoRequest request, CancellationToken cancellationToken = default)
    {
        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand("dbo.uspGuardarUnidadMedidaProducto", con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };

        cmd.Parameters.Add(new SqlParameter("@IdProducto", SqlDbType.Decimal)
        {
            Precision = 20,
            Scale = 0,
            Value = request.IdProducto
        });
        cmd.Parameters.Add(new SqlParameter("@UMDescripcion", SqlDbType.VarChar, 100)
        {
            Value = request.UMDescripcion.Trim()
        });
        cmd.Parameters.Add(new SqlParameter("@ValorUM", SqlDbType.Decimal)
        {
            Precision = 18,
            Scale = 2,
            Value = request.ValorUM
        });
        cmd.Parameters.Add(new SqlParameter("@PrecioVenta", SqlDbType.Decimal)
        {
            Precision = 18,
            Scale = 2,
            Value = request.PrecioVenta
        });
        cmd.Parameters.Add(new SqlParameter("@PrecioVentaB", SqlDbType.Decimal)
        {
            Precision = 18,
            Scale = 2,
            Value = request.PrecioVentaB
        });
        cmd.Parameters.Add(new SqlParameter("@PrecioCosto", SqlDbType.Decimal)
        {
            Precision = 18,
            Scale = 2,
            Value = request.PrecioCosto
        });

        await con.OpenAsync(cancellationToken);
        if (await StoredProcedureHasParameterAsync(con, "uspGuardarUnidadMedidaProducto", "@UnidadImagen", cancellationToken))
        {
            cmd.Parameters.Add(new SqlParameter("@UnidadImagen", SqlDbType.VarChar, -1)
            {
                Value = string.IsNullOrWhiteSpace(request.UnidadImagen)
                    ? DBNull.Value
                    : request.UnidadImagen.Trim()
            });
        }

        var result = await cmd.ExecuteScalarAsync(cancellationToken);
        if (result is null || result == DBNull.Value)
        {
            throw new InvalidOperationException("El procedimiento no devolvió IdUm.");
        }

        return Convert.ToInt64(result);
    }

    private static Producto MapProducto(SqlDataReader reader)
    {
        var aplicaInv = ReadString(reader, "AplicaINV") ?? ReadString(reader, "ProductoINV");

        return new Producto
        {
            IdProducto = ReadLong(reader, "IdProducto") ?? 0,
            IdSubLinea = ReadLong(reader, "IdSubLinea"),
            ProductoCodigo = ReadString(reader, "ProductoCodigo"),
            ProductoNombre = ReadString(reader, "ProductoNombre"),
            ProductoMarca = ReadString(reader, "ProductoMarca"),
            ProductoTipoCambio = ReadDecimal(reader, "ProductoTipoCambio"),
            ProductoCostoDolar = ReadDecimal(reader, "ProductoCostoDolar"),
            ProductoUM = ReadString(reader, "ProductoUM"),
            ProductoCosto = ReadDecimal(reader, "ProductoCosto"),
            ProductoVenta = ReadDecimal(reader, "ProductoVenta"),
            ProductoVentaB = ReadDecimal(reader, "ProductoVentaB") ?? ReadDecimal(reader, "ProductoVenta"),
            AlmacenId = ReadLong(reader, "AlmacenId"),
            ProductoUbicacion = ReadString(reader, "ProductoUbicacion"),
            ProductoCantidad = ReadDecimal(reader, "ProductoCantidad"),
            ProductoObs = ReadString(reader, "ProductoObs"),
            ProductoEstado = ReadString(reader, "ProductoEstado"),
            ProductoUsuario = ReadString(reader, "ProductoUsuario"),
            ProductoFecha = ReadDate(reader, "ProductoFecha"),
            ProductoImagen = ReadString(reader, "ProductoImagen"),
            ValorCritico = ReadDecimal(reader, "ValorCritico"),
            AplicaINV = aplicaInv,
            ProductoINV = aplicaInv,
            ProductoPV = ReadDecimal(reader, "ProductoPV"),
            ProductoSV = ReadDecimal(reader, "ProductoSV"),
            ProductoxCaja = ReadDecimal(reader, "ProductoxCaja"),
            AplicaFB = ReadString(reader, "AplicaFB")
        };
    }

    private static IReadOnlyList<EListaProducto> ApplyPagination(IReadOnlyList<EListaProducto> source, int page, int pageSize)
    {
        (page, pageSize) = NormalizePagination(page, pageSize);
        return source.Skip((page - 1) * pageSize).Take(pageSize).ToList();
    }

    private static IReadOnlyList<Producto> ApplyPagination(IReadOnlyList<Producto> source, int page, int pageSize)
    {
        (page, pageSize) = NormalizePagination(page, pageSize);
        return source.Skip((page - 1) * pageSize).Take(pageSize).ToList();
    }

    private static List<Producto> ParseProductosCrud(string data)
    {
        var lista = new List<Producto>();
        var registros = data.Split('¬');

        foreach (var registro in registros)
        {
            var campos = registro.Split('|');
            if (campos.Length == 0 || campos[0] == "~")
            {
                break;
            }

            lista.Add(new Producto
            {
                IdProducto = ToLong(campos, 0),
                IdSubLinea = ToNullableLong(campos, 1),
                ProductoCodigo = ToNullableString(campos, 2),
                ProductoNombre = ToNullableString(campos, 3),
                ProductoUM = ToNullableString(campos, 4),
                ProductoCosto = ToNullableDecimal(campos, 5),
                ProductoVenta = ToNullableDecimal(campos, 6),
                ProductoVentaB = ToNullableDecimal(campos, 7),
                ProductoCantidad = ToNullableDecimal(campos, 8),
                ProductoEstado = ToNullableString(campos, 9),
                ProductoUsuario = ToNullableString(campos, 10),
                ProductoFecha = ToNullableDate(campos, 11),
                ProductoImagen = ToNullableString(campos, 12),
                ValorCritico = ToNullableDecimal(campos, 13),
                AplicaINV = ToNullableString(campos, 14),
                ProductoINV = ToNullableString(campos, 14),
                ProductoPV = ToNullableDecimal(campos, 15),
                ProductoSV = ToNullableDecimal(campos, 16)
            });
        }

        return lista;
    }

    private static string? ToNullableString(string[] campos, int index)
    {
        if (index >= campos.Length) return null;
        var value = campos[index];
        return string.IsNullOrWhiteSpace(value) ? null : value;
    }

    private static long ToLong(string[] campos, int index)
    {
        var value = ToNullableString(campos, index);
        return long.TryParse(value, out var parsed) ? parsed : 0;
    }

    private static long? ToNullableLong(string[] campos, int index)
    {
        var value = ToNullableString(campos, index);
        return long.TryParse(value, out var parsed) ? parsed : null;
    }

    private static decimal? ToNullableDecimal(string[] campos, int index)
    {
        var value = ToNullableString(campos, index);
        return decimal.TryParse(value, out var parsed) ? parsed : null;
    }

    private static DateTime? ToNullableDate(string[] campos, int index)
    {
        var value = ToNullableString(campos, index);
        return DateTime.TryParse(value, out var parsed) ? parsed : null;
    }

    private static (int page, int pageSize) NormalizePagination(int page, int pageSize)
    {
        var normalizedPage = page < 1 ? 1 : page;
        var normalizedPageSize = pageSize < 1 ? 1 : Math.Min(pageSize, 100);
        return (normalizedPage, normalizedPageSize);
    }

    private static string FormatDecimal(decimal? value)
    {
        return (value ?? 0m).ToString(CultureInfo.InvariantCulture);
    }

    private static string? NormalizeDetalleUm(string? detalleUm)
    {
        if (string.IsNullOrWhiteSpace(detalleUm))
        {
            return null;
        }

        var normalized = detalleUm.Trim();
        if (normalized.StartsWith('[') && normalized.EndsWith(']') && normalized.Length > 1)
        {
            normalized = normalized[1..^1].Trim();
        }

        return string.IsNullOrWhiteSpace(normalized) ? null : normalized;
    }

    private static string? ResolveDetalleUm(Producto producto)
    {
        return NormalizeDetalleUm(producto.DetalleUm)
            ?? NormalizeDetalleUm(producto.DetalleUM)
            ?? NormalizeDetalleUm(producto.UnidadMedidaDetalle);
    }

    private static bool TryExtractDetalleDesdeAplicaInv(string aplicaInv, out string aplicaInvLimpio, out string? detalleUm)
    {
        aplicaInvLimpio = aplicaInv;
        detalleUm = null;

        if (string.IsNullOrWhiteSpace(aplicaInv))
        {
            return false;
        }

        var openIndex = aplicaInv.IndexOf('[');
        if (openIndex <= 0)
        {
            return false;
        }

        aplicaInvLimpio = aplicaInv[..openIndex].Trim();

        var closeIndex = aplicaInv.LastIndexOf(']');
        var rawDetalle = closeIndex > openIndex
            ? aplicaInv.Substring(openIndex + 1, closeIndex - openIndex - 1)
            : aplicaInv[(openIndex + 1)..];

        detalleUm = string.IsNullOrWhiteSpace(rawDetalle) ? null : rawDetalle.Trim();
        return true;
    }

    private static string ReplaceProductoImagenInRawData(string rawData, string? productoImagen)
    {
        if (productoImagen is null)
        {
            return rawData;
        }

        var openIndex = rawData.IndexOf('[');
        var closeIndex = rawData.LastIndexOf(']');
        var hasDetalle = openIndex >= 0 && closeIndex > openIndex;

        var cabecera = hasDetalle ? rawData[..openIndex] : rawData;
        var campos = cabecera.Split('|');
        if (campos.Length < 14)
        {
            return rawData;
        }

        campos[11] = productoImagen.Trim();
        var cabeceraActualizada = string.Join("|", campos);
        return hasDetalle ? $"{cabeceraActualizada}{rawData[openIndex..]}" : cabeceraActualizada;
    }

    private static void ApplyRawDataToProducto(Producto producto, string rawData)
    {
        var openIndex = rawData.IndexOf('[');
        var cabecera = openIndex >= 0 ? rawData[..openIndex] : rawData;
        var campos = cabecera.Split('|');
        if (campos.Length < 14)
        {
            return;
        }

        producto.IdProducto = ToLong(campos, 0);
        producto.IdSubLinea = ToNullableLong(campos, 1);
        producto.ProductoCodigo = ToNullableString(campos, 2);
        producto.ProductoNombre = ToNullableString(campos, 3);
        producto.ProductoUM = ToNullableString(campos, 4);
        producto.ProductoCosto = ToNullableDecimal(campos, 5);
        producto.ProductoVenta = ToNullableDecimal(campos, 6);
        producto.ProductoVentaB = ToNullableDecimal(campos, 7);
        producto.ProductoCantidad = ToNullableDecimal(campos, 8);
        producto.ProductoEstado = ToNullableString(campos, 9);
        producto.ProductoUsuario = ToNullableString(campos, 10);
        producto.ProductoImagen = ToNullableString(campos, 11);
        producto.ValorCritico = ToNullableDecimal(campos, 12);
        producto.AplicaINV = ToNullableString(campos, 13);
        producto.ProductoINV = producto.AplicaINV;
        producto.ProductoPV = ToNullableDecimal(campos, 14) ?? producto.ProductoPV;
        producto.ProductoSV = ToNullableDecimal(campos, 15) ?? producto.ProductoSV;
    }

    private static string? ExtractDetalleUm(string rawData)
    {
        if (string.IsNullOrWhiteSpace(rawData))
        {
            return null;
        }

        var openIndex = rawData.IndexOf('[');
        var closeIndex = rawData.LastIndexOf(']');
        if (openIndex < 0 || closeIndex <= openIndex)
        {
            return null;
        }

        var detalle = rawData.Substring(openIndex + 1, closeIndex - openIndex - 1).Trim();
        return string.IsNullOrWhiteSpace(detalle) ? null : detalle;
    }

    private async Task<string> ListarProductsRawAsync(string? estado, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT p.Id, p.CategoryId, p.Nombre, p.Precio, p.Stock, p.Status,
                   p.CreatedBy, p.CreatedDate, img.Url AS ImagenUrl
            FROM Products p
            OUTER APPLY (
                SELECT TOP 1 i.Url
                FROM Images i
                WHERE i.ProductId = p.Id
                ORDER BY i.Id
            ) img
            ORDER BY p.Id;
            """;

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.Text
        };

        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        var rows = new List<string>();

        while (await reader.ReadAsync(cancellationToken))
        {
            var status = reader["Status"] == DBNull.Value ? 1 : Convert.ToInt32(reader["Status"]);
            var productoEstado = status == 0 ? "INACTIVO" : "ACTIVO";
            if (!string.IsNullOrWhiteSpace(estado) &&
                !string.Equals(estado, productoEstado, StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            var id = Convert.ToInt64(reader["Id"]);
            var precio = reader["Precio"] == DBNull.Value ? 0m : Convert.ToDecimal(reader["Precio"]);
            var stock = reader["Stock"] == DBNull.Value ? 0m : Convert.ToDecimal(reader["Stock"]);
            var createdDate = reader["CreatedDate"] == DBNull.Value
                ? string.Empty
                : Convert.ToDateTime(reader["CreatedDate"]).ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);

            rows.Add(string.Join("|",
                id.ToString(CultureInfo.InvariantCulture),
                Field(reader["CategoryId"]),
                id.ToString(CultureInfo.InvariantCulture),
                Field(reader["Nombre"]),
                "UND",
                "0",
                precio.ToString(CultureInfo.InvariantCulture),
                precio.ToString(CultureInfo.InvariantCulture),
                stock.ToString(CultureInfo.InvariantCulture),
                productoEstado,
                Field(reader["CreatedBy"]),
                createdDate,
                Field(reader["ImagenUrl"]),
                "0",
                "S"));
        }

        return rows.Count == 0 ? "~" : $"{string.Join("¬", rows)}¬~";
    }

    private async Task<string> ListarProductoTableRawAsync(string? estado, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT *
            FROM Producto
            WHERE (@Estado IS NULL OR @Estado = '' OR ProductoEstado = @Estado
                   OR (@Estado = 'ACTIVO' AND ProductoEstado = 'BUENO'))
            ORDER BY ProductoCodigo;
            """;

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.Text
        };
        cmd.Parameters.AddWithValue("@Estado", (object?)estado ?? DBNull.Value);

        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        var rows = new List<string>();

        while (await reader.ReadAsync(cancellationToken))
        {
            var aplicaInv = Field(reader, "ProductoINV");
            if (string.IsNullOrWhiteSpace(aplicaInv))
            {
                aplicaInv = Field(reader, "AplicaINV");
            }

            rows.Add(string.Join("|",
                Field(reader, "IdProducto"),
                Field(reader, "IdSubLinea"),
                Field(reader, "ProductoCodigo"),
                Field(reader, "ProductoNombre"),
                Field(reader, "ProductoUM"),
                Field(reader, "ProductoCosto"),
                Field(reader, "ProductoVenta"),
                Field(reader, "ProductoVentaB", "ProductoVenta"),
                Field(reader, "ProductoCantidad"),
                Field(reader, "ProductoEstado"),
                Field(reader, "ProductoUsuario"),
                Field(reader, "ProductoFecha"),
                Field(reader, "ProductoImagen"),
                Field(reader, "ValorCritico"),
                aplicaInv,
                Field(reader, "ProductoPV"),
                Field(reader, "ProductoSV")));
        }

        return rows.Count == 0 ? "~" : $"{string.Join("¬", rows)}¬~";
    }

    private async Task<bool> TableExistsAsync(string tableName, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1 1
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @TableName;
            """;

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con)
        {
            CommandTimeout = 30,
            CommandType = CommandType.Text
        };
        cmd.Parameters.AddWithValue("@TableName", tableName);
        await con.OpenAsync(cancellationToken);
        var result = await cmd.ExecuteScalarAsync(cancellationToken);
        return result is not null && result != DBNull.Value;
    }

    private static string Field(object value)
    {
        if (value == DBNull.Value) return string.Empty;
        return Convert.ToString(value, CultureInfo.InvariantCulture)?
            .Replace("|", " ")
            .Replace("¬", " ")
            .Replace("[", " ")
            .Replace("]", " ")
            .Replace("\r", " ")
            .Replace("\n", " ")
            .Trim() ?? string.Empty;
    }

    private static string Field(SqlDataReader reader, string columnName, string? fallbackColumnName = null)
    {
        if (HasColumn(reader, columnName))
        {
            return Field(reader[columnName]);
        }

        return fallbackColumnName is not null && HasColumn(reader, fallbackColumnName)
            ? Field(reader[fallbackColumnName])
            : string.Empty;
    }

    private static bool HasColumn(IDataRecord reader, string columnName)
    {
        for (var i = 0; i < reader.FieldCount; i++)
        {
            if (string.Equals(reader.GetName(i), columnName, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }

    private static string? ReadString(SqlDataReader reader, string columnName)
    {
        if (!HasColumn(reader, columnName) || reader[columnName] == DBNull.Value)
        {
            return null;
        }

        var value = Convert.ToString(reader[columnName], CultureInfo.InvariantCulture);
        return string.IsNullOrWhiteSpace(value) ? null : value;
    }

    private static long? ReadLong(SqlDataReader reader, string columnName)
    {
        if (!HasColumn(reader, columnName) || reader[columnName] == DBNull.Value)
        {
            return null;
        }

        return Convert.ToInt64(reader[columnName], CultureInfo.InvariantCulture);
    }

    private static decimal? ReadDecimal(SqlDataReader reader, string columnName)
    {
        if (!HasColumn(reader, columnName) || reader[columnName] == DBNull.Value)
        {
            return null;
        }

        return Convert.ToDecimal(reader[columnName], CultureInfo.InvariantCulture);
    }

    private static DateTime? ReadDate(SqlDataReader reader, string columnName)
    {
        if (!HasColumn(reader, columnName) || reader[columnName] == DBNull.Value)
        {
            return null;
        }

        return Convert.ToDateTime(reader[columnName], CultureInfo.InvariantCulture);
    }

    private static string ResolveProductoInv(Producto producto)
    {
        var value = producto.ProductoINV ?? producto.AplicaINV;
        return string.Equals(value?.Trim(), "N", StringComparison.OrdinalIgnoreCase) ? "N" : "S";
    }

    private static string ResolveEstadoProducto(string? estado)
    {
        return string.Equals(estado?.Trim(), "INACTIVO", StringComparison.OrdinalIgnoreCase)
            ? "MALO"
            : "BUENO";
    }

    private static void AddVarChar(SqlCommand cmd, string name, string? value)
    {
        cmd.Parameters.Add(name, SqlDbType.VarChar).Value = string.IsNullOrWhiteSpace(value)
            ? string.Empty
            : value.Trim();
    }

    private static void AddDecimal(SqlCommand cmd, string name, long value)
    {
        AddDecimal(cmd, name, Convert.ToDecimal(value, CultureInfo.InvariantCulture));
    }

    private static void AddDecimal(SqlCommand cmd, string name, decimal value)
    {
        var parameter = cmd.Parameters.Add(name, SqlDbType.Decimal);
        parameter.Precision = 20;
        parameter.Scale = 4;
        parameter.Value = value;
    }

    private static void AddNullableDecimal(SqlCommand cmd, string name, long? value)
    {
        var parameter = cmd.Parameters.Add(name, SqlDbType.Decimal);
        parameter.Precision = 20;
        parameter.Scale = 0;
        parameter.Value = value.HasValue && value.Value > 0 ? value.Value : DBNull.Value;
    }

    private static async Task<bool> StoredProcedureHasParameterAsync(
        SqlConnection connection,
        string procedureName,
        string parameterName,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1 1
            FROM sys.parameters p
            INNER JOIN sys.objects o ON o.object_id = p.object_id
            WHERE o.type = 'P'
              AND o.name = @ProcedureName
              AND p.name = @ParameterName;
            """;

        await using var cmd = new SqlCommand(sql, connection)
        {
            CommandTimeout = 30,
            CommandType = CommandType.Text
        };
        cmd.Parameters.AddWithValue("@ProcedureName", procedureName);
        cmd.Parameters.AddWithValue("@ParameterName", parameterName);

        var result = await cmd.ExecuteScalarAsync(cancellationToken);
        return result is not null && result != DBNull.Value;
    }
}

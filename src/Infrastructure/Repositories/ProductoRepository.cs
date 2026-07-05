using System.Data;
using System.Globalization;
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
            var resultRaw = await _accesoDatos.EjecutarComandoAsync("uspIngresarProducto", "@Data", rawData, cancellationToken);
            return string.IsNullOrWhiteSpace(resultRaw) ? "error" : resultRaw;
        }

        var aplicaInv = (producto.AplicaINV ?? string.Empty).Trim();
        var detalleUm = ResolveDetalleUm(producto);

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
            SELECT IdProducto, IdSubLinea, ProductoCodigo, ProductoNombre, ProductoUM, ProductoCosto,
                   ProductoVenta, ProductoVentaB, ProductoCantidad, ProductoEstado, ProductoUsuario,
                   ProductoFecha, ProductoImagen, ValorCritico, AplicaINV
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
        return new Producto
        {
            IdProducto = Convert.ToInt64(reader["IdProducto"]),
            IdSubLinea = reader["IdSubLinea"] == DBNull.Value ? null : Convert.ToInt64(reader["IdSubLinea"]),
            ProductoCodigo = reader["ProductoCodigo"]?.ToString(),
            ProductoNombre = reader["ProductoNombre"]?.ToString(),
            ProductoUM = reader["ProductoUM"]?.ToString(),
            ProductoCosto = reader["ProductoCosto"] == DBNull.Value ? null : Convert.ToDecimal(reader["ProductoCosto"]),
            ProductoVenta = reader["ProductoVenta"] == DBNull.Value ? null : Convert.ToDecimal(reader["ProductoVenta"]),
            ProductoVentaB = reader["ProductoVentaB"] == DBNull.Value ? null : Convert.ToDecimal(reader["ProductoVentaB"]),
            ProductoCantidad = reader["ProductoCantidad"] == DBNull.Value ? null : Convert.ToDecimal(reader["ProductoCantidad"]),
            ProductoEstado = reader["ProductoEstado"]?.ToString(),
            ProductoUsuario = reader["ProductoUsuario"]?.ToString(),
            ProductoFecha = reader["ProductoFecha"] == DBNull.Value ? null : Convert.ToDateTime(reader["ProductoFecha"]),
            ProductoImagen = reader["ProductoImagen"]?.ToString(),
            ValorCritico = reader["ValorCritico"] == DBNull.Value ? null : Convert.ToDecimal(reader["ValorCritico"]),
            AplicaINV = reader["AplicaINV"]?.ToString()
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
                AplicaINV = ToNullableString(campos, 14)
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
            SELECT IdProducto, IdSubLinea, ProductoCodigo, ProductoNombre, ProductoUM, ProductoCosto,
                   ProductoVenta, ProductoCantidad, ProductoEstado, ProductoUsuario,
                   ProductoFecha, ProductoImagen, ValorCritico, ProductoINV, ProductoPV, ProductoSV
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
            rows.Add(string.Join("|",
                Field(reader["IdProducto"]),
                Field(reader["IdSubLinea"]),
                Field(reader["ProductoCodigo"]),
                Field(reader["ProductoNombre"]),
                Field(reader["ProductoUM"]),
                Field(reader["ProductoCosto"]),
                Field(reader["ProductoVenta"]),
                Field(reader["ProductoVenta"]),
                Field(reader["ProductoCantidad"]),
                Field(reader["ProductoEstado"]),
                Field(reader["ProductoUsuario"]),
                Field(reader["ProductoFecha"]),
                Field(reader["ProductoImagen"]),
                Field(reader["ValorCritico"]),
                Field(reader["ProductoINV"]),
                Field(reader["ProductoPV"]),
                Field(reader["ProductoSV"])));
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

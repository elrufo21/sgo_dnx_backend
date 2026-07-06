using System.Data;
using Ecommerce.Application.Contracts.Clientes;
using Ecommerce.Domain;
using Ecommerce.Infrastructure.Persistence;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public class ClienteRepository : ICliente
{
    private readonly string _connectionString;
    private readonly AccesoDatos _accesoDatos;

    public ClienteRepository(IConfiguration configuration, AccesoDatos accesoDatos)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");
        _accesoDatos = accesoDatos;
    }

    public async Task<string> InsertarAsync(Cliente cliente, CancellationToken cancellationToken = default)
    {
        var data = $"{cliente.ClienteId}|{cliente.ClienteRazon?.Trim()}|{cliente.ClienteRuc?.Trim()}|{cliente.ClienteDni?.Trim()}|{cliente.ClienteDireccion?.Trim()}|{cliente.ClienteTelefono}|{cliente.ClienteCorreo?.Trim()}|{cliente.ClienteEstado}|{cliente.ClienteDespacho?.Trim()}|{cliente.ClienteUsuario}";
        var result = await _accesoDatos.EjecutarComandoAsync("uspInsertarCliente", "@Data", data, cancellationToken);
        if (!string.IsNullOrWhiteSpace(cliente.ClienteCodigo))
        {
            var id = cliente.ClienteId > 0
                ? cliente.ClienteId
                : long.TryParse((result ?? "").Split('|')[0].Trim(), out var parsedId)
                    ? parsedId
                    : 0;
            if (id > 0) await ActualizarCodigoAsync(id, cliente.ClienteCodigo, cancellationToken);
        }

        return string.IsNullOrWhiteSpace(result) ? "error" : result;
    }

    public async Task<bool> EliminarAsync(long id, CancellationToken cancellationToken = default)
    {
        const string sql = "uspEliminarCliente";
        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.AddWithValue("@Id", id);
        await con.OpenAsync(cancellationToken);
        var rows = await cmd.ExecuteNonQueryAsync(cancellationToken);
        return rows > 0;
    }

    public async Task<IReadOnlyList<Cliente>> ListarAsync(string? estado = "ACTIVO", string? search = null, int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
    {
        return (await ListarPaginadoAsync(estado, search, page, pageSize, cancellationToken)).Items;
    }

    public async Task<ClienteListResult> ListarPaginadoAsync(string? estado = "ACTIVO", string? search = null, int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
    {
        (page, pageSize) = NormalizePagination(page, pageSize);
        var searchTerm = (search ?? string.Empty).Trim();
        var start = ((page - 1) * pageSize) + 1;
        var end = page * pageSize;

        const string sql = """
            WITH ClientesFiltrados AS (
                SELECT ClienteId, ClienteCodigo, ClienteRazon, ClienteRuc, ClienteDni, ClienteDireccion, ClienteTelefono,
                       ClienteCorreo, ClienteEstado, ClienteDespacho, ClienteUsuario, ClienteFecha,
                       COUNT(*) OVER() AS TotalRows,
                       ROW_NUMBER() OVER (ORDER BY ClienteRazon, ClienteId) AS RowNum
                FROM Cliente
                WHERE (@Estado IS NULL OR @Estado = '' OR ClienteEstado = @Estado)
                  AND (
                    @Search = ''
                    OR ISNULL(ClienteCodigo, '') LIKE @SearchLike
                    OR ISNULL(ClienteRazon, '') LIKE @SearchLike
                    OR ISNULL(ClienteRuc, '') LIKE @SearchLike
                    OR ISNULL(ClienteDni, '') LIKE @SearchLike
                  )
            )
            SELECT ClienteId, ClienteCodigo, ClienteRazon, ClienteRuc, ClienteDni, ClienteDireccion, ClienteTelefono,
                   ClienteCorreo, ClienteEstado, ClienteDespacho, ClienteUsuario, ClienteFecha, TotalRows
            FROM ClientesFiltrados
            WHERE RowNum BETWEEN @Start AND @End
            ORDER BY RowNum;
            """;

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddWithValue("@Estado", (object?)estado ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@Search", searchTerm);
        cmd.Parameters.AddWithValue("@SearchLike", $"%{searchTerm}%");
        cmd.Parameters.AddWithValue("@Start", start);
        cmd.Parameters.AddWithValue("@End", end);
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);

        var lista = new List<Cliente>();
        var total = 0;
        while (await reader.ReadAsync(cancellationToken))
        {
            total = Convert.ToInt32(reader["TotalRows"]);
            lista.Add(MapCliente(reader));
        }

        return new ClienteListResult { Items = lista, Total = total };
    }

    public async Task<Cliente?> ObtenerPorIdAsync(long id, CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT TOP 1 ClienteId, ClienteCodigo, ClienteRazon, ClienteRuc, ClienteDni, ClienteDireccion, ClienteTelefono,
                   ClienteCorreo, ClienteEstado, ClienteDespacho, ClienteUsuario, ClienteFecha
            FROM Cliente
            WHERE ClienteId = @Id;
            """;

        return await ObtenerUnoAsync(sql, cmd => cmd.Parameters.AddWithValue("@Id", id), cancellationToken);
    }

    public async Task<Cliente?> ObtenerPorCodigoAsync(string codigo, CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT TOP 1 ClienteId, ClienteCodigo, ClienteRazon, ClienteRuc, ClienteDni, ClienteDireccion, ClienteTelefono,
                   ClienteCorreo, ClienteEstado, ClienteDespacho, ClienteUsuario, ClienteFecha
            FROM Cliente
            WHERE LTRIM(RTRIM(ISNULL(ClienteCodigo, ''))) = @Codigo;
            """;

        return await ObtenerUnoAsync(sql, cmd => cmd.Parameters.AddWithValue("@Codigo", (codigo ?? string.Empty).Trim()), cancellationToken);
    }

    public async Task<string> ListarComboAsync(CancellationToken cancellationToken = default)
    {
        var result = await _accesoDatos.EjecutarComandoAsync("uspListaComboClienteWeb", cancellationToken: cancellationToken);
        return string.IsNullOrWhiteSpace(result) ? string.Empty : result;
    }

    private static (int page, int pageSize) NormalizePagination(int page, int pageSize)
    {
        var normalizedPage = page < 1 ? 1 : page;
        var normalizedPageSize = pageSize < 1 ? 1 : Math.Min(pageSize, 100);
        return (normalizedPage, normalizedPageSize);
    }

    private async Task<Cliente?> ObtenerUnoAsync(string sql, Action<SqlCommand> configure, CancellationToken cancellationToken)
    {
        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con);
        configure(cmd);
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? MapCliente(reader) : null;
    }

    private async Task ActualizarCodigoAsync(long clienteId, string codigo, CancellationToken cancellationToken)
    {
        const string sql = "UPDATE Cliente SET ClienteCodigo = @Codigo WHERE ClienteId = @ClienteId;";
        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddWithValue("@ClienteId", clienteId);
        cmd.Parameters.AddWithValue("@Codigo", codigo.Trim());
        await con.OpenAsync(cancellationToken);
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }

    private static Cliente MapCliente(IDataRecord reader) => new()
    {
        ClienteId = Convert.ToInt64(reader["ClienteId"]),
        ClienteCodigo = reader["ClienteCodigo"].ToString(),
        ClienteRazon = reader["ClienteRazon"].ToString(),
        ClienteRuc = reader["ClienteRuc"].ToString(),
        ClienteDni = reader["ClienteDni"].ToString(),
        ClienteDireccion = reader["ClienteDireccion"].ToString(),
        ClienteTelefono = reader["ClienteTelefono"].ToString(),
        ClienteCorreo = reader["ClienteCorreo"].ToString(),
        ClienteEstado = reader["ClienteEstado"].ToString(),
        ClienteDespacho = reader["ClienteDespacho"].ToString(),
        ClienteUsuario = reader["ClienteUsuario"].ToString(),
        ClienteFecha = reader["ClienteFecha"] == DBNull.Value ? null : Convert.ToDateTime(reader["ClienteFecha"])
    };
}

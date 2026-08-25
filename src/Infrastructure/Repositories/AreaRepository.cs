using System.Data;
using Ecommerce.Application.Contracts.Areas;
using Ecommerce.Domain;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public class AreaRepository : IArea
{
    private readonly string _connectionString;
    public AreaRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");
    }

    public Task<string> InsertarAsync(Area area, CancellationToken cancellationToken = default)
    {
        var data = area.AreaId > 0
            ? $"ACTUALIZAR|{area.AreaId}|{area.AreaNombre?.Trim()}"
            : $"CREAR|{area.AreaNombre?.Trim()}";
        return EjecutarAsync(data, cancellationToken);
    }

    public async Task<bool> EliminarAsync(int id, CancellationToken cancellationToken = default)
    {
        var result = await EjecutarAsync($"ELIMINAR|{id}", cancellationToken);
        return result.StartsWith("OK|", StringComparison.OrdinalIgnoreCase);
    }

    public async Task<IReadOnlyList<EGeneral>> ListarAsync(int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
    {
        (page, pageSize) = NormalizePagination(page, pageSize);

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = CrearComando(con, "LISTAR");
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);

        var areas = new List<EGeneral>();
        while (await reader.ReadAsync(cancellationToken))
        {
            var values = reader["Data"]?.ToString()?.Split('|', 2) ?? Array.Empty<string>();
            if (values.Length < 2 || string.IsNullOrWhiteSpace(values[0])) continue;
            areas.Add(new EGeneral { Id = values[0].Trim(), Nombre = values[1].Trim() });
        }

        return areas.Skip((page - 1) * pageSize).Take(pageSize).ToList();
    }

    private async Task<string> EjecutarAsync(string data, CancellationToken cancellationToken)
    {
        await using var con = new SqlConnection(_connectionString);
        await using var cmd = CrearComando(con, data);
        await con.OpenAsync(cancellationToken);
        return (await cmd.ExecuteScalarAsync(cancellationToken))?.ToString()?.Trim() ?? string.Empty;
    }

    private static SqlCommand CrearComando(SqlConnection con, string data)
    {
        var cmd = new SqlCommand("dbo.usp_Area", con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.Add("@Data", SqlDbType.VarChar, -1).Value = data;
        return cmd;
    }

    private static (int page, int pageSize) NormalizePagination(int page, int pageSize)
    {
        var normalizedPage = page < 1 ? 1 : page;
        var normalizedPageSize = pageSize < 1 ? 1 : Math.Min(pageSize, 100);
        return (normalizedPage, normalizedPageSize);
    }
}

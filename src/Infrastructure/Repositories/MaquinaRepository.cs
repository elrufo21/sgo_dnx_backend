using Ecommerce.Application.Contracts.Maquinas;
using Ecommerce.Domain;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public class MaquinaRepository : IMaquina
{
    private readonly string _connectionString;
    public MaquinaRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");
    }

    public Task<string> InsertarAsync(Maquina maquina, CancellationToken cancellationToken = default)
    {
        var data = maquina.IdMaquina > 0
            ? $"ACTUALIZAR|{maquina.IdMaquina}|{maquina.NombreMaquina?.Trim()}|{maquina.SerieFactura?.Trim()}|{maquina.SerieNC?.Trim()}|{maquina.SerieBoleta?.Trim()}|{maquina.Tiketera?.Trim()}"
            : $"CREAR|{maquina.NombreMaquina?.Trim()}|{maquina.SerieFactura?.Trim()}|{maquina.SerieNC?.Trim()}|{maquina.SerieBoleta?.Trim()}|{maquina.Tiketera?.Trim()}";
        return EjecutarAsync(data, cancellationToken);
    }

    public async Task<bool> EliminarAsync(int id, CancellationToken cancellationToken = default)
    {
        var result = await EjecutarAsync($"ELIMINAR|{id}", cancellationToken);
        return result.StartsWith("OK|", StringComparison.OrdinalIgnoreCase);
    }

    public async Task<IReadOnlyList<Maquina>> ListarAsync(int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
    {
        (page, pageSize) = NormalizePagination(page, pageSize);

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = CrearComando(con, "LISTAR");
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);

        var maquinas = new List<Maquina>();
        while (await reader.ReadAsync(cancellationToken))
        {
            var maquina = ParseMaquina(reader["Data"]?.ToString());
            if (maquina is not null) maquinas.Add(maquina);
        }

        return maquinas.Skip((page - 1) * pageSize).Take(pageSize).ToList();
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
        var cmd = new SqlCommand("dbo.usp_Maquina", con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.Add("@Data", SqlDbType.VarChar, -1).Value = data;
        return cmd;
    }

    private static Maquina? ParseMaquina(string? raw)
    {
        var values = raw?.Split('|', 7) ?? Array.Empty<string>();
        if (values.Length < 7 || !int.TryParse(values[0], out var id)) return null;

        return new Maquina
        {
            IdMaquina = id,
            NombreMaquina = values[1],
            Registro = values[2],
            SerieFactura = values[3],
            SerieNC = values[4],
            SerieBoleta = values[5],
            Tiketera = values[6]
        };
    }

    private static (int page, int pageSize) NormalizePagination(int page, int pageSize)
    {
        return (page < 1 ? 1 : page, pageSize < 1 ? 1 : Math.Min(pageSize, 100));
    }
}

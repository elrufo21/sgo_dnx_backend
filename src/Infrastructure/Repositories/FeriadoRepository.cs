using System.Data;
using System.Globalization;
using Ecommerce.Application.Contracts.Feriados;
using Ecommerce.Domain;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public class FeriadoRepository : IFeriado
{
    private readonly string _connectionString;

    public FeriadoRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");
    }

    public async Task<string> InsertarAsync(Feriado feriado, CancellationToken cancellationToken = default)
    {
        var fecha = feriado.Fecha?.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) ?? string.Empty;
        var motivo = feriado.Motivo?.Trim() ?? string.Empty;
        var data = feriado.IdFeriado > 0
            ? $"ACTUALIZAR|{feriado.IdFeriado}|{fecha}|{motivo}"
            : $"CREAR|{fecha}|{motivo}";
        return await EjecutarAsync(data, cancellationToken);
    }

    public async Task<bool> EliminarAsync(int id, CancellationToken cancellationToken = default)
    {
        var result = await EjecutarAsync($"ELIMINAR|{id}", cancellationToken);
        return result.StartsWith("OK|", StringComparison.OrdinalIgnoreCase);
    }

    public async Task<Feriado?> ObtenerPorIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var item = (await ListarAsync(cancellationToken))
            .Split('¬', StringSplitOptions.RemoveEmptyEntries)
            .Select(ParseFeriado)
            .FirstOrDefault(x => x?.IdFeriado == id);
        return item;
    }

    public async Task<string> ListarAsync(CancellationToken cancellationToken = default)
    {
        await using var con = new SqlConnection(_connectionString);
        await using var cmd = CrearComando(con, "LISTAR");
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        var items = new List<string>();
        while (await reader.ReadAsync(cancellationToken))
        {
            var data = reader["Data"]?.ToString()?.Trim();
            if (!string.IsNullOrWhiteSpace(data)) items.Add(data);
        }
        return string.Join('¬', items);
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
        var cmd = new SqlCommand("dbo.usp_Feriado", con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.Add("@Data", SqlDbType.VarChar, -1).Value = data;
        return cmd;
    }

    private static Feriado? ParseFeriado(string raw)
    {
        var values = raw.Split('|');
        if (values.Length < 3 || !int.TryParse(values[0], out var id)) return null;
        return new Feriado
        {
            IdFeriado = id,
            Fecha = DateTime.TryParseExact(values[1], "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var fecha)
                ? fecha
                : null,
            Motivo = string.Join('|', values.Skip(2)).Trim()
        };
    }
}

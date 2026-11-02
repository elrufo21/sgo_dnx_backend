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

    public async Task<string> InsertarAsync(Maquina maquina, CancellationToken cancellationToken = default)
    {
        var nombre = maquina.NombreMaquina?.Trim() ?? string.Empty;
        var serie = maquina.SerieFactura?.Trim() ?? string.Empty;
        if (nombre.Length == 0) return "ERROR|Debe ingresar el nombre de la máquina.";
        if (serie.Length == 0) return "ERROR|Debe ingresar la serie de factura.";
        if (nombre.Length > 140 || serie.Length > 4) return "ERROR|El nombre o la serie de factura excede la longitud permitida.";

        var data = maquina.IdMaquina > 0
            ? $"ACTUALIZAR|{maquina.IdMaquina}|{nombre}|{serie}|{maquina.SerieNC?.Trim()}|{maquina.SerieBoleta?.Trim()}|{maquina.Tiketera?.Trim()}"
            : $"CREAR|{nombre}|{serie}|{maquina.SerieNC?.Trim()}|{maquina.SerieBoleta?.Trim()}|{maquina.Tiketera?.Trim()}";

        await using var con = new SqlConnection(_connectionString);
        await con.OpenAsync(cancellationToken);
        await using var transaction = (SqlTransaction)await con.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
        await using var check = new SqlCommand("""
            SELECT CASE
                WHEN EXISTS (SELECT 1 FROM dbo.MAQUINAS WITH (UPDLOCK, HOLDLOCK)
                    WHERE IdMaquina <> @Id AND UPPER(LTRIM(RTRIM(Maquina))) = UPPER(@Nombre)) THEN 1
                WHEN EXISTS (SELECT 1 FROM dbo.MAQUINAS WITH (UPDLOCK, HOLDLOCK)
                    WHERE IdMaquina <> @Id AND UPPER(LTRIM(RTRIM(SerieFactura))) = UPPER(@Serie)) THEN 2
                ELSE 0 END
            """, con, transaction);
        check.Parameters.Add("@Id", SqlDbType.Int).Value = maquina.IdMaquina;
        check.Parameters.Add("@Nombre", SqlDbType.NVarChar, 140).Value = nombre;
        check.Parameters.Add("@Serie", SqlDbType.NVarChar, 4).Value = serie;
        var duplicate = Convert.ToInt32(await check.ExecuteScalarAsync(cancellationToken));
        if (duplicate != 0)
        {
            await transaction.RollbackAsync(cancellationToken);
            return duplicate == 1
                ? "ERROR|Ya existe una máquina registrada con ese nombre."
                : "ERROR|La serie de factura ya está asignada a otra máquina.";
        }

        await using var cmd = CrearComando(con, data);
        cmd.Transaction = transaction;
        var result = (await cmd.ExecuteScalarAsync(cancellationToken))?.ToString()?.Trim() ?? string.Empty;
        await transaction.CommitAsync(cancellationToken);
        return result;
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

        return maquinas.OrderByDescending(maquina => maquina.IdMaquina)
            .Skip((page - 1) * pageSize).Take(pageSize).ToList();
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

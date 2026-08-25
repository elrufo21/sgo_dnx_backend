using System.Data;
using Ecommerce.Application.Contracts.Lineas;
using Ecommerce.Domain;
using Ecommerce.Infrastructure.Persistence;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public class LineaRepository : ILinea
{
    private readonly string _connectionString;
    private readonly AccesoDatos _accesoDatos;

    public LineaRepository(IConfiguration configuration, AccesoDatos accesoDatos)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");
        _accesoDatos = accesoDatos;
    }

    public async Task<bool> EliminarAsync(int id, CancellationToken cancellationToken = default)
    {
        const string sql = "uspEliminarCategoria";
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

    public async Task<string> InsertarAsync(Linea linea, CancellationToken cancellationToken = default)
    {
        var data = $"{linea.IdSubLinea}|{linea.NombreSublinea?.Trim()}|{linea.CodigoSunat?.Trim()}";
        var result = await _accesoDatos.EjecutarComandoAsync(
            "uspInsertarCategoria",
            "@Data",
            data,
            cancellationToken);
        return string.IsNullOrWhiteSpace(result) ? "error" : result;
    }

    public async Task<IReadOnlyList<EGeneral>> ListarAsync(
        int page = 1,
        int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT IdSubLinea, NombreSublinea, CodigoSunat
            FROM Sublinea
            WHERE ISNULL(NombreSublinea, '') <> ''
            ORDER BY NombreSublinea ASC;
            """;

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con);
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);

        var lista = new List<EGeneral>();
        while (await reader.ReadAsync(cancellationToken))
        {
            lista.Add(new EGeneral
            {
                Id = reader["IdSubLinea"].ToString() ?? string.Empty,
                Nombre = reader["NombreSublinea"].ToString() ?? string.Empty,
                nombreSublinea = reader["NombreSublinea"].ToString() ?? string.Empty,
                CodigoSunat = reader["CodigoSunat"].ToString() ?? string.Empty
            });
        }

        return lista;
    }

    public async Task<string> InsertarMantenimientoAsync(Linea linea, CancellationToken cancellationToken = default)
    {
        var idSublinea = linea.IdSubLinea > 0 ? linea.IdSubLinea : 0;
        var accion = idSublinea > 0 ? "ACTUALIZAR" : "CREAR";
        var vista = string.IsNullOrWhiteSpace(linea.Vista) ? "V" : linea.Vista.Trim();
        var data = idSublinea > 0
            ? $"{accion}|{idSublinea}|{linea.IdLinea}|{linea.NombreSublinea?.Trim()}|{linea.CodigoSunat?.Trim()}|{vista}"
            : $"{accion}|{linea.IdLinea}|{linea.NombreSublinea?.Trim()}|{linea.CodigoSunat?.Trim()}|{vista}";

        var result = await _accesoDatos.EjecutarComandoAsync(
            "usp_Sublinea",
            "@Data",
            data,
            cancellationToken);

        return string.IsNullOrWhiteSpace(result) ? "ERROR|No se obtuvo respuesta." : result;
    }

    public async Task<bool> EliminarMantenimientoAsync(int id, CancellationToken cancellationToken = default)
    {
        if (id <= 0) return false;

        var result = await _accesoDatos.EjecutarComandoAsync(
            "usp_Sublinea",
            "@Data",
            $"ELIMINAR|{id}",
            cancellationToken);

        return result.StartsWith("OK|", StringComparison.OrdinalIgnoreCase);
    }

    public async Task<IReadOnlyList<EGeneral>> ListarMantenimientoAsync(
        int page = 1,
        int pageSize = 50,
        CancellationToken cancellationToken = default)
    {

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand("usp_Sublinea", con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.AddWithValue("@Data", "LISTAR");

        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);

        var lista = new List<EGeneral>();
        while (await reader.ReadAsync(cancellationToken))
        {
            var data = reader.IsDBNull(0) ? string.Empty : reader.GetString(0);
            var fields = data.Split('|', 5, StringSplitOptions.None);
            if (fields.Length < 5 || string.IsNullOrWhiteSpace(fields[0])) continue;

            lista.Add(new EGeneral
            {
                Id = fields[0].Trim(),
                IdLinea = fields[1].Trim(),
                Nombre = fields[2].Trim(),
                nombreSublinea = fields[2].Trim(),
                CodigoSunat = fields[3].Trim(),
                Vista = string.IsNullOrWhiteSpace(fields[4]) ? "V" : fields[4].Trim()
            });
        }

        return lista;
    }
}

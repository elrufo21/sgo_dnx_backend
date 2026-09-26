using System.Data;
using Ecommerce.Application.Contracts.Permisos;
using Ecommerce.Domain;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public sealed class PermisosIndicadorRepository : IPermisosIndicador
{
    private readonly string _connectionString;

    public PermisosIndicadorRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");
    }

    public async Task<PermisoPerfil> ObtenerPerfilAsync(int companiaId, int areaId, int? usuarioId, CancellationToken cancellationToken = default)
    {
        var permisos = await EjecutarLecturaAsync("OBTENER", companiaId, areaId, usuarioId, cancellationToken);
        return new PermisoPerfil { AreaId = areaId, UsuarioId = usuarioId, Permisos = permisos };
    }

    public async Task<IReadOnlyList<string>> ObtenerEfectivosAsync(int companiaId, int areaId, int usuarioId, CancellationToken cancellationToken = default)
    {
        var permisos = await EjecutarLecturaAsync("EFECTIVOS", companiaId, areaId, usuarioId, cancellationToken);
        return permisos.Where(x => x.Permitido).Select(x => x.Codigo).ToArray();
    }

    public async Task GuardarPerfilAsync(int companiaId, GuardarPermisoPerfilRequest request, CancellationToken cancellationToken = default)
    {
        await using var connection = new SqlConnection(_connectionString);
        await using var command = CrearComando(connection, "GUARDAR", companiaId, request.AreaId, request.UsuarioId);
        command.Parameters.Add("@Permisos", SqlDbType.VarChar, -1).Value = string.Join("|", request.Permisos
            .Select(x => $"{x.Codigo.Trim().ToUpperInvariant()}={(x.Permitido ? 1 : 0)}"));
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task<IReadOnlyList<PermisoEstado>> EjecutarLecturaAsync(string operacion, int companiaId, int areaId, int? usuarioId, CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(_connectionString);
        await using var command = CrearComando(connection, operacion, companiaId, areaId, usuarioId);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var permisos = new List<PermisoEstado>();
        while (await reader.ReadAsync(cancellationToken))
        {
            permisos.Add(new PermisoEstado
            {
                Codigo = reader.GetString(reader.GetOrdinal("Codigo")),
                Permitido = reader.GetBoolean(reader.GetOrdinal("Permitido"))
            });
        }
        return permisos;
    }

    private static SqlCommand CrearComando(SqlConnection connection, string operacion, int companiaId, int areaId, int? usuarioId)
    {
        var command = new SqlCommand("dbo.usp_PermisoIndicador", connection)
        {
            CommandType = CommandType.StoredProcedure,
            CommandTimeout = 30
        };
        command.Parameters.AddWithValue("@Operacion", operacion);
        command.Parameters.AddWithValue("@CompaniaId", companiaId);
        command.Parameters.AddWithValue("@AreaId", areaId);
        command.Parameters.AddWithValue("@UsuarioId", (object?)usuarioId ?? DBNull.Value);
        return command;
    }
}

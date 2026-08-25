using System.Data;
using System.Globalization;
using Ecommerce.Application.Contracts.Personales;
using Ecommerce.Domain;
using Ecommerce.Infrastructure.Persistence;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public class PersonalRepository : IPersonal
{
    private readonly string _connectionString;
    private readonly AccesoDatos _accesoDatos;

    public PersonalRepository(IConfiguration configuration, AccesoDatos accesoDatos)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");
        _accesoDatos = accesoDatos;
    }

    public async Task<string> InsertarAsync(Personal personal, CancellationToken cancellationToken = default)
    {
        var data = $"{personal.PersonalId}|{personal.PersonalNombres?.Trim()}|{personal.PersonalApellidos?.Trim()}|{personal.AreaId}|{personal.PersonalCodigo?.Trim()}|{FormatDate(personal.PersonalNacimiento)}|{FormatDate(personal.PersonalIngreso)}|{personal.PersonalDNI?.Trim()}|{personal.PersonalDireccion?.Trim()}|{personal.PersonalTelefono?.Trim()}|{personal.PersonalEmail?.Trim()}|{personal.PersonalEstado}|{personal.PersonalImagen}|{personal.CompaniaId}";
        var result = await _accesoDatos.EjecutarComandoAsync("uspIngresarPersonal", "@Data", data, cancellationToken);
        return string.IsNullOrWhiteSpace(result) ? "error" : result;
    }

    public async Task<bool> EliminarAsync(long id, CancellationToken cancellationToken = default)
    {
        const string sql = "uspEliminarPersonal";
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

    public async Task<Personal?> ObtenerPorIdAsync(long id, CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT PersonalId, PersonalNombres, PersonalApellidos, AreaId, PersonalCodigo,
                   PersonalNacimiento, PersonalIngreso, PersonalDNI, PersonalDireccion,
                   PersonalTelefono, PersonalEmail, PersonalEstado, PersonalImagen, CompaniaId
            FROM Personal
            WHERE PersonalId = @Id;
            """;

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddWithValue("@Id", id);
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? MapPersonal(reader) : null;
    }

    public async Task<IReadOnlyList<Personal>> ListarAsync(string? estado = "ACTIVO", int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
    {
        (page, pageSize) = NormalizePagination(page, pageSize);

        const string sql = """
            SELECT PersonalId, PersonalNombres, PersonalApellidos, AreaId, PersonalCodigo,
                   PersonalNacimiento, PersonalIngreso, PersonalDNI, PersonalDireccion,
                   PersonalTelefono, PersonalEmail, PersonalEstado, PersonalImagen, CompaniaId
            FROM Personal
            WHERE (@Estado IS NULL OR PersonalEstado = @Estado)
            ORDER BY PersonalId DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.Text
        };
        cmd.Parameters.AddWithValue("@Estado", (object?)estado ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@Offset", (page - 1) * pageSize);
        cmd.Parameters.AddWithValue("@PageSize", pageSize);
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);

        var lista = new List<Personal>();
        while (await reader.ReadAsync(cancellationToken))
        {
            lista.Add(MapPersonal(reader));
        }

        return lista;
    }

    public async Task<string> InsertarMantenimientoAsync(
        Personal personal,
        byte[]? huella = null,
        CancellationToken cancellationToken = default)
    {
        var id = personal.PersonalId > 0 ? personal.PersonalId : 0;
        var action = id > 0 ? "ACTUALIZAR" : "CREAR";
        var values = new[]
        {
            action,
            id > 0 ? id.ToString(CultureInfo.InvariantCulture) : null,
            personal.PersonalNombres,
            personal.PersonalApellidos,
            personal.AreaId?.ToString(CultureInfo.InvariantCulture),
            personal.PersonalCodigo,
            FormatDate(personal.PersonalNacimiento),
            FormatDate(personal.PersonalIngreso),
            personal.PersonalDNI,
            personal.PersonalDireccion,
            personal.PersonalTelefono,
            personal.PersonalTelefonoAsi,
            personal.PersonalEmail,
            personal.PersonalSueldo?.ToString(CultureInfo.InvariantCulture),
            personal.PersonalEstado,
            personal.PersonalBajaFecha,
            personal.PersonalRuc,
            personal.PersonalImagen,
            personal.CompaniaId?.ToString(CultureInfo.InvariantCulture)
        };

        var data = string.Join("|", id > 0 ? values : values.Where((_, index) => index != 1));
        var result = await EjecutarMantenimientoAsync(data, huella, cancellationToken);
        return string.IsNullOrWhiteSpace(result) ? "ERROR|No se obtuvo respuesta." : result;
    }

    public async Task<bool> EliminarMantenimientoAsync(long id, CancellationToken cancellationToken = default)
    {
        if (id <= 0) return false;
        var result = await EjecutarMantenimientoAsync(
            $"ELIMINAR|{id.ToString(CultureInfo.InvariantCulture)}",
            null,
            cancellationToken);
        return result.StartsWith("OK|", StringComparison.OrdinalIgnoreCase);
    }

    public async Task<IReadOnlyList<Personal>> ListarMantenimientoAsync(
        string? estado = "ACTIVO",
        int page = 1,
        int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        var all = new List<Personal>();
        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand("usp_Personal", con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.Add("@Data", SqlDbType.VarChar, -1).Value = "LISTAR";

        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var data = reader.IsDBNull(0) ? string.Empty : reader.GetString(0);
            var fields = data.Split('|', 19, StringSplitOptions.None);
            if (fields.Length < 19) continue;
            all.Add(MapMaintenance(fields));
        }

        var filtered = string.IsNullOrWhiteSpace(estado)
            ? all
            : all.Where(x => string.Equals(x.PersonalEstado?.Trim(), estado.Trim(), StringComparison.OrdinalIgnoreCase)).ToList();
        var normalizedPage = page < 1 ? 1 : page;
        var normalizedSize = pageSize < 1 ? 1 : Math.Min(pageSize, 100);
        return filtered.Skip((normalizedPage - 1) * normalizedSize).Take(normalizedSize).ToList();
    }

    private async Task<string> EjecutarMantenimientoAsync(
        string data,
        byte[]? huella,
        CancellationToken cancellationToken)
    {
        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand("usp_Personal", con)
        {
            CommandTimeout = 300,
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.Add("@Data", SqlDbType.VarChar, -1).Value = data;
        cmd.Parameters.Add("@Huella", SqlDbType.VarBinary, -1).Value = (object?)huella ?? DBNull.Value;
        await con.OpenAsync(cancellationToken);
        var result = await cmd.ExecuteScalarAsync(cancellationToken);
        return result?.ToString() ?? string.Empty;
    }

    private static Personal MapMaintenance(string[] fields)
    {
        return new Personal
        {
            PersonalId = long.TryParse(fields[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out var id) ? id : 0,
            PersonalNombres = fields[1].Trim(),
            PersonalApellidos = fields[2].Trim(),
            AreaId = long.TryParse(fields[3], NumberStyles.Integer, CultureInfo.InvariantCulture, out var area) ? area : null,
            PersonalCodigo = fields[4].Trim(),
            PersonalNacimiento = ParseDate(fields[5]),
            PersonalIngreso = ParseDate(fields[6]),
            PersonalDNI = fields[7].Trim(),
            PersonalDireccion = fields[8].Trim(),
            PersonalTelefono = fields[9].Trim(),
            PersonalTelefonoAsi = fields[10].Trim(),
            PersonalEmail = fields[11].Trim(),
            PersonalSueldo = decimal.TryParse(fields[12], NumberStyles.Any, CultureInfo.InvariantCulture, out var sueldo) ? sueldo : null,
            PersonalEstado = fields[13].Trim(),
            PersonalBajaFecha = fields[14].Trim(),
            PersonalRuc = fields[15].Trim(),
            PersonalImagen = fields[16].Trim(),
            CompaniaId = int.TryParse(fields[17], NumberStyles.Integer, CultureInfo.InvariantCulture, out var compania) ? compania : null,
            HuellaRegistrada = fields[18].Trim() == "1"
        };
    }

    private static DateTime? ParseDate(string value)
    {
        return DateTime.TryParseExact(value.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var date)
            ? date
            : null;
    }

    private static Personal MapPersonal(SqlDataReader reader)
    {
        return new Personal
        {
            PersonalId = Convert.ToInt64(reader["PersonalId"]),
            PersonalNombres = reader["PersonalNombres"].ToString(),
            PersonalApellidos = reader["PersonalApellidos"].ToString(),
            AreaId = reader["AreaId"] == DBNull.Value ? null : Convert.ToInt64(reader["AreaId"]),
            PersonalCodigo = reader["PersonalCodigo"].ToString(),
            PersonalNacimiento = ReadNullableDate(reader, "PersonalNacimiento"),
            PersonalIngreso = ReadNullableDate(reader, "PersonalIngreso"),
            PersonalDNI = reader["PersonalDNI"].ToString(),
            PersonalDireccion = reader["PersonalDireccion"].ToString(),
            PersonalTelefono = reader["PersonalTelefono"].ToString(),
            PersonalEmail = reader["PersonalEmail"].ToString(),
            PersonalEstado = reader["PersonalEstado"].ToString(),
            PersonalImagen = reader["PersonalImagen"].ToString(),
            CompaniaId = reader["CompaniaId"] == DBNull.Value ? null : Convert.ToInt32(reader["CompaniaId"])
        };
    }

    private static DateTime? ReadNullableDate(SqlDataReader reader, string columnName)
    {
        if (reader[columnName] == DBNull.Value) return null;

        if (reader[columnName] is DateTime dtValue)
        {
            return dtValue;
        }

        var value = reader[columnName]?.ToString();
        if (string.IsNullOrWhiteSpace(value)) return null;

        if (DateTime.TryParseExact(value, "dd/MM/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out var exact))
        {
            return exact;
        }

        return DateTime.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var parsed)
            ? parsed
            : (DateTime?)null;
    }

    private static string? FormatDate(DateTime? date)
    {
        return date?.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
    }

    private static (int page, int pageSize) NormalizePagination(int page, int pageSize)
    {
        var normalizedPage = page < 1 ? 1 : page;
        var normalizedPageSize = pageSize < 1 ? 1 : Math.Min(pageSize, 100);
        return (normalizedPage, normalizedPageSize);
    }
}

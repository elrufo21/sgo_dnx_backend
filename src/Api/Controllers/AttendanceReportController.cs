using System.Data;
using System.Globalization;
using System.Net;
using Ecommerce.Api.Security;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[RequirePermission("VENTAS.VER")]
public sealed class AttendanceReportController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public AttendanceReportController(IConfiguration configuration) => _configuration = configuration;

    [HttpGet]
    public async Task<IActionResult> Listar(
        [FromQuery] DateOnly? fecha,
        [FromQuery] DateOnly? fechaInicio,
        [FromQuery] DateOnly? fechaFin,
        [FromQuery] int? personalId,
        CancellationToken cancellationToken)
    {
        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { mensaje = "No se encontró la cadena de conexión." });

        if (fecha.HasValue && (fechaInicio.HasValue || fechaFin.HasValue))
            return BadRequest(new { mensaje = "Use una fecha o un rango de fechas, no ambos." });
        if (fecha.HasValue)
            return await ListarDiaAsync(connectionString, fecha.Value, cancellationToken);
        if (!fechaInicio.HasValue || !fechaFin.HasValue || fechaInicio.Value > fechaFin.Value)
            return BadRequest(new { mensaje = "Seleccione un rango de fechas válido." });
        if (personalId is <= 0)
            return BadRequest(new { mensaje = "El personal seleccionado no es válido." });

        await using var connection = new SqlConnection(connectionString);
        await using var command = new SqlCommand("""
            SELECT a.Id,
                   CONVERT(varchar(10), a.Fecha, 103) AS Fecha,
                   a.PersonalId,
                   SUBSTRING(p.PersonalNombres + ' ', 1, CHARINDEX(' ', p.PersonalNombres + ' ') - 1) + ' ' +
                   SUBSTRING(p.PersonalApellidos + ' ', 1, CHARINDEX(' ', p.PersonalApellidos + ' ') - 1) AS Nombres,
                   ISNULL(CONVERT(varchar(8), a.HoraIngreso, 108), '') AS HoraIngreso,
                   ISNULL(CONVERT(varchar(8), a.SalidaRefrigerio, 108), '') AS SalidaRefrigerio,
                   ISNULL(CONVERT(varchar(8), a.IngresoRefrigerio, 108), '') AS RetornoRefrigerio,
                   ISNULL(CONVERT(varchar(8), a.HoraSalida, 108), '') AS HoraSalida,
                   ISNULL(a.NroMarcacion, 0) AS NroMarcacion,
                   CASE WHEN a.Estado = 'T' THEN 'TARDANZA' ELSE 'ASISTIO' END AS EstadoAsistencia,
                   CASE
                       WHEN CONVERT(time, a.IngresoRefrigerio) > DATEADD(minute, 60, CONVERT(time, a.SalidaRefrigerio)) THEN 'T'
                       ELSE 'A'
                   END AS EstadoRefrigerio,
                   ISNULL(a.NroTardanza, 0) AS CantidadTardanzas
              FROM dbo.Asistencia AS a
              INNER JOIN dbo.Personal AS p ON p.PersonalId = a.PersonalId
              INNER JOIN dbo.Usuarios AS u ON u.PersonalId = p.PersonalId
             WHERE a.Fecha >= @FechaInicio
               AND a.Fecha < DATEADD(day, 1, @FechaFin)
               AND (@PersonalId IS NULL OR a.PersonalId = @PersonalId)
             ORDER BY a.Fecha, a.Id
            """, connection);
        command.Parameters.Add("@FechaInicio", SqlDbType.Date).Value = fechaInicio.Value.ToDateTime(TimeOnly.MinValue);
        command.Parameters.Add("@FechaFin", SqlDbType.Date).Value = fechaFin.Value.ToDateTime(TimeOnly.MinValue);
        command.Parameters.Add("@PersonalId", SqlDbType.Int).Value = (object?)personalId ?? DBNull.Value;

        await connection.OpenAsync(cancellationToken);
        var rows = new List<AttendanceReportRow>();
        await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                rows.Add(new AttendanceReportRow(
                    Convert.ToInt32(reader["Id"], CultureInfo.InvariantCulture),
                    reader["Fecha"]?.ToString() ?? string.Empty,
                    Convert.ToInt32(reader["PersonalId"], CultureInfo.InvariantCulture),
                    reader["Nombres"]?.ToString() ?? string.Empty,
                    reader["HoraIngreso"]?.ToString() ?? string.Empty,
                    reader["SalidaRefrigerio"]?.ToString() ?? string.Empty,
                    reader["RetornoRefrigerio"]?.ToString() ?? string.Empty,
                    reader["HoraSalida"]?.ToString() ?? string.Empty,
                    Convert.ToInt32(reader["NroMarcacion"], CultureInfo.InvariantCulture),
                    reader["EstadoAsistencia"]?.ToString() ?? string.Empty,
                    reader["EstadoRefrigerio"]?.ToString() ?? string.Empty,
                    Convert.ToInt32(reader["CantidadTardanzas"], CultureInfo.InvariantCulture)));
            }
        }

        return Ok(new { fechaInicio, fechaFin, personalId, asistencias = rows });
    }

    [HttpGet("personas")]
    public async Task<IActionResult> ListarPersonas(CancellationToken cancellationToken)
    {
        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { mensaje = "No se encontró la cadena de conexión." });

        await using var connection = new SqlConnection(connectionString);
        await using var command = new SqlCommand("""
            SELECT DISTINCT p.PersonalId,
                   SUBSTRING(p.PersonalNombres + ' ', 1, CHARINDEX(' ', p.PersonalNombres + ' ') - 1) + ' ' +
                   SUBSTRING(p.PersonalApellidos + ' ', 1, CHARINDEX(' ', p.PersonalApellidos + ' ') - 1) AS Nombres
              FROM dbo.Personal AS p
              INNER JOIN dbo.Usuarios AS u ON u.PersonalId = p.PersonalId
             WHERE p.PersonalEstado = 'ACTIVO'
               AND u.UsuarioEstado = 'ACTIVO'
             ORDER BY Nombres
            """, connection);
        await connection.OpenAsync(cancellationToken);

        var personas = new List<AttendancePersonOption>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
            personas.Add(new AttendancePersonOption(
                Convert.ToInt32(reader["PersonalId"], CultureInfo.InvariantCulture),
                reader["Nombres"]?.ToString() ?? string.Empty));

        return Ok(new { personas });
    }

    private async Task<IActionResult> ListarDiaAsync(
        string connectionString,
        DateOnly fecha,
        CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(connectionString);
        await using var command = new SqlCommand("dbo.uspAsistenciaListaCsvBWeb", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.Add("@Data", SqlDbType.Date).Value = fecha.ToDateTime(TimeOnly.MinValue);

        await connection.OpenAsync(cancellationToken);
        var payload = Convert.ToString(
            await command.ExecuteScalarAsync(cancellationToken),
            CultureInfo.InvariantCulture) ?? string.Empty;
        var rows = new List<AttendanceReportRow>();
        var sections = payload.Split('¬');

        foreach (var section in sections.Skip(3))
        {
            if (string.IsNullOrWhiteSpace(section) || section == "~") continue;

            var fields = section.Split('|');
            if (fields.Length != 12)
                return StatusCode(500, new { mensaje = "El procedimiento devolvió una fila de asistencia con formato inválido." });

            rows.Add(new AttendanceReportRow(
                ParseInteger(fields[0]),
                Decode(fields[1]),
                ParseInteger(fields[2]),
                Decode(fields[3]),
                Decode(fields[4]),
                Decode(fields[5]),
                Decode(fields[6]),
                Decode(fields[7]),
                ParseInteger(fields[8]),
                Decode(fields[9]),
                Decode(fields[10]),
                ParseInteger(fields[11])));
        }

        return Ok(new { fecha, asistencias = rows });
    }

    private static int ParseInteger(string value) =>
        int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var result) ? result : 0;

    private static string Decode(string value) => WebUtility.HtmlDecode(value) ?? string.Empty;
}

public sealed record AttendancePersonOption(int PersonalId, string Nombres);

public sealed record AttendanceReportRow(
    int Id,
    string Fecha,
    int PersonalId,
    string Nombres,
    string HoraIngreso,
    string SalidaRefrigerio,
    string RetornoRefrigerio,
    string HoraSalida,
    int NroMarcacion,
    string EstadoAsistencia,
    string EstadoRefrigerio,
    int CantidadTardanzas);

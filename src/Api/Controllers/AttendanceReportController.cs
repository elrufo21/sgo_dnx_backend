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
    public async Task<IActionResult> Listar([FromQuery] DateOnly fecha, CancellationToken cancellationToken)
    {
        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { mensaje = "No se encontró la cadena de conexión." });

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

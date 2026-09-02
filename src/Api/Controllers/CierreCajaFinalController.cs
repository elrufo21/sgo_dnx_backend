using System.Data;
using System.Globalization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public sealed class CierreCajaFinalController : ControllerBase
{
    private readonly IConfiguration _configuration;
    public CierreCajaFinalController(IConfiguration configuration) => _configuration = configuration;

    [HttpGet("preparacion")]
    public async Task<IActionResult> Preparacion([FromQuery] DateOnly fecha, CancellationToken ct)
    {
        await using var con = await Abrir(ct); var f = fecha.ToString("MM/dd/yyyy", CultureInfo.InvariantCulture);
        var gastosRaw = await Scalar(con, "uspTraerGastos", "@Fecha", f, ct);
        var monedasRaw = await Scalar(con, "uspTraeTodasMonedas", "@Fecha", f, ct);
        var cajerosRaw = await Scalar(con, "usptraerCajeros", "@Fecha", f, ct);
        var p = gastosRaw.Split('['); var gastos = Rows(p.ElementAtOrDefault(0));
        var ingresos = new List<Movimiento> { new("VITRINA", Money(p.ElementAtOrDefault(7))), new("IOC", Money(p.ElementAtOrDefault(4), 1)), new("REVISTAS", Money(p.ElementAtOrDefault(5))), new("COPIAS Y OTROS", Money(p.ElementAtOrDefault(6))) };
        ingresos.AddRange(Rows(p.ElementAtOrDefault(1)));
        var yaExiste = (await Scalar(con, "usplistaConteo", null, null, ct, fecha, fecha)).Split('¬', StringSplitOptions.RemoveEmptyEntries).Skip(3).Any(x => x != "~");
        return Ok(new { fecha, cajeros = cajerosRaw.Split('[')[0].Trim('~', ' ', ','), totalObs = Money(p.ElementAtOrDefault(3)), sencillo = Money(p.ElementAtOrDefault(2)), monedas = Monedas(monedasRaw), ingresos, gastos, existe = yaExiste });
    }

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] DateOnly fechaInicio, [FromQuery] DateOnly fechaFin, CancellationToken ct)
    {
        if (fechaInicio > fechaFin)
            return BadRequest(new { ok = false, mensaje = "La fecha inicio no puede ser mayor que la fecha fin." });
        await using var con = await Abrir(ct); var raw = await Scalar(con, "usplistaConteo", null, null, ct, fechaInicio, fechaFin);
        return Ok(raw.Split('¬', StringSplitOptions.RemoveEmptyEntries).Skip(3).Where(x => x != "~").Select(x => x.Split('|')).Where(x => x.Length > 10).Select(x => new { id = Number(x[0]), fecha = Fecha(x[1]), cajeros = x[2], totalObs = Money(x[3]), salidas = Money(x[4]), diferencia = Money(x[5]), totalEsperado = Money(x[6]), usuario = x[7], observaciones = x[10] }));
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> Detalle(long id, CancellationToken ct)
    {
        await using var con = await Abrir(ct); var raw = await Scalar(con, "usplistaDetalleConteo", "@ConteoId", id.ToString(CultureInfo.InvariantCulture), ct); var secciones = raw.Split('[');
        return Ok(new { monedas = Monedas(secciones.ElementAtOrDefault(0) ?? ""), ingresos = DetalleRows(secciones.ElementAtOrDefault(1)), gastos = DetalleRows(secciones.ElementAtOrDefault(2)) });
    }

    [HttpPost]
    public Task<IActionResult> Guardar([FromBody] GuardarCierre request, CancellationToken ct) => Persistir(request, 0, ct);

    [HttpPut("{id:long}")]
    public Task<IActionResult> Editar(long id, [FromBody] GuardarCierre request, CancellationToken ct) => Persistir(request, id, ct);

    private async Task<IActionResult> Persistir(GuardarCierre request, long conteoId, CancellationToken ct)
    {
        if (request.UsuarioId <= 0 || request.Fecha == default || request.Ingresos.Any(x => x.Importe < 0) || request.Gastos.Any(x => x.Importe < 0) || request.Monedas.Any(x => x.Cantidad < 0 || x.Denominacion <= 0)) return BadRequest(new { mensaje = "Revise los datos del informe." });
        var gastos = request.Gastos.Sum(x => x.Importe); var total = request.Ingresos.Sum(x => x.Importe); var contado = request.Monedas.Sum(x => x.Cantidad * x.Denominacion); var diferencia = contado - total;
        if (diferencia != 0 && string.IsNullOrWhiteSpace(request.Observaciones)) return BadRequest(new { mensaje = "Ingrese observaciones para justificar la diferencia." });
        var header = string.Join("|", conteoId, request.Fecha.ToString("MM/dd/yyyy", CultureInfo.InvariantCulture), request.UsuarioId, Limpio(request.Usuario), Limpio(request.Cajeros), Dinero(request.TotalObs), Dinero(gastos), Dinero(diferencia), Dinero(total), "", Limpio(request.Observaciones), "0");
        var movimientos = conteoId == 0
            ? string.Join(";", request.Ingresos.Select(x => $"{Limpio(x.Descripcion)}|{Dinero(x.Importe)}|T|I").Concat(request.Gastos.Select(x => $"{Limpio(x.Descripcion)}|{Dinero(x.Importe)}|T|S")))
            : string.Join(";", request.Ingresos.Select(x => $"{Limpio(x.Descripcion)}|{Dinero(x.Importe)}|{Limpio(x.Estado ?? "T")}|{x.Id}|I").Concat(request.Gastos.Select(x => $"{Limpio(x.Descripcion)}|{Dinero(x.Importe)}|{Limpio(x.Estado ?? "T")}|{x.Id}|S")));
        var monedas = conteoId == 0
            ? string.Join(";", request.Monedas.Select(x => $"{x.Cantidad}|{Dinero(x.Denominacion)}|{Dinero(x.Cantidad * x.Denominacion)}|"))
            : string.Join(";", request.Monedas.Select(x => $"{x.Id}|{x.Cantidad}|{Dinero(x.Cantidad * x.Denominacion)}"));
        await using var con = await Abrir(ct);
        if (conteoId == 0)
        {
            var existe = (await Scalar(con, "usplistaConteo", null, null, ct, request.Fecha, request.Fecha))
                .Split('¬', StringSplitOptions.RemoveEmptyEntries).Skip(3).Any(x => x != "~");
            if (existe)
                return Conflict(new { mensaje = "Ya existe un informe final para la fecha seleccionada." });
            var validacion = await Scalar(con, "uspValidarApertura", "@Fecha", request.Fecha.ToString("MM/dd/yyyy", CultureInfo.InvariantCulture), ct);
            if (validacion.Equals("PAGO/VARIOS", StringComparison.OrdinalIgnoreCase))
                return Conflict(new { mensaje = "Hay documentos con la condición PAGO/VARIOS que aún no se han liquidado." });
        }
        var result = await Scalar(con, conteoId == 0 ? "uspInsertarConteoCajaWEB" : "uspEditarConteoCajaWEB", "@ListaOrden", $"{header}[{movimientos}[{monedas}", ct);
        var insertedId = long.TryParse(result, out var id) && id > 0 ? id : 0;
        return string.IsNullOrWhiteSpace(result) || result.Equals("true", StringComparison.OrdinalIgnoreCase) || insertedId > 0
            ? Ok(new { ok = true, id = insertedId, mensaje = conteoId == 0 ? "Informe final registrado." : "Informe final actualizado." })
            : Conflict(new { mensaje = result });
    }

    private async Task<SqlConnection> Abrir(CancellationToken ct) { var con = new SqlConnection(_configuration.GetConnectionString("DefaultConnection")); await con.OpenAsync(ct); return con; }
    private static async Task<string> Scalar(SqlConnection con, string sp, string? name, string? value, CancellationToken ct, DateOnly? inicio = null, DateOnly? fin = null) { await using var cmd = new SqlCommand(sp, con) { CommandType = CommandType.StoredProcedure }; if (inicio.HasValue) { cmd.Parameters.Add("@fechainicio", SqlDbType.Date).Value = inicio.Value.ToDateTime(TimeOnly.MinValue); cmd.Parameters.Add("@fechafin", SqlDbType.Date).Value = fin!.Value.ToDateTime(TimeOnly.MinValue); } else if (name is not null) cmd.Parameters.AddWithValue(name, value ?? ""); return (await cmd.ExecuteScalarAsync(ct))?.ToString() ?? ""; }
    private static List<Movimiento> Rows(string? raw) => string.IsNullOrWhiteSpace(raw) || raw == "~" ? new List<Movimiento>() : raw.Split('¬', StringSplitOptions.RemoveEmptyEntries).Skip(3).Select(x => x.Split('|')).Where(x => x.Length > 1).Select(x => new Movimiento(x[0], Money(x[1]))).ToList();
    private static List<Movimiento> DetalleRows(string? raw) => string.IsNullOrWhiteSpace(raw) || raw == "~" ? new List<Movimiento>() : raw.Split('¬', StringSplitOptions.RemoveEmptyEntries).Select(x => x.Split('|')).Where(x => x.Length > 1).Select(x => new Movimiento(x[0], Money(x[1]), Number(x.ElementAtOrDefault(3)), x.ElementAtOrDefault(2) ?? "T")).ToList();
    private static List<Moneda> Monedas(string raw) => string.IsNullOrWhiteSpace(raw) || raw == "~" ? new List<Moneda>() : raw.Split('¬', StringSplitOptions.RemoveEmptyEntries).Select(x => x.Split('|')).Where(x => x.Length > 2).Select(x => new Moneda(Money(x[2]), (int)Number(x[1]), Number(x[0]))).ToList();
    private static decimal Money(string? value, int part = 0) => decimal.TryParse(value?.Split('|').ElementAtOrDefault(part)?.Replace(",", ""), NumberStyles.Number, CultureInfo.InvariantCulture, out var n) ? n : 0;
    private static long Number(string? value) => long.TryParse(value, out var n) ? n : 0;
    private static string Fecha(string value) => DateTime.TryParse(value, out var d) ? d.ToString("yyyy-MM-dd") : value;
    private static string Dinero(decimal value) => value.ToString("0.00", CultureInfo.InvariantCulture);
    private static string Limpio(string? value) => (value ?? "").Replace("|", " ").Replace(";", " ").Replace("[", " ").Replace("¬", " ");
}

public sealed record Movimiento(string Descripcion, decimal Importe, long Id = 0, string? Estado = "T");
public sealed record Moneda(decimal Denominacion, int Cantidad, long Id = 0);
public sealed record GuardarCierre(DateOnly Fecha, int UsuarioId, string Usuario, string? Cajeros, decimal TotalObs, string? Observaciones, List<Movimiento> Ingresos, List<Movimiento> Gastos, List<Moneda> Monedas);

using System.Data;
using System.Globalization;
using System.Security.Claims;
using Ecommerce.Application.Models.ImageManagement;
using Ecommerce.Api.Security;
using Ecommerce.Domain;
using Ecommerce.Infrastructure.ImageLocal;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Authorize]
[RequireAttendance]
[RequirePermission("CAJA.VER")]
[Route("api/v1/[controller]")]
public sealed class DepositosCentroController : ControllerBase
{
    private const long MaxImageSizeBytes = 5 * 1024 * 1024;
    private static readonly HashSet<string> Movimientos = new(StringComparer.OrdinalIgnoreCase)
        { "DEPOSITO", "EFECTIVO", "TARJETA", "YAPE" };
    private static readonly HashSet<string> Entidades = new(StringComparer.OrdinalIgnoreCase)
        { "BCP", "BBVA CONTINENTAL", "INTERBANK", "YAPE" };

    private readonly IConfiguration _configuration;
    private readonly LocalImageStorageService _images;
    private readonly UserManager<Usuario> _userManager;

    public DepositosCentroController(
        IConfiguration configuration,
        LocalImageStorageService images,
        UserManager<Usuario> userManager)
    {
        _configuration = configuration;
        _images = images;
        _userManager = userManager;
    }

    [HttpGet("validacion")]
    public async Task<IActionResult> Validar(CancellationToken ct)
    {
        if (!int.TryParse(User.FindFirstValue("companiaId"), out var companiaId) || companiaId <= 0)
            return Forbid();

        await using var con = await OpenConnectionAsync(ct);
        await using var cmd = new SqlCommand("""
            SELECT COALESCE(i.ValorNum, c.DiasMaxDep, 7)
              FROM dbo.Compania c
              OUTER APPLY (
                  SELECT TOP (1) ValorNum
                    FROM dbo.Indicador
                   WHERE CompaniaId = c.CompaniaId AND Descripcion = 'DIAS_MAX_DEPOSITO'
              ) i
             WHERE c.CompaniaId = @CompaniaId;
            """, con);
        cmd.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companiaId;
        var configuredDays = await cmd.ExecuteScalarAsync(ct);
        if (configuredDays is null or DBNull) return NotFound(new { mensaje = "No se encontró la compañía." });

        var days = Convert.ToInt32(configuredDays, CultureInfo.InvariantCulture);
        if (days is < 0 or > 3650) return BadRequest(new { mensaje = "DiasMaxDep debe estar entre 0 y 3650." });
        var desde = DateTime.Today.AddDays(-days);
        var hasta = DateTime.Today.AddDays(1);
        await using var count = new SqlCommand("""
            SELECT COUNT(1), COALESCE(SUM(CASE WHEN Estado = 'P' THEN 1 ELSE 0 END), 0)
              FROM dbo.DepositosCentro
             WHERE FechaRegistro >= @Desde AND FechaRegistro < @Hasta;
            """, con);
        count.Parameters.Add("@Desde", SqlDbType.DateTime).Value = desde;
        count.Parameters.Add("@Hasta", SqlDbType.DateTime).Value = hasta;
        await using var reader = await count.ExecuteReaderAsync(ct);
        await reader.ReadAsync(ct);
        var cantidad = Convert.ToInt32(reader.GetValue(0), CultureInfo.InvariantCulture);
        var pendientes = Convert.ToInt32(reader.GetValue(1), CultureInfo.InvariantCulture);
        return Ok(new { diasMaxDep = days, desde = desde.ToString("yyyy-MM-dd"), hasta = DateTime.Today.ToString("yyyy-MM-dd"), cantidad, pendientes, valida = cantidad == 0 });
    }

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] DateOnly? desde, [FromQuery] DateOnly? hasta, [FromQuery] string? buscar, CancellationToken ct)
    {
        var start = (desde ?? new DateOnly(DateTime.Today.Year, DateTime.Today.Month, 1)).ToDateTime(TimeOnly.MinValue);
        var end = (hasta ?? new DateOnly(DateTime.Today.Year, DateTime.Today.Month, DateTime.DaysInMonth(DateTime.Today.Year, DateTime.Today.Month))).AddDays(1).ToDateTime(TimeOnly.MinValue);
        if (start >= end) return BadRequest(new { mensaje = "El rango de fechas no es válido." });

        await using var con = await OpenConnectionAsync(ct);
        await using var cmd = new SqlCommand("""
            SELECT IdDepo, FechaRegistro, Movimiento, EntidadBan, NroOperacion,
                   Descripcion, Efectivo, Usuario, RutaImagen, Estado
              FROM dbo.DepositosCentro
             WHERE FechaRegistro >= @Desde AND FechaRegistro < @Hasta
               AND (@Buscar = '' OR Movimiento LIKE @Texto OR EntidadBan LIKE @Texto
                    OR NroOperacion LIKE @Texto OR Descripcion LIKE @Texto OR Usuario LIKE @Texto)
             ORDER BY FechaRegistro DESC, IdDepo DESC;
            """, con);
        cmd.Parameters.Add("@Desde", SqlDbType.DateTime).Value = start;
        cmd.Parameters.Add("@Hasta", SqlDbType.DateTime).Value = end;
        var term = (buscar ?? string.Empty).Trim();
        cmd.Parameters.Add("@Buscar", SqlDbType.VarChar, 200).Value = term;
        cmd.Parameters.Add("@Texto", SqlDbType.VarChar, 202).Value = $"%{term}%";

        var rows = new List<DepositoCentroResponse>();
        await using var reader = await cmd.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
            rows.Add(new DepositoCentroResponse(
                Convert.ToInt64(reader["IdDepo"], CultureInfo.InvariantCulture),
                Convert.ToDateTime(reader["FechaRegistro"], CultureInfo.InvariantCulture).ToString("yyyy-MM-ddTHH:mm:ss", CultureInfo.InvariantCulture),
                reader["Movimiento"]?.ToString() ?? "", reader["EntidadBan"]?.ToString() ?? "",
                reader["NroOperacion"]?.ToString() ?? "", reader["Descripcion"]?.ToString() ?? "",
                Convert.ToDecimal(reader["Efectivo"], CultureInfo.InvariantCulture), reader["Usuario"]?.ToString() ?? "",
                reader["RutaImagen"]?.ToString() ?? "", reader["Estado"]?.ToString() ?? ""));
        return Ok(rows);
    }

    [HttpPost]
    [RequirePermission("CAJA.GESTIONAR")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(MaxImageSizeBytes)]
    [RequestFormLimits(MultipartBodyLengthLimit = MaxImageSizeBytes)]
    public async Task<IActionResult> Guardar([FromForm] DepositoCentroRequest request, [FromForm] IFormFile? imagen, CancellationToken ct)
    {
        var movimiento = Texto(request.Movimiento).ToUpperInvariant();
        var entidad = Texto(request.Entidad).ToUpperInvariant();
        var operacion = Texto(request.NroOperacion);
        var operacionRaw = request.NroOperacion ?? string.Empty;
        var descripcion = Texto(request.Descripcion);
        if (!Movimientos.Contains(movimiento) || descripcion.Length is 0 or > 500 ||
            request.Importe <= 0 || request.Importe > 9999999999999999.99m ||
            entidad.Length > 40 || operacion.Length > 100 ||
            (operacionRaw.Length > 0 && operacionRaw.Any(c => c < '0' || c > '9')) ||
            (movimiento == "DEPOSITO" && (!Entidades.Contains(entidad) || (operacion.Length == 0 && entidad != "YAPE"))) ||
            (movimiento == "TARJETA" && (!Entidades.Contains(entidad) || operacion.Length == 0)) ||
            (movimiento == "YAPE" && entidad != "BCP") ||
            (movimiento == "EFECTIVO" && entidad != "-"))
            return BadRequest(new { ok = false, mensaje = "Revisa movimiento, entidad, operación, descripción e importe." });
        if (request.Id < 0 || imagen is null)
            return BadRequest(new { ok = false, mensaje = "Adjunta la imagen del depósito." });
        if (imagen is not null && !ImagenValida(imagen))
            return BadRequest(new { ok = false, mensaje = "Adjunta una imagen JPG, PNG o WEBP de hasta 5 MB." });

        var ruta = string.Empty;
        var rutaAnterior = string.Empty;
        var rutaNueva = false;
        var usuario = string.Empty;
        try
        {
            await using var con = await OpenConnectionAsync(ct);
            await using var tx = (SqlTransaction)await con.BeginTransactionAsync(IsolationLevel.Serializable, ct);
            if (request.Id > 0)
            {
                await using var current = new SqlCommand("SELECT ISNULL(RutaImagen, '') FROM dbo.DepositosCentro WITH (UPDLOCK, HOLDLOCK) WHERE IdDepo = @Id;", con, tx);
                current.Parameters.Add("@Id", SqlDbType.Decimal).Value = request.Id;
                var existingPath = await current.ExecuteScalarAsync(ct);
                if (existingPath is null or DBNull) return NotFound(new { ok = false, mensaje = "No se encontró el depósito." });
                rutaAnterior = existingPath.ToString() ?? string.Empty;
                ruta = rutaAnterior;
            }
            if (request.Id == 0 && operacion.Length > 0)
            {
                await using var duplicate = new SqlCommand("""
                    SELECT TOP 1 IdDepo FROM dbo.DepositosCentro WITH (UPDLOCK, HOLDLOCK)
                     WHERE EntidadBan = @Entidad AND NroOperacion = @Operacion
                       AND (@Id = 0 OR IdDepo <> @Id);
                    """, con, tx);
                duplicate.Parameters.Add("@Entidad", SqlDbType.VarChar, 40).Value = entidad;
                duplicate.Parameters.Add("@Operacion", SqlDbType.VarChar, 100).Value = operacion;
                duplicate.Parameters.Add("@Id", SqlDbType.Decimal).Value = request.Id > 0 ? request.Id : 0;
                if (await duplicate.ExecuteScalarAsync(ct) is not null)
                    return Conflict(new { ok = false, mensaje = "El número de operación ya existe para esa entidad." });
            }
            if (request.Id == 0)
            {
                if (!int.TryParse(User.FindFirstValue("userId"), out var usuarioId) || usuarioId <= 0)
                    return Forbid();
                await using var userCmd = new SqlCommand("""
                    SELECT COALESCE(NULLIF(LTRIM(RTRIM(
                               SUBSTRING(ISNULL(P.PersonalNombres, '') + ' ', 1, CHARINDEX(' ', ISNULL(P.PersonalNombres, '') + ' ') - 1) + ' ' +
                               SUBSTRING(ISNULL(P.PersonalApellidos, '') + ' ', 1, CHARINDEX(' ', ISNULL(P.PersonalApellidos, '') + ' ') - 1))), ''),
                           U.UsuarioAlias, '')
                      FROM dbo.Usuarios U
                      LEFT JOIN dbo.Personal P ON P.PersonalId = U.PersonalId
                     WHERE U.UsuarioID = @UsuarioId;
                    """, con, tx);
                userCmd.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
                usuario = (await userCmd.ExecuteScalarAsync(ct))?.ToString()?.Trim() ?? string.Empty;
                if (usuario.Length == 0) return Forbid();
            }
            if (imagen is not null)
            {
                await using var stream = imagen.OpenReadStream();
                ruta = await _images.UploadImage(new ImageData { ImageStream = stream, Nombre = imagen.FileName }, "depositos-centro");
                rutaNueva = true;
            }

            long id;
            if (request.Id > 0)
            {
                await using var update = new SqlCommand("""
                    UPDATE dbo.DepositosCentro SET RutaImagen = @Ruta WHERE IdDepo = @Id;
                    """, con, tx);
                update.Parameters.Add("@Ruta", SqlDbType.VarChar, -1).Value = ruta;
                update.Parameters.Add("@Id", SqlDbType.Decimal).Value = request.Id;
                if (await update.ExecuteNonQueryAsync(ct) != 1)
                    return NotFound(new { ok = false, mensaje = "No se encontró el depósito." });
                id = request.Id;
            }
            else
            {
                await using var insert = new SqlCommand("""
                    INSERT dbo.DepositosCentro (FechaRegistro, Movimiento, EntidadBan, NroOperacion,
                           Descripcion, Efectivo, Usuario, RutaImagen, Estado)
                    VALUES (GETDATE(), @Movimiento, @Entidad, @Operacion,
                           @Descripcion, @Importe, @Usuario, @Ruta, 'P');
                    SELECT CONVERT(bigint, SCOPE_IDENTITY());
                    """, con, tx);
                AddData(insert, movimiento, entidad, operacion, descripcion, request.Importe, ruta);
                insert.Parameters.Add("@Usuario", SqlDbType.VarChar, 100).Value = usuario;
                id = Convert.ToInt64(await insert.ExecuteScalarAsync(ct), CultureInfo.InvariantCulture);
            }
            await tx.CommitAsync(ct);
            if (rutaNueva && rutaAnterior.Length > 0) _images.DeleteImage(rutaAnterior);
            return Ok(new { ok = true, id, mensaje = request.Id > 0 ? "Comprobante actualizado." : "Depósito registrado." });
        }
        catch
        {
            if (rutaNueva) _images.DeleteImage(ruta);
            throw;
        }
    }

    [HttpDelete("{id:long}")]
    [RequirePermission("CAJA.GESTIONAR")]
    public async Task<IActionResult> Eliminar(long id, [FromBody] EliminarDepositoCentroRequest? request, CancellationToken ct)
    {
        if (id <= 0) return BadRequest(new { ok = false, mensaje = "Depósito inválido." });
        var clave = request?.Clave ?? string.Empty;
        if (string.IsNullOrWhiteSpace(clave))
            return BadRequest(new { ok = false, mensaje = "Ingresa tu contraseña." });

        var usuarioIdClaim = User.FindFirstValue("userId");
        var claveValida = false;
        if (int.TryParse(usuarioIdClaim, out var usuarioId) && usuarioId > 0)
        {
            await using var validationConnection = await OpenConnectionAsync(ct);
            await using var validarClave = new SqlCommand("""
                SELECT TOP (1) 1
                  FROM dbo.Usuarios
                 WHERE UsuarioID = @UsuarioId
                   AND dbo.desincrectar(UsuarioClave) = @Clave;
                """, validationConnection);
            validarClave.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
            validarClave.Parameters.Add("@Clave", SqlDbType.VarChar, 200).Value = clave;
            claveValida = await validarClave.ExecuteScalarAsync(ct) is not null;
        }
        else
        {
            var identityUserId = User.FindFirstValue("identityUserId")
                ?? usuarioIdClaim
                ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
            var identityUser = string.IsNullOrWhiteSpace(identityUserId)
                ? null
                : await _userManager.FindByIdAsync(identityUserId);
            claveValida = identityUser is { IsActive: true } &&
                await _userManager.CheckPasswordAsync(identityUser, clave);
        }

        if (!claveValida)
            return Unauthorized(new { ok = false, mensaje = "La contraseña del usuario actual es incorrecta." });

        await using var con = await OpenConnectionAsync(ct);
        string ruta;
        await using (var read = new SqlCommand("SELECT RutaImagen FROM dbo.DepositosCentro WHERE IdDepo = @Id;", con))
        {
            read.Parameters.Add("@Id", SqlDbType.Decimal).Value = id;
            var value = await read.ExecuteScalarAsync(ct);
            if (value is null or DBNull) return NotFound(new { ok = false, mensaje = "No se encontró el depósito." });
            ruta = value.ToString() ?? string.Empty;
        }
        await using var delete = new SqlCommand("DELETE dbo.DepositosCentro WHERE IdDepo = @Id;", con);
        delete.Parameters.Add("@Id", SqlDbType.Decimal).Value = id;
        if (await delete.ExecuteNonQueryAsync(ct) != 1) return Conflict(new { ok = false, mensaje = "No se pudo eliminar el depósito." });
        _images.DeleteImage(ruta);
        return Ok(new { ok = true, mensaje = "Depósito eliminado." });
    }

    private async Task<SqlConnection> OpenConnectionAsync(CancellationToken ct)
    {
        var value = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(value)) throw new InvalidOperationException("No se encontró la cadena de conexión.");
        var con = new SqlConnection(value);
        await con.OpenAsync(ct);
        return con;
    }

    private static void AddData(SqlCommand cmd, string movimiento, string entidad, string operacion, string descripcion, decimal importe, string ruta)
    {
        cmd.Parameters.Add("@Movimiento", SqlDbType.VarChar, 40).Value = movimiento;
        cmd.Parameters.Add("@Entidad", SqlDbType.VarChar, 40).Value = entidad;
        cmd.Parameters.Add("@Operacion", SqlDbType.VarChar, 100).Value = operacion;
        cmd.Parameters.Add("@Descripcion", SqlDbType.VarChar, 500).Value = descripcion;
        var amount = cmd.Parameters.Add("@Importe", SqlDbType.Decimal); amount.Precision = 18; amount.Scale = 2; amount.Value = importe;
        cmd.Parameters.Add("@Ruta", SqlDbType.VarChar, -1).Value = ruta;
    }

    private static string Texto(string? value) => (value ?? string.Empty).Trim().Replace("|", " ");
    private static bool ImagenValida(IFormFile image) => image.Length is > 0 and <= MaxImageSizeBytes &&
        (image.ContentType.Equals("image/jpeg", StringComparison.OrdinalIgnoreCase) ||
         image.ContentType.Equals("image/png", StringComparison.OrdinalIgnoreCase) ||
         image.ContentType.Equals("image/webp", StringComparison.OrdinalIgnoreCase));
}

public sealed record DepositoCentroRequest(long Id, string? Movimiento, string? Entidad, string? NroOperacion,
    string? Descripcion, decimal Importe);
public sealed record EliminarDepositoCentroRequest(string? Clave);
public sealed record DepositoCentroResponse(long Id, string Fecha, string Movimiento, string Entidad,
    string NroOperacion, string Descripcion, decimal Importe, string Usuario, string RutaImagen, string Estado);

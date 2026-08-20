using System.Data;
using System.Globalization;
using Ecommerce.Application.Contracts.Infrastructure;
using Ecommerce.Application.Models.ImageManagement;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public sealed class PettyCashMovementController : ControllerBase
{
    private const long MaxImageSizeBytes = 5 * 1024 * 1024;
    private static readonly HashSet<string> TiposImagenPermitidos = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg", "image/png", "image/webp"
    };
    private static readonly HashSet<string> TiposMovimiento = new(StringComparer.OrdinalIgnoreCase)
    {
        "INGRESO", "SALIDA"
    };

    private readonly IConfiguration _configuration;
    private readonly IManageImageService _imageService;

    public PettyCashMovementController(IConfiguration configuration, IManageImageService imageService)
    {
        _configuration = configuration;
        _imageService = imageService;
    }

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] int usuarioId, CancellationToken cancellationToken)
    {
        if (usuarioId <= 0) return BadRequest(new { ok = false, mensaje = "Usuario inválido." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await con.OpenAsync(cancellationToken);
        var cajaId = await ObtenerCajaActivaAsync(con, usuarioId, cancellationToken);
        if (cajaId is null)
            return Ok(new PettyCashMovementListResponse(0, Array.Empty<PettyCashMovementResponse>()));

        var movimientos = new List<PettyCashMovementResponse>();
        await using var cmd = new SqlCommand("""
            SELECT DetalleId, CONVERT(varchar(19), DetalleFecha, 126) AS Fecha,
                   DetalleMovimiento, DetalleConcepto, ISNULL(DetalleMonto, 0) AS Importe,
                   ISNULL(FormaPago, '') AS FormaPago, ISNULL(EntidadBancaria, '') AS Entidad,
                   ISNULL(NroOperacion, '') AS NroOperacion, ISNULL(RutaImagen, '') AS RutaImagen
              FROM CajaDetalle
             WHERE CajaId = @CajaId AND ISNULL(NotaId, 0) = 0
               AND ISNULL(NotaIdB, 0) = -1
             ORDER BY DetalleId DESC;
            """, con);
        AddCajaId(cmd, cajaId.Value);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
            movimientos.Add(new PettyCashMovementResponse(
                Convert.ToInt64(reader["DetalleId"], CultureInfo.InvariantCulture),
                reader["Fecha"]?.ToString() ?? string.Empty,
                reader["DetalleMovimiento"]?.ToString() ?? string.Empty,
                reader["DetalleConcepto"]?.ToString() ?? string.Empty,
                Convert.ToDecimal(reader["Importe"], CultureInfo.InvariantCulture),
                reader["FormaPago"]?.ToString() ?? string.Empty,
                reader["Entidad"]?.ToString() ?? string.Empty,
                reader["NroOperacion"]?.ToString() ?? string.Empty,
                reader["RutaImagen"]?.ToString() ?? string.Empty));

        return Ok(new PettyCashMovementListResponse(cajaId.Value, movimientos));
    }

    [RequestSizeLimit(MaxImageSizeBytes)]
    [RequestFormLimits(MultipartBodyLengthLimit = MaxImageSizeBytes)]
    [HttpPost]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> Guardar(
        [FromForm] CreatePettyCashMovementRequest request,
        [FromForm] IFormFile? imagen,
        CancellationToken cancellationToken)
    {
        var movimiento = Texto(request.Movimiento).ToUpperInvariant();
        var detalle = Texto(request.Detalle);
        var formaPago = Texto(request.FormaPago).ToUpperInvariant();
        var entidad = Texto(request.Entidad).ToUpperInvariant();
        var nroOperacion = Texto(request.NroOperacion);
        if (request.Id is < 0 || request.UsuarioId <= 0 || !TiposMovimiento.Contains(movimiento) ||
            detalle.Length is 0 or > 250 || request.Importe <= 0 || request.Importe > 9999999999999999.99m ||
            formaPago.Length is 0 or > 80 || entidad.Length > 40 || nroOperacion.Length > 40)
            return BadRequest(new { ok = false, mensaje = "Los datos del movimiento no son válidos." });
        if (formaPago == "DEPOSITO" && (entidad.Length == 0 || nroOperacion.Length == 0))
            return BadRequest(new { ok = false, mensaje = "Indica la entidad y el número de operación del depósito." });
        if (imagen is not null && !EsImagenValida(imagen, out var errorImagen))
            return BadRequest(new { ok = false, mensaje = errorImagen });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await con.OpenAsync(cancellationToken);
        await using var tx = (SqlTransaction)await con.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
        var cajaId = await ObtenerCajaActivaAsync(con, request.UsuarioId, cancellationToken, tx);
        if (cajaId is null)
            return BadRequest(new { ok = false, mensaje = "No tienes una caja activa." });

        var rutaImagen = string.Empty;
        var rutaImagenAnterior = string.Empty;
        if (request.Id is > 0)
        {
            await using var movimientoCmd = new SqlCommand("""
                SELECT ISNULL(RutaImagen, '') FROM CajaDetalle WITH (UPDLOCK, HOLDLOCK)
                 WHERE DetalleId = @DetalleId AND CajaId = @CajaId
                   AND ISNULL(NotaIdB, 0) = -1;
                """, con, tx);
            movimientoCmd.Parameters.Add("@DetalleId", SqlDbType.Decimal).Value = request.Id.Value;
            movimientoCmd.Parameters["@DetalleId"].Precision = 38;
            movimientoCmd.Parameters["@DetalleId"].Scale = 0;
            AddCajaId(movimientoCmd, cajaId.Value);
            var existente = await movimientoCmd.ExecuteScalarAsync(cancellationToken);
            if (existente is null)
                return NotFound(new { ok = false, mensaje = "No se encontró el movimiento de caja chica." });
            rutaImagen = existente.ToString() ?? string.Empty;
            rutaImagenAnterior = rutaImagen;
        }

        if (imagen is not null)
        {
            await using var stream = imagen.OpenReadStream();
            rutaImagen = (await _imageService.UploadImage(new ImageData
            {
                ImageStream = stream,
                Nombre = imagen.FileName
            })).Url ?? string.Empty;
        }

        if (nroOperacion.Length > 0)
        {
            await using var existeCmd = new SqlCommand("""
                SELECT 1 FROM CajaDetalle WITH (UPDLOCK, HOLDLOCK)
                 WHERE ISNULL(NotaIdB, 0) = -1
                   AND NroOperacion = @NroOperacion
                   AND (@DetalleId = 0 OR DetalleId <> @DetalleId);
                """, con, tx);
            existeCmd.Parameters.Add("@NroOperacion", SqlDbType.NVarChar, 40).Value = nroOperacion;
            var operacionDetalleId = existeCmd.Parameters.Add("@DetalleId", SqlDbType.Decimal);
            operacionDetalleId.Precision = 38;
            operacionDetalleId.Scale = 0;
            operacionDetalleId.Value = request.Id ?? 0;
            if (await existeCmd.ExecuteScalarAsync(cancellationToken) is not null)
                return BadRequest(new { ok = false, mensaje = "El número de operación ya existe." });
        }

        if (request.Id is > 0)
        {
            await using var updateCmd = new SqlCommand("""
                UPDATE CajaDetalle
                       SET DetalleMovimiento = @Movimiento, DetalleConcepto = @Detalle,
                       DetalleMonto = @Importe, DetalleEfectivo = @Importe,
                       FormaPago = @FormaPago, EntidadBancaria = @Entidad, NroOperacion = @NroOperacion,
                       RutaImagen = @RutaImagen
                 WHERE DetalleId = @DetalleId AND CajaId = @CajaId
                   AND ISNULL(NotaIdB, 0) = -1;
                """, con, tx);
            var updateId = updateCmd.Parameters.Add("@DetalleId", SqlDbType.Decimal);
            updateId.Precision = 38;
            updateId.Scale = 0;
            updateId.Value = request.Id.Value;
            AddCajaId(updateCmd, cajaId.Value);
            updateCmd.Parameters.Add("@Movimiento", SqlDbType.VarChar, 80).Value = movimiento;
            updateCmd.Parameters.Add("@Detalle", SqlDbType.VarChar, 250).Value = detalle;
            var updateImporte = updateCmd.Parameters.Add("@Importe", SqlDbType.Decimal);
            updateImporte.Precision = 18;
            updateImporte.Scale = 2;
            updateImporte.Value = request.Importe;
            updateCmd.Parameters.Add("@FormaPago", SqlDbType.VarChar, 80).Value = formaPago;
            updateCmd.Parameters.Add("@Entidad", SqlDbType.VarChar, 40).Value = entidad;
            updateCmd.Parameters.Add("@NroOperacion", SqlDbType.NVarChar, 40).Value = nroOperacion;
            updateCmd.Parameters.Add("@RutaImagen", SqlDbType.VarChar, -1).Value = rutaImagen;
            if (await updateCmd.ExecuteNonQueryAsync(cancellationToken) != 1)
                return Conflict(new { ok = false, mensaje = "No se pudo actualizar el movimiento." });
            await tx.CommitAsync(cancellationToken);
            if (imagen is not null && rutaImagenAnterior.Length > 0 && rutaImagenAnterior != rutaImagen)
                await _imageService.DeleteImage(rutaImagenAnterior);
            return Ok(new { ok = true, mensaje = "Movimiento de caja chica actualizado." });
        }

        await using var cmd = new SqlCommand("""
            INSERT INTO CajaDetalle
                (CajaId, DetalleFecha, NotaId, DetalleMovimiento,
                 DetalleConcepto, DetalleMonto, DetalleEfectivo, DetalleVuelto,
                 RutaImagen, Estado, Vista, NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion)
            VALUES
                (@CajaId, GETDATE(), 0, @Movimiento,
                 @Detalle, @Importe, @Importe, 0,
                 @RutaImagen, 'T', '', -1, '', @FormaPago, @Entidad, @NroOperacion);
            SELECT CONVERT(bigint, SCOPE_IDENTITY());
            """, con, tx);
        AddCajaId(cmd, cajaId.Value);
        cmd.Parameters.Add("@Movimiento", SqlDbType.VarChar, 80).Value = movimiento;
        cmd.Parameters.Add("@Detalle", SqlDbType.VarChar, 250).Value = detalle;
        var importe = cmd.Parameters.Add("@Importe", SqlDbType.Decimal);
        importe.Precision = 18;
        importe.Scale = 2;
        importe.Value = request.Importe;
        cmd.Parameters.Add("@FormaPago", SqlDbType.VarChar, 80).Value = formaPago;
        cmd.Parameters.Add("@Entidad", SqlDbType.VarChar, 40).Value = entidad;
        cmd.Parameters.Add("@NroOperacion", SqlDbType.NVarChar, 40).Value = nroOperacion;
        cmd.Parameters.Add("@RutaImagen", SqlDbType.VarChar, -1).Value = rutaImagen;
        var detalleId = Convert.ToInt64(await cmd.ExecuteScalarAsync(cancellationToken), CultureInfo.InvariantCulture);
        await tx.CommitAsync(cancellationToken);

        return Ok(new
        {
            ok = true,
            mensaje = "Movimiento de caja chica registrado.",
            movimiento = new PettyCashMovementResponse(detalleId, DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"), movimiento, detalle, request.Importe, formaPago, entidad, nroOperacion, rutaImagen)
        });
    }

    private static async Task<long?> ObtenerCajaActivaAsync(SqlConnection con, int usuarioId, CancellationToken cancellationToken, SqlTransaction? tx = null)
    {
        await using var cmd = new SqlCommand("""
            SELECT TOP 1 CajaId FROM Caja WITH (UPDLOCK, HOLDLOCK)
             WHERE UsuarioId = @UsuarioId AND CajaEstado = 'ACTIVO'
             ORDER BY CajaId DESC;
            """, con, tx);
        cmd.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
        var value = await cmd.ExecuteScalarAsync(cancellationToken);
        return value is null or DBNull ? null : Convert.ToInt64(value, CultureInfo.InvariantCulture);
    }

    private static void AddCajaId(SqlCommand cmd, long cajaId)
    {
        var parameter = cmd.Parameters.Add("@CajaId", SqlDbType.Decimal);
        parameter.Precision = 38;
        parameter.Scale = 0;
        parameter.Value = cajaId;
    }

    private static string Texto(string? value) => (value ?? string.Empty).Trim();

    private static bool EsImagenValida(IFormFile imagen, out string mensaje)
    {
        if (imagen.Length <= 0 || imagen.Length > MaxImageSizeBytes)
        {
            mensaje = "La imagen debe tener como máximo 5 MB.";
            return false;
        }
        if (!TiposImagenPermitidos.Contains(imagen.ContentType))
        {
            mensaje = "Solo se permiten imágenes JPG, PNG o WEBP.";
            return false;
        }
        mensaje = string.Empty;
        return true;
    }
}

public sealed record CreatePettyCashMovementRequest(long? Id, int UsuarioId, string? Movimiento, string? Detalle, decimal Importe, string? FormaPago, string? Entidad, string? NroOperacion);
public sealed record PettyCashMovementResponse(long Id, string Fecha, string Movimiento, string Detalle, decimal Importe, string FormaPago, string Entidad, string NroOperacion, string RutaImagen);
public sealed record PettyCashMovementListResponse(long CajaId, IReadOnlyList<PettyCashMovementResponse> Movimientos);

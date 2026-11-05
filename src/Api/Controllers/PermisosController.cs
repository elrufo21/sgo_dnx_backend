using System.Security.Claims;
using Ecommerce.Application.Contracts.Permisos;
using Ecommerce.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/[controller]")]
public sealed class PermisosController : ControllerBase
{
    private readonly IPermisosIndicador _permisos;
    private readonly IConfiguration _configuration;

    public PermisosController(IPermisosIndicador permisos, IConfiguration configuration)
    {
        _permisos = permisos;
        _configuration = configuration;
    }

    [HttpGet("areas")]
    public async Task<IActionResult> Areas(CancellationToken cancellationToken)
    {
        if (!await PuedeAdministrarPermisosAsync(cancellationToken)) return Forbid();
        await using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await using var command = new SqlCommand("SELECT AreaId, AreaNombre FROM dbo.Area ORDER BY AreaNombre, AreaId", connection);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var areas = new List<object>();
        while (await reader.ReadAsync(cancellationToken))
            areas.Add(new { id = Convert.ToInt32(reader["AreaId"]), area = reader["AreaNombre"].ToString() });
        return Ok(areas);
    }

    [HttpGet("usuarios")]
    public async Task<IActionResult> Usuarios(CancellationToken cancellationToken)
    {
        if (!await PuedeAdministrarPermisosAsync(cancellationToken)) return Forbid();
        const string sql = @"SELECT U.UsuarioID, U.UsuarioAlias, ISNULL(U.Administrador, 0) AS Administrador,
            P.AreaId, LTRIM(RTRIM(ISNULL(P.PersonalNombres, '') + ' ' + ISNULL(P.PersonalApellidos, ''))) AS Nombre
            FROM dbo.Usuarios U INNER JOIN dbo.Personal P ON P.PersonalId = U.PersonalId
            WHERE P.CompaniaId = @companiaId AND P.AreaId > 0 AND U.UsuarioEstado = 'ACTIVO'
            ORDER BY Nombre, U.UsuarioID";
        await using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@companiaId", CompaniaId());
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var users = new List<object>();
        while (await reader.ReadAsync(cancellationToken))
            users.Add(new { id = Convert.ToInt32(reader["UsuarioID"]), areaId = Convert.ToInt32(reader["AreaId"]),
                alias = reader["UsuarioAlias"].ToString(), nombre = reader["Nombre"].ToString(),
                administrador = Convert.ToBoolean(reader["Administrador"]) });
        return Ok(users);
    }

    [HttpGet("perfil")]
    public async Task<ActionResult<PermisoPerfil>> ObtenerPerfil([FromQuery] int areaId, [FromQuery] int? usuarioId, CancellationToken cancellationToken)
    {
        if (!await PuedeAdministrarPermisosAsync(cancellationToken)) return Forbid();
        return Ok(await _permisos.ObtenerPerfilAsync(CompaniaId(), areaId, usuarioId, cancellationToken));
    }

    [HttpPut("perfil")]
    public async Task<IActionResult> GuardarPerfil([FromBody] GuardarPermisoPerfilRequest request, CancellationToken cancellationToken)
    {
        if (!await PuedeAdministrarPermisosAsync(cancellationToken)) return Forbid();
        if (request.AreaId <= 0 || request.Permisos.Count == 0) return BadRequest("Debe indicar el área y los permisos.");
        await _permisos.GuardarPerfilAsync(CompaniaId(), request, cancellationToken);
        return Ok(new { ok = true });
    }

    [HttpGet("mis-permisos")]
    public async Task<IActionResult> MisPermisos(CancellationToken cancellationToken)
    {
        if (EsAdministrador()) return Ok(new { administrador = true, permisos = Array.Empty<string>() });
        var usuarioId = ClaimInt("userId");
        var areaId = ClaimInt("areaId");
        return Ok(new { administrador = false, permisos = await _permisos.ObtenerEfectivosAsync(CompaniaId(), areaId, usuarioId, cancellationToken) });
    }

    private bool EsAdministrador() => User.HasClaim("isAdmin", "1");

    private async Task<bool> PuedeAdministrarPermisosAsync(CancellationToken cancellationToken)
    {
        if (EsAdministrador()) return true;
        var permisos = await _permisos.ObtenerEfectivosAsync(CompaniaId(), ClaimInt("areaId"), ClaimInt("userId"), cancellationToken);
        return permisos.Contains("CONFIGURACION.PERMISOS", StringComparer.OrdinalIgnoreCase);
    }
    private int CompaniaId() => ClaimInt("companiaId");
    private int ClaimInt(string tipo) => int.TryParse(User.FindFirstValue(tipo), out var value) && value > 0
        ? value : throw new UnauthorizedAccessException("La sesión no contiene el contexto de permisos.");
}

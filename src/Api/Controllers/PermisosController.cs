using System.Security.Claims;
using Ecommerce.Application.Contracts.Permisos;
using Ecommerce.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/[controller]")]
public sealed class PermisosController : ControllerBase
{
    private readonly IPermisosIndicador _permisos;

    public PermisosController(IPermisosIndicador permisos) => _permisos = permisos;

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
        return NoContent();
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

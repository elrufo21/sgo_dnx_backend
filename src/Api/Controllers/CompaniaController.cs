using System.Net;
using Ecommerce.Application.Contracts.Companias;
using Ecommerce.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public class CompaniaController : ControllerBase
{
    private readonly ICompania _mediator;

    public CompaniaController(ICompania mediator)
    {
        _mediator = mediator;
    }

    [Authorize]
    [HttpPost("register", Name = "RegisterCompania")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> RegisterCompania([FromBody] Compania compania, CancellationToken cancellationToken)
    {
        return Ok(await _mediator.InsertarAsync(compania, cancellationToken));
    }

    [Authorize]
    [HttpPut("{id}", Name = "EditarCompania")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> EditarCompania(int id, [FromBody] Compania compania, CancellationToken cancellationToken)
    {
        return Ok(await _mediator.EditarAsync(id, compania, cancellationToken));
    }

    [Authorize]
    [HttpPatch("{id}/boleta-por-lote", Name = "ActualizarEnvioBoletaPorLote")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    [ProducesResponseType((int)HttpStatusCode.BadRequest)]
    [ProducesResponseType((int)HttpStatusCode.NotFound)]
    public async Task<IActionResult> ActualizarEnvioBoletaPorLote(
        int id,
        [FromBody] ActualizarBoletaPorLoteRequest? request,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest("Id inválido.");
        }

        if (request is null)
        {
            return BadRequest("Payload requerido.");
        }

        var actualizado = await _mediator.ActualizarBoletaPorLoteAsync(id, request.BoletaPorLote, cancellationToken);
        if (!actualizado)
        {
            return NotFound(new
            {
                ok = false,
                mensaje = $"No se encontró la compañía con id {id}."
            });
        }

        return Ok(new
        {
            ok = true,
            companiaId = id,
            boletaPorLote = request.BoletaPorLote
        });
    }

    [Authorize]
    [HttpPatch("{id}/flag-captura", Name = "ActualizarFlagCaptura")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    [ProducesResponseType((int)HttpStatusCode.BadRequest)]
    [ProducesResponseType((int)HttpStatusCode.NotFound)]
    public async Task<IActionResult> ActualizarFlagCaptura(
        int id,
        [FromBody] ActualizarFlagCapturaRequest? request,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest("Id inválido.");
        }

        if (request is null)
        {
            return BadRequest("Payload requerido.");
        }

        var actualizado = await _mediator.ActualizarFlagCapturaAsync(id, request.FlagCaptura, cancellationToken);
        if (!actualizado)
        {
            return NotFound(new
            {
                ok = false,
                mensaje = $"No se encontró la compañía con id {id}."
            });
        }

        return Ok(new
        {
            ok = true,
            companiaId = id,
            flagCaptura = request.FlagCaptura
        });
    }

    [Authorize]
    [HttpPatch("{id}/lista-productos-tabla", Name = "ActualizarListaProductosTabla")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    [ProducesResponseType((int)HttpStatusCode.BadRequest)]
    [ProducesResponseType((int)HttpStatusCode.NotFound)]
    public async Task<IActionResult> ActualizarListaProductosTabla(
        int id,
        [FromBody] ActualizarListaProductosTablaRequest? request,
        CancellationToken cancellationToken)
    {
        if (id <= 0) return BadRequest("Id inválido.");
        if (request is null) return BadRequest("Payload requerido.");

        var actualizado = await _mediator.ActualizarListaProductosTablaAsync(id, request.ListaProductosTabla, cancellationToken);
        if (!actualizado)
        {
            return NotFound(new
            {
                ok = false,
                mensaje = $"No se encontró la compañía con id {id}."
            });
        }

        return Ok(new
        {
            ok = true,
            companiaId = id,
            listaProductosTabla = request.ListaProductosTabla
        });
    }

    [Authorize]
    [HttpGet("{id}/caja-configuracion/estado", Name = "ObtenerEstadoCajasConfiguracion")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> ObtenerEstadoCajasConfiguracion(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return BadRequest("Id inválido.");
        return Ok(new { hayCajasAbiertas = await _mediator.TieneCajasAbiertasAsync(id, cancellationToken) });
    }

    [Authorize]
    [HttpPatch("{id}/caja-configuracion", Name = "ActualizarConfiguracionCaja")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    [ProducesResponseType((int)HttpStatusCode.BadRequest)]
    [ProducesResponseType((int)HttpStatusCode.NotFound)]
    public async Task<IActionResult> ActualizarConfiguracionCaja(
        int id,
        [FromBody] ActualizarConfiguracionCajaRequest? request,
        CancellationToken cancellationToken)
    {
        if (id <= 0) return BadRequest("Id inválido.");
        if (request is null) return BadRequest("Payload requerido.");
        if (request.DiasMaxDep is < 0 or > 3650) return BadRequest("DiasMaxDep debe estar entre 0 y 3650.");

        var resultado = await _mediator.ActualizarConfiguracionCajaAsync(
            id,
            request.FlagCaja,
            request.CorreosAdmin,
            request.DiasMaxDep,
            request.FlagAsistencia,
            cancellationToken);
        if (resultado == ActualizarConfiguracionCajaResult.CajasAbiertas)
        {
            return Conflict(new
            {
                ok = false,
                mensaje = "Cierra todas las cajas aperturadas antes de modificar la configuración de caja."
            });
        }

        if (resultado == ActualizarConfiguracionCajaResult.CompaniaNoEncontrada)
            return NotFound(new { ok = false, mensaje = $"No se encontró la compañía con id {id}." });

        return Ok(new
        {
            ok = true,
            companiaId = id,
            flagCaja = request.FlagCaja,
            correosAdmin = request.CorreosAdmin?.Trim() ?? string.Empty,
            diasMaxDep = request.DiasMaxDep,
            flagAsistencia = request.FlagAsistencia
        });
    }

    [Authorize]
    [HttpDelete("{id}", Name = "EliminarCompania")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> EliminarCompania(int id, CancellationToken cancellationToken)
    {
        return Ok(await _mediator.EliminarAsync(id, cancellationToken));
    }

    [AllowAnonymous]
    [HttpGet("list", Name = "GetCompaniaList")]
    [ProducesResponseType(typeof(IReadOnlyList<Compania>), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<IReadOnlyList<Compania>>> GetCompaniaList(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        return Ok(await _mediator.ListarAsync(page, pageSize, cancellationToken));
    }

    [AllowAnonymous]
    [HttpGet("combo", Name = "GetCompaniaCombo")]
    [ProducesResponseType(typeof(IReadOnlyList<EGeneral>), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<IReadOnlyList<EGeneral>>> GetCompaniaCombo(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        return Ok(await _mediator.ListarComboAsync(page, pageSize, cancellationToken));
    }
}

public class ActualizarBoletaPorLoteRequest
{
    public bool BoletaPorLote { get; set; }
}

public class ActualizarFlagCapturaRequest
{
    public bool FlagCaptura { get; set; }
}

public class ActualizarListaProductosTablaRequest
{
    public bool ListaProductosTabla { get; set; }
}

public class ActualizarConfiguracionCajaRequest
{
    public bool FlagCaja { get; set; }
    public string? CorreosAdmin { get; set; }
    public int DiasMaxDep { get; set; } = 7;
    public bool? FlagAsistencia { get; set; }
}

using System.Net;
using Ecommerce.Application.Contracts.Clientes;
using Ecommerce.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public class ClienteController: ControllerBase
{
    private readonly ICliente _mediator;
    public ClienteController(ICliente mediador)
    {
        _mediator = mediador;
    }

    [Authorize]
    [HttpPost("register", Name = "RegisterCliente")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> RegisterCliente([FromBody] Cliente cliente, CancellationToken cancellationToken)
    {
        return Ok(await _mediator.InsertarAsync(cliente, cancellationToken));
    }
    
    [Authorize]
    [HttpDelete("{id}", Name = "EliminarCliente")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> EliminarCliente(long id, CancellationToken cancellationToken)
    {
        return Ok(await _mediator.EliminarAsync(id, cancellationToken));
    }

    [AllowAnonymous]
    [HttpGet("list", Name = "GetClienteList")]
    [ProducesResponseType(typeof(ClienteListResult), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<ClienteListResult>> GetClienteList(
        [FromQuery] string? estado = "ACTIVO",
        [FromQuery] string? search = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        return Ok(await _mediator.ListarPaginadoAsync(estado, search, page, pageSize, cancellationToken));
    }

    [AllowAnonymous]
    [HttpGet("{id:long}", Name = "GetClienteById")]
    [ProducesResponseType(typeof(Cliente), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<Cliente>> GetClienteById(long id, CancellationToken cancellationToken = default)
    {
        var cliente = await _mediator.ObtenerPorIdAsync(id, cancellationToken);
        return cliente is null ? NotFound() : Ok(cliente);
    }

    [AllowAnonymous]
    [HttpGet("by-codigo/{codigo}", Name = "GetClienteByCodigo")]
    [ProducesResponseType(typeof(Cliente), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<Cliente>> GetClienteByCodigo(string codigo, CancellationToken cancellationToken = default)
    {
        var cliente = await _mediator.ObtenerPorCodigoAsync(codigo, cancellationToken);
        return cliente is null ? NotFound() : Ok(cliente);
    }

    [AllowAnonymous]
    [HttpGet(Name = "GetListCombo")]
    [ProducesResponseType(typeof(string), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<string>> ListarCombo(CancellationToken cancellationToken)
    {
        return Ok(await _mediator.ListarComboAsync(cancellationToken));
    }
}

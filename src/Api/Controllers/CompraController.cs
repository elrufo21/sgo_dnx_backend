using System.Collections.Generic;
using System.Net;
using Ecommerce.Application.Contracts.Compras;
using Ecommerce.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public class CompraController : ControllerBase
{
    private readonly ICompra _mediator;

    public CompraController(ICompra mediator)
    {
        _mediator = mediator;
    }

    [AllowAnonymous]
    [HttpGet("crud", Name = "GetCompraCrud")]
    [ProducesResponseType(typeof(IReadOnlyList<Compra>), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<IReadOnlyList<Compra>>> ListarCompraCrud(
        [FromQuery] string? estado = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        return Ok(await _mediator.ListarCrudAsync(estado, page, pageSize, cancellationToken));
    }

    [AllowAnonymous]
    [HttpGet("list", Name = "GetCompraList")]
    [ProducesResponseType(typeof(IReadOnlyList<Compra>), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<IReadOnlyList<Compra>>> ListarCompras(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        return Ok(await _mediator.ListarCrudAsync(page: page, pageSize: pageSize, cancellationToken: cancellationToken));
    }

    [AllowAnonymous]
    [HttpGet("facturas-servicio", Name = "GetFacturasServicio")]
    [ProducesResponseType(typeof(IReadOnlyList<CompraServicioConDetalleResponse>), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<IReadOnlyList<CompraServicioConDetalleResponse>>> ListarFacturasServicio(
        [FromQuery] string? estado = null,
        [FromQuery] DateTime? fechaInicio = null,
        [FromQuery] DateTime? fechaFin = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        if (fechaInicio.HasValue && fechaFin.HasValue && fechaInicio.Value.Date > fechaFin.Value.Date)
        {
            return BadRequest("fechaInicio no puede ser mayor a fechaFin.");
        }

        var compras = await _mediator.ListarFacturasServicioAsync(
            estado,
            fechaInicio,
            fechaFin,
            page,
            pageSize,
            cancellationToken);

        var response = new List<CompraServicioConDetalleResponse>();
        foreach (var compra in compras)
        {
            var detalles = await _mediator.ListarDetalleAsync(compra.CompraId, page: 1, pageSize: 100, cancellationToken);
            response.Add(new CompraServicioConDetalleResponse
            {
                Compra = compra,
                Detalles = detalles.ToList()
            });
        }

        return Ok(response);
    }

    [AllowAnonymous]
    [HttpGet("{id:long}", Name = "GetCompraById")]
    [ProducesResponseType(typeof(Compra), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<Compra?>> ObtenerCompra(long id, CancellationToken cancellationToken)
    {
        var compra = await _mediator.ObtenerPorIdAsync(id, cancellationToken);
        if (compra is null) return NotFound();
        return Ok(compra);
    }

    [AllowAnonymous]
    [HttpGet("{id:long}/detalles", Name = "GetCompraDetalles")]
    [ProducesResponseType(typeof(IReadOnlyList<DetalleCompra>), (int)HttpStatusCode.OK)]
    public async Task<ActionResult<IReadOnlyList<DetalleCompra>>> ObtenerDetalles(
        long id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        return Ok(await _mediator.ListarDetalleAsync(id, page, pageSize, cancellationToken));
    }

    [Authorize]
    [HttpPost("register", Name = "RegisterCompra")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> RegistrarCompra([FromBody] Compra compra, CancellationToken cancellationToken)
    {
        return Ok(await _mediator.InsertarAsync(compra, cancellationToken));
    }

    [Authorize]
    [HttpPost("register-with-detail", Name = "RegisterCompraConDetalle")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> RegistrarCompraConDetalle([FromBody] CompraConDetalleRequest request, CancellationToken cancellationToken)
    {
        if (request is null || request.Compra is null)
        {
            return BadRequest("Compra requerida.");
        }
        return Ok(await _mediator.InsertarConDetalleAsync(request.Compra, request.Detalles ?? new List<DetalleCompra>(), cancellationToken));
    }

    [Authorize]
    [HttpPost("facturas-servicio", Name = "RegisterFacturaServicio")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    [ProducesResponseType((int)HttpStatusCode.BadRequest)]
    public async Task<IActionResult> RegistrarFacturaServicio([FromBody] CompraConDetalleRequest request, CancellationToken cancellationToken)
    {
        if (request is null || request.Compra is null)
        {
            return BadRequest("Compra requerida.");
        }

        var detalles = request.Detalles ?? new List<DetalleCompra>();
        var errores = ValidarFacturaServicio(request.Compra, detalles);
        if (errores.Count > 0)
        {
            return BadRequest(new { errores });
        }

        NormalizarFacturaServicio(request.Compra, detalles);

        var result = await _mediator.InsertarConDetalleAsync(request.Compra, detalles, cancellationToken);
        return Ok(new
        {
            compraId = result,
            compra = request.Compra,
            detalles
        });
    }

    [Authorize]
    [HttpDelete("{id:long}", Name = "EliminarCompra")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> EliminarCompra(long id, CancellationToken cancellationToken)
    {
        var ok = await _mediator.EliminarAsync(id, cancellationToken);
        if (!ok) return NotFound();
        return Ok(ok);
    }

    private static List<string> ValidarFacturaServicio(Compra compra, IReadOnlyList<DetalleCompra> detalles)
    {
        var errores = new List<string>();

        if (!compra.ProveedorId.HasValue || compra.ProveedorId <= 0)
        {
            errores.Add("ProveedorId es requerido.");
        }

        if (string.IsNullOrWhiteSpace(compra.CompraSerie))
        {
            errores.Add("CompraSerie es requerido.");
        }

        if (string.IsNullOrWhiteSpace(compra.CompraNumero))
        {
            errores.Add("CompraNumero es requerido.");
        }

        if (detalles.Count == 0)
        {
            errores.Add("Debe enviar al menos un detalle de servicio.");
        }

        for (var i = 0; i < detalles.Count; i++)
        {
            var detalle = detalles[i];
            var cantidad = detalle.DetalleCantidad ?? 1;
            var precio = detalle.PrecioCosto ?? 0;
            var importe = detalle.DetalleImporte ?? 0;

            if (string.IsNullOrWhiteSpace(detalle.Descripcion))
            {
                errores.Add($"Detalles[{i}].Descripcion es requerido.");
            }

            if (cantidad <= 0)
            {
                errores.Add($"Detalles[{i}].DetalleCantidad debe ser mayor a 0.");
            }

            if (precio <= 0 && importe <= 0)
            {
                errores.Add($"Detalles[{i}] debe incluir PrecioCosto o DetalleImporte mayor a 0.");
            }
        }

        return errores;
    }

    private static void NormalizarFacturaServicio(Compra compra, List<DetalleCompra> detalles)
    {
        var fechaEmision = (compra.CompraEmision ?? DateTime.Today).Date;
        compra.CompraRegistro ??= DateTime.Now;
        compra.CompraEmision = fechaEmision;
        compra.CompraComputo ??= fechaEmision;
        compra.TipoCodigo = "01";
        compra.CompraSerie = compra.CompraSerie?.Trim().ToUpperInvariant();
        compra.CompraNumero = compra.CompraNumero?.Trim();
        compra.CompraCorrelativo = string.IsNullOrWhiteSpace(compra.CompraCorrelativo)
            ? $"{compra.CompraSerie}-{compra.CompraNumero}"
            : compra.CompraCorrelativo.Trim();
        compra.CompraMoneda = string.IsNullOrWhiteSpace(compra.CompraMoneda)
            ? "PEN"
            : compra.CompraMoneda.Trim().ToUpperInvariant();
        compra.CompraTipoCambio ??= 1;
        compra.CompraTipoIgv = string.IsNullOrWhiteSpace(compra.CompraTipoIgv)
            ? "GRAVADO"
            : compra.CompraTipoIgv.Trim();
        compra.CompraConcepto = "SERVICIO";
        compra.CompraAsociado ??= string.Empty;
        compra.CompraObs ??= string.Empty;
        compra.CompraTipoSunat ??= 0;
        compra.CompraPercepcion ??= 0;
        compra.CompraDescuento ??= 0;

        decimal valorVenta = 0;
        foreach (var detalle in detalles)
        {
            var cantidad = detalle.DetalleCantidad ?? 1;
            var importe = detalle.DetalleImporte ?? ((detalle.PrecioCosto ?? 0) * cantidad);
            var precio = detalle.PrecioCosto ?? (cantidad == 0 ? 0 : importe / cantidad);

            detalle.DetalleCantidad = cantidad;
            detalle.PrecioCosto = RoundAmount(precio, 4);
            detalle.DetalleImporte = RoundAmount(importe);
            detalle.DetalleDescuento ??= 0;
            detalle.DetalleEstado = string.IsNullOrWhiteSpace(detalle.DetalleEstado)
                ? "EMITIDO"
                : detalle.DetalleEstado.Trim();
            detalle.DetalleUm = string.IsNullOrWhiteSpace(detalle.DetalleUm)
                ? "ZZ"
                : detalle.DetalleUm.Trim().ToUpperInvariant();
            detalle.DetalleCodigo = string.IsNullOrWhiteSpace(detalle.DetalleCodigo)
                ? "SERVICIO"
                : detalle.DetalleCodigo.Trim();
            detalle.Descripcion = detalle.Descripcion?.Trim();
            detalle.DescuentoB ??= 0;
            detalle.EstadoB ??= string.Empty;
            detalle.ValorUM ??= 1;

            valorVenta += detalle.DetalleImporte ?? 0;
        }

        compra.CompraValorVenta ??= RoundAmount(valorVenta);
        var subtotal = compra.CompraSubtotal ?? RoundAmount(Math.Max(0, valorVenta - (compra.CompraDescuento ?? 0)));
        compra.CompraSubtotal = subtotal;
        compra.CompraIgv ??= CalcularIgv(subtotal, compra.CompraTipoIgv);
        compra.CompraTotal ??= RoundAmount(subtotal + (compra.CompraIgv ?? 0) + (compra.CompraPercepcion ?? 0));
        compra.CompraSaldo ??= compra.CompraTotal;

        if (!compra.CompraFechaPago.HasValue && compra.CompraDias.HasValue && compra.CompraDias > 0)
        {
            compra.CompraFechaPago = fechaEmision.AddDays(compra.CompraDias.Value);
        }
        else
        {
            compra.CompraFechaPago ??= fechaEmision;
        }

        compra.CompraDias ??= Math.Max(0, (compra.CompraFechaPago.Value.Date - fechaEmision).Days);
        compra.CompraCondicion = string.IsNullOrWhiteSpace(compra.CompraCondicion)
            ? ((compra.CompraSaldo ?? 0) > 0 ? "CREDITO" : "ALCONTADO")
            : compra.CompraCondicion.Trim();
        compra.CompraEstado = string.IsNullOrWhiteSpace(compra.CompraEstado)
            ? ((compra.CompraSaldo ?? 0) > 0 ? "PENDIENTE DE PAGO" : "CANCELADO")
            : compra.CompraEstado.Trim();
    }

    private static decimal CalcularIgv(decimal subtotal, string? tipoIgv)
    {
        if (!string.IsNullOrWhiteSpace(tipoIgv)
            && (tipoIgv.Contains("EXONER", StringComparison.OrdinalIgnoreCase)
                || tipoIgv.Contains("INAFECT", StringComparison.OrdinalIgnoreCase)
                || tipoIgv.Contains("SIN", StringComparison.OrdinalIgnoreCase)))
        {
            return 0;
        }

        return RoundAmount(subtotal * 0.18m);
    }

    private static decimal RoundAmount(decimal amount, int decimals = 2)
    {
        return Math.Round(amount, decimals, MidpointRounding.AwayFromZero);
    }
}

public class CompraConDetalleRequest
{
    public Compra? Compra { get; set; }
    public List<DetalleCompra>? Detalles { get; set; }
}

public class CompraServicioConDetalleResponse
{
    public Compra? Compra { get; set; }
    public List<DetalleCompra> Detalles { get; set; } = new();
}

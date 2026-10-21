using Ecommerce.Api.Security;
using Ecommerce.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/configuracion/correo-emisor")]
[RequirePermission("CONFIGURACION.PERMISOS")]
public sealed class EmailSenderConfigurationController : ControllerBase
{
    private readonly EmailSenderConfigurationService _configuration;

    public EmailSenderConfigurationController(EmailSenderConfigurationService configuration) =>
        _configuration = configuration;

    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken cancellationToken) =>
        Ok(await _configuration.GetViewAsync(cancellationToken));

    [HttpPut]
    public async Task<IActionResult> Put(
        [FromBody] SaveEmailSenderConfigurationRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            await _configuration.SaveAsync(request.Email ?? string.Empty, request.AppPassword, cancellationToken);
            return NoContent();
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }
}

public sealed class SaveEmailSenderConfigurationRequest
{
    public string? Email { get; set; }
    public string? AppPassword { get; set; }
}

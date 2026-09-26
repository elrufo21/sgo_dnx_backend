using System.Security.Claims;
using Ecommerce.Application.Contracts.Permisos;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Ecommerce.Api.Security;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true)]
public sealed class RequirePermissionAttribute : TypeFilterAttribute
{
    public RequirePermissionAttribute(string codigo) : base(typeof(RequirePermissionFilter))
        => Arguments = new object[] { codigo };
}

public sealed class RequirePermissionFilter : IAsyncAuthorizationFilter
{
    private readonly IPermisosIndicador _permisos;
    private readonly string _codigo;

    public RequirePermissionFilter(IPermisosIndicador permisos, string codigo)
    {
        _permisos = permisos;
        _codigo = codigo;
    }

    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var user = context.HttpContext.User;
        if (user.Identity?.IsAuthenticated != true)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        if (user.HasClaim("isAdmin", "1")) return;

        if (!TryClaim(user, "userId", out var usuarioId) ||
            !TryClaim(user, "companiaId", out var companiaId) ||
            !TryClaim(user, "areaId", out var areaId))
        {
            context.Result = new ForbidResult();
            return;
        }

        var permisos = await _permisos.ObtenerEfectivosAsync(companiaId, areaId, usuarioId, context.HttpContext.RequestAborted);
        if (!permisos.Contains(_codigo, StringComparer.OrdinalIgnoreCase))
            context.Result = new ForbidResult();
    }

    private static bool TryClaim(ClaimsPrincipal user, string tipo, out int value)
        => int.TryParse(user.FindFirstValue(tipo), out value) && value > 0;
}

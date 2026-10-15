using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Security;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false)]
public sealed class RequireAttendanceAttribute : TypeFilterAttribute
{
    public RequireAttendanceAttribute() : base(typeof(RequireAttendanceFilter)) { }
}

public sealed class RequireAttendanceFilter : IAsyncAuthorizationFilter
{
    private const string AttendanceMessage = "NO PODRÁ REALIZAR NINGUNA OPERACIÓN EN CAJA PORQUE NO MARCÓ SU ASISTENCIA.";
    private readonly IConfiguration _configuration;

    public RequireAttendanceFilter(IConfiguration configuration) => _configuration = configuration;

    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var method = context.HttpContext.Request.Method;
        if (HttpMethods.IsGet(method) || HttpMethods.IsHead(method) || HttpMethods.IsOptions(method))
            return;

        if (!int.TryParse(context.HttpContext.User.FindFirstValue("userId"), out var usuarioId) || usuarioId <= 0)
        {
            context.Result = new ForbidResult();
            return;
        }

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            context.Result = new ObjectResult(new { ok = false, mensaje = "No se encontró la cadena de conexión." })
            {
                StatusCode = StatusCodes.Status500InternalServerError
            };
            return;
        }

        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(context.HttpContext.RequestAborted);
        await using var command = new SqlCommand("""
            SELECT CASE
                     WHEN (
                         SELECT MAX(CASE WHEN ISNULL(i.ValorNum, 1) <> 0 THEN 1 ELSE 0 END)
                         FROM dbo.Usuarios AS u
                         INNER JOIN dbo.Personal AS p ON p.PersonalId = u.PersonalId
                         LEFT JOIN dbo.Indicador AS i
                           ON i.CompaniaId = p.CompaniaId
                          AND i.Descripcion = 'ASISTENCIA'
                         WHERE u.UsuarioID = @UsuarioId
                     ) = 0 THEN CAST(1 AS bit)
                     WHEN EXISTS
                     (
                         SELECT 1
                         FROM dbo.Asistencia AS a
                         INNER JOIN dbo.Usuarios AS u ON u.PersonalId = a.PersonalId
                         WHERE u.UsuarioID = @UsuarioId
                           AND a.Fecha = CONVERT(date, GETDATE())
                     ) THEN CAST(1 AS bit)
                     ELSE CAST(0 AS bit)
                   END;
            """, connection);
        command.Parameters.Add("@UsuarioId", System.Data.SqlDbType.Int).Value = usuarioId;

        var puedeContinuar = Convert.ToBoolean(
            await command.ExecuteScalarAsync(context.HttpContext.RequestAborted),
            System.Globalization.CultureInfo.InvariantCulture);
        if (!puedeContinuar)
        {
            context.Result = new ObjectResult(new
            {
                ok = false,
                codigo = "ASISTENCIA_REQUERIDA",
                mensaje = AttendanceMessage
            })
            {
                StatusCode = StatusCodes.Status409Conflict
            };
        }
    }
}

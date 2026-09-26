using Ecommerce.Application.Contracts.Usuarios;
using Ecommerce.Application.Contracts.Permisos;
using Ecommerce.Application.Identity;
using Ecommerce.Application.Models.Token;
using Ecommerce.Domain;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Ecommerce.Infrastructure.Persistence;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Configuration;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public class UsuarioRepository : IUsuario
{
    private readonly IAuthService _authService;
    private readonly JwtSettings _jwtSettings;
    private readonly AccesoDatos _accesoDatos;
    private readonly UserManager<Usuario> _userManager;
    private readonly IPermisosIndicador _permisos;
    private readonly string _connectionString;

    public UsuarioRepository(
        IAuthService authService,
        IOptions<JwtSettings> jwtSettings,
        AccesoDatos accesoDatos,
        UserManager<Usuario> userManager,
        IPermisosIndicador permisos,
        IConfiguration configuration)
    {
        _authService = authService;
        _jwtSettings = jwtSettings.Value;
        _accesoDatos = accesoDatos;
        _userManager = userManager;
        _permisos = permisos;
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");
    }

    public async Task<AuthResponseA> LoginAsync(EUser loginUser, CancellationToken cancellationToken = default)
    {
        var data = $"{loginUser.Email}|{loginUser.Password}|WEB";
        try
        {
            var result = await _accesoDatos.EjecutarComandoAsync("uspValidaUsuarioweb", "@Data", data, cancellationToken);
            return await BuildLegacyResponseAsync(result, cancellationToken);
        }
        catch (SqlException ex) when (ex.Number == 2812)
        {
            return await LoginIdentityAsync(loginUser);
        }
    }

    private async Task<AuthResponseA> BuildLegacyResponseAsync(string result, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(result))
        {
            throw new InvalidOperationException("No hay conexión con el servidor.");
        }

        var info = result.Split('[');
        if (info.Length == 0 || info[0] == "~")
        {
            throw new UnauthorizedAccessException("Acceso denegado, usuario no válido.");
        }

        var payload = info[0].Split('|');
        if (payload.Length < 6)
        {
            throw new InvalidOperationException("Respuesta de autenticación inválida.");
        }

        var nowUtc = DateTime.UtcNow;
        var expiresAtUtc = nowUtc.Add(_jwtSettings.ExpireTime);
        var expiresInSeconds = (int)_jwtSettings.ExpireTime.TotalSeconds;
        var usuarioId = int.TryParse(GetPayloadValue(payload, 0), out var parsedUsuarioId) ? parsedUsuarioId : 0;
        var contexto = await ObtenerContextoPermisosAsync(usuarioId, cancellationToken);
        var companiaId = contexto.CompaniaId > 0
            ? contexto.CompaniaId
            : int.TryParse(GetPayloadValue(payload, 4), out var parsedCompaniaId) ? parsedCompaniaId : 0;
        var permisos = contexto.Administrador || contexto.AreaId <= 0 || companiaId <= 0
            ? Array.Empty<string>()
            : await _permisos.ObtenerEfectivosAsync(companiaId, contexto.AreaId, usuarioId, cancellationToken);
        return new AuthResponseA
        {
            Id = GetPayloadValue(payload, 0),
            PersonalId = GetPayloadValue(payload, 1),
            Area = GetPayloadValue(payload, 2),
            Usuario = GetPayloadValue(payload, 3),
            CompaniaId = GetPayloadValue(payload, 4),
            RazonSocial = GetPayloadValue(payload, 5),
            FechaVencimientoClave = GetPayloadValue(payload, 6, null),
            DescuentoMax = GetPayloadValue(payload, 7, "0"),
            CompaniaRuc = GetPayloadValue(payload, 8),
            CompaniaNomUbg = GetPayloadValue(payload, 9),
            CompaniaComercial = GetPayloadValue(payload, 10),
            CompaniaDirecSunat = GetPayloadValue(payload, 11),
            UsuarioSol = GetPayloadValue(payload, 12),
            ClaveSol = GetPayloadValue(payload, 13),
            CertificadoBase64 = GetPayloadValue(payload, 14),
            ClaveCertificado = GetPayloadValue(payload, 15),
            Entorno = GetPayloadValue(payload, 16, "3"),
            CompaniaTelefono = GetPayloadValue(payload, 17),
            BoletaPorLote = ParseBoolFlag(GetPayloadValue(payload, 18, "1"), true),
            FlagCaptura = ParseBoolFlag(GetPayloadValue(payload, 19, "0"), false),
            Administrador = contexto.Administrador,
            Permisos = permisos,
            Token = _authService.CreateTokenA(expiresAtUtc.ToString("O"), GetPayloadValue(payload, 2), usuarioId, companiaId, contexto.AreaId, contexto.Administrador),
            ExpiresAtUtc = expiresAtUtc,
            ExpiresInSeconds = expiresInSeconds
        };
    }

    private async Task<AuthResponseA> LoginIdentityAsync(EUser loginUser)
    {
        var username = loginUser.Email?.Trim();
        var password = loginUser.Password?.Trim();
        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
        {
            throw new UnauthorizedAccessException("Acceso denegado, usuario no válido.");
        }

        var user = await _userManager.FindByNameAsync(username)
            ?? await _userManager.FindByEmailAsync(username)
            ?? await _userManager.Users.FirstOrDefaultAsync(u =>
                ((u.Nombre ?? "") + " " + (u.Apellido ?? "")).Trim() == username);
        if (user is null || !user.IsActive || !await _userManager.CheckPasswordAsync(user, password))
        {
            throw new UnauthorizedAccessException("Acceso denegado, usuario no válido.");
        }

        var nowUtc = DateTime.UtcNow;
        var expiresAtUtc = nowUtc.Add(_jwtSettings.ExpireTime);
        var expiresInSeconds = (int)_jwtSettings.ExpireTime.TotalSeconds;

        return new AuthResponseA
        {
            Id = user.Id,
            PersonalId = user.Id,
            Area = "DXN",
            Usuario = string.Join(' ', new[] { user.Nombre, user.Apellido }.Where(x => !string.IsNullOrWhiteSpace(x))).Trim(),
            CompaniaId = "1",
            RazonSocial = "DXN CUSCO",
            DescuentoMax = "0",
            Entorno = "3",
            BoletaPorLote = true,
            FlagCaptura = false,
            Administrador = true,
            Permisos = Array.Empty<string>(),
            Token = _authService.CreateTokenA(expiresAtUtc.ToString("O"), "DXN", administrador: true),
            ExpiresAtUtc = expiresAtUtc,
            ExpiresInSeconds = expiresInSeconds
        };
    }

    private static string? GetPayloadValue(string[] payload, int index, string? fallback = "")
    {
        return payload.Length > index ? payload[index] : fallback;
    }

    private static bool ParseBoolFlag(string? value, bool fallback)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return fallback;
        }

        var normalized = value.Trim();
        if (string.Equals(normalized, "1", StringComparison.Ordinal) ||
            string.Equals(normalized, "true", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        if (string.Equals(normalized, "0", StringComparison.Ordinal) ||
            string.Equals(normalized, "false", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return fallback;
    }

    private async Task<(int AreaId, int CompaniaId, bool Administrador)> ObtenerContextoPermisosAsync(int usuarioId, CancellationToken cancellationToken)
    {
        if (usuarioId <= 0) return default;

        const string sql = """
            SELECT ISNULL(P.AreaId, 0) AS AreaId,
                   ISNULL(P.CompaniaId, 0) AS CompaniaId,
                   ISNULL(U.Administrador, 0) AS Administrador
            FROM dbo.Usuarios U
            LEFT JOIN dbo.Personal P ON P.PersonalId = U.PersonalId
            WHERE U.UsuarioID = @UsuarioId;
            """;

        await using var connection = new SqlConnection(_connectionString);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@UsuarioId", usuarioId);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) return default;

        return (
            Convert.ToInt32(reader.GetValue(0)),
            Convert.ToInt32(reader.GetValue(1)),
            Convert.ToBoolean(reader.GetValue(2)));
    }
}

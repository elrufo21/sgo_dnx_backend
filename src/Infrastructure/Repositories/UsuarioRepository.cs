using Ecommerce.Application.Contracts.Usuarios;
using Ecommerce.Application.Identity;
using Ecommerce.Application.Models.Token;
using Ecommerce.Domain;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Ecommerce.Infrastructure.Persistence;
using Microsoft.Extensions.Options;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public class UsuarioRepository : IUsuario
{
    private readonly IAuthService _authService;
    private readonly JwtSettings _jwtSettings;
    private readonly AccesoDatos _accesoDatos;
    private readonly UserManager<Usuario> _userManager;

    public UsuarioRepository(
        IAuthService authService,
        IOptions<JwtSettings> jwtSettings,
        AccesoDatos accesoDatos,
        UserManager<Usuario> userManager)
    {
        _authService = authService;
        _jwtSettings = jwtSettings.Value;
        _accesoDatos = accesoDatos;
        _userManager = userManager;
    }

    public async Task<AuthResponseA> LoginAsync(EUser loginUser, CancellationToken cancellationToken = default)
    {
        var data = $"{loginUser.Email}|{loginUser.Password}|WEB";
        try
        {
            var result = await _accesoDatos.EjecutarComandoAsync("uspValidaUsuario", "@Data", data, cancellationToken);
            return BuildLegacyResponse(result);
        }
        catch (SqlException ex) when (ex.Number == 2812)
        {
            return await LoginIdentityAsync(loginUser);
        }
    }

    private AuthResponseA BuildLegacyResponse(string result)
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
        return new AuthResponseA
        {
            Id = GetPayloadValue(payload, 0),
            PersonalId = GetPayloadValue(payload, 1),
            Area = GetPayloadValue(payload, 2),
            Usuario = GetPayloadValue(payload, 3),
            CompaniaId = GetPayloadValue(payload, 4),
            RazonSocial = GetPayloadValue(payload, 5),
            CompaniaRuc = GetPayloadValue(payload, 6),
            FechaVencimientoClave = GetPayloadValue(payload, 20, null),
            DescuentoMax = "0",
            CompaniaNomUbg = "",
            CompaniaComercial = GetPayloadValue(payload, 10),
            CompaniaDirecSunat = "",
            UsuarioSol = "",
            ClaveSol = "",
            CertificadoBase64 = "",
            ClaveCertificado = "",
            Entorno = "3",
            CompaniaTelefono = "",
            BoletaPorLote = ParseBoolFlag(GetPayloadValue(payload, 8, "1")),
            Token = _authService.CreateTokenA(expiresAtUtc.ToString("O")),
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
            Token = _authService.CreateTokenA(expiresAtUtc.ToString("O")),
            ExpiresAtUtc = expiresAtUtc,
            ExpiresInSeconds = expiresInSeconds
        };
    }

    private static string? GetPayloadValue(string[] payload, int index, string? fallback = "")
    {
        return payload.Length > index ? payload[index] : fallback;
    }

    private static bool ParseBoolFlag(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return true;
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

        return true;
    }
}

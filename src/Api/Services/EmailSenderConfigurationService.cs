using System.Data;
using System.Net.Mail;
using Ecommerce.Application.Models.Email;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;

namespace Ecommerce.Api.Services;

public sealed class EmailSenderConfigurationService
{
    private const string SenderKey = "SMTP_REMITENTE";
    private const string PasswordKey = "SMTP_APP_PASSWORD";
    private const string ProtectedPrefix = "dp:v1:";
    private readonly string _connectionString;
    private readonly EmailSettings _fallback;
    private readonly IDataProtector _protector;

    public EmailSenderConfigurationService(
        IConfiguration configuration,
        IOptions<EmailSettings> fallback,
        IDataProtectionProvider dataProtectionProvider)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Falta ConnectionStrings:DefaultConnection.");
        _fallback = fallback.Value;
        _protector = dataProtectionProvider.CreateProtector("SGO.EmailSenderConfiguration.v1");
    }

    public async Task<EmailSettings> GetEffectiveAsync(CancellationToken cancellationToken)
    {
        var stored = await ReadStoredAsync(null, cancellationToken);
        if (!stored.Exists)
            return _fallback;

        if (string.IsNullOrWhiteSpace(stored.Email) || string.IsNullOrWhiteSpace(stored.Password))
            throw new InvalidOperationException("La configuración global del correo emisor está incompleta.");

        return CreateEffective(stored.Email, Unprotect(stored.Password));
    }

    public async Task<EmailSenderConfigurationView> GetViewAsync(CancellationToken cancellationToken)
    {
        var stored = await ReadStoredAsync(null, cancellationToken);
        if (stored.Exists)
            return new(stored.Email?.Trim() ?? string.Empty, !string.IsNullOrWhiteSpace(stored.Password), "Indicador");

        var fallbackConfigured = !string.IsNullOrWhiteSpace(_fallback.Email) && !string.IsNullOrWhiteSpace(_fallback.Key);
        return new(_fallback.Email?.Trim() ?? string.Empty, fallbackConfigured, fallbackConfigured ? "Servidor" : "Sin configurar");
    }

    public async Task SaveAsync(string email, string? appPassword, CancellationToken cancellationToken)
    {
        email = email.Trim();
        appPassword = NormalizeAppPassword(appPassword);
        if (!MailAddress.TryCreate(email, out _) || email.Length > 254)
            throw new ArgumentException("Ingresa un correo emisor válido.", nameof(email));

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);

        var current = await ReadStoredAsync((connection, transaction), cancellationToken);
        var currentEmail = current.Exists ? current.Email : _fallback.Email?.Trim() ?? string.Empty;
        var changedEmail = !string.Equals(email, currentEmail, StringComparison.OrdinalIgnoreCase);

        if (string.IsNullOrWhiteSpace(appPassword))
        {
            if (changedEmail)
                throw new ArgumentException("Ingresa la contraseña de aplicación de Google para esta cuenta.", nameof(appPassword));
            appPassword = current.Exists
                ? string.IsNullOrWhiteSpace(current.Password) ? string.Empty : Unprotect(current.Password)
                : _fallback.Key?.Trim() ?? string.Empty;
            if (string.IsNullOrWhiteSpace(appPassword))
                throw new ArgumentException("Ingresa la contraseña de aplicación de Google para esta cuenta.", nameof(appPassword));
        }

        var protectedPassword = ProtectedPrefix + _protector.Protect(appPassword);
        await UpsertAsync(connection, transaction, SenderKey, email, cancellationToken);
        await UpsertAsync(connection, transaction, PasswordKey, protectedPassword, cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    private EmailSettings CreateEffective(string email, string password) => new()
    {
        Email = email,
        Key = password,
        Host = string.IsNullOrWhiteSpace(_fallback.Host) ? "smtp.gmail.com" : _fallback.Host,
        Port = _fallback.Port ?? 587,
        EnableSsl = _fallback.EnableSsl ?? true,
        DisplayName = _fallback.DisplayName,
        BaseUrlClient = _fallback.BaseUrlClient
    };

    private async Task<StoredConfiguration> ReadStoredAsync(
        (SqlConnection Connection, SqlTransaction Transaction)? scope,
        CancellationToken cancellationToken)
    {
        var ownsConnection = scope is null;
        await using var connection = ownsConnection ? new SqlConnection(_connectionString) : null;
        var activeConnection = scope?.Connection ?? connection!;
        if (ownsConnection)
            await activeConnection.OpenAsync(cancellationToken);

        var lockHint = scope is null ? string.Empty : "WITH (UPDLOCK, HOLDLOCK)";
        await using var command = new SqlCommand($@"
SELECT Descripcion, ValorTexto1
FROM dbo.Indicador {lockHint}
WHERE CompaniaId IS NULL AND Area = 'CORREO' AND TipoIndicador = 3
  AND IdIndicador IS NULL AND Descripcion IN (@SenderKey, @PasswordKey);",
            activeConnection, scope?.Transaction);
        command.Parameters.Add("@SenderKey", SqlDbType.VarChar, 500).Value = SenderKey;
        command.Parameters.Add("@PasswordKey", SqlDbType.VarChar, 500).Value = PasswordKey;

        string? email = null;
        string? password = null;
        var keys = new HashSet<string>(StringComparer.Ordinal);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var key = reader.GetString(0);
            if (!keys.Add(key))
                throw new InvalidOperationException("Hay indicadores globales duplicados para el correo emisor.");
            var value = reader.IsDBNull(1) ? null : reader.GetString(1).Trim();
            if (key == SenderKey) email = value;
            if (key == PasswordKey) password = value;
        }
        return new(keys.Count > 0, email, password);
    }

    private static async Task UpsertAsync(SqlConnection connection, SqlTransaction transaction, string key, string value, CancellationToken cancellationToken)
    {
        await using var command = new SqlCommand(@"
IF EXISTS (SELECT 1 FROM dbo.Indicador WITH (UPDLOCK, HOLDLOCK)
           WHERE CompaniaId IS NULL AND Area = 'CORREO' AND TipoIndicador = 3
             AND IdIndicador IS NULL AND Descripcion = @Descripcion)
    UPDATE dbo.Indicador
       SET ValorTexto1 = @Valor, FechaActualizacion = GETDATE()
     WHERE CompaniaId IS NULL AND Area = 'CORREO' AND TipoIndicador = 3
       AND IdIndicador IS NULL AND Descripcion = @Descripcion;
ELSE
    INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1)
    VALUES (NULL, 'CORREO', 3, NULL, @Descripcion, @Valor);", connection, transaction);
        command.Parameters.Add("@Descripcion", SqlDbType.VarChar, 500).Value = key;
        command.Parameters.Add("@Valor", SqlDbType.VarChar, 500).Value = value;
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private string Unprotect(string value)
    {
        if (!value.StartsWith(ProtectedPrefix, StringComparison.Ordinal))
            throw new InvalidOperationException("La contraseña del correo emisor no está protegida. Vuelve a guardarla desde Configuración.");
        return _protector.Unprotect(value[ProtectedPrefix.Length..]);
    }

    private static string NormalizeAppPassword(string? value) =>
        new((value ?? string.Empty).Where(character => !char.IsWhiteSpace(character)).ToArray());

    private sealed record StoredConfiguration(bool Exists, string? Email, string? Password);
}

public sealed record EmailSenderConfigurationView(string Email, bool HasAppPassword, string Source);

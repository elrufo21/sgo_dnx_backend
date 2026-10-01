namespace Ecommerce.Api.Interfaces;

public interface ISunatAuthService
{
    Task<string> GetAccessTokenAsync();
    object? GetLastAuthDebug();
}


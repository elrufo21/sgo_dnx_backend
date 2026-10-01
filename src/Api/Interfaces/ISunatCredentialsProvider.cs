using Ecommerce.Api.Models;

namespace Ecommerce.Api.Interfaces;

public interface ISunatCredentialsProvider
{
    Task<SunatCredentials> GetCredentialsAsync(CancellationToken cancellationToken = default);
}


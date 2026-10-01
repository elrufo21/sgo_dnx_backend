using Ecommerce.Api.Models;

namespace Ecommerce.Api.Interfaces;

public interface ISunatComprobanteService
{
    Task<IReadOnlyList<ValidarComprobanteSunatResult>> ValidarAsync(
        IReadOnlyList<ValidarComprobanteSunatItem> documentos,
        CancellationToken cancellationToken = default);
}


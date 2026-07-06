using Ecommerce.Domain;
namespace Ecommerce.Application.Contracts.Clientes;

public interface ICliente
{
    Task<string> InsertarAsync(Cliente cliente, CancellationToken cancellationToken = default);
    Task<bool> EliminarAsync(long id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Cliente>> ListarAsync(
        string? estado = "ACTIVO",
        string? search = null,
        int page = 1,
        int pageSize = 50,
        CancellationToken cancellationToken = default);
    Task<ClienteListResult> ListarPaginadoAsync(
        string? estado = "ACTIVO",
        string? search = null,
        int page = 1,
        int pageSize = 50,
        CancellationToken cancellationToken = default);
    Task<Cliente?> ObtenerPorIdAsync(long id, CancellationToken cancellationToken = default);
    Task<Cliente?> ObtenerPorCodigoAsync(string codigo, CancellationToken cancellationToken = default);
    Task<string> ListarComboAsync(CancellationToken cancellationToken = default);
}

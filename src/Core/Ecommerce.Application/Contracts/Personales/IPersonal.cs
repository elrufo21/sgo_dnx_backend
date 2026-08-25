using Ecommerce.Domain;

namespace Ecommerce.Application.Contracts.Personales;

public interface IPersonal
{
    Task<string> InsertarAsync(Personal personal, CancellationToken cancellationToken = default);
    Task<bool> EliminarAsync(long id, CancellationToken cancellationToken = default);
    Task<Personal?> ObtenerPorIdAsync(long id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Personal>> ListarAsync(
        string? estado = "ACTIVO",
        int page = 1,
        int pageSize = 50,
        CancellationToken cancellationToken = default);
    Task<string> InsertarMantenimientoAsync(
        Personal personal,
        byte[]? huella = null,
        CancellationToken cancellationToken = default);
    Task<bool> EliminarMantenimientoAsync(long id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Personal>> ListarMantenimientoAsync(
        string? estado = "ACTIVO",
        int page = 1,
        int pageSize = 50,
        CancellationToken cancellationToken = default);
}

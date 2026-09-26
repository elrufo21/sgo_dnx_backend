using Ecommerce.Domain;

namespace Ecommerce.Application.Contracts.Permisos;

public interface IPermisosIndicador
{
    Task<PermisoPerfil> ObtenerPerfilAsync(int companiaId, int areaId, int? usuarioId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<string>> ObtenerEfectivosAsync(int companiaId, int areaId, int usuarioId, CancellationToken cancellationToken = default);
    Task GuardarPerfilAsync(int companiaId, GuardarPermisoPerfilRequest request, CancellationToken cancellationToken = default);
}

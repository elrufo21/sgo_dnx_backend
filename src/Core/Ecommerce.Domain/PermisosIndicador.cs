namespace Ecommerce.Domain;

public sealed class PermisoEstado
{
    public string Codigo { get; set; } = string.Empty;
    public bool Permitido { get; set; }
    public bool Heredar { get; set; }
    public bool PermisoArea { get; set; }
    public bool? ExcepcionUsuario { get; set; }
}

public sealed class PermisoPerfil
{
    public int AreaId { get; set; }
    public int? UsuarioId { get; set; }
    public IReadOnlyList<PermisoEstado> Permisos { get; set; } = Array.Empty<PermisoEstado>();
}

public sealed class GuardarPermisoPerfilRequest
{
    public int AreaId { get; set; }
    public int? UsuarioId { get; set; }
    public IReadOnlyList<PermisoEstado> Permisos { get; set; } = Array.Empty<PermisoEstado>();
}

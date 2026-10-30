using Ecommerce.Infrastructure.Persistence.Repositories;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

var connection = Environment.GetEnvironmentVariable("DNX_READONLY_TEST_CONNECTION") ?? throw new Exception("Configure DNX_READONLY_TEST_CONNECTION.");
var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?> { ["ConnectionStrings:DefaultConnection"] = connection }).Build();
var users = await new UsuariosCrudRepository(config).ListarMantenimientoAsync("ACTIVO", 1, 50);
if (users.Count == 0) throw new Exception("No hay usuarios para verificar.");
await using var con = new SqlConnection(connection);
await con.OpenAsync();
var checkedCount = 0;
foreach (var user in users.Where(u => u.PersonalId.HasValue).Take(10))
{
    await using var cmd = new SqlCommand("SELECT LTRIM(RTRIM(ISNULL(p.PersonalNombres, '') + ' ' + ISNULL(p.PersonalApellidos, ''))) AS Nombre, a.AreaNombre AS Area FROM dbo.Personal p LEFT JOIN dbo.Area a ON a.AreaId = p.AreaId WHERE p.PersonalId = @id", con);
    cmd.Parameters.AddWithValue("@id", user.PersonalId!.Value);
    await using var reader = await cmd.ExecuteReaderAsync();
    if (!await reader.ReadAsync()) continue;
    var name = reader["Nombre"].ToString();
    var area = reader["Area"] == DBNull.Value ? null : reader["Area"].ToString();
    if (user.Nombre != name || user.Area != area) throw new Exception("Nombre o área no coinciden con el personal asociado.");
    checkedCount++;
}
if (checkedCount == 0) throw new Exception("No se encontraron relaciones de personal para verificar.");
Console.WriteLine($"Listado y datos de {checkedCount} usuarios verificados con consultas de lectura.");

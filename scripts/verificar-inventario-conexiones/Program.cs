using System.Reflection;
using Ecommerce.Api.Controllers;
using Microsoft.Extensions.Configuration;
using Microsoft.Data.SqlClient;

static (bool ok, string[] sources) Resolve(Dictionary<string, string?> settings)
{
    var config = new ConfigurationBuilder().AddInMemoryCollection(settings).Build();
    var controller = new InventarioVistaPreviaController(config);
    var method = typeof(InventarioVistaPreviaController).GetMethod("TrySources", BindingFlags.Instance | BindingFlags.NonPublic)!;
    object?[] args = { null };
    var ok = (bool)method.Invoke(controller, args)!;
    var sources = ((Array)args[0]!).Cast<object>().Select(source =>
        (string)source.GetType().GetProperty("ConnectionString")!.GetValue(source)!).ToArray();
    return (ok, sources);
}

static void Check(bool value, string name)
{
    if (!value) throw new Exception(name);
    Console.WriteLine($"OK: {name}");
}

var local = new Dictionary<string, string?> {
    ["ConnectionStrings:DefaultConnection"] = "Server=local;Database=principal;Integrated Security=true",
    ["InventarioVistaPrevia:BaseComas"] = "COMAS", ["InventarioVistaPrevia:BaseIca"] = "ICA"
};
var result = Resolve(local);
Check(result.ok && new SqlConnectionStringBuilder(result.sources[0]).InitialCatalog == "COMAS" && new SqlConnectionStringBuilder(result.sources[1]).InitialCatalog == "ICA", "Local por defecto conserva las dos bases");
local["InventarioVistaPrevia:BaseIca"] = "COMAS";
Check(!Resolve(local).ok, "Local rechaza bases iguales");
var remote = new Dictionary<string, string?> {
    ["InventarioVistaPrevia:Modo"] = "Conexion",
    ["ConnectionStrings:InventarioComas"] = "Server=servidor-comas;Database=COMAS;Integrated Security=true",
    ["ConnectionStrings:InventarioIca"] = "Server=servidor-ica;Database=ICA;Integrated Security=true"
};
result = Resolve(remote);
Check(result.ok && new SqlConnectionStringBuilder(result.sources[0]).DataSource == "servidor-comas" && new SqlConnectionStringBuilder(result.sources[1]).DataSource == "servidor-ica", "Conexion usa cada servidor correspondiente");
remote["ConnectionStrings:InventarioIca"] = null;
Check(!Resolve(remote).ok, "Conexion rechaza una sede sin configurar");
remote["ConnectionStrings:InventarioIca"] = "Server=servidor-comas;Database=COMAS;Integrated Security=true";
Check(!Resolve(remote).ok, "Conexion rechaza dos destinos iguales");
remote["ConnectionStrings:InventarioIca"] = "cadena invalida";
Check(!Resolve(remote).ok, "Conexion rechaza configuracion invalida");
remote["InventarioVistaPrevia:Modo"] = "otro";
Check(!Resolve(remote).ok, "Modo desconocido no genera consolidado");

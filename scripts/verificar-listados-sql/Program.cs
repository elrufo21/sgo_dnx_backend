using Microsoft.SqlServer.TransactSql.ScriptDom;
using System.Text.Json;

// Analisis de archivos, sin conexion ni ejecucion contra SQL Server.
var root = Path.GetFullPath(args.Length > 0 ? args[0] : Directory.GetCurrentDirectory());
var folder = Path.Combine(root, "scripts/sql/20261020_optimizacion_listados");
var schema = new Dictionary<string, HashSet<string>>(StringComparer.OrdinalIgnoreCase);
foreach (var name in new[] { "DXNCOMAS", "DXN_ICA15102026" })
{
    var file = Path.Combine(root, $"artifacts/analisis-dxncomas-20261018/{name}.json");
    if (!File.Exists(file)) continue;
    using var json = JsonDocument.Parse(File.ReadAllText(file));
    foreach (var column in json.RootElement.GetProperty("columns").EnumerateArray())
    {
        var table = column.GetProperty("table_name").GetString();
        if (!schema.TryGetValue(table, out var columns)) schema[table] = columns = new(StringComparer.OrdinalIgnoreCase);
        columns.Add(column.GetProperty("name").GetString());
    }
}
var parser = new TSql100Parser(true);
var issues = new List<string>();
foreach (var file in Directory.GetFiles(folder, "*.sql").OrderBy(f => f))
{
    using var reader = File.OpenText(file);
    var fragment = parser.Parse(reader, out var errors);
    issues.AddRange(errors.Select(e => $"{Path.GetFileName(file)}:{e.Line}: {e.Message}"));
    var guard = new ReadOnlyGuard();
    fragment.Accept(guard);
    issues.AddRange(guard.Errors.Select(e => $"{Path.GetFileName(file)}: {e}"));
    if (schema.Count > 0)
    {
        var references = new References();
        fragment.Accept(references);
        foreach (var column in references.Columns)
        {
            if (column.MultiPartIdentifier?.Identifiers.Count != 2) continue;
            var alias = column.MultiPartIdentifier.Identifiers[0].Value;
            var field = column.MultiPartIdentifier.Identifiers[1].Value;
            if (references.VariableAliases.Contains(alias)) continue;
            var tables = references.Tables.Where(t => string.Equals(t.Alias?.Value ?? t.SchemaObject.BaseIdentifier.Value, alias, StringComparison.OrdinalIgnoreCase))
                .Select(t => t.SchemaObject).ToArray();
            // Un alias de temporal/CTE o ambiguo necesita el contexto de la consulta, que no se infiere aqui.
            if (tables.Length == 0 || tables.Any(t => t.SchemaIdentifier?.Value != "dbo")) continue;
            foreach (var table in tables.Select(t => t.BaseIdentifier.Value).Distinct(StringComparer.OrdinalIgnoreCase))
                if (schema.TryGetValue(table, out var fields) && !fields.Contains(field))
                    issues.Add($"{Path.GetFileName(file)}:{column.StartLine}: columna desconocida {table}.{field}");
        }
    }
    Console.WriteLine($"{Path.GetFileName(file)}: analizado con TSql100Parser");
}
var invoices = File.ReadAllText(Path.Combine(folder, "03_procedimiento_facturas_servicio.sql"));
if (invoices.Contains("SET @Page = CASE")) issues.Add("Facturas no debe repetir la ultima pagina: Despacho itera hasta recibir una pagina vacia.");
if (!invoices.Contains("FROM #Pagina p INNER JOIN dbo.DetalleDocumento")) issues.Add("Los detalles deben contarse solo para la pagina.");
var cash = File.ReadAllText(Path.Combine(folder, "02_procedimiento_caja.sql"));
if (!cash.Contains("FROM #Cerradas c")) issues.Add("El calculo debe limitarse a las cajas cerradas de la pagina.");
foreach (var issue in issues.Distinct()) Console.Error.WriteLine(issue);
if (schema.Count == 0) Console.WriteLine("Sin snapshots locales: solo sintaxis, destinos de escritura y estructura; no se verificaron columnas.");
Console.WriteLine($"Resultado: {issues.Count} incidencias. No se ejecuto SQL ni se abrio conexion.");
return issues.Count == 0 ? 0 : 1;

sealed class References : TSqlFragmentVisitor
{
    public List<NamedTableReference> Tables { get; } = new();
    public List<ColumnReferenceExpression> Columns { get; } = new();
    public HashSet<string> VariableAliases { get; } = new(StringComparer.OrdinalIgnoreCase);
    public override void ExplicitVisit(NamedTableReference n) { Tables.Add(n); base.ExplicitVisit(n); }
    public override void ExplicitVisit(VariableTableReference n) { if (n.Alias != null) VariableAliases.Add(n.Alias.Value); base.ExplicitVisit(n); }
    public override void ExplicitVisit(ColumnReferenceExpression n) { Columns.Add(n); base.ExplicitVisit(n); }
}
sealed class ReadOnlyGuard : TSqlFragmentVisitor
{
    public List<string> Errors { get; } = new();
    public override void ExplicitVisit(InsertStatement n)
    {
        Check(n.InsertSpecification.Target, null);
        base.ExplicitVisit(n);
    }
    public override void ExplicitVisit(DeleteStatement n)
    {
        Check(n.DeleteSpecification.Target, n.DeleteSpecification.FromClause);
        base.ExplicitVisit(n);
    }
    public override void ExplicitVisit(UpdateStatement n)
    {
        Check(n.UpdateSpecification.Target, n.UpdateSpecification.FromClause);
        base.ExplicitVisit(n);
    }
    private void Check(TableReference target, FromClause from)
    {
        if (target is VariableTableReference) return;
        if (target is NamedTableReference table)
        {
            var name = table.SchemaObject.BaseIdentifier.Value;
            if (name.StartsWith("#")) return;
            if (from != null)
            {
                var refs = new References(); from.Accept(refs);
                if (refs.Tables.Any(t => string.Equals(t.Alias?.Value, name, StringComparison.OrdinalIgnoreCase)
                                        && t.SchemaObject.BaseIdentifier.Value.StartsWith("#"))) return;
            }
            Errors.Add($"DML fuera de tablas temporales: {name}, linea {target.StartLine}");
            return;
        }
        Errors.Add($"Destino DML no reconocido en linea {target.StartLine}");
    }
}

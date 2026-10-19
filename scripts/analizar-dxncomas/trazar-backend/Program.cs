using System.Text.Json;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

var root = Path.GetFullPath(args[0]);
var results = new List<object>();
foreach (var file in Directory.EnumerateFiles(Path.Combine(root, "src"), "*.cs", SearchOption.AllDirectories))
{
    if (file.Split(Path.DirectorySeparatorChar).Any(p => p is "obj" or "bin" or "artifacts" or "Migrations")) continue;
    var text = File.ReadAllText(file);
    var syntax = CSharpSyntaxTree.ParseText(text);
    int Line(SyntaxNode n) => syntax.GetLineSpan(n.Span).StartLinePosition.Line + 1;
    object Attr(AttributeSyntax a) => new { name = a.Name.ToString(), args = a.ArgumentList?.Arguments.Select(x => new { name = x.NameEquals?.Name.ToString(), value = x.Expression is LiteralExpressionSyntax l ? l.Token.ValueText : x.Expression.ToString() }).ToArray() };
    foreach (var cls in syntax.GetRoot().DescendantNodes().OfType<ClassDeclarationSyntax>())
    {
        results.Add(new {
            file = Path.GetRelativePath(root, file).Replace('\\', '/'),
            name = cls.Identifier.ValueText,
            bases = cls.BaseList?.Types.Select(t => t.Type.ToString()).ToArray() ?? [],
            attrs = cls.AttributeLists.SelectMany(x => x.Attributes).Select(Attr).ToArray(),
            fields = cls.Members.OfType<FieldDeclarationSyntax>().SelectMany(f => f.Declaration.Variables.Select(v => new { name = v.Identifier.ValueText, type = f.Declaration.Type.ToString(), initializer = v.Initializer?.Value.ToString() })).ToArray(),
            methods = cls.Members.OfType<MethodDeclarationSyntax>().Select(m => new {
                name = m.Identifier.ValueText, line = Line(m), end = syntax.GetLineSpan(m.Span).EndLinePosition.Line + 1,
                attrs = m.AttributeLists.SelectMany(x => x.Attributes).Select(Attr).ToArray(),
                parameters = m.ParameterList.Parameters.Select(p => new { name = p.Identifier.ValueText, type = p.Type?.ToString() }).ToArray(),
                text = m.ToString(),
                strings = m.DescendantNodes().OfType<LiteralExpressionSyntax>().Where(l => l.IsKind(SyntaxKind.StringLiteralExpression)).Select(l => new { value = l.Token.ValueText, line = Line(l) }).ToArray(),
                interpolated = m.DescendantNodes().OfType<InterpolatedStringExpressionSyntax>().Select(l => new { value = string.Concat(l.Contents.Select(c => c is InterpolatedStringTextSyntax t ? t.TextToken.ValueText : "{dynamic}")), line = Line(l) }).ToArray(),
                calls = m.DescendantNodes().OfType<InvocationExpressionSyntax>().Select(i => new { name = i.Expression is MemberAccessExpressionSyntax ma ? ma.Name.Identifier.ValueText : i.Expression is GenericNameSyntax g ? g.Identifier.ValueText : i.Expression.ToString(), receiver = i.Expression is MemberAccessExpressionSyntax access ? access.Expression.ToString() : "", line = Line(i), args = i.ArgumentList.Arguments.Select(a => a.Expression.ToString()).ToArray() }).ToArray()
            }).ToArray()
        });
    }
}
File.WriteAllText(args[1], JsonSerializer.Serialize(results, new JsonSerializerOptions { WriteIndented = true }));
Console.WriteLine($"Clases inspeccionadas: {results.Count}");

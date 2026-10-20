using System.Collections;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Ecommerce.Api.Filters;

public sealed class DepurarTextoEntradaFilter : IAsyncActionFilter
{
    private static readonly HashSet<string> SensitivePropertyNames = new(StringComparer.OrdinalIgnoreCase)
    {
        "Password",
        "PasswordHash",
        "Clave",
        "Contrasena",
        "SecurityStamp",
        "ConcurrencyStamp",
        "Token",
        "AccessToken",
        "RefreshToken",
    };

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        if (HttpMethods.IsPost(context.HttpContext.Request.Method) ||
            HttpMethods.IsPut(context.HttpContext.Request.Method) ||
            HttpMethods.IsPatch(context.HttpContext.Request.Method))
        {
            var visited = new HashSet<object>(ReferenceComparer.Instance);
            foreach (var argument in context.ActionArguments.ToArray())
            {
                if (!IsSensitive(argument.Key))
                {
                    context.ActionArguments[argument.Key] = Sanitize(argument.Value, visited);
                }
            }
        }

        await next();
    }

    private static object? Sanitize(object? value, HashSet<object> visited)
    {
        if (value is null) return null;
        if (value is string text) return DbDepurarTexto(text);
        if (value is JsonElement json) return SanitizeJson(json, skip: false);
        if (value is Microsoft.AspNetCore.Http.IFormFile or Stream) return value;

        var type = value.GetType();
        if (type.IsValueType || type.Namespace?.StartsWith("System", StringComparison.Ordinal) == true)
        {
            if (value is IList list)
            {
                for (var index = 0; index < list.Count; index++)
                {
                    if (list[index] is string item) list[index] = DbDepurarTexto(item);
                    else if (list[index] is { } nested) list[index] = Sanitize(nested, visited);
                }
            }
            else if (value is IDictionary dictionary)
            {
                foreach (var key in dictionary.Keys.Cast<object>().ToArray())
                {
                    if (dictionary[key] is string item) dictionary[key] = DbDepurarTexto(item);
                    else if (dictionary[key] is { } nested) dictionary[key] = Sanitize(nested, visited);
                }
            }

            return value;
        }

        if (!visited.Add(value)) return value;

        foreach (var property in type.GetProperties(BindingFlags.Instance | BindingFlags.Public))
        {
            if (!property.CanRead || !property.CanWrite || property.GetIndexParameters().Length != 0 ||
                IsSensitive(property.Name))
            {
                continue;
            }

            var propertyValue = property.GetValue(value);
            if (propertyValue is string propertyText)
            {
                property.SetValue(value, DbDepurarTexto(propertyText));
            }
            else if (propertyValue is not null)
            {
                property.SetValue(value, Sanitize(propertyValue, visited));
            }
        }

        return value;
    }

    private static string DbDepurarTexto(string texto) =>
        texto.Replace("'", "")
            .Replace("[", "")
            .Replace("]", "")
            .Replace(";", "")
            .Replace("|", "")
            .Replace("¬", "")
            .Replace("}", "")
            .Replace("{", "");

    private static bool IsSensitive(string name) =>
        SensitivePropertyNames.Contains(name) ||
        name.Contains("password", StringComparison.OrdinalIgnoreCase) ||
        name.Contains("clave", StringComparison.OrdinalIgnoreCase) ||
        name.Contains("contrasena", StringComparison.OrdinalIgnoreCase) ||
        name.Contains("token", StringComparison.OrdinalIgnoreCase) ||
        name.Contains("secret", StringComparison.OrdinalIgnoreCase);

    private static JsonElement SanitizeJson(JsonElement element, bool skip)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream))
        {
            WriteJson(element, writer, skip);
        }

        using var document = JsonDocument.Parse(stream.ToArray());
        return document.RootElement.Clone();
    }

    private static void WriteJson(JsonElement element, Utf8JsonWriter writer, bool skip)
    {
        switch (element.ValueKind)
        {
            case JsonValueKind.Object:
                writer.WriteStartObject();
                foreach (var property in element.EnumerateObject())
                {
                    writer.WritePropertyName(property.Name);
                    WriteJson(property.Value, writer, skip || IsSensitive(property.Name));
                }
                writer.WriteEndObject();
                break;
            case JsonValueKind.Array:
                writer.WriteStartArray();
                foreach (var item in element.EnumerateArray()) WriteJson(item, writer, skip);
                writer.WriteEndArray();
                break;
            case JsonValueKind.String:
                writer.WriteStringValue(skip ? element.GetString() : DbDepurarTexto(element.GetString() ?? ""));
                break;
            case JsonValueKind.Undefined:
                writer.WriteNullValue();
                break;
            default:
                element.WriteTo(writer);
                break;
        }
    }

    private sealed class ReferenceComparer : IEqualityComparer<object>
    {
        public static readonly ReferenceComparer Instance = new();
        public new bool Equals(object? x, object? y) => ReferenceEquals(x, y);
        public int GetHashCode(object obj) => RuntimeHelpers.GetHashCode(obj);
    }
}

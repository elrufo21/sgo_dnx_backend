using System.Text.RegularExpressions;

namespace Ecommerce.Domain;

public static class ClienteRazonNormalizer
{
    public static string Normalize(string? value) => Regex.Replace(
            value ?? string.Empty, @"\[?EXP[0-9]{2}-[0-9]{2}-[0-9]{4}\]?", "", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)
        .Replace(".", "").Replace(",", "")
        .Replace("{", "").Replace("}", "")
        .Replace("[", "").Replace("]", "").Trim();
}

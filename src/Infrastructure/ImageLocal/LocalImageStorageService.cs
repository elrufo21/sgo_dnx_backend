using Ecommerce.Application.Models.ImageManagement;
using Microsoft.Extensions.Options;

namespace Ecommerce.Infrastructure.ImageLocal;

public sealed class LocalImageStorageService
{
    private static readonly HashSet<string> ImageExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".webp"
    };

    private readonly LocalMediaSettings _settings;

    public LocalImageStorageService(IOptions<LocalMediaSettings> settings) => _settings = settings.Value;

    public async Task<string> UploadImage(ImageData image)
    {
        if (image.ImageStream is null) throw new InvalidOperationException("No se recibió el contenido de la imagen.");

        var extension = Path.GetExtension(image.Nombre ?? string.Empty).ToLowerInvariant();
        if (!ImageExtensions.Contains(extension)) throw new InvalidOperationException("La imagen debe ser JPG, PNG o WEBP.");

        var now = DateTime.UtcNow;
        var relativePath = Path.Combine("caja-chica", now.ToString("yyyy"), now.ToString("MM"), $"{Guid.NewGuid():N}{extension}");
        var fullPath = Path.Combine(GetRootPath(), relativePath);
        Directory.CreateDirectory(Path.GetDirectoryName(fullPath)!);

        await using var target = new FileStream(fullPath, FileMode.CreateNew, FileAccess.Write, FileShare.None);
        await image.ImageStream.CopyToAsync(target);
        return $"{GetRequestPath()}/{relativePath.Replace(Path.DirectorySeparatorChar, '/')}";
    }

    public bool DeleteImage(string? value)
    {
        if (!TryGetLocalPath(value, out var fullPath)) return false;
        if (File.Exists(fullPath)) File.Delete(fullPath);
        return true;
    }

    private string GetRootPath()
    {
        if (string.IsNullOrWhiteSpace(_settings.RootPath)) throw new InvalidOperationException("Configure LocalMedia:RootPath.");
        return Path.GetFullPath(_settings.RootPath);
    }

    private string GetRequestPath()
    {
        var path = (_settings.RequestPath ?? string.Empty).Trim().Trim('/');
        if (string.IsNullOrWhiteSpace(path)) throw new InvalidOperationException("Configure LocalMedia:RequestPath.");
        return $"/{path}";
    }

    private bool TryGetLocalPath(string? value, out string fullPath)
    {
        fullPath = string.Empty;
        if (string.IsNullOrWhiteSpace(value)) return false;

        var requestPath = GetRequestPath();
        var path = value.Trim();
        if (Uri.TryCreate(path, UriKind.Absolute, out var uri)) path = uri.AbsolutePath;
        if (!path.StartsWith($"{requestPath}/caja-chica/", StringComparison.OrdinalIgnoreCase)) return false;

        var root = GetRootPath();
        var relativePath = Uri.UnescapeDataString(path[(requestPath.Length + 1)..]).Replace('/', Path.DirectorySeparatorChar);
        var candidate = Path.GetFullPath(Path.Combine(root, relativePath));
        var rootPrefix = root.EndsWith(Path.DirectorySeparatorChar) ? root : root + Path.DirectorySeparatorChar;
        if (!candidate.StartsWith(rootPrefix, StringComparison.OrdinalIgnoreCase)) return false;

        fullPath = candidate;
        return true;
    }
}

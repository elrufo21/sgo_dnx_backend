using Ecommerce.Application.Models.ImageManagement;
using Microsoft.Extensions.Options;

namespace Ecommerce.Infrastructure.ImageLocal;

public sealed class LocalCpeStorageService
{
    private readonly LocalMediaSettings _settings;
    public LocalCpeStorageService(IOptions<LocalMediaSettings> settings) => _settings = settings.Value;

    private string Prefix => $"/{_settings.RequestPath.Trim().Trim('/')}/cpe/";
    private string Root => Path.GetFullPath(Path.Combine(_settings.RootPath, "cpe"));

    public async Task<string> SaveAsync(Stream source, string fileName, CancellationToken cancellationToken)
    {
        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        if (extension is not ".xml" and not ".zip") throw new InvalidOperationException("Archivo CPE inválido.");
        var name = $"{Guid.NewGuid():N}{extension}";
        Directory.CreateDirectory(Root);
        var path = Path.Combine(Root, name);
        try
        {
            await using var target = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None);
            await source.CopyToAsync(target, cancellationToken);
        }
        catch
        {
            if (File.Exists(path)) File.Delete(path);
            throw;
        }
        return Prefix + name;
    }

    public bool TryResolve(string value, out string path)
    {
        path = string.Empty;
        if (!value.StartsWith(Prefix, StringComparison.OrdinalIgnoreCase)) return false;
        var name = value[Prefix.Length..];
        if (name.Length != 36) return false;
        if (!Guid.TryParseExact(Path.GetFileNameWithoutExtension(name), "N", out _)) return false;
        var extension = Path.GetExtension(name);
        if (!extension.Equals(".xml", StringComparison.OrdinalIgnoreCase) && !extension.Equals(".zip", StringComparison.OrdinalIgnoreCase)) return false;
        path = Path.Combine(Root, name);
        return true;
    }
}

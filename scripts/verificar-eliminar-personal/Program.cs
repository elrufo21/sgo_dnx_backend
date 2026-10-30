using Ecommerce.Api.Controllers;
using Ecommerce.Application.Contracts.Infrastructure;
using Ecommerce.Application.Contracts.Personales;
using Ecommerce.Application.Models.ImageManagement;
using Ecommerce.Domain;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging.Abstractions;

foreach (var (databaseResult, hasImage, imageFails) in new[] { (false, true, false), (true, true, false), (true, true, true), (true, false, false) })
{
    var personal = new FakePersonal { Result = databaseResult, HasImage = hasImage };
    var images = new FakeImages { Fail = imageFails, Personal = personal };
    var controller = new PersonalController(personal, images, NullLogger<PersonalController>.Instance);
    var response = await controller.EliminarMaintenancePersonal(1, CancellationToken.None) as OkObjectResult;
    if (response?.Value is not bool result || result != databaseResult) throw new Exception("Resultado incorrecto.");
    if (images.Called != (databaseResult && hasImage)) throw new Exception("Limpieza de imagen incorrecta.");
}
var failingDatabase = new FakePersonal { HasImage = true, Fail = true };
var retainedImage = new FakeImages { Personal = failingDatabase };
try
{
    await new PersonalController(failingDatabase, retainedImage, NullLogger<PersonalController>.Instance).EliminarMaintenancePersonal(1, CancellationToken.None);
    throw new Exception("Se ocultó el error de la base.");
}
catch (InvalidOperationException) { }
if (retainedImage.Called) throw new Exception("Se eliminó la imagen pese al error de la base.");
Console.WriteLine("Eliminación simulada: éxito, rechazo, sin imagen y fallo de limpieza verificados.");

sealed class FakePersonal : IPersonal
{
    public bool Result { get; init; }
    public bool HasImage { get; init; }
    public bool Fail { get; init; }
    public bool Completed { get; private set; }
    public Task<Personal?> ObtenerPorIdAsync(long id, CancellationToken cancellationToken = default) => Task.FromResult<Personal?>(new Personal { PersonalImagen = HasImage ? "https://example.test/image.jpg" : null });
    public Task<bool> EliminarMantenimientoAsync(long id, CancellationToken cancellationToken = default) { if (Fail) throw new InvalidOperationException("Fallo simulado de base."); Completed = true; return Task.FromResult(Result); }
    public Task<string> InsertarAsync(Personal personal, CancellationToken cancellationToken = default) => throw new NotSupportedException();
    public Task<bool> EliminarAsync(long id, CancellationToken cancellationToken = default) => throw new NotSupportedException();
    public Task<IReadOnlyList<Personal>> ListarAsync(string? estado = "ACTIVO", int page = 1, int pageSize = 50, CancellationToken cancellationToken = default) => throw new NotSupportedException();
    public Task<string> InsertarMantenimientoAsync(Personal personal, byte[]? huella = null, CancellationToken cancellationToken = default) => throw new NotSupportedException();
    public Task<IReadOnlyList<Personal>> ListarMantenimientoAsync(string? estado = "ACTIVO", int page = 1, int pageSize = 50, CancellationToken cancellationToken = default) => throw new NotSupportedException();
}

sealed class FakeImages : IManageImageService
{
    public required FakePersonal Personal { get; init; }
    public bool Fail { get; init; }
    public bool Called { get; private set; }
    public Task DeleteImage(string? publicIdOrUrl)
    {
        if (!Personal.Completed) throw new Exception("Imagen eliminada antes de confirmar la base.");
        Called = true;
        if (Fail) throw new InvalidOperationException("Fallo simulado de almacenamiento.");
        return Task.CompletedTask;
    }
    public Task<ImageResponse> UploadImage(ImageData imageStream) => throw new NotSupportedException();
    public Task<ImageResponse> UploadFile(ImageData fileStream, string? folder = null) => throw new NotSupportedException();
}

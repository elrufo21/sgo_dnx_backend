using Ecommerce.Application.Models.ImageManagement;

namespace Ecommerce.Application.Contracts.Infrastructure;

public interface IManageImageService
{

    Task<ImageResponse> UploadImage(ImageData imageStream);
    Task<ImageResponse> UploadFile(ImageData fileStream, string? folder = null);
    Task DeleteImage(string? publicIdOrUrl);
}

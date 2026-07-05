namespace Ecommerce.Application.Models.Email;

public class EmailSettings
{
    public string? Email { get; set; }
    public string? Key { get; set; }
    public string? BaseUrlClient { get; set; }
    public string? Host { get; set; }
    public int? Port { get; set; }
    public bool? EnableSsl { get; set; }
    public string? DisplayName { get; set; }
}

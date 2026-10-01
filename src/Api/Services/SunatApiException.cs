using System.Net;

namespace Ecommerce.Api.Services;

public class SunatApiException : Exception
{
    public SunatApiException(
        string message,
        HttpStatusCode statusCode,
        string responseBody,
        string? requestUrl = null,
        object? debug = null)
        : base(message)
    {
        StatusCode = statusCode;
        ResponseBody = responseBody;
        RequestUrl = requestUrl;
        Debug = debug;
    }

    public HttpStatusCode StatusCode { get; }
    public string ResponseBody { get; }
    public string? RequestUrl { get; }
    public object? Debug { get; }
}


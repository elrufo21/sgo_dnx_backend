namespace Ecommerce.Api.Interfaces;

public interface ISireService
{
    Task<string> GetAsync(string endpoint);
    Task<string> PostAsync(string endpoint, object body);
    Task<string> ObtenerComprasAsync(string periodo);
    Task<string> ObtenerVentasAsync(string periodo);
    Task<string> ObtenerPeriodosVentasAsync(string codLibro);
    Task<string> ConsultarTicketVentasAsync(string perIni, string perFin, string numTicket, int page, int perPage);
    Task<byte[]> DescargarArchivoVentasAsync(
        string nomArchivoReporte,
        string codTipoArchivoReporte,
        string codLibro,
        string? perTributario = null,
        string? codProceso = null,
        string? numTicket = null);
    Task<object> ObtenerRegistrosVentasAsync(
        string periodo,
        int maxIntentos,
        int segundosEspera,
        string? fecDocumentoDesde = null,
        string? fecDocumentoHasta = null,
        string? mtoTotalDesde = null,
        string? mtoTotalHasta = null,
        string? numRucAdquiriente = null,
        string? numCarSunat = null,
        string? codTipoCDP = null,
        string? codTipoInconsistencia = null);
}


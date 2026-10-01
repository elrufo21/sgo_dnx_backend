namespace Ecommerce.Api.Options;

public class SunatOptions
{
    public const string SectionName = "Sunat";

    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string Ruc { get; set; } = string.Empty;
    public string UsuarioSol { get; set; } = string.Empty;
    public string ClaveSol { get; set; } = string.Empty;
    public string SireBaseUrl { get; set; } = "https://api-sire.sunat.gob.pe";
    public string Scope { get; set; } = "https://api-sire.sunat.gob.pe";
    public string SeguridadBaseUrl { get; set; } = "https://api-seguridad.sunat.gob.pe";
    public string ComprobanteClientId { get; set; } = string.Empty;
    public string ComprobanteClientSecret { get; set; } = string.Empty;
    public string ComprobanteScope { get; set; } = "https://api.sunat.gob.pe/v1/contribuyente/contribuyentes";
    public string ComprobanteBaseUrl { get; set; } = "https://api.sunat.gob.pe";
    public string RceComprasEndpoint { get; set; } = "/v1/contribuyente/migeigv/libros/rce/propuesta/web/propuesta/{periodo}/exportacioncomprobantepropuesta?codTipoArchivo=0&codOrigenEnvio=2";
    public string RvieVentasEndpoint { get; set; } = "/v1/contribuyente/migeigv/libros/rvie/propuesta/web/propuesta/{periodo}/exportapropuesta?mtoTotalDesde=&mtoTotalHasta=&fecDocumentoDesde=&fecDocumentoHasta=&numRucAdquiriente=&numCarSunat=&codTipoCDP=&codTipoInconsistencia=&codTipoArchivo=0";
    public string RviePeriodosEndpoint { get; set; } = "/v1/contribuyente/migeigv/libros/rvierce/padron/web/omisos/{codLibro}/periodos";
    public string RvieTicketEndpoint { get; set; } = "/v1/contribuyente/migeigv/libros/rvierce/gestionprocesosmasivos/web/masivo/consultaestadotickets?perIni={perIni}&perFin={perFin}&page={page}&perPage={perPage}&numTicket={numTicket}";
    public string RvieArchivoEndpoint { get; set; } = "/v1/contribuyente/migeigv/libros/rvierce/gestionprocesosmasivos/web/masivo/archivoreporte?nomArchivoReporte={nomArchivoReporte}&codTipoArchivoReporte={codTipoArchivoReporte}&codLibro={codLibro}&perTributario={perTributario}&codProceso={codProceso}&numTicket={numTicket}";
    public bool IncludeSensitiveDebug { get; set; }
}


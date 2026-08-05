namespace Ecommerce.Domain;

public class Producto
{
    public long IdProducto { get; set; }
    public long? IdSubLinea { get; set; }
    public string? ProductoCodigo { get; set; }
    public string? ProductoNombre { get; set; }
    public string? ProductoUM { get; set; }
    public decimal? ProductoCosto { get; set; }
    public decimal? ProductoVenta { get; set; }
    public decimal? ProductoVentaB { get; set; }
    public decimal? ProductoCantidad { get; set; }
    public string? ProductoEstado { get; set; }
    public string? ProductoUsuario { get; set; }
    public DateTime? ProductoFecha { get; set; }
    public string? ProductoImagen { get; set; }
    public decimal? ValorCritico { get; set; }
    public string? AplicaINV { get; set; }
    public string? ProductoINV { get; set; }
    public string? ProductoMarca { get; set; }
    public decimal? ProductoTipoCambio { get; set; }
    public decimal? ProductoCostoDolar { get; set; }
    public long? AlmacenId { get; set; }
    public string? ProductoUbicacion { get; set; }
    public string? ProductoObs { get; set; }
    public decimal? ProductoPV { get; set; }
    public decimal? ProductoSV { get; set; }
    public decimal? ProductoxCaja { get; set; }
    public string? AplicaFB { get; set; }
    public string? DetalleUm { get; set; }
    public string? DetalleUM { get; set; }
    public string? UnidadMedidaDetalle { get; set; }
    public string? Data { get; set; }

}

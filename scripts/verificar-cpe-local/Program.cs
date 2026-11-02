using System.Text;
using Ecommerce.Application.Models.ImageManagement;
using Ecommerce.Infrastructure.ImageLocal;
using Microsoft.Extensions.Options;
using Ecommerce.Api.Controllers;
using System.Reflection;
using System.Collections;
using System.IO.Compression;
using System.Net;
using System.Net.Sockets;
using Ecommerce.Api.Legacy;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using BusinessEntities;

var root = Path.Combine(Path.GetTempPath(), "dnx-cpe-test-" + Guid.NewGuid().ToString("N"));
try
{
    var storage = new LocalCpeStorageService(Options.Create(new LocalMediaSettings { RootPath = root, RequestPath = "/media" }));
    var fakeGateway = new FakeCreditGateway();
    var notaController = new NotaController(null!, null!, null!, null!, null!, new ConfigurationBuilder().Build(), fakeGateway, storage, NullLogger<NotaController>.Instance);
    var validateSeries = typeof(NotaController).GetMethod("EsSerieNotaCreditoValida", BindingFlags.Static | BindingFlags.NonPublic)!;
    foreach (var value in new[] { "FB01", "FZ01" })
    {
        if (!(bool)validateSeries.Invoke(null, new object[] { value })!) throw new Exception("Serie rechazada: " + value);
        var requestNc = new EnviarFacturaRequest { NRO_COMPROBANTE = value + "-00000012" };
        var cpe = (CPE)typeof(NotaController).GetMethod("MapearNotaCreditoLegacy", BindingFlags.Static | BindingFlags.NonPublic)!.Invoke(null, new object[] { requestNc, 3, "" })!;
        if (cpe.NRO_COMPROBANTE != requestNc.NRO_COMPROBANTE) throw new Exception("La serie cambió al preparar el CPE.");
    }
    foreach (var value in new[] { "", "BN01", "FZ1", "FZ 1" })
        if ((bool)validateSeries.Invoke(null, new object[] { value })!) throw new Exception("Serie inválida aceptada: " + value);
    var withoutMachine = new EnviarFacturaRequest { TIPO_PROCESO = JsonSerializer.SerializeToElement(3), NRO_COMPROBANTE = "" };
    if (await notaController.EnviarNotaCreditoFacturaServicioOse(withoutMachine, CancellationToken.None) is not BadRequestObjectResult)
        throw new Exception("La nota de crédito de servicio no bloqueó la máquina ausente.");
    if (await notaController.EnviarNotaCreditoElectronica(withoutMachine, CancellationToken.None) is not BadRequestObjectResult)
        throw new Exception("La nota de crédito no bloqueó la máquina ausente.");
    if (fakeGateway.Calls != 0) throw new Exception("Se intentó enviar una nota sin máquina.");
    foreach (var file in new[] { "factura.XML", "R-factura.ZIP" })
    {
        var contents = Encoding.UTF8.GetBytes(file);
        var url = await storage.SaveAsync(new MemoryStream(contents), file, CancellationToken.None);
        if (!storage.TryResolve(url, out var path) || !File.ReadAllBytes(path).SequenceEqual(contents))
            throw new Exception("No se conservó el archivo " + file);
    }
    if (storage.TryResolve("/media/cpe/../secret.xml", out _) || storage.TryResolve("https://example.com/file.xml", out _))
        throw new Exception("Se aceptó una ruta externa o inválida.");
    try
    {
        await storage.SaveAsync(new MemoryStream(), "archivo.exe", CancellationToken.None);
        throw new Exception("Se aceptó una extensión no permitida.");
    }
    catch (InvalidOperationException) { }
    var xml = await storage.SaveAsync(new MemoryStream(Encoding.UTF8.GetBytes("xml")), "factura.xml", CancellationToken.None);
    var cdr = await storage.SaveAsync(new MemoryStream(Encoding.UTF8.GetBytes("cdr")), "cdr.xml", CancellationToken.None);
    var controller = new CorreoController(null!, storage);
    var request = new EnviarCorreoComprobanteRequest { Para = "test@example.com", Asunto = "Factura", XmlUrl = xml, CdrUrl = cdr };
    var flags = BindingFlags.Instance | BindingFlags.NonPublic;
    var errors = (List<string>)typeof(CorreoController).GetMethod("ValidarRequest", flags)!.Invoke(controller, new object[] { request })!;
    if (errors.Count != 0) throw new Exception("El correo rechazó las rutas locales: " + string.Join(", ", errors));
    var task = (Task)typeof(CorreoController).GetMethod("DescargarAdjuntosUrlAsync", flags)!.Invoke(controller, new object[] { request, CancellationToken.None })!;
    await task;
    var attachments = (IEnumerable)task.GetType().GetProperty("Result")!.GetValue(task)!;
    var contentsRead = new List<string>();
    foreach (var attachment in attachments)
    {
        using var stream = (Stream)attachment!.GetType().GetProperty("Stream")!.GetValue(attachment)!;
        using var reader = new StreamReader(stream);
        contentsRead.Add(await reader.ReadToEndAsync());
    }
    if (!contentsRead.SequenceEqual(new[] { "xml", "cdr" })) throw new Exception("El correo no leyó ambos adjuntos locales.");
    var expectedXml = "<?xml version=\"1.0\"?><ApplicationResponse><DocumentReference><ID>F001-00000012</ID></DocumentReference></ApplicationResponse>";
    using var zipData = new MemoryStream();
    using (var zip = new ZipArchive(zipData, ZipArchiveMode.Create, true))
    using (var writer = new StreamWriter(zip.CreateEntry("R-factura.xml").Open())) writer.Write(expectedXml);
    var soap = $"<Envelope><Body><statusCode>0</statusCode><content>{Convert.ToBase64String(zipData.ToArray())}</content></Body></Envelope>";
    var socket = new TcpListener(IPAddress.Loopback, 0);
    socket.Start();
    var port = ((IPEndPoint)socket.LocalEndpoint).Port;
    socket.Stop();
    using var listener = new HttpListener();
    listener.Prefixes.Add($"http://127.0.0.1:{port}/");
    listener.Start();
    var originalUrl = Environment.GetEnvironmentVariable("CPE_WS_URL");
    try
    {
        Environment.SetEnvironmentVariable("CPE_WS_URL", $"http://127.0.0.1:{port}/");
        var server = Task.Run(async () =>
        {
            for (var i = 0; i < 4; i++)
            {
                var context = await listener.GetContextAsync();
                if (context.Request.Headers["SOAPAction"]?.Trim('"') != "http://service.sunat.gob.pe/getStatusCdr") throw new Exception("Falta SOAPAction requerido por Nubefact.");
                using var input = new StreamReader(context.Request.InputStream);
                var requestXml = await input.ReadToEndAsync();
                if (!requestXml.Contains("getStatusCdr") || !requestXml.Contains("F001")) throw new Exception("Solicitud OSE inválida.");
                if (i == 3) context.Response.StatusCode = 500;
                var response = Encoding.UTF8.GetBytes(i == 3 ? "<Envelope><Fault><faultcode>Client.0109</faultcode><faultstring>Error CLAVE</faultstring></Fault></Envelope>" : i == 2 ? "<Envelope><statusCode>99</statusCode></Envelope>" : soap);
                await context.Response.OutputStream.WriteAsync(response);
                context.Response.Close();
            }
        });
        var gateway = new CpeGateway(Options.Create(new CpePruebasSettings()), NullLogger<CpeGateway>.Instance);
        var recovered = await gateway.ConsultarCdrAsync("20123456789", "USUARIO", "CLAVE", 1, "F001", "12", CancellationToken.None);
        if (Encoding.UTF8.GetString(recovered).TrimStart('\uFEFF') != expectedXml) throw new Exception("El XML recuperado no se preservó.");
        try
        {
            await gateway.ConsultarCdrAsync("20123456789", "USUARIO", "CLAVE", 1, "F001", "13", CancellationToken.None);
            throw new Exception("Se aceptó el CDR de otra factura.");
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("otro comprobante")) { }
        try
        {
            await gateway.ConsultarCdrAsync("20123456789", "USUARIO", "CLAVE", 1, "F001", "12", CancellationToken.None);
            throw new Exception("Se aceptó una respuesta sin CDR.");
        }
        catch (CdrConsultaException ex) when (ex.Message.Contains("99")) { }
        try
        {
            await gateway.ConsultarCdrAsync("20123456789", "USUARIO", "CLAVE", 1, "F001", "12", CancellationToken.None);
            throw new Exception("Se aceptó un error SOAP.");
        }
        catch (CdrConsultaException ex) when (ex.Message.Contains("Client.0109") && !ex.Message.Contains("CLAVE")) { }
        await server;
    }
    finally { Environment.SetEnvironmentVariable("CPE_WS_URL", originalUrl); }
    Console.WriteLine("Guardado, adjuntos y consulta OSE simulada con validación de CDR: OK");
}
finally
{
    if (Directory.Exists(root)) Directory.Delete(root, true);
}

sealed class FakeCreditGateway : ICpeGateway
{
    public int Calls { get; private set; }
    public Dictionary<string, string> Envio(CPE cpe) { Calls++; throw new Exception("No debe enviarse un CPE."); }
    public Dictionary<string, string> EnvioResumen(CPE_RESUMEN_BOLETA resumen) => throw new NotSupportedException();
    public Dictionary<string, string> EnvioBaja(CPE_BAJA baja) => throw new NotSupportedException();
    public Dictionary<string, string> ConsultaTicket(CONSULTA_TICKET consultaTicket) => throw new NotSupportedException();
    public Task<byte[]> ConsultarCdrAsync(string ruc, string usuarioSol, string claveSol, int tipoProceso, string serie, string numero, CancellationToken cancellationToken) => throw new NotSupportedException();
}

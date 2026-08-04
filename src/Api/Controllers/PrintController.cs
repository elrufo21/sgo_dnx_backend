using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/print")]
public class PrintController : ControllerBase
{
    [HttpPost("pdf")]
    public async Task<IActionResult> PrintPdf(IFormFile file)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { ok = false, message = "No se recibio el PDF" });
        }

        const string printerName = "EPSON TM-T(203dpi) Receipt";
        const string sumatraPath = @"C:\app\SumatraPDF\SumatraPDF.exe";
        var tempFolder = Path.Combine(Path.GetTempPath(), "PrintTemp");
        Directory.CreateDirectory(tempFolder);

        var tempFile = Path.Combine(tempFolder, $"{Guid.NewGuid()}.pdf");

        try
        {
            await using (var stream = System.IO.File.Create(tempFile))
            {
                await file.CopyToAsync(stream);
            }

            var psi = new ProcessStartInfo
            {
                FileName = sumatraPath,
                Arguments = $"-print-to \"{printerName}\" -print-settings \"noscale,portrait\" -silent \"{tempFile}\"",
                CreateNoWindow = true,
                UseShellExecute = false,
                WindowStyle = ProcessWindowStyle.Hidden
            };

            using var process = Process.Start(psi);
            if (process == null)
            {
                throw new InvalidOperationException("No se pudo iniciar SumatraPDF.");
            }

            if (!process.WaitForExit(15000))
            {
                process.Kill();
                throw new TimeoutException("SumatraPDF demoro demasiado en imprimir.");
            }

            if (process.ExitCode != 0)
            {
                throw new InvalidOperationException($"SumatraPDF termino con codigo {process.ExitCode}.");
            }

            return Ok(new { ok = true, message = "PDF enviado a imprimir" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                ok = false,
                message = "Error al imprimir PDF",
                error = ex.Message
            });
        }
        finally
        {
            try
            {
                if (System.IO.File.Exists(tempFile))
                {
                    System.IO.File.Delete(tempFile);
                }
            }
            catch
            {
            }
        }
    }
}

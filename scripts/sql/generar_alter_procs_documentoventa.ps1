$p = 'scripts/sql/bdactual.sql'
$out = 'scripts/sql/ALTER_PROCEDURES_DOCUMENTOVENTA_PRODUCCION.sql'
$lines = Get-Content $p

function Get-ProcText($name) {
    $m = $lines | Select-String -Pattern "^(create|CREATE)\s+.*procedure\s+\[dbo\]\.\[$name\]" | Select-Object -First 1
    if (-not $m) { throw "No encontrado: $name" }
    $start = $m.LineNumber
    $goRel = $lines[($start)..($lines.Count - 1)] | Select-String -Pattern '^GO$' | Select-Object -First 1
    $end = $start + $goRel.LineNumber - 1
    $text = ($lines[($start - 1)..($end - 1)] -join "`r`n")
    $text = $text -replace "(?im)^create\s+.*procedure\s+\[dbo\]\.\[$name\]", "ALTER PROCEDURE [dbo].[$name]"
    return $text
}

function Replace-Block($text, $startPattern, $endPattern, $replacement) {
    $pattern = "(?s)$startPattern.*?$endPattern"
    return [regex]::Replace($text, $pattern, $replacement, 1)
}

$factReplacement = @'
INSERT INTO DocumentoVenta
(
    CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId, DocuRegistro,
    DocuEmision, DocuCondicion, DocuLetras, DocuSubTotal, DocuIgv, DocuTotal,
    DocuSaldo, DocuUsuario, DocuEstado, DocuSerie, TipoCodigo, DocuAdicional,
    DocuAsociado, DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, ICBPER,
    CodigoSunat, MensajeSunat, DocuGravada, DocuDescuento, EnvioCorreo,
    FormaPago, EntidadBancaria, NroOperacion, Efectivo, Deposito,
    ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
    DocuPdfUrl, DocuXmlUrl, DocuCdrUrl
)
VALUES
(
    @CompaniaId, @NotaId, @DocuDocumento, @DocuNumero,
    @ClienteId, GETDATE(), @DocuEmision, 'ALCONTADO', @Letras,
    @DocuSubTotal, @DocuIgv, @DocuTotal, 0,
    @DocuUsuario, 'EMITIDO', @DocuSerie, @TipoCodigo, @DocuAdicional,
    @DocuAsociado, @DocuConcepto, '', @DocuHASH, @EstadoSunat, @ICBPER,
    @CodigoSunat, @MensajeSunat, @DocuGravada, @DocuDescuento, '', @NotaFormaPago,
    @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
)
'@

$rechReplacement = @'
INSERT INTO DocumentoVenta
(
    CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId, DocuRegistro,
    DocuEmision, DocuCondicion, DocuLetras, DocuSubTotal, DocuIgv, DocuTotal,
    DocuSaldo, DocuUsuario, DocuEstado, DocuSerie, TipoCodigo, DocuAdicional,
    DocuAsociado, DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, ICBPER,
    CodigoSunat, MensajeSunat, DocuGravada, DocuDescuento, EnvioCorreo,
    FormaPago, EntidadBancaria, NroOperacion, Efectivo, Deposito,
    ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
    DocuPdfUrl, DocuXmlUrl, DocuCdrUrl
)
VALUES
(
    @CompaniaId, @NotaId, @DocuDocumento, @DocuNumero,
    @ClienteId, GETDATE(), @DocuEmision, 'ALCONTADO', 'CERO CON 00/100 SOLES',
    0, 0, 0, 0,
    @DocuUsuario, 'RECHAZADO', @DocuSerie, @TipoCodigo, 0,
    @DocuAsociado, @DocuConcepto, '', @DocuHASH, 'RECHAZADO', 0,
    @CodigoSunat, @MensajeSunat, 0, 0, '', 'EFECTIVO', '', '', 0, 0,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
)
'@

$ncReplacement = @'
INSERT INTO DocumentoVenta
(
    CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId, DocuRegistro,
    DocuEmision, DocuCondicion, DocuLetras, DocuSubTotal, DocuIgv, DocuTotal,
    DocuSaldo, DocuUsuario, DocuEstado, DocuSerie, TipoCodigo, DocuAdicional,
    DocuAsociado, DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, ICBPER,
    CodigoSunat, MensajeSunat, DocuGravada, DocuDescuento, EnvioCorreo,
    FormaPago, EntidadBancaria, NroOperacion, Efectivo, Deposito,
    ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
    DocuPdfUrl, DocuXmlUrl, DocuCdrUrl
)
VALUES
(
    @CompaniaId, @NotaId, @DocuDocumento, @DocuNumero,
    @ClienteId, GETDATE(), @DocuEmision, 'ALCONTADO', @Letras,
    @DocuSubTotal, @DocuIgv, @DocuTotal, 0,
    @DocuUsuario, 'EMITIDO', @DocuSerie, @TipoCodigo, @DocuAdicional,
    @DocuAsociado, @DocuConcepto, @NroReferencia, @DocuHASH, @EstadoSunat, @ICBPER,
    @CodigoSunat, @MensajeSunat, @DocuGravada, @DocuDescuento, '', @FormaPago,
    @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
)
'@

$fact = Get-ProcText 'uspinsertaFactura'
$fact = Replace-Block $fact 'insert\s+into\s+DocumentoVenta\s+values\(@CompaniaId,@NotaId,@DocuDocumento,@DocuNumero,' '@ClienteRazon,@ClienteRuc,@ClienteDni,@DireccionFiscal\)' $factReplacement

$rech = Get-ProcText 'uspinsertaRechazo'
$rech = Replace-Block $rech 'insert\s+into\s+DocumentoVenta\s+values\(@CompaniaId,@NotaId,@DocuDocumento,@DocuNumero,' '@ClienteRazon,@ClienteRuc,@ClienteDni,@DireccionFiscal\)' $rechReplacement

$nc = Get-ProcText 'uspinsertarNC'
$nc = Replace-Block $nc 'insert\s+into\s+DocumentoVenta\s+values\(@CompaniaId,@NotaId,@DocuDocumento,@DocuNumero,' '@ClienteRazon,@ClienteRuc,@ClienteDni,@DireccionFiscal\)' $ncReplacement

$notab = Get-ProcText 'uspinsertarNotaB'
$notab = $notab -replace 'ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal\r?\n\s*\)', "ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,`r`n            DocuPdfUrl, DocuXmlUrl, DocuCdrUrl`r`n        )"
$notab = $notab -replace '@ClienteRazon,@ClienteRuc,@ClienteDni,@DireccionFiscal\)', "@ClienteRazon,@ClienteRuc,@ClienteDni,@DireccionFiscal,`r`n         '', '', '')"

$header = @'
/*
Listo para copiar/pegar en produccion.
No guarda XML/CDR/PDF en estos flujos: DocuPdfUrl/DocuXmlUrl/DocuCdrUrl = ''.
Factura por servicio NO va aqui: ese flujo guarda XML/CDR desde backend.
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
'@

$header = $header + "`r`n"

$content = $header + $fact + "`r`nGO`r`n`r`n" +
    $header + $rech + "`r`nGO`r`n`r`n" +
    $header + $nc + "`r`nGO`r`n`r`n" +
    $header + $notab + "`r`nGO`r`n"

Set-Content -Path $out -Value $content -Encoding UTF8
Write-Output $out

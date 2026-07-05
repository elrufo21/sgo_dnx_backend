/*
Procedimientos a cambiar por nuevas columnas en DocumentoVenta:

1. dbo.uspinsertarNotaB      -- crearOrden: PROFORMA V / FACTURA / BOLETA
2. dbo.uspinsertaFactura     -- factura flujo antiguo
3. dbo.uspinsertaRechazo     -- rechazo SUNAT/OSE flujo antiguo
4. dbo.uspinsertarNC         -- nota de credito flujo antiguo

Motivo:
No usar:
    INSERT INTO DocumentoVenta VALUES (...)

Usar siempre:
    INSERT INTO DocumentoVenta (columnas...) VALUES (valores...)

En estos flujos NO se guarda XML/CDR/PDF. Por eso:
    DocuPdfUrl = ''
    DocuXmlUrl = ''
    DocuCdrUrl = ''

Factura por servicio NO va aqui. Ese flujo ya lo maneja backend y si guarda XML/CDR.
*/

/* ============================================================
   dbo.uspinsertaFactura
   Reemplazar su INSERT INTO DocumentoVenta VALUES (...) por:
   ============================================================ */

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
    @CompaniaId, @NotaId, @DocuDocumento, @DocuNumero, @ClienteId, GETDATE(),
    @DocuEmision, 'ALCONTADO', @Letras, @DocuSubTotal, @DocuIgv, @DocuTotal,
    0, @DocuUsuario, 'EMITIDO', @DocuSerie, @TipoCodigo, @DocuAdicional,
    @DocuAsociado, @DocuConcepto, '', @DocuHASH, @EstadoSunat, @ICBPER,
    @CodigoSunat, @MensajeSunat, @DocuGravada, @DocuDescuento, '',
    @NotaFormaPago, @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
);

/* ============================================================
   dbo.uspinsertaRechazo
   Reemplazar su INSERT INTO DocumentoVenta VALUES (...) por:
   ============================================================ */

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
    @CompaniaId, @NotaId, @DocuDocumento, @DocuNumero, @ClienteId, GETDATE(),
    @DocuEmision, 'ALCONTADO', 'CERO CON 00/100 SOLES', 0, 0, 0,
    0, @DocuUsuario, 'RECHAZADO', @DocuSerie, @TipoCodigo, 0,
    @DocuAsociado, @DocuConcepto, '', @DocuHASH, 'RECHAZADO', 0,
    @CodigoSunat, @MensajeSunat, 0, 0, '',
    'EFECTIVO', '', '', 0, 0,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
);

/* ============================================================
   dbo.uspinsertarNC
   Reemplazar su INSERT INTO DocumentoVenta VALUES (...) por:
   ============================================================ */

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
    @CompaniaId, @NotaId, @DocuDocumento, @DocuNumero, @ClienteId, GETDATE(),
    @DocuEmision, 'ALCONTADO', @Letras, @DocuSubTotal, @DocuIgv, @DocuTotal,
    0, @DocuUsuario, 'EMITIDO', @DocuSerie, @TipoCodigo, @DocuAdicional,
    @DocuAsociado, @DocuConcepto, @NroReferencia, @DocuHASH, @EstadoSunat, @ICBPER,
    @CodigoSunat, @MensajeSunat, @DocuGravada, @DocuDescuento, '',
    @FormaPago, @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
);

/* ============================================================
   dbo.uspinsertarNotaB
   Tiene 3 INSERT a DocumentoVenta: PROFORMA V, FACTURA, BOLETA.
   En cada INSERT agregar columnas:
       DocuPdfUrl, DocuXmlUrl, DocuCdrUrl
   y valores:
       '', '', ''
   ============================================================ */

/* dbo.uspinsertarNotaB - PROFORMA V */
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
    @CompaniaId, @NotaId, 'PROFORMA V', @cod, @ClienteId, GETDATE(),
    GETDATE(), @NotaCondicion, @Letra, @DocuSubtotal, @DocuIGV, @NotaPagar,
    0, @NotaUsuario, 'EMITIDO', @Serie, '00', @NotaMovilidad,
    '', 'VENTA', '', @DocuHash, 'ENVIADO', @ICBPER,
    '', '', @DocuGravada, @DocuDescuento, '',
    @NotaFormaPago, @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
);

/* dbo.uspinsertarNotaB - FACTURA */
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
    @CompaniaId, @NotaId, 'FACTURA', @cod, @ClienteId, GETDATE(),
    GETDATE(), @NotaCondicion, @Letra, @DocuSubtotal, @DocuIGV, @NotaPagar,
    0, @NotaUsuario, 'EMITIDO', @Serie, '01', @DocuAdicional,
    '', 'VENTA', '', @DocuHash, @EstadoSunat, @ICBPER,
    '', '', @DocuGravada, @DocuDescuento, '',
    @NotaFormaPago, @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
);

/* dbo.uspinsertarNotaB - BOLETA */
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
    @CompaniaId, @NotaId, 'BOLETA', @cod, @ClienteId, GETDATE(),
    GETDATE(), @NotaCondicion, @Letra, @DocuSubtotal, @DocuIGV, @NotaPagar,
    0, @NotaUsuario, 'EMITIDO', @Serie, '03', @NotaMovilidad,
    '', 'VENTA', '', @DocuHash, @EstadoSunat, @ICBPER,
    '', '', @DocuGravada, @DocuDescuento, '',
    @NotaFormaPago, @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
);


using Ecommerce.Application.Contracts.Companias;
using Ecommerce.Domain;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Ecommerce.Infrastructure.Persistence.Repositories;

public class CompaniaRepository : ICompania
{
    private readonly string _connectionString;

    public CompaniaRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");
    }

    public async Task<bool> InsertarAsync(Compania compania, CancellationToken cancellationToken = default)
    {
        const string sql = @"INSERT INTO Compania (
                                CompaniaRazonSocial,
                                CompaniaRUC,
                                CompaniaDireccion,
                                CompaniaTelefono,
                                CompaniaEmail,
                                CompaniaIniFecha,
                                CompaniaComercial,
                                CompaniaUserSecun,
                                ComapaniaPWD,
                                CompaniaPFX,
                                CompaniaClave,
                                CompaniaNomUBG,
                                CompaniaCodigoUBG,
                                CompaniaDistrito,
                                CompaniaDirecSunat,
                                ICBPER,
                                TokenApi,
                                ClienIdToken,
                                RenovacionOSE,
                                RenovacionFirma,
                                RenovacionSome)
                              OUTPUT INSERTED.CompaniaId
                              VALUES (
                                @CompaniaRazonSocial,
                                @CompaniaRUC,
                                @CompaniaDireccion,
                                @CompaniaTelefono,
                                @CompaniaEmail,
                                @CompaniaIniFecha,
                                @CompaniaComercial,
                                @CompaniaUserSecun,
                                @ComapaniaPWD,
                                @CompaniaPFX,
                                @CompaniaClave,
                                @CompaniaNomUBG,
                                @CompaniaCodigoUBG,
                                @CompaniaDistrito,
                                @CompaniaDirecSunat,
                                @ICBPER,
                                @TokenApi,
                                @ClienIdToken,
                                @RenovacionOSE,
                                @RenovacionFirma,
                                @RenovacionSome)";

        await using var con = new SqlConnection(_connectionString);
        await con.OpenAsync(cancellationToken);
        await using var transaction = (SqlTransaction)await con.BeginTransactionAsync(cancellationToken);
        await using var cmd = new SqlCommand(sql, con, transaction);
        AddParameters(cmd, compania);
        var id = Convert.ToInt32(await cmd.ExecuteScalarAsync(cancellationToken));
        await GuardarConfiguracionAsync(con, transaction, id, compania, cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return id > 0;
    }

    public async Task<bool> EditarAsync(int id, Compania compania, CancellationToken cancellationToken = default)
    {
        const string sql = @"UPDATE Compania SET
                                CompaniaRazonSocial = @CompaniaRazonSocial,
                                CompaniaRUC = @CompaniaRUC,
                                CompaniaDireccion = @CompaniaDireccion,
                                CompaniaTelefono = @CompaniaTelefono,
                                CompaniaEmail = @CompaniaEmail,
                                CompaniaIniFecha = @CompaniaIniFecha,
                                CompaniaComercial = @CompaniaComercial,
                                CompaniaUserSecun = @CompaniaUserSecun,
                                ComapaniaPWD = @ComapaniaPWD,
                                CompaniaPFX = @CompaniaPFX,
                                CompaniaClave = @CompaniaClave,
                                CompaniaNomUBG = @CompaniaNomUBG,
                                CompaniaCodigoUBG = @CompaniaCodigoUBG,
                                CompaniaDistrito = @CompaniaDistrito,
                                CompaniaDirecSunat = @CompaniaDirecSunat,
                                ICBPER = @ICBPER,
                                TokenApi = @TokenApi,
                                ClienIdToken = @ClienIdToken,
                                RenovacionOSE = @RenovacionOSE,
                                RenovacionFirma = @RenovacionFirma,
                                RenovacionSome = @RenovacionSome
                              WHERE CompaniaId = @Id";

        await using var con = new SqlConnection(_connectionString);
        await con.OpenAsync(cancellationToken);
        await using var transaction = (SqlTransaction)await con.BeginTransactionAsync(cancellationToken);
        await using var cmd = new SqlCommand(sql, con, transaction);
        cmd.Parameters.AddWithValue("@Id", id);
        AddParameters(cmd, compania);
        var rows = await cmd.ExecuteNonQueryAsync(cancellationToken);
        if (rows == 0)
        {
            await transaction.RollbackAsync(cancellationToken);
            return false;
        }

        await GuardarConfiguracionAsync(con, transaction, id, compania, cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return true;
    }

    public async Task<bool> ActualizarBoletaPorLoteAsync(int id, bool boletaPorLote, CancellationToken cancellationToken = default)
    {
        await using var con = new SqlConnection(_connectionString);
        await con.OpenAsync(cancellationToken);
        return await GuardarIndicadorAsync(con, null, id, "VENTAS", "BOLETA_POR_LOTE", 1, null, boletaPorLote ? 1 : 0, null, cancellationToken);
    }

    public async Task<bool> ActualizarFlagCapturaAsync(int id, bool flagCaptura, CancellationToken cancellationToken = default)
    {
        await using var con = new SqlConnection(_connectionString);
        await con.OpenAsync(cancellationToken);
        return await GuardarIndicadorAsync(con, null, id, "VENTAS", "CAPTURA_HTML", 1, null, flagCaptura ? 1 : 0, null, cancellationToken);
    }

    public async Task<bool> ActualizarConfiguracionCajaAsync(
        int id,
        bool flagCaja,
        string? correosAdmin,
        CancellationToken cancellationToken = default)
    {
        await using var con = new SqlConnection(_connectionString);
        await con.OpenAsync(cancellationToken);
        await using var transaction = (SqlTransaction)await con.BeginTransactionAsync(cancellationToken);
        var existe = await GuardarIndicadorAsync(con, transaction, id, "CAJA", "MULTIPLES_CAJAS", 1, null, flagCaja ? 1 : 0, null, cancellationToken);
        if (!existe)
        {
            await transaction.RollbackAsync(cancellationToken);
            return false;
        }

        await GuardarIndicadorAsync(con, transaction, id, "CORREO", "CORREOS_ADMIN", 3, correosAdmin?.Trim(), null, null, cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return true;
    }

    public async Task<bool> EliminarAsync(int id, CancellationToken cancellationToken = default)
    {
        const string sql = """
            DELETE FROM dbo.Indicador WHERE CompaniaId = @Id;
            DELETE FROM dbo.Compania WHERE CompaniaId = @Id;
            """;
        await using var con = new SqlConnection(_connectionString);
        await con.OpenAsync(cancellationToken);
        await using var transaction = (SqlTransaction)await con.BeginTransactionAsync(cancellationToken);
        await using var cmd = new SqlCommand(sql, con, transaction);
        cmd.Parameters.AddWithValue("@Id", id);
        var rows = await cmd.ExecuteNonQueryAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return rows > 0;
    }

    public async Task<IReadOnlyList<Compania>> ListarAsync(int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
    {
        (page, pageSize) = NormalizePagination(page, pageSize);
        const string sql = @";WITH Companias AS (
                             SELECT CompaniaId,
                                    CompaniaRazonSocial,
                                    CompaniaRUC,
                                    CompaniaDireccion,
                                    CompaniaTelefono,
                                    CompaniaEmail,
                                    CompaniaIniFecha,
                                    CompaniaComercial,
                                    CompaniaUserSecun,
                                    ComapaniaPWD,
                                    CompaniaPFX,
                                    CompaniaClave,
                                    CompaniaNomUBG,
                                    CompaniaCodigoUBG,
                                    CompaniaDistrito,
                                    CompaniaDirecSunat,
                                    ICBPER,
                                    TokenApi,
                                    ClienIdToken,
                                    RenovacionOSE,
                                    RenovacionFirma,
                                    RenovacionSome,
                                    Configuracion.FechaRenovacion,
                                    Configuracion.DescuentoMax,
                                    Configuracion.CorreoSGO,
                                    Configuracion.PasswordCorreo,
                                    Configuracion.CorreosAdmin,
                                    CAST(COALESCE(Configuracion.BoletaPorLote, 1) AS bit) AS BoletaPorLote,
                                    CAST(COALESCE(Configuracion.FlagCaptura, 0) AS bit) AS FlagCaptura,
                                    CAST(COALESCE(Configuracion.FlagCaja, 0) AS bit) AS FlagCaja,
                                    ROW_NUMBER() OVER (ORDER BY CompaniaId DESC) AS RowNum
                             FROM Compania
                             OUTER APPLY
                             (
                                 SELECT
                                     MAX(CASE WHEN Descripcion = 'FECHA_RENOVACION' THEN ValorTexto1 END) AS FechaRenovacion,
                                     MAX(CASE WHEN Descripcion = 'DESCUENTO_MAXIMO' THEN ValorDecimal END) AS DescuentoMax,
                                     MAX(CASE WHEN Descripcion = 'CORREO_SGO' THEN ValorTexto1 END) AS CorreoSGO,
                                     MAX(CASE WHEN Descripcion = 'PASSWORD_CORREO' THEN ValorTexto1 END) AS PasswordCorreo,
                                     MAX(CASE WHEN Descripcion = 'CORREOS_ADMIN' THEN ValorTexto1 END) AS CorreosAdmin,
                                     MAX(CASE WHEN Descripcion = 'BOLETA_POR_LOTE' THEN ValorNum END) AS BoletaPorLote,
                                     MAX(CASE WHEN Descripcion = 'CAPTURA_HTML' THEN ValorNum END) AS FlagCaptura,
                                     MAX(CASE WHEN Descripcion = 'MULTIPLES_CAJAS' THEN ValorNum END) AS FlagCaja
                                 FROM dbo.Indicador
                                 WHERE CompaniaId = Compania.CompaniaId
                             ) Configuracion
                             )
                             SELECT *
                             FROM Companias
                             WHERE RowNum BETWEEN @Start AND @End
                             ORDER BY RowNum;";

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddWithValue("@Start", ((page - 1) * pageSize) + 1);
        cmd.Parameters.AddWithValue("@End", page * pageSize);
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);

        var lista = new List<Compania>();
        while (await reader.ReadAsync(cancellationToken))
        {
            lista.Add(new Compania
            {
                CompaniaId = Convert.ToInt32(reader["CompaniaId"]),
                CompaniaRazonSocial = reader["CompaniaRazonSocial"].ToString(),
                CompaniaRUC = reader["CompaniaRUC"].ToString(),
                CompaniaDireccion = reader["CompaniaDireccion"].ToString(),
                CompaniaTelefono = reader["CompaniaTelefono"].ToString(),
                CompaniaEmail = reader["CompaniaEmail"].ToString(),
                CompaniaIniFecha = reader["CompaniaIniFecha"].ToString(),
                CompaniaComercial = reader["CompaniaComercial"].ToString(),
                CompaniaUserSecun = reader["CompaniaUserSecun"].ToString(),
                ComapaniaPWD = reader["ComapaniaPWD"].ToString(),
                CompaniaPFX = reader["CompaniaPFX"].ToString(),
                CompaniaClave = reader["CompaniaClave"].ToString(),
                CompaniaNomUBG = reader["CompaniaNomUBG"].ToString(),
                CompaniaCodigoUBG = reader["CompaniaCodigoUBG"].ToString(),
                CompaniaDistrito = reader["CompaniaDistrito"].ToString(),
                CompaniaDirecSunat = reader["CompaniaDirecSunat"].ToString(),
                ICBPER = reader["ICBPER"] == DBNull.Value ? null : Convert.ToDecimal(reader["ICBPER"]),
                TokenApi = reader["TokenApi"].ToString(),
                ClienIdToken = reader["ClienIdToken"].ToString(),
                FechaRenovacion = reader["FechaRenovacion"] == DBNull.Value ? null : Convert.ToDateTime(reader["FechaRenovacion"]),
                DescuentoMax = reader["DescuentoMax"] == DBNull.Value ? null : Convert.ToDecimal(reader["DescuentoMax"]),
                RenovacionOSE = reader["RenovacionOSE"] == DBNull.Value ? null : Convert.ToDateTime(reader["RenovacionOSE"]),
                RenovacionFirma = reader["RenovacionFirma"] == DBNull.Value ? null : Convert.ToDateTime(reader["RenovacionFirma"]),
                RenovacionSome = reader["RenovacionSome"] == DBNull.Value ? null : Convert.ToDateTime(reader["RenovacionSome"]),
                CorreoSGO = reader["CorreoSGO"].ToString(),
                PasswordCorreo = reader["PasswordCorreo"].ToString(),
                CorreosAdmin = reader["CorreosAdmin"].ToString(),
                BoletaPorLote = reader["BoletaPorLote"] != DBNull.Value && Convert.ToBoolean(reader["BoletaPorLote"]),
                FlagCaptura = reader["FlagCaptura"] != DBNull.Value && Convert.ToBoolean(reader["FlagCaptura"]),
                FlagCaja = reader["FlagCaja"] != DBNull.Value && Convert.ToBoolean(reader["FlagCaja"])
            });
        }

        return lista;
    }

    public async Task<IReadOnlyList<EGeneral>> ListarComboAsync(int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
    {
        (page, pageSize) = NormalizePagination(page, pageSize);
        const string sql = """
            ;WITH Companias AS (
                SELECT CompaniaId,
                       CompaniaRazonSocial,
                       ROW_NUMBER() OVER (ORDER BY CompaniaId DESC) AS RowNum
                FROM Compania
            )
            SELECT CompaniaId, CompaniaRazonSocial
            FROM Companias
            WHERE RowNum BETWEEN @Start AND @End
            ORDER BY RowNum;
            """;

        await using var con = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddWithValue("@Start", ((page - 1) * pageSize) + 1);
        cmd.Parameters.AddWithValue("@End", page * pageSize);
        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);

        var lista = new List<EGeneral>();
        while (await reader.ReadAsync(cancellationToken))
        {
            lista.Add(new EGeneral
            {
                Id = reader["CompaniaId"].ToString(),
                Nombre = reader["CompaniaRazonSocial"].ToString()
            });
        }

        return lista;
    }

    private static void AddParameters(SqlCommand cmd, Compania compania)
    {
        cmd.Parameters.AddWithValue("@CompaniaRazonSocial", (object?)compania.CompaniaRazonSocial ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaRUC", (object?)compania.CompaniaRUC ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaDireccion", (object?)compania.CompaniaDireccion ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaTelefono", (object?)compania.CompaniaTelefono ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaEmail", (object?)compania.CompaniaEmail ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaIniFecha", (object?)compania.CompaniaIniFecha ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaComercial", (object?)compania.CompaniaComercial ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaUserSecun", (object?)compania.CompaniaUserSecun ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@ComapaniaPWD", (object?)compania.ComapaniaPWD ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaPFX", (object?)compania.CompaniaPFX ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaClave", (object?)compania.CompaniaClave ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaNomUBG", (object?)compania.CompaniaNomUBG ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaCodigoUBG", (object?)compania.CompaniaCodigoUBG ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaDistrito", (object?)compania.CompaniaDistrito ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@CompaniaDirecSunat", (object?)compania.CompaniaDirecSunat ?? DBNull.Value);

        var icbperParam = cmd.Parameters.Add("@ICBPER", System.Data.SqlDbType.Decimal);
        icbperParam.Precision = 18;
        icbperParam.Scale = 2;
        icbperParam.Value = (object?)compania.ICBPER ?? DBNull.Value;

        cmd.Parameters.AddWithValue("@TokenApi", (object?)compania.TokenApi ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@ClienIdToken", (object?)compania.ClienIdToken ?? DBNull.Value);

        cmd.Parameters.AddWithValue("@RenovacionOSE", (object?)compania.RenovacionOSE ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@RenovacionFirma", (object?)compania.RenovacionFirma ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@RenovacionSome", (object?)compania.RenovacionSome ?? DBNull.Value);
    }

    private static async Task GuardarConfiguracionAsync(SqlConnection con, SqlTransaction transaction, int companiaId, Compania compania, CancellationToken cancellationToken)
    {
        await GuardarIndicadorAsync(con, transaction, companiaId, "CONFIGURACION", "FECHA_RENOVACION", 3, compania.FechaRenovacion?.ToString("yyyy-MM-dd"), null, null, cancellationToken);
        await GuardarIndicadorAsync(con, transaction, companiaId, "VENTAS", "DESCUENTO_MAXIMO", 2, null, null, compania.DescuentoMax, cancellationToken);
        await GuardarIndicadorAsync(con, transaction, companiaId, "CORREO", "CORREO_SGO", 3, compania.CorreoSGO?.Trim(), null, null, cancellationToken);
        await GuardarIndicadorAsync(con, transaction, companiaId, "CORREO", "PASSWORD_CORREO", 3, compania.PasswordCorreo, null, null, cancellationToken);
        await GuardarIndicadorAsync(con, transaction, companiaId, "CORREO", "CORREOS_ADMIN", 3, compania.CorreosAdmin?.Trim(), null, null, cancellationToken);
        await GuardarIndicadorAsync(con, transaction, companiaId, "VENTAS", "BOLETA_POR_LOTE", 1, null, compania.BoletaPorLote ? 1 : 0, null, cancellationToken);
        await GuardarIndicadorAsync(con, transaction, companiaId, "VENTAS", "CAPTURA_HTML", 1, null, compania.FlagCaptura ? 1 : 0, null, cancellationToken);
        await GuardarIndicadorAsync(con, transaction, companiaId, "CAJA", "MULTIPLES_CAJAS", 1, null, compania.FlagCaja ? 1 : 0, null, cancellationToken);
    }

    private static async Task<bool> GuardarIndicadorAsync(
        SqlConnection con,
        SqlTransaction? transaction,
        int companiaId,
        string area,
        string descripcion,
        int tipoIndicador,
        string? valorTexto,
        int? valorNum,
        decimal? valorDecimal,
        CancellationToken cancellationToken)
    {
        const string sql = """
            IF NOT EXISTS (SELECT 1 FROM dbo.Compania WHERE CompaniaId = @CompaniaId)
            BEGIN
                SELECT CAST(0 AS bit);
                RETURN;
            END;

            UPDATE dbo.Indicador
               SET Area = @Area,
                   TipoIndicador = @TipoIndicador,
                   ValorTexto1 = @ValorTexto1,
                   ValorNum = @ValorNum,
                   ValorDecimal = @ValorDecimal,
                   FechaActualizacion = SYSDATETIME()
             WHERE CompaniaId = @CompaniaId
               AND Descripcion = @Descripcion;

            IF @@ROWCOUNT = 0
                INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum, ValorDecimal)
                VALUES (@CompaniaId, @Area, @TipoIndicador, NULL, @Descripcion, @ValorTexto1, @ValorNum, @ValorDecimal);

            SELECT CAST(1 AS bit);
            """;

        await using var cmd = new SqlCommand(sql, con, transaction);
        cmd.Parameters.AddWithValue("@CompaniaId", companiaId);
        cmd.Parameters.AddWithValue("@Area", area);
        cmd.Parameters.AddWithValue("@Descripcion", descripcion);
        cmd.Parameters.AddWithValue("@TipoIndicador", tipoIndicador);
        cmd.Parameters.AddWithValue("@ValorTexto1", (object?)valorTexto ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@ValorNum", (object?)valorNum ?? DBNull.Value);
        var decimalParam = cmd.Parameters.Add("@ValorDecimal", System.Data.SqlDbType.Decimal);
        decimalParam.Precision = 18;
        decimalParam.Scale = 2;
        decimalParam.Value = (object?)valorDecimal ?? DBNull.Value;
        return Convert.ToBoolean(await cmd.ExecuteScalarAsync(cancellationToken));
    }

    private static (int page, int pageSize) NormalizePagination(int page, int pageSize)
    {
        var normalizedPage = page < 1 ? 1 : page;
        var normalizedPageSize = pageSize < 1 ? 1 : Math.Min(pageSize, 100);
        return (normalizedPage, normalizedPageSize);
    }
}

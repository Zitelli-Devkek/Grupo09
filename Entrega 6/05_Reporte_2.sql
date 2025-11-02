CREATE OR ALTER PROCEDURE rpt_Recaudacion_Mes_Departamento_XML
    @StartMonth CHAR(7),  -- 'YYYY-MM'
    @EndMonth   CHAR(7),
    @id_consorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH pagos_meses AS (
        SELECT p.id_pago,
               p.fecha,
               p.valor,
               uf.departamento,
               FORMAT(p.fecha,'yyyy-MM') AS mes,
               c.id_consorcio
        FROM Pago p
        LEFT JOIN Unidad_Funcional uf ON p.id_uf = uf.id_uf
        LEFT JOIN Consorcio c ON uf.id_consorcio = c.id_consorcio
        WHERE FORMAT(p.fecha,'yyyy-MM') BETWEEN @StartMonth AND @EndMonth
          AND (@id_consorcio IS NULL OR c.id_consorcio = @id_consorcio)
    )
    SELECT
        mes AS [@mes],
        (
            SELECT departamento AS [@departamento],
                   SUM(valor) AS [@total]
            FROM pagos_meses pm2
            WHERE pm2.mes = pm1.mes
            GROUP BY departamento
            FOR XML PATH('Departamento'), TYPE
        )
    FROM (SELECT DISTINCT mes FROM pagos_meses) pm1
    ORDER BY mes
    FOR XML PATH('Mes'), ROOT('RecaudacionPorMesYDepartamento');
END

CREATE OR ALTER PROCEDURE rpt_Recaudacion_Por_Procedencia_XML
    @StartDate DATE,
    @EndDate   DATE,
    @id_consorcio INT = NULL,
    @periodo VARCHAR(10) = 'month' -- 'month' or 'week'
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH pagos AS (
        SELECT p.id_pago, p.fecha, p.valor,
               ISNULL(ed.tipo_gasto,'SinClasificar') AS tipo_gasto,
               uf.id_consorcio,
               CASE WHEN @periodo = 'week' THEN CONCAT(DATEPART(YEAR,p.fecha),'-W',DATEPART(WEEK,p.fecha))
                    ELSE FORMAT(p.fecha,'yyyy-MM') END AS periodo_label
        FROM Pago p
        LEFT JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
        LEFT JOIN Unidad_Funcional uf ON p.id_uf = uf.id_uf
        WHERE p.fecha BETWEEN @StartDate AND @EndDate
          AND (@id_consorcio IS NULL OR uf.id_consorcio = @id_consorcio)
    )
    SELECT
        periodo_label AS [@periodo],
        (
            SELECT tipo_gasto AS [@procedencia],
                   SUM(valor) AS [@total]
            FROM pagos p2
            WHERE p2.periodo_label = p1.periodo_label
            GROUP BY tipo_gasto
            FOR XML PATH('Procedencia'), TYPE
        )
    FROM (SELECT DISTINCT periodo_label FROM pagos) p1
    ORDER BY periodo_label
    FOR XML PATH('Periodo'), ROOT('RecaudacionPorProcedencia');
END

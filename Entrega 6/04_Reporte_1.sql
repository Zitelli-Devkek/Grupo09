CREATE OR ALTER PROCEDURE rpt_FlujoCaja_Semanal
    @StartDate DATE,
    @EndDate   DATE,
    @id_consorcio INT = NULL  -- si NULL => todos
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH pagos_filtrados AS (
        SELECT p.id_pago,
               p.fecha,
               p.valor,
               ed.tipo_gasto,
               c.id_consorcio,
               DATEPART(YEAR, p.fecha) AS yr,
               DATEPART(WEEK, p.fecha) AS wk,
               -- week label
               CONCAT(DATEPART(YEAR, p.fecha), '-W', RIGHT('0' + CAST(DATEPART(WEEK,p.fecha) AS VARCHAR(2)),2)) AS semana
        FROM Pago p
        LEFT JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
        LEFT JOIN Expensa e ON ed.id_expensa = e.id_expensa
        LEFT JOIN Unidad_Funcional uf ON p.id_uf = uf.id_uf
        LEFT JOIN Consorcio c ON uf.id_consorcio = c.id_consorcio
        WHERE p.fecha BETWEEN @StartDate AND @EndDate
          AND (@id_consorcio IS NULL OR c.id_consorcio = @id_consorcio)
    ),
    agrup AS (
        SELECT semana, yr, wk, ISNULL(tipo_gasto,'SinClasificar') AS tipo_gasto,
               SUM(valor) AS total_semana
        FROM pagos_filtrados
        GROUP BY semana, yr, wk, ISNULL(tipo_gasto,'SinClasificar')
    ),
    -- Totales por semana con columnas para ordinario/extraordinario
    pivoted AS (
        SELECT semana, yr, wk,
            ISNULL(SUM(CASE WHEN tipo_gasto = 'Ordinario' THEN total_semana END),0) AS total_ordinario,
            ISNULL(SUM(CASE WHEN tipo_gasto = 'Extraordinario' THEN total_semana END),0) AS total_extra,
            ISNULL(SUM(CASE WHEN tipo_gasto NOT IN ('Ordinario','Extraordinario') THEN total_semana END),0) AS total_otro,
            ISNULL(SUM(total_semana),0) AS total_semana
        FROM agrup
        GROUP BY semana, yr, wk
    )
    SELECT
        semana,
        yr,
        wk,
        total_ordinario,
        total_extra,
        total_otro,
        total_semana,
        -- promedio en periodo (promedio semanal)
        AVG(total_semana) OVER () AS promedio_semanal,
        -- acumulado progresivo ordenado por año/semana
        SUM(total_semana) OVER (ORDER BY yr, wk ROWS UNBOUNDED PRECEDING) AS acumulado_progresivo
    FROM pivoted
    ORDER BY yr, wk;
END
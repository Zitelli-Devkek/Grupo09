CREATE OR ALTER PROCEDURE rpt_Top5_Meses_Gastos_Ingresos
    @StartDate DATE,
    @EndDate   DATE,
    @id_consorcio INT = NULL,
    @TopN INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    -- GASTOS = suma de importe en Expensa (o Gasto_Ordinario/Extra) por mes
    ;WITH gastos_mes AS (
        SELECT FORMAT(e.vencimiento,'yyyy-MM') AS mes,
               SUM(COALESCE(go.importe, ge.importe, 0)) AS total_gastos,
               c.id_consorcio
        FROM Expensa e
        LEFT JOIN Gasto_Ordinario go ON go.id_expensa = e.id_expensa
        LEFT JOIN Gasto_Extraordinario ge ON ge.id_expensa = e.id_expensa
        LEFT JOIN Consorcio c ON e.id_consorcio = c.id_consorcio
        WHERE e.vencimiento BETWEEN @StartDate AND @EndDate
          AND (@id_consorcio IS NULL OR c.id_consorcio = @id_consorcio)
        GROUP BY FORMAT(e.vencimiento,'yyyy-MM'), c.id_consorcio
    ),
    ingresos_mes AS (
        -- Ingresos = pagos agregados por mes (pagos asociados a expensas)
        SELECT FORMAT(p.fecha,'yyyy-MM') AS mes,
               SUM(p.valor) AS total_ingresos,
               uf.id_consorcio
        FROM Pago p
        LEFT JOIN Unidad_Funcional uf ON p.id_uf = uf.id_uf
        WHERE p.fecha BETWEEN @StartDate AND @EndDate
          AND (@id_consorcio IS NULL OR uf.id_consorcio = @id_consorcio)
        GROUP BY FORMAT(p.fecha,'yyyy-MM'), uf.id_consorcio
    )
    -- Top gastos
    SELECT TOP (@TopN) mes, total_gastos AS monto, 'Gasto' AS tipo
    FROM gastos_mes
    WHERE (@id_consorcio IS NULL OR id_consorcio = @id_consorcio)
    ORDER BY total_gastos DESC;

    -- Top ingresos
    SELECT TOP (@TopN) mes, total_ingresos AS monto, 'Ingreso' AS tipo
    FROM ingresos_mes
    WHERE (@id_consorcio IS NULL OR id_consorcio = @id_consorcio)
    ORDER BY total_ingresos DESC;
END

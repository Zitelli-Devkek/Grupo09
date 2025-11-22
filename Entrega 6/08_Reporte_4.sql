/*
BASE DE DATOS APLICADA

GRUPO 9

Alumnos:
Jiménez Damián (DNI 43.194.984)
Mendoza Gonzalo (DNI 44.597.456)
Demis Colman (DNI 37.174.947)
Feiertag Mateo (DNI 46.293.138)
Suriano Lautaro (DNI 44.792.129)
Zitelli Emanuel (DNI 45.064.107)


Reporte 4
Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos.*/


CREATE OR ALTER PROCEDURE dbo.sp_Report_Top5GastosIngresos
    @id_consorcio INT,
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Top 5 GASTOS
    ;WITH facturas_cte AS (
        SELECT
            FORMAT(f.fecha_emision,'yyyy-MM') AS periodo,
            ROUND(SUM(f.importe),2) AS total
        FROM Factura f
        INNER JOIN Expensa e ON f.id_expensa = e.id_expensa
        WHERE e.id_consorcio = @id_consorcio
          AND f.fecha_emision BETWEEN @fecha_inicio AND @fecha_fin
        GROUP BY FORMAT(f.fecha_emision,'yyyy-MM')
    )
    SELECT TOP 5
        'Gasto' AS tipo,
        periodo,
        total
    INTO #top_gastos
    FROM facturas_cte
    ORDER BY total DESC;

    -- Top 5 INGRESOS
    ;WITH ingresos_cte AS (
        SELECT
            FORMAT(p.fecha,'yyyy-MM') AS periodo,
            ROUND(SUM(p.valor),2) AS total
        FROM Pago p
        INNER JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
        INNER JOIN Expensa e ON ed.id_expensa = e.id_expensa
        WHERE e.id_consorcio = @id_consorcio
          AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin
        GROUP BY FORMAT(p.fecha,'yyyy-MM')
    )
    SELECT TOP 5
        'Ingreso' AS tipo,
        periodo,
        total
    INTO #top_ingresos
    FROM ingresos_cte
    ORDER BY total DESC;

    -- Combinamos en una sola tabla final
    SELECT tipo, periodo, total
    FROM #top_gastos
    UNION ALL
    SELECT tipo, periodo, total
    FROM #top_ingresos
    ORDER BY tipo, total DESC;

    -- Limpiamos temporales
    DROP TABLE #top_gastos;
    DROP TABLE #top_ingresos;
END;
GO




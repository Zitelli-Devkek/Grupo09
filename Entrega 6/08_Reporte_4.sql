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
Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos. */

USE Com2900G09
GO

CREATE OR ALTER PROCEDURE dbo.sp_Report_Top5GastosIngresos
    @id_consorcio INT,
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- GASTOS por mes (Facturas vinculadas a Expensa -> Expensa.id_consorcio)
    ;WITH facturas_cte AS (
        SELECT
            FORMAT(f.fecha_emision,'yyyy-MM') AS periodo,
            SUM(f.importe) AS total_gastos
        FROM Factura f
        LEFT JOIN Servicio s ON f.id_servicio = s.id_servicio
        LEFT JOIN Expensa e ON f.id_expensa = e.id_expensa
        WHERE e.id_consorcio = @id_consorcio
          AND f.fecha_emision BETWEEN @fecha_inicio AND @fecha_fin
        GROUP BY FORMAT(f.fecha_emision,'yyyy-MM')
    ),
    ingresos_cte AS (
        SELECT
            FORMAT(p.fecha,'yyyy-MM') AS periodo,
            SUM(p.valor) AS total_ingresos
        FROM Pago p
        LEFT JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
        LEFT JOIN Expensa e ON ed.id_expensa = e.id_expensa
        WHERE e.id_consorcio = @id_consorcio
          AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin
        GROUP BY FORMAT(p.fecha,'yyyy-MM')
    )
    -- Top 5 gastos
    SELECT TOP 5 periodo, total_gastos
    FROM facturas_cte
    ORDER BY total_gastos DESC;

    -- Top 5 ingresos
    SELECT TOP 5 periodo, total_ingresos
    FROM ingresos_cte
    ORDER BY total_ingresos DESC;
END
GO
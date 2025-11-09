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


Reporte 2
Presente el total de recaudación por mes y departamento en formato de tabla cruzada. */

USE Com2900G09
GO


CREATE OR ALTER PROCEDURE dbo.sp_Report_RecaudacionMesDepartamento
    @anio INT,
    @id_consorcio INT = NULL,
    @tipo_moneda VARCHAR(10) = 'PESOS'  -- 'PESOS' o 'USD'
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------------------------
    -- Obtener cotización del dólar más reciente desde la API
    --------------------------------------------------------------------
    DECLARE @dolar DECIMAL(10,2) = (
        SELECT TOP 1 venta FROM ##DolarHistorico ORDER BY fecha DESC
    );
    IF @dolar IS NULL
        SET @dolar = 1000;  -- Valor de respaldo si la API no respondió

    --------------------------------------------------------------------
    -- Obtener datos base: recaudación por mes y departamento
    --------------------------------------------------------------------
    ;WITH CTE_Recaudacion AS (
        SELECT 
            c.id_consorcio,
            uf.departamento,
            e.mes,
            SUM(p.valor) AS total_pesos
        FROM Pago p
        INNER JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
        INNER JOIN Expensa e ON ed.id_expensa = e.id_expensa
        INNER JOIN Unidad_Funcional uf ON uf.id_consorcio = e.id_consorcio
        INNER JOIN Consorcio c ON c.id_consorcio = e.id_consorcio
        WHERE LEFT(e.mes, 4) = CAST(@anio AS CHAR(4))
        GROUP BY c.id_consorcio, uf.departamento, e.mes
    )
    --------------------------------------------------------------------
    -- Conversión según tipo de moneda
    --------------------------------------------------------------------
    SELECT 
        departamento,
        [2024-01] AS Ene,
        [2024-02] AS Feb,
        [2024-03] AS Mar,
        [2024-04] AS Abr,
        [2024-05] AS May,
        [2024-06] AS Jun,
        [2024-07] AS Jul,
        [2024-08] AS Ago,
        [2024-09] AS Sep,
        [2024-10] AS Oct,
        [2024-11] AS Nov,
        [2024-12] AS Dic
    FROM (
        SELECT 
            departamento,
            mes,
            CASE 
                WHEN @tipo_moneda = 'USD' THEN total_pesos / @dolar
                ELSE total_pesos
            END AS total
        FROM CTE_Recaudacion
        WHERE (@id_consorcio IS NULL OR id_consorcio = @id_consorcio)
    ) AS SourceTable
    PIVOT (
        SUM(total)
        FOR mes IN ([2024-01],[2024-02],[2024-03],[2024-04],[2024-05],
                    [2024-06],[2024-07],[2024-08],[2024-09],[2024-10],
                    [2024-11],[2024-12])
    ) AS PivotTable
    ORDER BY departamento;

END;
GO

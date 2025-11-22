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


Reporte 1
Se desea analizar el flujo de caja en forma semanal. Debe presentar la recaudación por
pagos ordinarios y extraordinarios de cada semana, el promedio en el periodo, y el
acumulado progresivo.*/


CREATE OR ALTER PROCEDURE dbo.sp_Report_FlujoCajaSemanal
    @id_consorcio INT,
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- obtener cotización (venta) más reciente
    DECLARE @venta DECIMAL(18,6) = NULL;
    SELECT TOP 1 @venta = venta FROM ##DolarHistorico WHERE venta IS NOT NULL ORDER BY fecha DESC;

    IF @venta IS NULL
        SET @venta = 1; -- evita división por cero si no hay cotización; ojo: resultará same valor.

    ;WITH pagos_cte AS (
        SELECT
            p.id_pago,
            p.fecha,
            p.valor AS importe_pesos,
            CASE 
                WHEN ed.tipo IS NOT NULL AND LOWER(ed.tipo) LIKE '%extra%' THEN 'Extraordinario'
                ELSE 'Ordinario'
            END AS tipo_pago,
            DATEPART(YEAR, p.fecha) AS anio,
            DATEPART(WEEK, p.fecha) AS semana_num
        FROM Pago p
        LEFT JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
        LEFT JOIN Expensa e ON ed.id_expensa = e.id_expensa
        WHERE e.id_consorcio = @id_consorcio
          AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin
    ),
    semana_sum AS (
        SELECT
            anio,
            semana_num,
            tipo_pago,
            SUM(importe_pesos) AS total_pesos
        FROM pagos_cte
        GROUP BY anio, semana_num, tipo_pago
    ),
    semana_totales AS (
        -- total por semana (ambos tipos)
        SELECT
            anio,
            semana_num,
            tipo_pago,
            total_pesos,
            total_pesos / @venta AS total_usd
        FROM semana_sum
    ),
    semanas_distintas AS (
        SELECT DISTINCT anio, semana_num FROM pagos_cte
    ),
    promedio_por_tipo AS (
        SELECT
            s.tipo_pago,
            AVG(s.total_pesos) AS promedio_pesos
        FROM semana_sum s
        GROUP BY s.tipo_pago
    ),
    acumulado AS (
        SELECT
            st.anio,
            st.semana_num,
            st.tipo_pago,
            st.total_pesos,
            st.total_pesos / @venta AS total_usd,
            SUM(st.total_pesos) OVER (PARTITION BY st.tipo_pago ORDER BY st.anio, st.semana_num ROWS UNBOUNDED PRECEDING) AS acumulado_pesos,
            SUM(st.total_pesos) OVER (ORDER BY st.anio, st.semana_num ROWS UNBOUNDED PRECEDING) AS acumulado_total_pesos
        FROM semana_totales st
    )
    
    SELECT
        CONVERT(VARCHAR(7), anio) + '-W' + RIGHT('0' + CAST(semana_num AS VARCHAR(2)),2) AS semana,
        tipo_pago,
        total_pesos AS recaudacion_pesos,
        ROUND(total_usd,2) AS recaudacion_usd,
        ROUND(ISNULL((SELECT promedio_pesos FROM promedio_por_tipo WHERE tipo_pago = a.tipo_pago),0),2) AS promedio_periodo_pesos,
        ROUND(acumulado_pesos,2) AS acumulado_progresivo_pesos,
        ROUND(acumulado_pesos / @venta,2) AS acumulado_progresivo_usd,
        ROUND(acumulado_total_pesos,2) AS acumulado_total_general_pesos,
        ROUND(acumulado_total_pesos / @venta,2) AS acumulado_total_general_usd
    FROM acumulado a
    ORDER BY anio, semana_num, tipo_pago;
END
GO


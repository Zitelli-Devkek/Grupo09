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

CREATE OR ALTER PROCEDURE dbo.spReporte2_RecaudacionMensual
    @Anio INT,
    @IdConsorcio INT = NULL,
    @MesInicio INT = 1,
    @tipo_dolar NVARCHAR(50) = 'Blue'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @valor_dolar DECIMAL(10,2);

    -- Tomamos el valor más reciente del tipo de dólar seleccionado
    IF OBJECT_ID('tempdb..##DolarHistorico') IS NOT NULL
    BEGIN
        SELECT TOP 1 @valor_dolar = venta
        FROM ##DolarHistorico
        WHERE tipo = @tipo_dolar
        ORDER BY fecha DESC;
    END

    IF @valor_dolar IS NULL SET @valor_dolar = 1;

    -- Tabla temporal con recaudación por departamento y mes
    SELECT 
        uf.departamento,
        MONTH(p.fecha) AS Mes,
        SUM(p.valor) AS TotalPesos,
        SUM(p.valor) / @valor_dolar AS TotalDolares
    INTO #temp
    FROM Pago p
    INNER JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
    INNER JOIN Expensa e ON e.id_expensa = ed.id_expensa
    INNER JOIN Unidad_Funcional uf ON uf.id_consorcio = e.id_consorcio
    WHERE YEAR(p.fecha) = @Anio
      AND MONTH(p.fecha) >= @MesInicio
      AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
    GROUP BY uf.departamento, MONTH(p.fecha);

    -- Pivot pesos
    SELECT * INTO #pivot_pesos
    FROM
    (
        SELECT departamento, Mes, TotalPesos
        FROM #temp
    ) src
    PIVOT
    (
        SUM(TotalPesos) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
    ) AS p;

    -- Pivot dólares
    SELECT * INTO #pivot_dolares
    FROM
    (
        SELECT departamento, Mes, TotalDolares
        FROM #temp
    ) src
    PIVOT
    (
        SUM(TotalDolares) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
    ) AS d;

    -- Join final y renombramos columnas con sufijos
    SELECT 
        p.departamento,
        ISNULL(p.[1],0) AS Ene_ARS, ISNULL(d.[1],0) AS Ene_USD,
        ISNULL(p.[2],0) AS Feb_ARS, ISNULL(d.[2],0) AS Feb_USD,
        ISNULL(p.[3],0) AS Mar_ARS, ISNULL(d.[3],0) AS Mar_USD,
        ISNULL(p.[4],0) AS Abr_ARS, ISNULL(d.[4],0) AS Abr_USD,
        ISNULL(p.[5],0) AS May_ARS, ISNULL(d.[5],0) AS May_USD,
        ISNULL(p.[6],0) AS Jun_ARS, ISNULL(d.[6],0) AS Jun_USD,
        ISNULL(p.[7],0) AS Jul_ARS, ISNULL(d.[7],0) AS Jul_USD,
        ISNULL(p.[8],0) AS Ago_ARS, ISNULL(d.[8],0) AS Ago_USD,
        ISNULL(p.[9],0) AS Sep_ARS, ISNULL(d.[9],0) AS Sep_USD,
        ISNULL(p.[10],0) AS Oct_ARS, ISNULL(d.[10],0) AS Oct_USD,
        ISNULL(p.[11],0) AS Nov_ARS, ISNULL(d.[11],0) AS Nov_USD,
        ISNULL(p.[12],0) AS Dic_ARS, ISNULL(d.[12],0) AS Dic_USD
    FROM #pivot_pesos p
    INNER JOIN #pivot_dolares d ON p.departamento = d.departamento
    ORDER BY p.departamento;

    DROP TABLE #temp;
    DROP TABLE #pivot_pesos;
    DROP TABLE #pivot_dolares;
END;
GO
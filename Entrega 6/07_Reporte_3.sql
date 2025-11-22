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


Reporte 3
Presente un cuadro cruzado con la recaudación total desagregada según su procedencia
(ordinario, extraordinario, etc.) según el periodo.*/


CREATE OR ALTER PROCEDURE dbo.sp_Report_RecaudacionPorProcedencia_Unica
    @id_consorcio INT,
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @venta DECIMAL(10,2) = NULL;

    -- Tomamos último valor de dólar
    IF OBJECT_ID('tempdb..##DolarHistorico') IS NOT NULL
        SELECT TOP 1 @venta = venta
        FROM ##DolarHistorico
        WHERE venta IS NOT NULL
        ORDER BY fecha DESC;
    IF @venta IS NULL SET @venta = 1;

    -- Generamos todos los meses del rango
    ;WITH meses_rango AS
    (
        SELECT FORMAT(@fecha_inicio,'yyyy-MM') AS periodo
        UNION ALL
        SELECT FORMAT(DATEADD(MONTH,1,CAST(periodo + '-01' AS DATE)),'yyyy-MM')
        FROM meses_rango
        WHERE DATEADD(MONTH,1,CAST(periodo + '-01' AS DATE)) <= @fecha_fin
    )
    SELECT periodo INTO #meses_rango FROM meses_rango OPTION (MAXRECURSION 0);

    -- Pagos con origen
    SELECT 
        FORMAT(p.fecha,'yyyy-MM') AS periodo,
        CASE
            WHEN ed.descripcion IS NOT NULL AND LOWER(ed.descripcion) LIKE '%extra%' THEN 'Extraordinario'
            WHEN ed.descripcion IS NOT NULL AND LOWER(ed.descripcion) LIKE '%ordinario%' THEN 'Ordinario'
            ELSE 'Otro'
        END AS origen,
        CAST(p.valor AS DECIMAL(10,2)) AS importe_pesos,
        CAST(p.valor / @venta AS DECIMAL(10,2)) AS importe_usd
    INTO #temp_pagos
    FROM Pago p
    LEFT JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
    LEFT JOIN Expensa e ON ed.id_expensa = e.id_expensa
    WHERE e.id_consorcio = @id_consorcio
      AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin;

    IF NOT EXISTS (SELECT 1 FROM #temp_pagos)
    BEGIN
        PRINT 'No hay pagos en el rango de fechas indicado.';
        DROP TABLE #temp_pagos;
        DROP TABLE #meses_rango;
        RETURN;
    END

    -- Todas las combinaciones de origen x mes
    ;WITH origenes AS (SELECT DISTINCT origen FROM #temp_pagos)
    SELECT o.origen, m.periodo
    INTO #origen_mes
    FROM origenes o
    CROSS JOIN #meses_rango m;

    -- Combinamos con pagos reales
    SELECT 
        om.origen,
        om.periodo,
        ISNULL(tp.importe_pesos,0) AS importe_pesos,
        ISNULL(tp.importe_usd,0) AS importe_usd
    INTO #temp_completo
    FROM #origen_mes om
    LEFT JOIN #temp_pagos tp
        ON om.origen = tp.origen AND om.periodo = tp.periodo;

    -- Convertimos a formato long para pivot
    SELECT origen, periodo + '_Pesos' AS periodo_col, importe_pesos AS importe INTO #long_pesos FROM #temp_completo;
    SELECT origen, periodo + '_USD' AS periodo_col, importe_usd AS importe INTO #long_usd FROM #temp_completo;

    -- Combinamos ambas
    SELECT origen, periodo_col, importe INTO #combined_long
    FROM
    (
        SELECT * FROM #long_pesos
        UNION ALL
        SELECT * FROM #long_usd
    ) t;

    -- Pivot final
    DECLARE @cols_final NVARCHAR(MAX) = '';
    SELECT @cols_final = STRING_AGG(QUOTENAME(periodo_col), ',') 
    FROM (SELECT DISTINCT periodo_col FROM #combined_long) x;

    DECLARE @sql NVARCHAR(MAX) = N'
    SELECT origen, ' + @cols_final + '
    FROM
    (
        SELECT origen, periodo_col, importe FROM #combined_long
    ) src
    PIVOT
    (
        SUM(importe) FOR periodo_col IN (' + @cols_final + ')
    ) pvt
    ORDER BY origen;
    ';

    EXEC sp_executesql @sql;

    -- Limpiamos temporales
    DROP TABLE #temp_pagos;
    DROP TABLE #meses_rango;
    DROP TABLE #origen_mes;
    DROP TABLE #temp_completo;
    DROP TABLE #long_pesos;
    DROP TABLE #long_usd;
    DROP TABLE #combined_long;
END;
GO



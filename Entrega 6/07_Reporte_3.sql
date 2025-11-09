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

USE Com2900G09
GO

CREATE OR ALTER PROCEDURE dbo.sp_Report_RecaudacionPorProcedencia
    @id_consorcio INT,
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @venta DECIMAL(18,6) = NULL;
    SELECT TOP 1 @venta = venta FROM ##DolarHistorico WHERE venta IS NOT NULL ORDER BY fecha DESC;
    IF @venta IS NULL SET @venta = 1;

    ;WITH pagos_origen AS (
        SELECT
            FORMAT(p.fecha,'yyyy-MM') AS periodo,
            CASE
                WHEN ed.descripcion IS NOT NULL AND LOWER(ed.descripcion) LIKE '%extra%' THEN 'Extraordinario'
                WHEN ed.descripcion IS NOT NULL AND LOWER(ed.descripcion) LIKE '%ordinario%' THEN 'Ordinario'
                ELSE 'Otro'
            END AS origen,
            p.valor AS importe_pesos
        FROM Pago p
        LEFT JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
        LEFT JOIN Expensa e ON ed.id_expensa = e.id_expensa
        WHERE e.id_consorcio = @id_consorcio
          AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin
    ),
    meses AS (SELECT DISTINCT periodo FROM pagos_origen)
    SELECT periodo INTO #periodos_temp FROM meses;

    DECLARE @cols NVARCHAR(MAX) = '';
    SELECT @cols = @cols + QUOTENAME(periodo) + ',' FROM #periodos_temp;
    SET @cols = LEFT(@cols, LEN(@cols)-1);

    DECLARE @sql_pesos NVARCHAR(MAX) = N'
    SELECT origen, ' + @cols + '
    FROM
    (
        SELECT origen, periodo, importe_pesos FROM pagos_origen
    ) src
    PIVOT
    (
        SUM(importe_pesos) FOR periodo IN (' + @cols + ')
    ) pvt
    ORDER BY origen;
    ';

    PRINT '---- Recaudación por procedencia (PESOS) ----';
    EXEC sp_executesql @sql_pesos;

    DECLARE @sql_usd NVARCHAR(MAX) = N'
    SELECT origen, ' + @cols + '
    FROM
    (
        SELECT origen, periodo, (importe_pesos / ' + CAST(@venta AS VARCHAR(20)) + N') as importe_usd FROM pagos_origen
    ) src
    PIVOT
    (
        SUM(importe_usd) FOR periodo IN (' + @cols + ')
    ) pvt
    ORDER BY origen;
    ';
    PRINT '---- Recaudación por procedencia (USD) ----';
    EXEC sp_executesql @sql_usd;

    DROP TABLE IF EXISTS #periodos_temp;
END
GO
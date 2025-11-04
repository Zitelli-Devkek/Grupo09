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

CREATE OR ALTER PROCEDURE sp_Reporte3_RecaudacionPorTipo
    @Anio INT,
    @IdConsorcio INT = NULL,
    @MesInicio INT = 1,
    @tipo_dolar NVARCHAR(50) = 'Blue'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @valor_dolar DECIMAL(10,2);

    -- Tomamos el valor más reciente del tipo de dólar seleccionado
    SELECT TOP 1 @valor_dolar = venta
    FROM ##DolarHistorico
    WHERE tipo = @tipo_dolar
    ORDER BY fecha DESC;

    IF @valor_dolar IS NULL SET @valor_dolar = 1;

    SELECT 
        ed.tipo_gasto,
        e.mes,
        SUM(p.valor) AS TotalPesos,
        SUM(p.valor) / @valor_dolar AS TotalDolares
    INTO #temp
    FROM Pago p
    INNER JOIN Unidad_Funcional uf ON uf.id_uf = p.id_uf
    INNER JOIN Expensa e ON e.id_uf = uf.id_uf
    INNER JOIN Expensa_Detalle ed ON ed.id_expensa = e.id_expensa
    WHERE YEAR(p.fecha) = @Anio
      AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
      AND CAST(SUBSTRING(e.mes, 1, 2) AS INT) >= @MesInicio
    GROUP BY ed.tipo_gasto, e.mes;

    SELECT *
    FROM #temp
    PIVOT (
        SUM(TotalPesos) FOR tipo_gasto IN ([Ordinario],[Extraordinario])
    ) AS PivotPesos;

    SELECT *
    FROM #temp
    PIVOT (
        SUM(TotalDolares) FOR tipo_gasto IN ([Ordinario],[Extraordinario])
    ) AS PivotDolares;

    DROP TABLE #temp;
END;
GO

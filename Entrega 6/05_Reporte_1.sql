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

CREATE OR ALTER PROCEDURE sp_Reporte1_FlujoSemanal
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @id_consorcio INT,
    @tipo_dolar NVARCHAR(50) = 'Blue'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @valor_dolar DECIMAL(10,2);

    -- Tomamos el valor más reciente del tipo de dólar seleccionado
    SELECT TOP 1 @valor_dolar = venta
    FROM [dbo].[##DolarHistorico]
    WHERE tipo = @tipo_dolar
    ORDER BY fecha DESC;

    SELECT 
        DATEPART(WEEK, P.fecha) AS Semana,
        SUM(P.valor) AS TotalPesos,
        SUM(P.valor) / @valor_dolar AS TotalDolares,
        AVG(P.valor) AS PromedioSemanal,
        SUM(SUM(P.valor)) OVER (ORDER BY DATEPART(WEEK, P.fecha)) AS Acumulado
    FROM Pago P
    INNER JOIN Unidad_Funcional UF ON P.id_uf = UF.id_uf
    INNER JOIN Consorcio C ON UF.id_consorcio = C.id_consorcio
    WHERE 
        P.fecha BETWEEN @fecha_inicio AND @fecha_fin
        AND C.id_consorcio = @id_consorcio
    GROUP BY DATEPART(WEEK, P.fecha)
    ORDER BY Semana;
END;
GO

EXEC sp_Reporte1_FlujoSemanal '2020-01-01', '2025-12-31', 1;

/*CREATE OR ALTER PROCEDURE sp_Reporte1_FlujoSemanal
    @FechaInicio DATE,
    @FechaFin DATE,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        DATEPART(WEEK, p.fecha) AS Semana,
        YEAR(p.fecha) AS Año,
        ed.tipo_gasto AS TipoGasto,
        SUM(p.valor) AS Recaudacion,
        AVG(SUM(p.valor)) OVER() AS PromedioPeriodo,
        SUM(SUM(p.valor)) OVER(ORDER BY DATEPART(WEEK, p.fecha)) AS Acumulado
    FROM Pago p
    INNER JOIN Unidad_Funcional uf ON uf.id_uf = p.id_uf
    INNER JOIN Expensa e ON e.id_uf = uf.id_uf
    INNER JOIN Expensa_Detalle ed ON ed.id_expensa = e.id_expensa
    WHERE p.fecha BETWEEN @FechaInicio AND @FechaFin
      AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
    GROUP BY DATEPART(WEEK, p.fecha), YEAR(p.fecha), ed.tipo_gasto
    ORDER BY Año, Semana;
END;
GO
*/
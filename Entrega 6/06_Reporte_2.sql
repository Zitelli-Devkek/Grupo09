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


Genere índices para optimizar la ejecución de las consultas de los reportes. Debe existir un
script adicional con la generación de índices.*/

CREATE OR ALTER PROCEDURE sp_Reporte2_RecaudacionMensual
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

    -- Si no existe valor, evitamos dividir por NULL
    IF @valor_dolar IS NULL SET @valor_dolar = 1;

    SELECT 
        uf.departamento,
        MONTH(p.fecha) AS Mes,
        SUM(p.valor) AS TotalPesos,
        SUM(p.valor) / @valor_dolar AS TotalDolares
    INTO #temp
    FROM Pago p
    INNER JOIN Unidad_Funcional uf ON uf.id_uf = p.id_uf
    INNER JOIN Expensa e ON e.id_uf = uf.id_uf
    WHERE YEAR(p.fecha) = @Anio
      AND MONTH(p.fecha) >= @MesInicio
      AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
    GROUP BY uf.departamento, MONTH(p.fecha);

    SELECT * 
    FROM #temp
    PIVOT (
        SUM(TotalPesos) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
    ) AS PivotePesos;

    SELECT * 
    FROM #temp
    PIVOT (
        SUM(TotalDolares) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
    ) AS PivoteDolares;

    DROP TABLE #temp;
END;
GO

/*CREATE OR ALTER PROCEDURE sp_Reporte2_RecaudacionMensual
    @Anio INT,
    @IdConsorcio INT = NULL,
    @MesInicio INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        uf.departamento,
        MONTH(p.fecha) AS Mes,
        SUM(p.valor) AS TotalRecaudado
    INTO #temp
    FROM Pago p
    INNER JOIN Unidad_Funcional uf ON uf.id_uf = p.id_uf
    INNER JOIN Expensa e ON e.id_uf = uf.id_uf
    WHERE YEAR(p.fecha) = @Anio
      AND MONTH(p.fecha) >= @MesInicio
      AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
    GROUP BY uf.departamento, MONTH(p.fecha);

    SELECT * 
    FROM #temp
    PIVOT (
        SUM(TotalRecaudado) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
    ) AS PivoteMensual;

    DROP TABLE #temp;
END;
GO*/

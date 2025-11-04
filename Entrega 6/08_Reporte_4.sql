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

CREATE OR ALTER PROCEDURE sp_Reporte4_MayoresGastosIngresos
    @Anio INT,
    @IdConsorcio INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Ingresos AS (
        SELECT 
            YEAR(p.fecha) AS Anio, MONTH(p.fecha) AS Mes, SUM(p.valor) AS TotalIngresos
        FROM Pago p
        INNER JOIN Unidad_Funcional uf ON uf.id_uf = p.id_uf
        WHERE YEAR(p.fecha) = @Anio
          AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
        GROUP BY YEAR(p.fecha), MONTH(p.fecha)
    ) SELECT TOP 5 * FROM Ingresos ORDER BY TotalIngresos DESC;

    ;WITH Gastos AS (
        SELECT 
            YEAR(e.vencimiento) AS Anio, MONTH(e.vencimiento) AS Mes,
            SUM(ed.importe_uf) AS TotalGastos
        FROM Expensa_Detalle ed
        INNER JOIN Expensa e ON e.id_expensa = ed.id_expensa
        INNER JOIN Unidad_Funcional uf ON uf.id_uf = e.id_uf
        WHERE YEAR(e.vencimiento) = @Anio
          AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
        GROUP BY YEAR(e.vencimiento), MONTH(e.vencimiento)
    )
    SELECT TOP 5 * FROM Gastos ORDER BY TotalGastos DESC;
END;
GO

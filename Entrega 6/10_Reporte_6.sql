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


Reporte 6
Muestre las fechas de pagos de expensas ordinarias de cada UF y la cantidad de días que
pasan entre un pago y el siguiente, para el conjunto examinado.*/

CREATE OR ALTER PROCEDURE sp_Reporte6_DiasEntrePagos_XML
    @IdConsorcio INT = NULL,
    @Anio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PagosOrd AS (
        SELECT 
            uf.id_uf,
            p.fecha,
            LAG(p.fecha) OVER(PARTITION BY uf.id_uf ORDER BY p.fecha) AS FechaAnterior
        FROM Pago p
        INNER JOIN Unidad_Funcional uf ON uf.id_uf = p.id_uf
        INNER JOIN Expensa e ON e.id_uf = uf.id_uf
        INNER JOIN Expensa_Detalle ed ON ed.id_expensa = e.id_expensa
        WHERE ed.tipo_gasto = 'Ordinario'
          AND (@Anio IS NULL OR YEAR(p.fecha) = @Anio)
          AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
    )
    SELECT 
        id_uf,
        FechaAnterior,
        fecha AS FechaPago,
        DATEDIFF(DAY, FechaAnterior, fecha) AS DiasEntrePagos
    FROM PagosOrd
    WHERE FechaAnterior IS NOT NULL
    FOR XML AUTO, ELEMENTS, ROOT('PagosOrdinarios');
END;
GO

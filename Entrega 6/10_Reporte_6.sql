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

USE Com2900G09
GO

CREATE OR ALTER PROCEDURE dbo.sp_Report_PagosOrdinariosPorUF_XML
    @id_consorcio INT,
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    /*
      Necesitamos listar pagos por UF: mapeo Pago -> Persona (por cbu) -> Persona_UF vigente -> UF
      Filtramos sólo pagos considerados "Ordinarios" (descr no like '%extra%').
      Luego ordenamos por fecha y calculamos la diferencia entre fecha actual y la siguiente (LEAD).
    */

    ;WITH pagos_por_uf AS (
        SELECT
            uf.id_uf,
            uf.nr_uf,
            uf.piso,
            uf.departamento,
            p.fecha,
            p.valor,
            ROW_NUMBER() OVER (PARTITION BY uf.id_uf ORDER BY p.fecha) AS rn,
            LEAD(p.fecha) OVER (PARTITION BY uf.id_uf ORDER BY p.fecha) AS fecha_siguiente
        FROM Pago p
        LEFT JOIN Persona per ON per.cbu_cvu = p.cvu_cbu
        LEFT JOIN Persona_UF puf ON puf.DNI = per.DNI
            AND puf.fecha_inicio <= p.fecha
            AND (puf.fecha_fin IS NULL OR puf.fecha_fin >= p.fecha)
        LEFT JOIN Unidad_Funcional uf ON uf.id_uf = puf.id_uf
        LEFT JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
        LEFT JOIN Expensa e ON ed.id_expensa = e.id_expensa
        WHERE e.id_consorcio = @id_consorcio
          AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin
          AND NOT (ed.descripcion IS NOT NULL AND LOWER(ed.descripcion) LIKE '%extra%') -- sólo ordinarias
    )
    SELECT
        id_uf AS '@id_uf',
        nr_uf AS '@nr_uf',
        piso AS '@piso',
        departamento AS '@departamento',
        (
            SELECT
                CONVERT(VARCHAR(10), fecha, 23) AS 'FechaPago',
                fecha_siguiente AS 'FechaSiguiente',
                DATEDIFF(day, fecha, fecha_siguiente) AS 'DiasEntrePagos'
            FROM pagos_por_uf p2
            WHERE p2.id_uf = p1.id_uf
            ORDER BY p2.rn
            FOR XML PATH('Pago'), TYPE
        ) AS Pagos
    FROM (SELECT DISTINCT id_uf, nr_uf, piso, departamento FROM pagos_por_uf) p1
    FOR XML PATH('UnidadFuncional'), ROOT('PagosOrdinariosPorUF');
END
GO
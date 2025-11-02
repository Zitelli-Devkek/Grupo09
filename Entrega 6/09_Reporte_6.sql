CREATE OR ALTER PROCEDURE rpt_Pagos_UF_Intervalos
    @StartDate DATE,
    @EndDate DATE,
    @id_consorcio INT = NULL,
    @id_uf INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH pagos_ord AS (
        SELECT p.id_pago, p.fecha, p.valor, p.id_uf, ed.tipo_gasto
        FROM Pago p
        LEFT JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
        LEFT JOIN Unidad_Funcional uf ON p.id_uf = uf.id_uf
        WHERE p.fecha BETWEEN @StartDate AND @EndDate
          AND (ed.tipo_gasto = 'Ordinario' OR ed.tipo_gasto IS NULL)  -- si NULL, queda como "posible ordinario"
          AND (@id_consorcio IS NULL OR uf.id_consorcio = @id_consorcio)
          AND (@id_uf IS NULL OR p.id_uf = @id_uf)
    ),
    ordenados AS (
        SELECT p.*,
               LEAD(p.fecha) OVER (PARTITION BY p.id_uf ORDER BY p.fecha) AS next_fecha
        FROM pagos_ord p
    )
    SELECT
        id_uf,
        id_pago,
        fecha AS fecha_pago,
        next_fecha,
        DATEDIFF(DAY, fecha, next_fecha) AS dias_entre_pagos
    FROM ordenados
    ORDER BY id_uf, fecha;
END

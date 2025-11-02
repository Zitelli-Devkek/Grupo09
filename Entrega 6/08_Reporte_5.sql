CREATE OR ALTER PROCEDURE rpt_TopMorosos
    @FechaCorte DATE,
    @id_consorcio INT = NULL,
    @TopN INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH detalles_vencidos AS (
        SELECT ed.id_exp_detalle, ed.importe_uf, ed.id_expensa,
               e.id_consorcio,
               ed.id_expensa AS id_exp
        FROM Expensa_Detalle ed
        JOIN Expensa e ON ed.id_expensa = e.id_expensa
        WHERE ed.fecha_venc <= @FechaCorte
          AND (@id_consorcio IS NULL OR e.id_consorcio = @id_consorcio)
    ),
    pagos_aplicados AS (
        SELECT p.id_pago, p.valor, p.id_uf, p.id_exp_detalle
        FROM Pago p
        WHERE p.fecha <= @FechaCorte
    ),
    -- deuda por unidad funcional = suma(importe_uf de sus expensa_detalle vencidas) - pagos aplicados (si pago.id_uf corresponde)
    deuda_uf AS (
        SELECT uf.id_uf,
               SUM(dv.importe_uf) AS total_vencido,
               ISNULL(SUM(p.valor),0) AS pagos_realizados,
               SUM(dv.importe_uf) - ISNULL(SUM(p.valor),0) AS deuda
        FROM detalles_vencidos dv
        JOIN Expensa e2 ON dv.id_expensa = e2.id_expensa
        JOIN Unidad_Funcional uf ON e2.id_consorcio = uf.id_consorcio -- relacion por consorcio primero
        LEFT JOIN Pago p ON ( (p.id_exp_detalle = dv.id_exp_detalle) OR (p.id_uf = uf.id_uf AND p.id_exp_detalle IS NULL) )
        GROUP BY uf.id_uf
    ),
    propietario_actual AS (
        -- obtener propietario vigente en fecha corte
        SELECT pu.id_uf, pu.DNI
        FROM Persona_UF pu
        WHERE pu.fecha_inicio <= @FechaCorte
          AND (pu.fecha_fin IS NULL OR pu.fecha_fin >= @FechaCorte)
    )
    SELECT TOP (@TopN)
        pr.DNI,
        pr.nombre + ' ' + pr.apellido AS nombre_completo,
        pr.email_personal,
        pr.telefono,
        du.deuda
    FROM deuda_uf du
    LEFT JOIN propietario_actual pa ON pa.id_uf = du.id_uf
    LEFT JOIN Persona pr ON pr.DNI = pa.DNI
    WHERE pr.DNI IS NOT NULL
    ORDER BY du.deuda DESC;
END

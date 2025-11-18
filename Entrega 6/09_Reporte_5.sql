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


Reporte 5
Obtenga los 3 (tres) propietarios con mayor morosidad. Presente información de contacto y
DNI de los propietarios para que la administración los pueda contactar o remitir el trámite al
estudio jurídico.*/

USE Com2900G09
GO

CREATE OR ALTER PROCEDURE dbo.sp_Report_Top3Morosos_XML
    @id_consorcio INT,
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @venta DECIMAL(18,6) = NULL;

    SELECT TOP 1 @venta = venta
    FROM ##DolarHistorico
    WHERE venta IS NOT NULL
    ORDER BY fecha DESC;

    IF @venta IS NULL SET @venta = 1;

    DECLARE @coef_total DECIMAL(18,6);

    SELECT @coef_total = SUM(coeficiente)
    FROM Unidad_Funcional
    WHERE id_consorcio = @id_consorcio;

    IF @coef_total IS NULL SET @coef_total = 1;

    ;WITH Cargos AS (
        SELECT 
            per.DNI,
            SUM( ed.importe_uf * (uf.coeficiente / @coef_total) ) AS cargos_pesos
        FROM Persona per
        INNER JOIN Persona_UF puf ON puf.DNI = per.DNI
        INNER JOIN Unidad_Funcional uf ON uf.id_uf = puf.id_uf
        INNER JOIN Expensa e ON e.id_consorcio = @id_consorcio
        INNER JOIN Expensa_Detalle ed ON ed.id_expensa = e.id_expensa
        WHERE ed.fecha_venc BETWEEN @fecha_inicio AND @fecha_fin
        GROUP BY per.DNI
    ),

    Pagos AS (
        SELECT 
            per.DNI,
            SUM(DISTINCT p.valor) AS pagos_pesos   -- << FIX: evita duplicados
        FROM Pago p
        INNER JOIN Persona per ON per.cbu_cvu = p.cvu_cbu
        INNER JOIN Expensa_Detalle ed ON ed.id_exp_detalle = p.id_exp_detalle
        INNER JOIN Expensa e ON e.id_expensa = ed.id_expensa
        WHERE e.id_consorcio = @id_consorcio
          AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin
        GROUP BY per.DNI
    )

    SELECT TOP 3
        per.DNI,
        per.nombre,
        per.apellido,
        per.email_personal,
        per.telefono,
        ROUND(CASE 
                WHEN c.cargos_pesos - ISNULL(p.pagos_pesos,0) < 0 THEN 0
                ELSE c.cargos_pesos - ISNULL(p.pagos_pesos,0)
              END,2) AS monto_deuda_pesos,
        ROUND(
              CASE 
                WHEN c.cargos_pesos - ISNULL(p.pagos_pesos,0) < 0 THEN 0
                ELSE (c.cargos_pesos - ISNULL(p.pagos_pesos,0)) / @venta
              END,2
        ) AS monto_deuda_usd
    FROM Cargos c
    INNER JOIN Persona per ON per.DNI = c.DNI
    LEFT JOIN Pagos p ON p.DNI = c.DNI
    WHERE c.cargos_pesos - ISNULL(p.pagos_pesos,0) > 0   -- Solo morosos reales
    ORDER BY monto_deuda_pesos DESC
    FOR XML PATH('Propietario'), ROOT('Morosos');

END
GO

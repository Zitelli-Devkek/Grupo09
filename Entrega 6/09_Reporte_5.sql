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
    SELECT TOP 1 @venta = venta FROM ##DolarHistorico WHERE venta IS NOT NULL ORDER BY fecha DESC;
    IF @venta IS NULL SET @venta = 1;

    /*
      Lógica de deuda por propietario:
      - deuda = suma(importe_uf de expensa_detalle vinculada a la UF del propietario en ese periodo)
               - pagos realizados por ese propietario (mapeando Pago.cvu_cbu = Persona.cbu_cvu)
      - atribuimos Expensa_Detalle a una UF: asumimos que Expensa_Detalle tiene aplicabilidad a todas las UF,
        pero vamos a estimar deuda por UF proporcional o, mejor: si Expensa_Detalle tuviera un id_uf
        usaríamos eso. Dado que no existe, asumimos: cada Expensa_Detalle aplicado a la UF del propietario
        cuando el pago/registro esté en la fecha del periodo. (Usamos unión via Persona_UF)
    */

    ;WITH deuda_por_persona AS (
        -- total cargos (sum de importe_uf) asignados a cada propietario según su UF vigente
    SELECT
        per.DNI,
        per.nombre,
        per.apellido,
        per.email_personal,
        per.telefono,
        SUM(ISNULL(ed.importe_uf,0)) AS total_cargos_pesos
    FROM Persona per
    LEFT JOIN Persona_UF puf ON puf.DNI = per.DNI
    LEFT JOIN Unidad_Funcional uf ON uf.id_uf = puf.id_uf
    LEFT JOIN Expensa e ON e.id_consorcio = @id_consorcio
    LEFT JOIN Expensa_Detalle ed ON ed.id_expensa = e.id_expensa
        AND ed.fecha_venc BETWEEN @fecha_inicio AND @fecha_fin
    WHERE per.id_tipo_ocupante IS NOT NULL
    GROUP BY per.DNI, per.nombre, per.apellido, per.email_personal, per.telefono 
    ),
    pagos_por_persona AS (
        -- pagos realizados por persona (mapeo por cuenta)
    SELECT
        per.DNI,
        SUM(p.valor) AS total_pagos_pesos
    FROM Pago p
    LEFT JOIN Persona per ON per.cbu_cvu = p.cvu_cbu
    LEFT JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
    LEFT JOIN Expensa e ON ed.id_expensa = e.id_expensa
    WHERE e.id_consorcio = @id_consorcio
      AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin
    GROUP BY per.DNI 
    ),
    resumen AS (
        SELECT
            d.DNI,
            d.nombre,
            d.apellido,
            d.email_personal,
            d.telefono,
            COALESCE(d.total_cargos_pesos,0) - COALESCE(pp.total_pagos_pesos,0) AS monto_deuda_pesos
        FROM deuda_por_persona d
        LEFT JOIN pagos_por_persona pp ON pp.DNI = d.DNI
    )
    SELECT TOP 3
        DNI,
        nombre,
        apellido,
        email_personal,
        telefono,
        monto_deuda_pesos,
        ROUND(monto_deuda_pesos / @venta,2) AS monto_deuda_usd
    FROM resumen
    ORDER BY monto_deuda_pesos DESC
    FOR XML PATH('Propietario'), ROOT('Morosos');
END
GO
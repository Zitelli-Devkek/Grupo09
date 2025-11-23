/*
-- =================================================================
-- Asignatura: Bases de Datos Aplicada
-- Comisión: 01-2900 
-- Grupo Nro: 09
-- Fecha de Entrega:
--
-- Enunciado: Descifrado de reporte 5 para ver datos.
-- =================================================================
-- Integrantes:
-- Jiménez Damián (DNI 43.194.984)
-- Mendoza Gonzalo (DNI 44.597.456)
-- Demis Colman (DNI 37.174.947)
-- Feiertag Mateo (DNI 46.293.138)
-- Suriano Lautaro (DNI 44.792.129)
-- Zitelli Emanuel (DNI 45.064.107)
-- =================================================================
*/




CREATE OR ALTER PROCEDURE dbo.spReportTop3MorososXML
    @id_consorcio INT,
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- llave de cifrado 
    OPEN SYMMETRIC KEY SK_DatosSensibles
    DECRYPTION BY CERTIFICATE Cert_DatosSensibles;

    BEGIN TRY

        DECLARE @venta DECIMAL(18,6) = NULL;
        SELECT TOP 1 @venta = venta FROM ##DolarHistorico WHERE venta IS NOT NULL ORDER BY fecha DESC;
        IF @venta IS NULL SET @venta = 1;

        ;WITH deuda_por_persona AS (
            --
            -- NOTA: DNI, email_personal, telefono están AÚN cifrados (VARBINARY) aquí.
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
            
            --  Descifrar 'cbu_cvu' para el JOIN
            LEFT JOIN Persona per 
                ON CONVERT(VARCHAR, DECRYPTBYKEY(per.cbu_cvu)) = p.cvu_cbu
                
            LEFT JOIN Expensa_Detalle ed ON p.id_exp_detalle = ed.id_exp_detalle
            LEFT JOIN Expensa e ON ed.id_expensa = e.id_expensa
            WHERE e.id_consorcio = @id_consorcio
                AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin
            GROUP BY per.DNI
        ),
        resumen AS (
--
            SELECT
                d.DNI,
                d.nombre,
                d.apellido,
                d.email_personal,
                d.telefono,
                COALESCE(d.total_cargos_pesos,0) - COALESCE(pp.total_pagos_pesos,0) AS monto_deuda_pesos
            FROM deuda_por_persona d
            LEFT JOIN pagos_por_persona pp ON pp.DNI = d.DNI -- (Este JOIN es VARBINARY = VARBINARY, está OK)
        )
        --  Descifrar los datos en el SELECT final
        SELECT TOP 3
            CONVERT(VARCHAR, DECRYPTBYKEY(DNI)) AS DNI,
            nombre,
            apellido,
            CONVERT(VARCHAR, DECRYPTBYKEY(email_personal)) AS email_personal,
            CONVERT(VARCHAR, DECRYPTBYKEY(telefono)) AS telefono,
            monto_deuda_pesos,
            ROUND(monto_deuda_pesos / @venta,2) AS monto_deuda_usd
        FROM resumen
        ORDER BY monto_deuda_pesos DESC
        FOR XML PATH('Propietario'), ROOT('Morosos');

        -- llave de cifrado 
        CLOSE SYMMETRIC KEY SK_DatosSensibles;

    END TRY
    BEGIN CATCH
        -- Asegurarse de cerrar la llave si hay un error
        IF (SELECT key_guid('SK_DatosSensibles') FROM sys.open_keys) IS NOT NULL
            CLOSE SYMMETRIC KEY SK_DatosSensibles;
        
        PRINT 'Error al generar el reporte de morosos cifrado.';
        THROW; -- Muestra el error original
    END CATCH
END
GO

EXEC dbo.spReportTop3MorososXML
    @id_consorcio = 1,
    @fecha_inicio = '2025-01-01',
    @fecha_fin = '2026-10-31';

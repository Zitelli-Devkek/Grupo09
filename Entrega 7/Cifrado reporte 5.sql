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

USE AltosSaintJust 
GO

CREATE OR ALTER PROCEDURE sp_Reporte5_MayorMorosidad
    @Anio INT,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        OPEN SYMMETRIC KEY SK_DatosSensibles 
        DECRYPTION BY CERTIFICATE Cert_DatosSensibles; 

        SELECT TOP 3
            CONVERT(VARCHAR, DECRYPTBYKEY(per.DNI)) AS '@DNI',
            per.nombre AS 'Nombre',
            per.apellido AS 'Apellido',
            CONVERT(VARCHAR, DECRYPTBYKEY(per.email_personal)) AS 'Email',
            CONVERT(VARCHAR, DECRYPTBYKEY(per.telefono)) AS 'Telefono',
            COUNT(*) AS 'CantidadVencidas'
        FROM Expensa_Detalle ed
        INNER JOIN Expensa e ON e.id_expensa = ed.id_expensa
        INNER JOIN Unidad_Funcional uf ON uf.id_uf = e.id_uf
        INNER JOIN Persona_UF p ON p.id_uf = uf.id_uf
        INNER JOIN Persona per ON per.DNI_Cifrado = p.DNI_Cifrado -- (IMPORTANTE: Asegúrate de unir por la columna cifrada/PK correcta)
        WHERE ed.estado = 'Vencido'
          AND YEAR(e.vencimiento) = @Anio
          AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
        GROUP BY per.DNI_Cifrado, per.nombre, per.apellido, per.email_personal, per.telefono 

        ORDER BY CantidadVencidas DESC
        FOR XML PATH('Moroso'), ROOT('MayoresMorosos'), ELEMENTS;

        CLOSE SYMMETRIC KEY SK_DatosSensibles;

    END TRY
    BEGIN CATCH
        IF (SELECT key_guid('SK_DatosSensibles') FROM sys.open_keys) IS NOT NULL
            CLOSE SYMMETRIC KEY SK_DatosSensibles;
        
        PRINT 'Error al generar el reporte de morosos cifrado.';
        THROW;
    END CATCH
END;
GO

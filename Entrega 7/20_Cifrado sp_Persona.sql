/*
-- =================================================================
-- Asignatura: Bases de Datos Aplicada
-- Comisión: 01-2900 
-- Grupo Nro: 09
-- Fecha de Entrega:
--
-- Enunciado: Cifrado de datos sensibles tabla persona.
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

USE Com2900G09;
GO


CREATE OR ALTER PROCEDURE spimportar_csv_inquilino_propietarios_datos
    @rutaArchivo NVARCHAR(500) 
AS
BEGIN
    SET NOCOUNT ON;

--
    IF OBJECT_ID('tempdb..#inquilino_propietarios_datos_tmp') IS NOT NULL
        DROP TABLE #inquilino_propietarios_datos_tmp;

    CREATE TABLE #inquilino_propietarios_datos_tmp (
        nombre NVARCHAR(100),
        apellido NVARCHAR(100),
        DNI NVARCHAR(50),
        email_personal NVARCHAR(100),
        telefono NVARCHAR(50),
        cbu_cvu NVARCHAR(22),
        inquilino NVARCHAR(10)
    );

    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #inquilino_propietarios_datos_tmp
            FROM ''' + @rutaArchivo + N'''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''ACP''
            );
        ';
        EXEC sp_executesql @sql;

        INSERT INTO Tipo_Ocupante (descripcion)
SELECT 
    CASE 
        WHEN TRY_CONVERT(INT, inquilino) = 1 THEN 'Inquilino'
        WHEN TRY_CONVERT(INT, inquilino) = 0 THEN 'Propietario'
    END
FROM #inquilino_propietarios_datos_tmp
WHERE TRY_CONVERT(INT, inquilino) IN (0, 1)

        --  CIFRAR Y GUARDAR 

        OPEN SYMMETRIC KEY SK_DatosSensibles 
        DECRYPTION BY CERTIFICATE Cert_DatosSensibles;

        INSERT INTO Persona (
            DNI, --  cifrada
            id_tipo_ocupante, 
            nombre, 
            apellido, 
            email_personal, --  cifrada
            telefono, --  cifrada
            cbu_cvu --  cifrada
        )
        SELECT 
            --  Cifrar los datos 
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), TRY_CONVERT(CHAR(8), t.DNI)),
            1, -- tipo_ocupante
            t.nombre,
            t.apellido,
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), t.email_personal),
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), t.telefono),
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), t.cbu_cvu)
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY TRY_CONVERT(CHAR(8), DNI) ORDER BY (SELECT NULL)) AS rn
            FROM #inquilino_propietarios_datos_tmp
        ) AS t
        WHERE rn = 1
          AND TRY_CONVERT(INT, t.DNI) BETWEEN 10000000 AND 99999999
          AND NOT EXISTS (
                -- Descifrar el DNI  para comparar
                SELECT 1 FROM Persona AS p 
                WHERE CONVERT(VARCHAR, DECRYPTBYKEY(p.DNI)) = TRY_CONVERT(CHAR(8), t.DNI)
          );
        
        -- Cerrar la llave
        CLOSE SYMMETRIC KEY SK_DatosSensibles;


    END TRY
    BEGIN CATCH
        -- Asegurarse de cerrar la llave si hay un error
        IF (SELECT key_guid('SK_DatosSensibles') FROM sys.open_keys) IS NOT NULL
            CLOSE SYMMETRIC KEY SK_DatosSensibles;
        
        PRINT 'Error: No se pudo importar el archivo .csv';
        THROW;
    END CATCH
END;
GO


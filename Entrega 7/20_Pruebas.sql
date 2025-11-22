IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'ClaveMaestraSegura2024';
END
GO

IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CertificadoDatosSensibles')
BEGIN
    CREATE CERTIFICATE CertificadoDatosSensibles
    WITH SUBJECT = 'Cifrado de datos personales';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.symmetric_keys WHERE name = 'LlaveDatosSensibles'
)
BEGIN
    CREATE SYMMETRIC KEY LlaveDatosSensibles
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE CertificadoDatosSensibles;
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE Name = N'DNI_Cifrado' AND Object_ID = Object_ID('Persona')
)
BEGIN
    ALTER TABLE Persona ADD DNI_Cifrado VARBINARY(MAX);
END

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE Name = N'Email_Cifrado' AND Object_ID = Object_ID('Persona')
)
BEGIN
    ALTER TABLE Persona ADD Email_Cifrado VARBINARY(MAX);
END
GO

CREATE OR ALTER TRIGGER trg_CifrarDatosPersona
ON Persona
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Verifico existencia de llave/certificado
        IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'LlaveDatosSensibles')
        BEGIN
            INSERT INTO ErrorLogs (tipo_archivo,nombre_archivo,origen_sp,campo_error,error_descripcion)
            VALUES ('CIFRADO','-','trg_CifrarDatosPersona','LlaveMissing','LlaveDatosSensibles no existe en la BD');
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'CertificadoDatosSensibles')
        BEGIN
            INSERT INTO ErrorLogs (tipo_archivo,nombre_archivo,origen_sp,campo_error,error_descripcion)
            VALUES ('CIFRADO','-','trg_CifrarDatosPersona','CertificadoMissing','CertificadoDatosSensibles no existe en la BD');
            RETURN;
        END

        -- Abrir la llave simétrica
        OPEN SYMMETRIC KEY LlaveDatosSensibles
            DECRYPTION BY CERTIFICATE CertificadoDatosSensibles;

        -- Actualizo las filas afectadas (multi-row safe)
        ;WITH src AS (
            SELECT DISTINCT LTRIM(RTRIM(CONVERT(NVARCHAR(50), i.DNI))) AS DNI_i,
                            LTRIM(RTRIM(CONVERT(NVARCHAR(200), i.email_personal))) AS email_i
            FROM inserted i
        )
        UPDATE p
        SET
            DNI_Cifrado = EncryptByKey(Key_GUID('LlaveDatosSensibles'), s.DNI_i),
            Email_Cifrado = EncryptByKey(Key_GUID('LlaveDatosSensibles'), s.email_i)
        FROM Persona p
        INNER JOIN src s ON LTRIM(RTRIM(CONVERT(NVARCHAR(50), p.DNI))) = s.DNI_i;

        CLOSE SYMMETRIC KEY LlaveDatosSensibles;
    END TRY
    BEGIN CATCH
        DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
        INSERT INTO ErrorLogs (tipo_archivo,nombre_archivo,origen_sp,campo_error,error_descripcion)
        VALUES ('CIFRADO','-','trg_CifrarDatosPersona','TriggerError', @err);
        -- intentar cerrar la llave si estaba abierta
        BEGIN TRY
            CLOSE SYMMETRIC KEY LlaveDatosSensibles;
        END TRY
        BEGIN CATCH
        END CATCH;
    END CATCH;
END;
GO





OPEN SYMMETRIC KEY LlaveDatosSensibles
    DECRYPTION BY CERTIFICATE CertificadoDatosSensibles;

SELECT  
    CONVERT(VARCHAR(200), DecryptByKey(DNI_Cifrado)) AS DNI_Desencriptado,
    CONVERT(VARCHAR(200), DecryptByKey(Email_Cifrado)) AS Email_Desencriptado,
    Nombre,
    email_personal,
    DNI
FROM Persona;

SELECT  
    *
FROM Persona;

CLOSE SYMMETRIC KEY LlaveDatosSensibles;


-- Abrir key (si no puede abrir, dará error)
OPEN SYMMETRIC KEY LlaveDatosSensibles DECRYPTION BY CERTIFICATE CertificadoDatosSensibles;
SELECT EncryptByKey(Key_GUID('LlaveDatosSensibles'), CONVERT(NVARCHAR(50), '20333444')) AS Prueba_Encrypt;
CLOSE SYMMETRIC KEY LlaveDatosSensibles;

OPEN SYMMETRIC KEY LlaveDatosSensibles DECRYPTION BY CERTIFICATE CertificadoDatosSensibles;

SELECT CONVERT(NVARCHAR(50), DecryptByKey(DNI_Cifrado)) AS DNI_Desencriptado
FROM Persona
WHERE DNI_Cifrado IS NOT NULL;

CLOSE SYMMETRIC KEY LlaveDatosSensibles;

SELECT name, is_disabled
FROM sys.triggers
WHERE name = 'trg_CifrarDatosPersona';

-- Asegurate que la llave y certificado existen antes
OPEN SYMMETRIC KEY LlaveDatosSensibles DECRYPTION BY CERTIFICATE CertificadoDatosSensibles;

UPDATE Persona
SET
    DNI_Cifrado = EncryptByKey(Key_GUID('LlaveDatosSensibles'), CONVERT(NVARCHAR(50), DNI)),
    Email_Cifrado = EncryptByKey(Key_GUID('LlaveDatosSensibles'), CONVERT(NVARCHAR(200), email_personal))
WHERE (DNI_Cifrado IS NULL OR Email_Cifrado IS NULL)
  AND (DNI IS NOT NULL OR email_personal IS NOT NULL);

CLOSE SYMMETRIC KEY LlaveDatosSensibles;


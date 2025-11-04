CREATE OR ALTER PROCEDURE sp_importar_csv_persona
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        OPEN SYMMETRIC KEY SK_DatosSensibles 
        DECRYPTION BY CERTIFICATE Cert_DatosSensibles;

        MERGE INTO persona AS Target
        USING sp_importar_csv_persona AS Source
        ON (Target.IdPersona = Source.IdPersona)

        WHEN MATCHED THEN
            UPDATE SET
                Target.Nombre = Source.Nombre,
                Target.Apellido = Source.Apellido,
                Target.DNI = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), Source.DNI),
                Target.email_personal = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), Source.email_personal),
                Target.telefono = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), Source.telefono),
                Target.cbu_cvu = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), Source.cbu_cvu)

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (IdPersona, Nombre, Apellido, DNI, Email, Telefono, CVU_CBU)
            VALUES (
                Source.IdPersona, Source.Nombre, Source.Apellido,
                ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), Source.DNI),
                ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), Source.email_personal),
                ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), Source.telefono),
                ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), Source.cbu_cvu)
            );


        CLOSE SYMMETRIC KEY SK_DatosSensibles;
        

    END TRY
    BEGIN CATCH
        IF (SELECT key_guid('SK_DatosSensibles') FROM sys.open_keys) IS NOT NULL
            CLOSE SYMMETRIC KEY SK_DatosSensibles;
        
        PRINT 'Error: No se pudo procesar el staging cifrado';
        THROW;
    END CATCH
END
GO

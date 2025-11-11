/*
-- =================================================================
-- Asignatura: Bases de Datos Aplicada
-- Comisión: 01-2900 
-- Grupo Nro: 09
-- Fecha de Entrega:
--
-- Enunciado: Creacion de Key y cifrado.
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

BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password09';
END
GO


BEGIN
    CREATE CERTIFICATE Cert_DatosSensibles WITH SUBJECT = 'Certificado para cifrado de datos personales';
END
GO


BEGIN
    CREATE SYMMETRIC KEY SK_DatosSensibles
    ENCRYPTION BY CERTIFICATE Cert_DatosSensibles;
END
GO





OPEN SYMMETRIC KEY SK_DatosSensibles
DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
GO

-- --- Cifrar Tabla [Persona] ---


ALTER TABLE Persona ADD DNI_Enc VARBINARY(256);
ALTER TABLE Persona ADD Email_Enc VARBINARY(256);
ALTER TABLE Persona ADD Telefono_Enc VARBINARY(256);
ALTER TABLE Persona ADD CVU_CBU_Enc VARBINARY(256);
GO


UPDATE Persona
SET 
    DNI_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), DNI),
    Email_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), email_personal),
    Telefono_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), telefono),
    CVU_CBU_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), cbu_cvu);
GO


ALTER TABLE Persona DROP COLUMN DNI;
ALTER TABLE Persona DROP COLUMN email_personal;
ALTER TABLE Persona DROP COLUMN telefono;
ALTER TABLE Persona DROP COLUMN cbu_cvu;
GO


EXEC sp_rename 'Persona.DNI_Enc', 'DNI', 'COLUMN';
EXEC sp_rename 'Persona.Email_Enc', 'Email', 'COLUMN';
EXEC sp_rename 'Persona.Telefono_Enc', 'Telefono', 'COLUMN';
EXEC sp_rename 'Persona.CVU_CBU_Enc', 'CVU_CBU', 'COLUMN';
GO

CLOSE SYMMETRIC KEY SK_DatosSensibles;
GO







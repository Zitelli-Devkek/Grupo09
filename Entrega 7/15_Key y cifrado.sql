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

IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password09';
GO
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'Cert_DatosSensibles')
    CREATE CERTIFICATE Cert_DatosSensibles WITH SUBJECT = 'Certificado para cifrado de datos personales';
GO
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'SK_DatosSensibles')
    CREATE SYMMETRIC KEY SK_DatosSensibles WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE Cert_DatosSensibles;
GO

OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
GO


IF EXISTS(SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'DNI_Enc')
    ALTER TABLE Persona DROP COLUMN DNI_Enc;
IF EXISTS(SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'Email_Enc')
    ALTER TABLE Persona DROP COLUMN Email_Enc;
IF EXISTS(SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'Telefono_Enc')
    ALTER TABLE Persona DROP COLUMN Telefono_Enc;
IF EXISTS(SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'CVU_CBU_Enc')
    ALTER TABLE Persona DROP COLUMN CVU_CBU_Enc;
GO


DECLARE @sqlLimpieza NVARCHAR(MAX) = '';

--  DROP de Foreign Keys que apunten a Persona 
SELECT @sqlLimpieza += 'ALTER TABLE ' + OBJECT_NAME(parent_object_id) + 
       ' DROP CONSTRAINT ' + name + ';' + CHAR(13)
FROM sys.foreign_keys
WHERE referenced_object_id = OBJECT_ID('Persona');

--  DROP de Defaults y Checks en la tabla Persona
SELECT @sqlLimpieza += 'ALTER TABLE Persona DROP CONSTRAINT ' + name + ';' + CHAR(13)
FROM sys.objects
WHERE parent_object_id = OBJECT_ID('Persona')
  AND type IN ('D', 'C') -- D=Default, C=Check
  AND object_id IN (
      SELECT default_object_id FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name IN ('DNI', 'email_personal', 'telefono', 'cbu_cvu')
      UNION
      SELECT object_id FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID('Persona') -- Checks a nivel tabla o columna
  );

-- DROP de la Primary Key
SELECT @sqlLimpieza += 'ALTER TABLE Persona DROP CONSTRAINT ' + name + ';' + CHAR(13)
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('Persona') AND type = 'PK';


IF @sqlLimpieza <> ''
BEGIN
    PRINT @sqlLimpieza; 
    EXEC sp_executesql @sqlLimpieza;
END
GO


ALTER TABLE Persona ADD 
    DNI_Enc VARBINARY(256),
    Email_Enc VARBINARY(256),
    Telefono_Enc VARBINARY(256),
    CVU_CBU_Enc VARBINARY(256);
GO

UPDATE Persona SET 
    DNI_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), DNI),
    Email_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), email_personal),
    Telefono_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), telefono),
    CVU_CBU_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), cbu_cvu);
GO

ALTER TABLE Persona DROP COLUMN cbu_cvu;
ALTER TABLE Persona DROP COLUMN telefono;
ALTER TABLE Persona DROP COLUMN DNI;
ALTER TABLE Persona DROP COLUMN email_personal;
GO

EXEC sp_rename 'Persona.DNI_Enc', 'DNI', 'COLUMN';
EXEC sp_rename 'Persona.Email_Enc', 'email_personal', 'COLUMN';
EXEC sp_rename 'Persona.Telefono_Enc', 'telefono', 'COLUMN';
EXEC sp_rename 'Persona.CVU_CBU_Enc', 'cbu_cvu', 'COLUMN';
GO

CLOSE SYMMETRIC KEY SK_DatosSensibles;
GO

SELECT * FROM Persona;

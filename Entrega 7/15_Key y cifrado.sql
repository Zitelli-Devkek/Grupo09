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

/* ========================================================
    1) CREACIÓN DE CLAVES SI NO EXISTEN
======================================================== */
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password09';
GO

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'Cert_DatosSensibles')
    CREATE CERTIFICATE Cert_DatosSensibles WITH SUBJECT = 'Certificado para cifrado de datos personales';
GO

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'SK_DatosSensibles')
    CREATE SYMMETRIC KEY SK_DatosSensibles WITH ALGORITHM = AES_256 
    ENCRYPTION BY CERTIFICATE Cert_DatosSensibles;
GO


/* ========================================================
    2) ELIMINAR RESTRICCIONES, CHECKS, DEFAULTS, FKs, PKs, ÚNICOS
======================================================== */

DECLARE @sql NVARCHAR(MAX) = '';

-- Foreign keys que apuntan a Persona
SELECT @sql += 'ALTER TABLE ' + QUOTENAME(OBJECT_NAME(parent_object_id)) +
               ' DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.foreign_keys
WHERE referenced_object_id = OBJECT_ID('Persona');

-- Constraints en Persona
SELECT @sql += 'ALTER TABLE Persona DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.objects
WHERE parent_object_id = OBJECT_ID('Persona')
  AND type IN ('D','C','UQ','PK');  -- Default, Check, Unique, Primary Key

-- Índices normales basados en columnas sensibles (excluye PK y UQ)
SELECT @sql += 
       'DROP INDEX ' + QUOTENAME(i.name) + ' ON Persona;' + CHAR(13)
FROM sys.indexes i
JOIN sys.index_columns ic 
    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c 
    ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('Persona')
  AND c.name IN ('DNI','email_personal','telefono','cbu_cvu')
  AND i.is_primary_key = 0
  AND i.is_unique_constraint = 0;


IF @sql <> ''
BEGIN
    PRINT @sql;
    EXEC sp_executesql @sql;
END
GO


/* ========================================================
    3) ELIMINAR COLUMNAS CIFRADAS VIEJAS SI EXISTEN
======================================================== */
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'DNI_Enc')
    ALTER TABLE Persona DROP COLUMN DNI_Enc;

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'Email_Enc')
    ALTER TABLE Persona DROP COLUMN Email_Enc;

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'Telefono_Enc')
    ALTER TABLE Persona DROP COLUMN Telefono_Enc;

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'CVU_CBU_Enc')
    ALTER TABLE Persona DROP COLUMN CVU_CBU_Enc;
GO


/* ========================================================
    4) AGREGAR COLUMNAS CIFRADAS
======================================================== */
ALTER TABLE Persona ADD
    DNI_Enc VARBINARY(256) NULL,
    Email_Enc VARBINARY(256) NULL,
    Telefono_Enc VARBINARY(256) NULL,
    CVU_CBU_Enc VARBINARY(256) NULL;
GO


/* ========================================================
    5) ACTUALIZAR CIFRADOS
======================================================== */
OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
GO

UPDATE Persona SET 
    DNI_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), DNI),
    Email_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), email_personal),
    Telefono_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), telefono),
    CVU_CBU_Enc = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), cbu_cvu);
GO

CLOSE SYMMETRIC KEY SK_DatosSensibles;
GO


/* ========================================================
    6) ELIMINAR COLUMNAS ORIGINALES
======================================================== */
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name='DNI')
    ALTER TABLE Persona DROP COLUMN DNI;

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name='email_personal')
    ALTER TABLE Persona DROP COLUMN email_personal;

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name='telefono')
    ALTER TABLE Persona DROP COLUMN telefono;

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name='cbu_cvu')
    ALTER TABLE Persona DROP COLUMN cbu_cvu;
GO


/* ========================================================
    7) RENOMBRAR COLUMNAS CIFRADAS A LOS NOMBRES ORIGINALES
======================================================== */
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name='DNI')
    EXEC sp_rename 'Persona.DNI_Enc','DNI','COLUMN';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name='email_personal')
    EXEC sp_rename 'Persona.Email_Enc','email_personal','COLUMN';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name='telefono')
    EXEC sp_rename 'Persona.Telefono_Enc','telefono','COLUMN';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name='cbu_cvu')
    EXEC sp_rename 'Persona.CVU_CBU_Enc','cbu_cvu','COLUMN';
GO


/* ========================================================
    8) RESULTADO FINAL
======================================================== */
SELECT * FROM Persona;

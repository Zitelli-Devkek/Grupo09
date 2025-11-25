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

USE Com2900G09
GO

CREATE OR ALTER PROCEDURE spimportarcsvinquilinopropietariosdatos
    @rutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Si existe la tabla temporal la elimino. Para que no tire error al ejecutar dos veces
    IF OBJECT_ID('tempdb..#inquilino_propietarios_datos_tmp') IS NOT NULL
        DROP TABLE #inquilino_propietarios_datos_tmp;

    IF OBJECT_ID('tempdb..#tmp_validos') IS NOT NULL 
        DROP TABLE #tmp_validos;

    IF OBJECT_ID('tempdb..#tmp_dup') IS NOT NULL 
        DROP TABLE #tmp_dup;

    -- Creo tabla temporal
    CREATE TABLE #inquilino_propietarios_datos_tmp (
        nombre NVARCHAR(100),
        apellido NVARCHAR(100),
        DNI NVARCHAR(50),
        email_personal NVARCHAR(100),
        telefono NVARCHAR(50),
        cbu_cvu NVARCHAR(22),
        inquilino NVARCHAR(10)
    );

    -- Me fijo si existe el archivo a importar
    DECLARE @existe INT;
    EXEC master.dbo.xp_fileexist @rutaArchivo, @existe OUTPUT;

    IF @existe = 0
    BEGIN
        RAISERROR('Escribiste mal la ruta, o el archivo no existe.', 16, 1);
        RETURN;
    END

    -- Inicio una transacción. O cargamos todo o no cargamos nada
    BEGIN TRY
        BEGIN TRAN;

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
       
        -- Hago una carga de los roles inquilino y propietario en Tipo_Ocupante
        IF NOT EXISTS (SELECT 1 FROM Tipo_Ocupante WHERE descripcion = 'Inquilino')
            INSERT INTO Tipo_Ocupante(descripcion) VALUES('Inquilino');

        IF NOT EXISTS (SELECT 1 FROM Tipo_Ocupante WHERE descripcion = 'Propietario')
            INSERT INTO Tipo_Ocupante(descripcion) VALUES('Propietario');

        DECLARE @id_inquilino INT = (SELECT id_tipo_ocupante FROM Tipo_Ocupante WHERE descripcion = 'Inquilino');
        DECLARE @id_propietario INT = (SELECT id_tipo_ocupante FROM Tipo_Ocupante WHERE descripcion = 'Propietario');

        --Guardo dni duplicados en una tabla temp_dup
        SELECT DNI
        INTO #tmp_dup
        FROM (
            SELECT DNI, COUNT(*) AS cnt
            FROM #inquilino_propietarios_datos_tmp
            WHERE DNI IS NOT NULL AND LTRIM(RTRIM(DNI)) <> ''
            GROUP BY DNI
            HAVING COUNT(*) > 1
        ) d;

        -- Normalizo espacios y valores de texto de la tabla a la que cargamos el import
        UPDATE #inquilino_propietarios_datos_tmp
        SET DNI = LTRIM(RTRIM(DNI)),
        nombre = LOWER(LTRIM(RTRIM(nombre))),
        apellido = LOWER(LTRIM(RTRIM(apellido))),
        email_personal = LOWER(LTRIM(RTRIM(email_personal))),
        telefono = LTRIM(RTRIM(telefono)),
        cbu_cvu = LTRIM(RTRIM(cbu_cvu));

         --registro los duplicados en mi errorlog
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV',
            @rutaArchivo,
            'sp_importar_csv_inquilino_propietarios_datos',
            'DNI',
            'DNI duplicado en archivo: ' + ISNULL(DNI,'<NULL>')
        FROM #tmp_dup;

        --esta validacion es por si ya tengo cargada la tabla persona a futuro y comparo para ver si existe el dni en la tabla persona
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV',
            @rutaArchivo,
            'sp_importar_csv_inquilino_propietarios_datos',
            'DNI',
            'DNI duplicado en tabla Persona: ' + t.DNI
        FROM (
            SELECT DISTINCT LTRIM(RTRIM(DNI)) AS DNI
            FROM #inquilino_propietarios_datos_tmp
            WHERE DNI IS NOT NULL AND LTRIM(RTRIM(DNI)) <> ''
        ) t
        WHERE EXISTS (SELECT 1 FROM Persona p WHERE p.DNI = TRY_CONVERT(CHAR(8), t.DNI));

        --registro en errorlog dni con digitos fuera de rango
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV',
            @rutaArchivo,
            'sp_importar_csv_inquilino_propietarios_datos',
            'DNI',
            'DNI vacío o fuera de rango (debe tener 8 dígitos): ' + ISNULL(DNI,'<NULL>')
        FROM #inquilino_propietarios_datos_tmp
        WHERE DNI IS NULL OR LEN(DNI) <> 8 OR TRY_CONVERT(INT, DNI) NOT BETWEEN 10000000 AND 99999999;

        --registro en errorlog cbu_cvu con digitos fuera de rango
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV',
            @rutaArchivo,
            'sp_importar_csv_inquilino_propietarios_datos',
            'CBU/CVU',
            'CBU/CVU inválido (debe tener 22 dígitos): ' + ISNULL(cbu_cvu,'<NULL>')
        FROM #inquilino_propietarios_datos_tmp
        WHERE cbu_cvu IS NOT NULL AND LTRIM(RTRIM(cbu_cvu)) <> '' AND LEN(REPLACE(cbu_cvu,' ','') ) <> 22;

       --registro en error log inquilinos invalidos
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV', @rutaArchivo, 'sp_importar_csv_inquilino_propietarios_datos',
            'Inquilino', 'Valor inquilino inválido (debe ser 0 o 1): ' + ISNULL(inquilino,'<NULL>')
        FROM #inquilino_propietarios_datos_tmp
        WHERE TRY_CONVERT(INT, inquilino) NOT IN (0,1);

        --registro nombres o apellidos vacios en errorlog
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV', @rutaArchivo, 'sp_importar_csv_inquilino_propietarios_datos',
            CASE WHEN nombre IS NULL OR nombre = '' THEN 'Nombre' ELSE 'Apellido' END,
            CASE WHEN nombre IS NULL OR nombre = '' THEN 'Nombre vacío' ELSE 'Apellido vacío' END
        FROM #inquilino_propietarios_datos_tmp
        WHERE nombre IS NULL OR nombre = '' OR apellido IS NULL OR apellido = '';
  

        --registro en errorlog mails invalidos
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV', @rutaArchivo, 'sp_importar_csv_inquilino_propietarios_datos',
            'Email', 'Email inválido según regla: ' + ISNULL(email_personal,'<NULL>')
        FROM #inquilino_propietarios_datos_tmp
        WHERE email_personal IS NOT NULL AND email_personal <> '' AND email_personal NOT LIKE '%_@_%._%';
  
        --llave encriptacion
        OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
        
        
        DELETE FROM #inquilino_propietarios_datos_tmp WHERE DNI IS NULL OR DNI = '' OR nombre IS NULL OR nombre = '' OR apellido IS NULL OR apellido = '';
        DELETE FROM #inquilino_propietarios_datos_tmp WHERE TRY_CONVERT(INT, DNI) NOT BETWEEN 10000000 AND 99999999;
        UPDATE #inquilino_propietarios_datos_tmp SET email_personal = REPLACE(email_personal, ' ', '') WHERE email_personal LIKE '% %';
        DELETE FROM #inquilino_propietarios_datos_tmp WHERE email_personal NOT LIKE '%@%.%' OR PATINDEX('%[^A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ@._-]%', email_personal COLLATE Latin1_General_CI_AI) > 0;
        DELETE FROM #inquilino_propietarios_datos_tmp WHERE LEN(cbu_cvu) > 22;
        DELETE FROM #inquilino_propietarios_datos_tmp WHERE inquilino NOT IN ('0','1');

        -- FIN DE FILTROS TABLA TEMPORAL


        -- Cargo los registros filtrados en la tabla Persona
INSERT INTO Persona (
            DNI,
            id_tipo_ocupante,
            nombre,
            apellido,
            email_personal,
            telefono,
            cbu_cvu
        )
        SELECT 
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), TRY_CONVERT(CHAR(8), t.DNI)), -- Cifrar DNI
            CASE WHEN t.inquilino = '1' THEN @id_inquilino ELSE @id_propietario END,
            t.nombre,
            t.apellido,
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), t.email_personal), -- Cifrar Email
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), t.telefono),       -- Cifrar Telefono
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), t.cbu_cvu)         -- Cifrar CBU
        FROM (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY TRY_CONVERT(CHAR(8), DNI) ORDER BY (SELECT NULL)) AS rn
            FROM #inquilino_propietarios_datos_tmp
        ) AS t
        WHERE rn = 1
          -- Validación final de duplicados (usando DECRYPTBYKEY)
          AND NOT EXISTS (
                SELECT 1 FROM Persona AS p 
                WHERE CONVERT(VARCHAR, DECRYPTBYKEY(p.DNI)) = TRY_CONVERT(CHAR(8), t.DNI)
          );

        -- cerrar llave
        CLOSE SYMMETRIC KEY SK_DatosSensibles;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        PRINT 'Error: Lo siento, no se pudo importar el archivo .csv';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

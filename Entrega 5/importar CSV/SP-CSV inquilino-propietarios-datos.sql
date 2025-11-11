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

Consigna: En este script se importa el archivo inquilino-propietarios-datos.csv y se carga en las tablas "Tipo_Ocupante" y "Persona"
*/
USE Com2900G09;
GO

CREATE OR ALTER PROCEDURE sp_importar_csv_inquilino_propietarios_datos
    @rutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Si existe la tabla temporal la elimino. Para que no tire error al ejecutar dos veces
    IF OBJECT_ID('tempdb..#inquilino_propietarios_datos_tmp') IS NOT NULL
        DROP TABLE #inquilino_propietarios_datos_tmp;

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

        -- Toda esta sección es de limpieza de datos de la tabla temporal.

        -- 1. Normalizo espacios y valores de texto
        UPDATE #inquilino_propietarios_datos_tmp
        SET DNI = LTRIM(RTRIM(DNI)),
            nombre = LTRIM(RTRIM(nombre)),
            apellido = LTRIM(RTRIM(apellido)),
            email_personal = LTRIM(RTRIM(email_personal)),
            telefono = LTRIM(RTRIM(telefono)),
            cbu_cvu = LTRIM(RTRIM(cbu_cvu));

        -- 2. Elimino registros con campos obligatorios vacíos
        DELETE FROM #inquilino_propietarios_datos_tmp
        WHERE DNI IS NULL OR DNI = ''
           OR nombre IS NULL OR nombre = ''
           OR apellido IS NULL OR apellido = '';

        -- 3. Elimino DNIs no numéricos o fuera de un rango apropiado
        DELETE FROM #inquilino_propietarios_datos_tmp
        WHERE TRY_CONVERT(INT, DNI) NOT BETWEEN 10000000 AND 99999999;

        -- 4. Limpieza de mails
        -- 4.1 Elimino espacios dentro del mail
        UPDATE #inquilino_propietarios_datos_tmp
        SET email_personal = REPLACE(email_personal, ' ', '')
        WHERE email_personal LIKE '% %';

        -- 4.2. Elimino mails con estructuras incorrectas o con símbolos raros
        DELETE FROM #inquilino_propietarios_datos_tmp
        WHERE 
            email_personal NOT LIKE '%@%.%'                                   -- estructura básica inválida
            OR PATINDEX('%[^A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ@._-]%', email_personal COLLATE Latin1_General_CI_AI) > 0  -- caracteres no permitidos
            OR email_personal LIKE '%¥%'                                      -- símbolo de yen
            OR email_personal LIKE '%.@%' OR email_personal LIKE '%..%'       -- punto mal ubicado
            OR email_personal LIKE '%@%@%';                                   -- doble @

        -- 5. Elimino CBU/CVU demasiado largos
        DELETE FROM #inquilino_propietarios_datos_tmp
        WHERE LEN(cbu_cvu) > 22;

        -- 6. Elimino registros con valores no válidos de “inquilino”
        DELETE FROM #inquilino_propietarios_datos_tmp
        WHERE inquilino NOT IN ('0','1');
        -- FIN DE FILTROS TABLA TEMPORAL
       
        -- Hago una carga de los roles inquilino y propietario en Tipo_Ocupante
        IF NOT EXISTS (SELECT 1 FROM Tipo_Ocupante WHERE descripcion = 'Inquilino')
            INSERT INTO Tipo_Ocupante(descripcion) VALUES('Inquilino');

        IF NOT EXISTS (SELECT 1 FROM Tipo_Ocupante WHERE descripcion = 'Propietario')
            INSERT INTO Tipo_Ocupante(descripcion) VALUES('Propietario');

        DECLARE @id_inquilino INT = (SELECT id_tipo_ocupante FROM Tipo_Ocupante WHERE descripcion = 'Inquilino');
        DECLARE @id_propietario INT = (SELECT id_tipo_ocupante FROM Tipo_Ocupante WHERE descripcion = 'Propietario');

        -- Cargo los registros filtrados en la tabla Persona
        INSERT INTO Persona (DNI, id_tipo_ocupante, nombre, apellido, email_personal, telefono, cbu_cvu)
        SELECT 
            TRY_CONVERT(CHAR(8), t.DNI),
            CASE WHEN t.inquilino = '1' THEN @id_inquilino ELSE @id_propietario END,
            t.nombre,
            t.apellido,
            t.email_personal,
            t.telefono,
            t.cbu_cvu
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY TRY_CONVERT(CHAR(8), DNI) ORDER BY (SELECT NULL)) AS rn
            FROM #inquilino_propietarios_datos_tmp
        ) AS t
        WHERE rn = 1
          AND NOT EXISTS (
                SELECT 1 FROM Persona AS p 
                WHERE p.DNI = TRY_CONVERT(CHAR(8), t.DNI)
          );

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
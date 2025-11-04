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

    -- Borrar tabla temporal si ya existe
    IF OBJECT_ID('tempdb..#inquilino_propietarios_datos_tmp') IS NOT NULL
        DROP TABLE #inquilino_propietarios_datos_tmp;

    -- Crear tabla temporal
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
WHERE TRY_CONVERT(INT, inquilino) IN (0, 1);

        -- Inserción a tabla Persona (ignorando el campo "inquilino")
        INSERT INTO Persona (DNI, id_tipo_ocupante, nombre, apellido, email_personal, telefono, cbu_cvu)
        SELECT 
            TRY_CONVERT(CHAR(8), t.DNI),
            1,
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
          AND TRY_CONVERT(INT, t.DNI) BETWEEN 10000000 AND 99999999
          AND NOT EXISTS (
                SELECT 1 FROM Persona AS p 
                WHERE p.DNI = TRY_CONVERT(CHAR(8), t.DNI)
          );

    END TRY
    BEGIN CATCH
        PRINT 'Error: No se pudo importar el archivo .csv';
        THROW;
    END CATCH
END;
GO
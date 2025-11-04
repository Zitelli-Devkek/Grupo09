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

Consigna: En este script se importa el archivo inquilino-propietarios-UF.csv y se carga en las tablas "Consorcio" y "Unidad_Funcional"
*/
USE Com2900G09;
GO

CREATE OR ALTER PROCEDURE sp_importar_csv_inquilino_propietarios_UF
    @rutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Borramos si ya existía la tabla temporal
    IF OBJECT_ID('tempdb..#uf_tmp') IS NOT NULL DROP TABLE #uf_tmp;

    -- Estructura temporal según el CSV
    CREATE TABLE #uf_tmp (
        cbu_cvu NVARCHAR(50),
        nombre_consorcio NVARCHAR(100),
        nroUnidadFuncional NVARCHAR(50),
        piso NVARCHAR(20),
        departamento NVARCHAR(50)
    );

    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX);

        -- Carga del CSV
        SET @sql = N'
            BULK INSERT #uf_tmp
            FROM ''' + @rutaArchivo + N'''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''|'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''ACP'',
                TABLOCK
            );
        ';
        EXEC sp_executesql @sql;

        -------------------------------------------------------
        -- Inserción a CONSORCIO (solo si no existen)
        -------------------------------------------------------
        INSERT INTO Consorcio (nombre, direccion, admin_nombre, admin_cuit, admin_email, cbu_cvu)
        SELECT DISTINCT 
            RTRIM(LTRIM(t.nombre_consorcio)) AS nombre,
            'Desconocida' AS direccion,
            NULL AS admin_nombre,
            RIGHT('00000000000' + CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(11)), 11) AS admin_cuit,  -- CUIT ficticio único
            NULL AS admin_email,
            LEFT(RTRIM(LTRIM(t.cbu_cvu)), 22) AS cbu_cvu
        FROM #uf_tmp AS t
        WHERE RTRIM(LTRIM(t.nombre_consorcio)) NOT IN (
            SELECT nombre FROM Consorcio
        );

        -------------------------------------------------------
        -- Inserción a UNIDAD_FUNCIONAL
        -------------------------------------------------------
        INSERT INTO Unidad_Funcional (id_consorcio, nr_uf, piso, departamento, coeficiente, m2)
        SELECT 
            c.id_consorcio,
            TRY_CONVERT(INT, t.nroUnidadFuncional) AS nr_uf,
            NULLIF(RTRIM(LTRIM(t.piso)), '') AS piso,
            NULLIF(RTRIM(LTRIM(t.departamento)), '') AS departamento,
            0.000 AS coeficiente,   -- valor por defecto
            1.00 AS m2              -- valor por defecto
        FROM #uf_tmp AS t
        INNER JOIN Consorcio AS c
            ON c.nombre = RTRIM(LTRIM(t.nombre_consorcio))
        WHERE TRY_CONVERT(INT, t.nroUnidadFuncional) IS NOT NULL
          AND NOT EXISTS (
                SELECT 1 FROM Unidad_Funcional uf
                WHERE uf.nr_uf = TRY_CONVERT(INT, t.nroUnidadFuncional)
                  AND uf.id_consorcio = c.id_consorcio
          );

    END TRY
    BEGIN CATCH
        PRINT 'Error: No se pudo importar el archivo .csv';
        THROW;
    END CATCH
END;
GO
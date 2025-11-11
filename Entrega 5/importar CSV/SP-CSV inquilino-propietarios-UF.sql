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

    DECLARE @fileExists INT;
    -- 1. Valido que existe el archivo
    EXEC master.dbo.xp_fileexist @rutaArchivo, @fileExists OUTPUT;

    IF @fileExists = 0
    BEGIN
        RAISERROR('Error: El archivo especificado no existe o la ruta es inválida.', 16, 1); -- parametros de 1. nivel de gravedad 2. state, para diferenciar distintos raiserror
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        -- 2. Cargo el CSV en una tabla temporal
        IF OBJECT_ID('tempdb..#uf_tmp') IS NOT NULL
            DROP TABLE #uf_tmp;

        CREATE TABLE #uf_tmp (
            cbu_cvu NVARCHAR(50),
            nombre_consorcio NVARCHAR(100),
            nroUnidadFuncional NVARCHAR(50),
            piso NVARCHAR(20),
            departamento NVARCHAR(50)
        );

        DECLARE @sql NVARCHAR(MAX);
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
        -- 3. Sección de filtros sobre la tabla temporal

        -- 3.1 Normalizo los espacios
        UPDATE #uf_tmp
        SET 
            cbu_cvu = LTRIM(RTRIM(cbu_cvu)),
            nombre_consorcio = LTRIM(RTRIM(nombre_consorcio)),
            nroUnidadFuncional = LTRIM(RTRIM(nroUnidadFuncional)),
            piso = LTRIM(RTRIM(piso)),
            departamento = LTRIM(RTRIM(departamento));

        -- 3.2 Elimino registros con nombre de consorcio vacío
        DELETE FROM #uf_tmp
        WHERE nombre_consorcio IS NULL OR nombre_consorcio = '';

        -- 3.3 Elimino registros con nroUnidadFuncional no numérico o nulo
        DELETE FROM #uf_tmp
        WHERE TRY_CONVERT(INT, nroUnidadFuncional) IS NULL;

        -- 3.4 Limito el largo del cbu o cvu
        DELETE FROM #uf_tmp
        WHERE LEN(cbu_cvu) > 22;

        -- 3.5 Elimino duplicados
        ;WITH cte AS (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY nombre_consorcio, nroUnidadFuncional ORDER BY (SELECT NULL)) AS rn
            FROM #uf_tmp
        )
        DELETE FROM cte WHERE rn > 1;

        -- Carga de registros totales


        -- Inserto registros en Consorcio
        INSERT INTO Consorcio (nombre, cuit, cbu_cvu)
        SELECT DISTINCT 
            t.nombre_consorcio AS nombre,
            RIGHT('00000000000' + CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(11)), 11) AS cuit,
            LEFT(t.cbu_cvu, 22) AS cbu_cvu
        FROM #uf_tmp AS t
        WHERE NOT EXISTS (
            SELECT 1 FROM Consorcio WHERE nombre = t.nombre_consorcio
        );

        -- Inserto registros en Unidad_Funcional 
        INSERT INTO Unidad_Funcional (id_consorcio, nr_uf, piso, departamento, coeficiente, m2)
        SELECT 
            c.id_consorcio,
            TRY_CONVERT(INT, t.nroUnidadFuncional),
            NULLIF(t.piso, ''),
            NULLIF(t.departamento, ''),
            0.000,
            1.00
        FROM #uf_tmp AS t
        INNER JOIN Consorcio AS c
            ON c.nombre = t.nombre_consorcio
        WHERE NOT EXISTS (
            SELECT 1 FROM Unidad_Funcional uf
            WHERE uf.nr_uf = TRY_CONVERT(INT, t.nroUnidadFuncional)
              AND uf.id_consorcio = c.id_consorcio
        );

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        PRINT 'Error al importar el archivo CSV.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO
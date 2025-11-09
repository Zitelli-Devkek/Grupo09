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

SP para importar el archivo "UF por consorcio.txt"
*/

USE Com2900G09
GO

CREATE OR ALTER PROCEDURE sp_Importar_UF_Por_Consorcio
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#UF_Temp') IS NOT NULL --si ya existe una tabla temporal con ese nombre la borra para poder crearla sin problemas
            DROP TABLE #UF_Temp;

        CREATE TABLE #UF_Temp (--creacion de tabla temporal todos como varchar para evitar errores de formato
            NombreConsorcio      VARCHAR(100),
            nroUnidadFuncional   VARCHAR(10),
            Piso                 VARCHAR(10),
            Departamento         VARCHAR(10),
            Coeficiente          VARCHAR(20),
            m2_uf                VARCHAR(20),
            Baulera              VARCHAR(5),
            Cochera              VARCHAR(5),
            m2_baulera           VARCHAR(20),
            m2_cochera           VARCHAR(20)
        );

        DECLARE @sql NVARCHAR(MAX);--uso sql dinamico ya que voy a mandar el archivo como parametro (la ruta)
        SET @sql = N'
        BULK INSERT #UF_Temp
        FROM ''' + @RutaArchivo + N'''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ''\t'', -- tabulador como separador
            ROWTERMINATOR = ''\n'', -- salto de línea de Windows
            CODEPAGE = ''ACP'',
            KEEPNULLS --si hay espacios vacios en algun dato lo deja como NULL
        );';
        EXEC sp_executesql @sql;

        PRINT 'Archivo cargado correctamente en la tabla temporal.';

        --ISNULL es para filtrar el DELETE y saltar filas vacias
        --la funcion del delete es que elimine filas completas o vacias para que luego no las inserte en la tabla
        DELETE FROM #UF_Temp
            WHERE LTRIM(RTRIM(ISNULL(NombreConsorcio, ''))) = ''--si es null lo reemplaza por cadena vacia y tambien normalizo espacios en blanco a los costados
               OR LTRIM(RTRIM(ISNULL(nroUnidadFuncional, ''))) = '';

        --Inserto en la tabla consorcio (el cuit lo genero yo)
        INSERT INTO Consorcio (nombre, cuit)
        SELECT DISTINCT
            t.NombreConsorcio,
            RIGHT('00000000000' + CAST(CAST(RAND() * 10000000000 + ROW_NUMBER() OVER (ORDER BY t.NombreConsorcio) AS BIGINT) AS VARCHAR(11)), 11) -- genero CUIT aleatorio distinto
        FROM #UF_Temp t
        WHERE NOT EXISTS (
            SELECT * FROM Consorcio c WHERE c.nombre = t.NombreConsorcio
        );

        PRINT 'Importacion a Consorcio completada.';

        --valido datos y filtro no duplicados
        INSERT INTO Unidad_Funcional (id_consorcio, nr_uf, piso, departamento, coeficiente, m2)
        SELECT 
            c.id_consorcio,
            TRY_CAST(t.nroUnidadFuncional AS INT),--uso try_cast porque si uso cast y falla me tira error
            NULLIF(LTRIM(RTRIM(t.Piso)), ''),          -- si está vacío o con espacios devuelve NULL gracias a NULLIF
            NULLIF(LTRIM(RTRIM(t.Departamento)), ''),      
            TRY_CAST(REPLACE(t.Coeficiente, ',', '.') AS DECIMAL(6,3)),  -- convierte coma a punto y valida el tipo
            TRY_CAST(REPLACE(t.m2_uf, ',', '.') AS DECIMAL(6,2))         
        FROM #UF_Temp t
        INNER JOIN Consorcio c ON c.nombre = t.NombreConsorcio
        WHERE TRY_CAST(t.nroUnidadFuncional AS INT) IS NOT NULL
          AND TRY_CAST(REPLACE(t.Coeficiente, ',', '.') AS DECIMAL(6,3)) IS NOT NULL
          AND TRY_CAST(REPLACE(t.m2_uf, ',', '.') AS DECIMAL(6,2)) IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 
              FROM Unidad_Funcional uf
              WHERE uf.id_consorcio = c.id_consorcio--para duplicados
                AND uf.nr_uf = TRY_CAST(t.nroUnidadFuncional AS INT)
          );

        PRINT 'Importacion a Unidad_funcional completada.';

        --Inserto complemento (BAULERAS/COCHERAS)
        INSERT INTO Complemento (id_uf, m2, tipo_complemento)
        SELECT uf.id_uf, 
               TRY_CAST(REPLACE(t.m2_baulera, ',', '.') AS DECIMAL(6,2)),
               'Baulera'
        FROM #UF_Temp t
        INNER JOIN Consorcio c ON c.nombre = t.NombreConsorcio
        INNER JOIN Unidad_Funcional uf 
            ON uf.id_consorcio = c.id_consorcio 
           AND uf.nr_uf = TRY_CAST(t.nroUnidadFuncional AS INT)
        WHERE UPPER(LTRIM(RTRIM(t.Baulera))) = 'SI'--uso upper por las mayus
          AND TRY_CAST(REPLACE(t.m2_baulera, ',', '.') AS DECIMAL(6,2)) > 0

        UNION ALL

        SELECT uf.id_uf, 
               TRY_CAST(REPLACE(t.m2_cochera, ',', '.') AS DECIMAL(6,2)),
               'Cochera'
        FROM #UF_Temp t
        INNER JOIN Consorcio c ON c.nombre = t.NombreConsorcio
        INNER JOIN Unidad_Funcional uf 
            ON uf.id_consorcio = c.id_consorcio 
           AND uf.nr_uf = TRY_CAST(t.nroUnidadFuncional AS INT)
        WHERE UPPER(LTRIM(RTRIM(t.Cochera))) = 'SI'
          AND TRY_CAST(REPLACE(t.m2_cochera, ',', '.') AS DECIMAL(6,2)) > 0;

          PRINT 'Importacion a Complemento completada.'

        DROP TABLE IF EXISTS #UF_Temp;

        COMMIT TRANSACTION;
        PRINT 'Importación de archivo completada.';

   END TRY
   BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'Error crítico durante la importación. Se ejecuta ROLLBACK.';
   END CATCH
END

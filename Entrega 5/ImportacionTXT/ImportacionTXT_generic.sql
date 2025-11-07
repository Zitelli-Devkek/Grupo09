USE Com2900G09
GO


CREATE OR ALTER PROCEDURE sp_ImportarUF_PorConsorcio
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;


        IF OBJECT_ID('tempdb..#UF_Temp') IS NOT NULL--si ya existe una tabla temporal con ese nombre la borra para poder crearla sin problemas
            DROP TABLE #UF_Temp;

        CREATE TABLE #UF_Temp (
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
            FIELDTERMINATOR = ''\t'',
            ROWTERMINATOR = ''\n'',
            CODEPAGE = ''ACP'',
            KEEPNULLS--si hay espacios vacios en algun dato lo deja como NULL
        );';
        EXEC sp_executesql @sql;

        PRINT 'Archivo cargado correctamente en la tabla temporal.';

        --Limpio las filas vacías o con datos nulos (con LTRIM Y RTRIM)
        --ISNULL es para filtrar el DELETE y saltar filas vacias
        DELETE FROM #UF_Temp
            WHERE LTRIM(RTRIM(ISNULL(NombreConsorcio, ''))) = ''
                OR LTRIM(RTRIM(ISNULL(nroUnidadFuncional, ''))) = '';


        --Inserto en la tabla consorcio
       INSERT INTO Consorcio (nombre, direccion, admin_cuit, cbu_cvu)
        SELECT DISTINCT
            t.NombreConsorcio,
            'Sin dirección',
            RIGHT('00000000000' + CAST(CAST(RAND() * 10000000000 + ROW_NUMBER() OVER (ORDER BY t.NombreConsorcio) AS BIGINT) AS VARCHAR(11)), 11),
            RIGHT('0000000000000000000000' + CAST(CAST(RAND() * 1000000000000000 + ROW_NUMBER() OVER (ORDER BY t.NombreConsorcio) AS BIGINT) AS VARCHAR(22)), 22)
        FROM #UF_Temp t
        WHERE NOT EXISTS (
            SELECT 1 FROM Consorcio c WHERE c.nombre = t.NombreConsorcio
        );


        PRINT 'Consorcios insertados.';

        --valido datos y filtro no duplicados
       INSERT INTO Unidad_Funcional (id_consorcio, nr_uf, piso, departamento, coeficiente, m2)
        SELECT 
            c.id_consorcio,
            TRY_CAST(t.nroUnidadFuncional AS INT),
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


        PRINT 'Unidades funcionales insertadas.';

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

        COMMIT TRANSACTION;
        PRINT 'Importación de archivo completada.';

   END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Error crítico durante la importación. Se ejecuta ROLLBACK.';
END CATCH

END

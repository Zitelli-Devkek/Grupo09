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

SP para importar "datos varios.xlsx" hoja de Proveedores en la tabla Proveedor
*/


USE Com2900G09
GO

CREATE OR ALTER PROCEDURE sp_ImportarProveedoresDesdeExcel
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF OBJECT_ID('tempdb..#ExcelProveedores') IS NOT NULL
            DROP TABLE #ExcelProveedores;

        CREATE TABLE #ExcelProveedores (
            Categoria NVARCHAR(200),
            NombreProveedor NVARCHAR(200),
            Detalle NVARCHAR(500),
            NombreConsorcio NVARCHAR(200)
        );


        DECLARE @sql NVARCHAR(MAX) = N'
            INSERT INTO #ExcelProveedores (Categoria, NombreProveedor, Detalle, NombreConsorcio)
            SELECT
                F1 AS Categoria,
                F2 AS NombreProveedor,
                F3 AS Detalle,
                F4 AS NombreConsorcio
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=NO;Database=' + @RutaArchivo + ''',
                ''SELECT F1,F2,F3,F4 FROM [Proveedores$]''
            ) AS t
            WHERE F1 IS NOT NULL OR F2 IS NOT NULL OR F4 IS NOT NULL';
        EXEC(@sql);


        INSERT INTO ErrorLogs (
            tipo_archivo, nombre_archivo, origen_sp,
            campo_error, error_descripcion
        )
        SELECT
            'EXCEL',
            @RutaArchivo,
            'sp_ImportarProveedoresDesdeExcel',
            -- Dato que falla
            CASE 
                WHEN Categoria IS NULL OR LTRIM(RTRIM(Categoria)) = '' THEN 'Categoria: ' + ISNULL(Categoria,'NULL')
                WHEN NombreProveedor IS NULL OR LTRIM(RTRIM(NombreProveedor)) = '' THEN 'NombreProveedor: ' + ISNULL(NombreProveedor,'NULL')
                WHEN NombreConsorcio IS NULL OR LTRIM(RTRIM(NombreConsorcio)) = '' THEN 'NombreConsorcio: ' + ISNULL(NombreConsorcio,'NULL')
            END,
            -- Descripción del error
            CASE 
                WHEN Categoria IS NULL OR LTRIM(RTRIM(Categoria)) = '' THEN 'Categoría vacía'
                WHEN NombreProveedor IS NULL OR LTRIM(RTRIM(NombreProveedor)) = '' THEN 'Nombre de proveedor vacío'
                WHEN NombreConsorcio IS NULL OR LTRIM(RTRIM(NombreConsorcio)) = '' THEN 'Consorcio vacío'
            END
        FROM #ExcelProveedores
        WHERE 
            Categoria IS NULL OR LTRIM(RTRIM(Categoria)) = ''
            OR NombreProveedor IS NULL OR LTRIM(RTRIM(NombreProveedor)) = ''
            OR NombreConsorcio IS NULL OR LTRIM(RTRIM(NombreConsorcio)) = '';

        --Inserto solo filas validas
        INSERT INTO Proveedor (nombre_consorcio, categoria, nombre_proveedor, detalle)
        SELECT
            NombreConsorcio,
            Categoria,
            NombreProveedor,
            Detalle
        FROM #ExcelProveedores
        WHERE 
            Categoria IS NOT NULL AND LTRIM(RTRIM(Categoria)) <> ''
            AND NombreProveedor IS NOT NULL AND LTRIM(RTRIM(NombreProveedor)) <> ''
            AND NombreConsorcio IS NOT NULL AND LTRIM(RTRIM(NombreConsorcio)) <> '';

        PRINT 'Importación completada correctamente.';

    END TRY
    BEGIN CATCH

        --Informar si hay error critico y guardarlo en el log
        INSERT INTO ErrorLogs (
            tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion
        )
        VALUES (
            'EXCEL', @RutaArchivo, 'sp_ImportarProveedoresDesdeExcel', NULL, ERROR_MESSAGE()
        );

        PRINT 'Ocurrió un error durante la importación.';
    END CATCH
END;
GO

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

SP para importar "datos varios.xlsx" hoja de Consorcios en la tabla Consorcio
*/

CREATE OR ALTER PROCEDURE sp_ImportarConsorcioExcel
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);

    BEGIN TRY
        --creo tabla temp
        IF OBJECT_ID('tempdb..#TempConsorcio') IS NOT NULL
            DROP TABLE #TempConsorcio;

        CREATE TABLE #TempConsorcio (
            Consorcio NVARCHAR(500),
            NombreDelConsorcio NVARCHAR(500),
            Domicilio NVARCHAR(500),
            CantUnidadesFuncionales NVARCHAR(500),
            M2Totales NVARCHAR(500)
        );

        --Para cargar los datos del excel
        SET @SQL = N'
            INSERT INTO #TempConsorcio (Consorcio, NombreDelConsorcio, Domicilio, CantUnidadesFuncionales, M2Totales)
            SELECT Consorcio, [Nombre del consorcio], Domicilio, [Cant unidades funcionales], [m2 totales]
            FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
                            ''Excel 12.0;HDR=YES;Database=' + @RutaArchivo + ''',
                            ''SELECT * FROM [Consorcios$]'')';
        EXEC sp_executesql @SQL;

        --Registro errores en el log
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT 
            'EXCEL',
            @RutaArchivo,
            'sp_ImportarConsorcioExcel',
            -- Valor que falló
            CASE
                WHEN NombreDelConsorcio IS NULL OR LTRIM(RTRIM(NombreDelConsorcio)) = '' THEN ISNULL(NombreDelConsorcio,'NULL')
                WHEN Domicilio IS NULL OR LTRIM(RTRIM(Domicilio)) = '' THEN ISNULL(Domicilio,'NULL')
                WHEN ISNUMERIC(CantUnidadesFuncionales) = 0 THEN CantUnidadesFuncionales
                WHEN ISNUMERIC(M2Totales) = 0 THEN M2Totales
                WHEN CAST(CantUnidadesFuncionales AS INT) <= 0 THEN CantUnidadesFuncionales
                WHEN CAST(M2Totales AS INT) <= 0 THEN M2Totales
            END,
            -- Descripción del error
            CASE
                WHEN NombreDelConsorcio IS NULL OR LTRIM(RTRIM(NombreDelConsorcio)) = '' 
                    OR Domicilio IS NULL OR LTRIM(RTRIM(Domicilio)) = '' THEN 'Falta nombre o domicilio'
                WHEN ISNUMERIC(CantUnidadesFuncionales) = 0 OR ISNUMERIC(M2Totales) = 0 THEN 'CantUnidadesFuncionales o M2 no es numérico'
                WHEN CAST(CantUnidadesFuncionales AS INT) <= 0 OR CAST(M2Totales AS INT) <= 0 THEN 'CantUnidadesFuncionales o M2 <= 0'
                ELSE 'Error desconocido'
            END
        FROM #TempConsorcio
        WHERE 
            NombreDelConsorcio IS NULL OR LTRIM(RTRIM(NombreDelConsorcio)) = ''
            OR Domicilio IS NULL OR LTRIM(RTRIM(Domicilio)) = ''
            OR ISNUMERIC(CantUnidadesFuncionales) = 0
            OR ISNUMERIC(M2Totales) = 0
            OR CAST(CantUnidadesFuncionales AS INT) <= 0
            OR CAST(M2Totales AS INT) <= 0;

        --Inserto solo filas validas
        INSERT INTO Consorcio (nombre, domicilio, cant_uf, m2)
        SELECT 
            NombreDelConsorcio,
            Domicilio,
            CAST(CantUnidadesFuncionales AS INT),
            CAST(M2Totales AS INT)
        FROM #TempConsorcio
        WHERE ISNUMERIC(CantUnidadesFuncionales) = 1
          AND ISNUMERIC(M2Totales) = 1
          AND CAST(CantUnidadesFuncionales AS INT) > 0
          AND CAST(M2Totales AS INT) > 0
          AND NombreDelConsorcio IS NOT NULL AND LTRIM(RTRIM(NombreDelConsorcio)) <> ''
          AND Domicilio IS NOT NULL AND LTRIM(RTRIM(Domicilio)) <> '';

        DROP TABLE #TempConsorcio;

    END TRY
    BEGIN CATCH
        -- Registrar error crítico del SP
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        VALUES ('EXCEL', @RutaArchivo, 'sp_ImportarConsorcioExcel', NULL, ERROR_MESSAGE());
    END CATCH
END;
GO

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

SP para importar "UF por consorcio.txt" en las tablas unidad_funcional y complemento
*/

CREATE OR ALTER PROCEDURE sp_Importar_UF_Complemento
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        --Creo tabla temp
        IF OBJECT_ID('tempdb..#UF_Temp') IS NOT NULL
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

        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
        BULK INSERT #UF_Temp
        FROM ''' + @RutaArchivo + N'''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ''\t'',
            ROWTERMINATOR = ''\n'',
            CODEPAGE = ''ACP'',
            KEEPNULLS
        );';
        EXEC sp_executesql @sql;

        --Registro errores
        INSERT INTO ErrorLogs (
            tipo_archivo, nombre_archivo, origen_sp,
            campo_error, error_descripcion
        )
        SELECT
            'TXT',
            @RutaArchivo,
            'sp_Importar_UF_Complemento',
            --Registramos el valor exacto que falló
            CASE
                WHEN LTRIM(RTRIM(ISNULL(t.NombreConsorcio,''))) = '' THEN 'NombreConsorcio vacío'
                WHEN LTRIM(RTRIM(ISNULL(t.nroUnidadFuncional,''))) = '' THEN 'nroUnidadFuncional vacío'
                WHEN c.id_consorcio IS NULL THEN t.NombreConsorcio
                WHEN TRY_CAST(t.nroUnidadFuncional AS INT) IS NULL THEN t.nroUnidadFuncional
                WHEN TRY_CAST(REPLACE(t.Coeficiente, ',', '.') AS DECIMAL(4,2)) IS NULL THEN t.Coeficiente
                WHEN TRY_CAST(REPLACE(t.m2_uf, ',', '.') AS DECIMAL(4,2)) IS NULL THEN t.m2_uf
                ELSE 'Error desconocido'
            END,
            CASE
                WHEN LTRIM(RTRIM(ISNULL(t.NombreConsorcio,''))) = '' 
                  OR LTRIM(RTRIM(ISNULL(t.nroUnidadFuncional,''))) = '' THEN 'Fila vacía o incompleta'
                WHEN c.id_consorcio IS NULL THEN 'Consorcio no encontrado'
                WHEN TRY_CAST(t.nroUnidadFuncional AS INT) IS NULL THEN 'nr_uf inválido'
                WHEN TRY_CAST(REPLACE(t.Coeficiente, ',', '.') AS DECIMAL(4,2)) IS NULL THEN 'Coeficiente inválido'
                WHEN TRY_CAST(REPLACE(t.m2_uf, ',', '.') AS DECIMAL(4,2)) IS NULL THEN 'm2_uf inválido'
                ELSE 'Error desconocido'
            END
        FROM #UF_Temp t
        LEFT JOIN Consorcio c ON c.nombre = t.NombreConsorcio
        WHERE
            LTRIM(RTRIM(ISNULL(t.NombreConsorcio,''))) = ''
            OR LTRIM(RTRIM(ISNULL(t.nroUnidadFuncional,''))) = ''
            OR c.id_consorcio IS NULL
            OR TRY_CAST(t.nroUnidadFuncional AS INT) IS NULL
            OR TRY_CAST(REPLACE(t.Coeficiente, ',', '.') AS DECIMAL(4,2)) IS NULL
            OR TRY_CAST(REPLACE(t.m2_uf, ',', '.') AS DECIMAL(4,2)) IS NULL;

        --Inserto valores validos en unidad_funcional
        INSERT INTO Unidad_Funcional (id_consorcio, nr_uf, piso, departamento, coeficiente, m2)
        SELECT 
            c.id_consorcio,
            TRY_CAST(t.nroUnidadFuncional AS INT),
            NULLIF(LTRIM(RTRIM(t.Piso)), ''),
            NULLIF(LTRIM(RTRIM(t.Departamento)), ''),
            TRY_CAST(REPLACE(t.Coeficiente, ',', '.') AS DECIMAL(4,2)),
            TRY_CAST(REPLACE(t.m2_uf, ',', '.') AS DECIMAL(4,2))
        FROM #UF_Temp t
        INNER JOIN Consorcio c ON c.nombre = t.NombreConsorcio
        WHERE
            LTRIM(RTRIM(ISNULL(t.NombreConsorcio,''))) <> ''
            AND LTRIM(RTRIM(ISNULL(t.nroUnidadFuncional,''))) <> ''
            AND c.id_consorcio IS NOT NULL
            AND TRY_CAST(t.nroUnidadFuncional AS INT) IS NOT NULL
            AND TRY_CAST(REPLACE(t.Coeficiente, ',', '.') AS DECIMAL(4,2)) IS NOT NULL
            AND TRY_CAST(REPLACE(t.m2_uf, ',', '.') AS DECIMAL(4,2)) IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 
                FROM Unidad_Funcional uf
                WHERE uf.id_consorcio = c.id_consorcio
                  AND uf.nr_uf = TRY_CAST(t.nroUnidadFuncional AS INT)
            );

        --Inserto datos validos en complemento
        INSERT INTO Complemento (id_uf, m2, tipo_complemento)
        SELECT uf.id_uf,
               TRY_CAST(REPLACE(t.m2_baulera, ',', '.') AS DECIMAL(4,2)),
               'Baulera'
        FROM #UF_Temp t
        INNER JOIN Consorcio c ON c.nombre = t.NombreConsorcio
        INNER JOIN Unidad_Funcional uf ON uf.id_consorcio = c.id_consorcio
           AND uf.nr_uf = TRY_CAST(t.nroUnidadFuncional AS INT)
        WHERE UPPER(LTRIM(RTRIM(t.Baulera))) = 'SI'
          AND TRY_CAST(REPLACE(t.m2_baulera, ',', '.') AS DECIMAL(4,2)) > 0

        UNION ALL

        SELECT uf.id_uf,
               TRY_CAST(REPLACE(t.m2_cochera, ',', '.') AS DECIMAL(4,2)),
               'Cochera'
        FROM #UF_Temp t
        INNER JOIN Consorcio c ON c.nombre = t.NombreConsorcio
        INNER JOIN Unidad_Funcional uf ON uf.id_consorcio = c.id_consorcio
           AND uf.nr_uf = TRY_CAST(t.nroUnidadFuncional AS INT)
        WHERE UPPER(LTRIM(RTRIM(t.Cochera))) = 'SI'
          AND TRY_CAST(REPLACE(t.m2_cochera, ',', '.') AS DECIMAL(4,2)) > 0;

        DROP TABLE IF EXISTS #UF_Temp;

        COMMIT TRANSACTION;
        PRINT 'Importación completada correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        VALUES ('TXT', @RutaArchivo, 'sp_Importar_UF_Complemento', NULL, ERROR_MESSAGE());
    END CATCH
END;

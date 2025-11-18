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
        
        --crear tabla temporal
        IF OBJECT_ID('tempdb..#TempConsorcio') IS NOT NULL
            DROP TABLE #TempConsorcio;

        CREATE TABLE #TempConsorcio (
            NombreDelConsorcio NVARCHAR(500),
            Domicilio NVARCHAR(500)
        );

        --cargar los campos que necesito de mi excel
        SET @SQL = N'
            INSERT INTO #TempConsorcio (NombreDelConsorcio, Domicilio)
            SELECT [Nombre del consorcio], [Domicilio]
            FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0;HDR=YES;Database=' + @RutaArchivo + ''',
                    ''SELECT [Nombre del consorcio], [Domicilio] FROM [Consorcios$]''
                );
        ';

        EXEC sp_executesql @SQL;

        ---------------------------------------------------------------------
        -- registro de errores → campos vacíos
        ---------------------------------------------------------------------
        INSERT INTO ErrorLogs (
            tipo_archivo, nombre_archivo, origen_sp,
            campo_error, error_descripcion
        )
        SELECT 
            'EXCEL',
            @RutaArchivo,
            'sp_ImportarConsorcioExcel',
            CASE
                WHEN NombreDelConsorcio IS NULL OR LTRIM(RTRIM(NombreDelConsorcio)) = '' 
                    THEN 'Nombre del consorcio vacío'
                WHEN Domicilio IS NULL OR LTRIM(RTRIM(Domicilio)) = ''
                    THEN 'Domicilio vacío'
            END,
            CASE
                WHEN NombreDelConsorcio IS NULL OR LTRIM(RTRIM(NombreDelConsorcio)) = '' 
                    THEN 'El nombre del consorcio no puede estar vacío'
                WHEN Domicilio IS NULL OR LTRIM(RTRIM(Domicilio)) = ''
                    THEN 'El domicilio no puede estar vacío'
            END
        FROM #TempConsorcio
        WHERE 
            NombreDelConsorcio IS NULL OR LTRIM(RTRIM(NombreDelConsorcio)) = ''
            OR Domicilio IS NULL OR LTRIM(RTRIM(Domicilio)) = '';

        ---------------------------------------------------------------------
        -- registro de errores → duplicados en Consorcio
        ---------------------------------------------------------------------
        INSERT INTO ErrorLogs (
            tipo_archivo, nombre_archivo, origen_sp,
            campo_error, error_descripcion
        )
        SELECT
            'EXCEL',
            @RutaArchivo,
            'sp_ImportarConsorcioExcel',
            'Consorcio duplicado',
            CONCAT(
                'El consorcio "', 
                LTRIM(RTRIM(t.NombreDelConsorcio)), 
                '" ya existe en la tabla Consorcio'
            )
        FROM #TempConsorcio t
        INNER JOIN Consorcio c
            ON LTRIM(RTRIM(t.NombreDelConsorcio)) = LTRIM(RTRIM(c.nombre))
        WHERE 
            t.NombreDelConsorcio IS NOT NULL
            AND LTRIM(RTRIM(t.NombreDelConsorcio)) <> '';

        ---------------------------------------------------------------------
        -- insertar filas válidas (no vacías y no duplicadas)
        ---------------------------------------------------------------------
        INSERT INTO Consorcio (nombre, domicilio)
        SELECT
            LTRIM(RTRIM(t.NombreDelConsorcio)),
            LTRIM(RTRIM(t.Domicilio))
        FROM #TempConsorcio t
        WHERE 
            -- válidos
            t.NombreDelConsorcio IS NOT NULL AND LTRIM(RTRIM(t.NombreDelConsorcio)) <> ''
            AND t.Domicilio IS NOT NULL AND LTRIM(RTRIM(t.Domicilio)) <> ''
            -- no duplicados
            AND NOT EXISTS (
                SELECT 1
                FROM Consorcio c
                WHERE LTRIM(RTRIM(c.nombre)) = LTRIM(RTRIM(t.NombreDelConsorcio))
            );

        --borro tabla temp
        DROP TABLE #TempConsorcio;

        PRINT 'Importación de consorcios completada correctamente.';

    END TRY
    BEGIN CATCH
        --error de sp si lo hay
        INSERT INTO ErrorLogs (
            tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion
        )
        VALUES (
            'EXCEL', @RutaArchivo, 'sp_ImportarConsorcioExcel', NULL, ERROR_MESSAGE()
        );

        PRINT 'Error crítico durante la importación: ' + ERROR_MESSAGE();
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
        
        -- Eliminar la tabla temporal si ya existe
        IF OBJECT_ID('tempdb..#ExcelProveedores') IS NOT NULL
            DROP TABLE #ExcelProveedores;

        -- Crear la tabla temporal para cargar los datos del Excel
        CREATE TABLE #ExcelProveedores (
            Categoria NVARCHAR(200),
            NombreProveedor NVARCHAR(200),
            Detalle NVARCHAR(500),
            NombreConsorcio NVARCHAR(200)
        );

        -- Cargar los datos desde el archivo Excel
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
            -- Evito el encabezado porque HDR=NO
            WHERE NOT (F1 = ''Nombre del consorcio'')
                  AND (F1 IS NOT NULL OR F2 IS NOT NULL OR F4 IS NOT NULL);
        ';
        EXEC(@sql);

        -- Registrar los errores de validación en la tabla ErrorLogs
        INSERT INTO ErrorLogs (
            tipo_archivo, nombre_archivo, origen_sp,
            campo_error, error_descripcion
        )
        SELECT
            'EXCEL',
            @RutaArchivo,
            'sp_ImportarProveedoresDesdeExcel',
            CASE 
                WHEN Categoria IS NULL OR LTRIM(RTRIM(Categoria)) = '' THEN 'Categoria vacía'
                WHEN NombreProveedor IS NULL OR LTRIM(RTRIM(NombreProveedor)) = '' THEN 'NombreProveedor vacío'
                WHEN NombreConsorcio IS NULL OR LTRIM(RTRIM(NombreConsorcio)) = '' THEN 'NombreConsorcio vacío'
            END,
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

        -- Insertar solo los registros válidos en la tabla Proveedor
        INSERT INTO Proveedor (ref_consorcio, categoria, nombre_proveedor, detalle)
        SELECT
            -- Buscar el id del consorcio según el nombre
            (SELECT id_consorcio FROM Consorcio WHERE nombre = t.NombreConsorcio),
            t.Categoria,
            t.NombreProveedor,
            t.Detalle
        FROM #ExcelProveedores t
        WHERE 
            t.Categoria IS NOT NULL AND LTRIM(RTRIM(t.Categoria)) <> ''
            AND t.NombreProveedor IS NOT NULL AND LTRIM(RTRIM(t.NombreProveedor)) <> ''
            AND t.NombreConsorcio IS NOT NULL AND LTRIM(RTRIM(t.NombreConsorcio)) <> ''
            AND EXISTS (SELECT 1 FROM Consorcio c WHERE c.nombre = t.NombreConsorcio);  -- Asegurarse de que el consorcio existe

        PRINT 'Importación completada correctamente.';

    END TRY
    BEGIN CATCH
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        -------------------------------------------------------------
        -- EVITAR registrar errores falsos del proveedor ACE.OLEDB
        -- Son errores internos que NO afectan la importación real
        -------------------------------------------------------------
        IF @ErrorMessage NOT LIKE '%Microsoft.ACE.OLEDB.12.0%'
           AND @ErrorMessage NOT LIKE '%No se puede inicializar el objeto%'
           AND @ErrorMessage NOT LIKE '%The Microsoft Access database engine%'
        BEGIN
            INSERT INTO ErrorLogs (
                tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion
            )
            VALUES (
                'EXCEL', @RutaArchivo, 'sp_ImportarProveedoresDesdeExcel',
                NULL, @ErrorMessage
            );
        END

        PRINT 'Ocurrió un error durante la importación: ' + @ErrorMessage;

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

USE Com2900G09
GO

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

Consigna: En este script se importa el archivo inquilino-propietarios-datos.csv 
y se carga en las tablas "Tipo_Ocupante" y "Persona"
*/

CREATE OR ALTER PROCEDURE sp_importar_csv_inquilino_propietarios_datos
    @rutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    --borro tablas temps si existen
    IF OBJECT_ID('tempdb..#tmp_import') IS NOT NULL DROP TABLE #tmp_import;
    IF OBJECT_ID('tempdb..#tmp_validos') IS NOT NULL DROP TABLE #tmp_validos;
    IF OBJECT_ID('tempdb..#tmp_dup') IS NOT NULL DROP TABLE #tmp_dup;

    --creo tabla temp_import con todo nvarchar por los formatos
    CREATE TABLE #tmp_import (
        nombre NVARCHAR(200),
        apellido NVARCHAR(200),
        DNI NVARCHAR(50),
        email_personal NVARCHAR(200),
        telefono NVARCHAR(50),
        cbu_cvu NVARCHAR(50),
        inquilino NVARCHAR(10)
    );


    BEGIN TRY
        --sql dinamico porque mando el archivo por parametro
        DECLARE @sql NVARCHAR(MAX) = N'
            BULK INSERT #tmp_import
            FROM ''' + REPLACE(@rutaArchivo,'''','''''') + N'''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''ACP''
            );';
        EXEC sp_executesql @sql;

        --normalizo con ltrim, rtrim y lower
        UPDATE #tmp_import
        SET
            nombre = LOWER(LTRIM(RTRIM(nombre))),
            apellido = LOWER(LTRIM(RTRIM(apellido))),
            DNI = LTRIM(RTRIM(DNI)),
            email_personal = LTRIM(RTRIM(email_personal)),
            telefono = LTRIM(RTRIM(telefono)),
            cbu_cvu = LTRIM(RTRIM(cbu_cvu)),
            inquilino = LTRIM(RTRIM(inquilino));

        --reviso que existan los tipos de ocupantes
        IF NOT EXISTS (SELECT 1 FROM Tipo_Ocupante WHERE descripcion = 'Inquilino')
            INSERT INTO Tipo_Ocupante(descripcion) VALUES('Inquilino');
        IF NOT EXISTS (SELECT 1 FROM Tipo_Ocupante WHERE descripcion = 'Propietario')
            INSERT INTO Tipo_Ocupante(descripcion) VALUES('Propietario');

        DECLARE @id_inquilino INT = (SELECT id_tipo_ocupante FROM Tipo_Ocupante WHERE descripcion = 'Inquilino');
        DECLARE @id_propietario INT = (SELECT id_tipo_ocupante FROM Tipo_Ocupante WHERE descripcion = 'Propietario');

        --guardo dni duplicados en una tabla temp_dup
        SELECT DNI
        INTO #tmp_dup
        FROM (
            SELECT DNI, COUNT(*) AS cnt
            FROM #tmp_import
            WHERE DNI IS NOT NULL AND LTRIM(RTRIM(DNI)) <> ''
            GROUP BY DNI
            HAVING COUNT(*) > 1
        ) d;

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
            FROM #tmp_import
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
        FROM #tmp_import
        WHERE DNI IS NULL OR LEN(DNI) <> 8 OR TRY_CONVERT(INT, DNI) NOT BETWEEN 10000000 AND 99999999;

        --registro en errorlog cbu_cvu con digitos fuera de rango
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV',
            @rutaArchivo,
            'sp_importar_csv_inquilino_propietarios_datos',
            'CBU/CVU',
            'CBU/CVU inválido (debe tener 22 dígitos): ' + ISNULL(cbu_cvu,'<NULL>')
        FROM #tmp_import
        WHERE cbu_cvu IS NOT NULL AND LTRIM(RTRIM(cbu_cvu)) <> '' AND LEN(REPLACE(cbu_cvu,' ','') ) <> 22;

       --registro en error log inquilinos invalidos
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV', @rutaArchivo, 'sp_importar_csv_inquilino_propietarios_datos',
            'Inquilino', 'Valor inquilino inválido (debe ser 0 o 1): ' + ISNULL(inquilino,'<NULL>')
        FROM #tmp_import
        WHERE TRY_CONVERT(INT, inquilino) NOT IN (0,1);

        --registro nombres o apellidos vacios en errorlog
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV', @rutaArchivo, 'sp_importar_csv_inquilino_propietarios_datos',
            CASE WHEN nombre IS NULL OR nombre = '' THEN 'Nombre' ELSE 'Apellido' END,
            CASE WHEN nombre IS NULL OR nombre = '' THEN 'Nombre vacío' ELSE 'Apellido vacío' END
        FROM #tmp_import
        WHERE nombre IS NULL OR nombre = '' OR apellido IS NULL OR apellido = '';

        --registro en errorlog mails invalidos
        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        SELECT
            'CSV', @rutaArchivo, 'sp_importar_csv_inquilino_propietarios_datos',
            'Email', 'Email inválido según regla: ' + ISNULL(email_personal,'<NULL>')
        FROM #tmp_import
        WHERE email_personal IS NOT NULL AND email_personal <> '' AND email_personal NOT LIKE '%_@_%._%';

        --armo tabla de datos validados
        IF OBJECT_ID('tempdb..#tmp_validos') IS NOT NULL DROP TABLE #tmp_validos;
        CREATE TABLE #tmp_validos (
            DNI_valido CHAR(8),
            id_tipo_ocupante INT,
            nombre NVARCHAR(200),
            apellido NVARCHAR(200),
            email_personal NVARCHAR(200),
            telefono NVARCHAR(50),
            cbu_cvu NVARCHAR(22)
        );

        INSERT INTO #tmp_validos (DNI_valido, id_tipo_ocupante, nombre, apellido, email_personal, telefono, cbu_cvu)
        SELECT DISTINCT
            TRY_CONVERT(CHAR(8), LTRIM(RTRIM(t.DNI))) AS DNI_valido,
            CASE WHEN TRY_CONVERT(INT, t.inquilino) = 1 THEN @id_inquilino ELSE @id_propietario END,
            t.nombre,
            t.apellido,
            t.email_personal,
            t.telefono,
            CASE WHEN LTRIM(RTRIM(t.cbu_cvu)) = '' THEN NULL ELSE LTRIM(RTRIM(t.cbu_cvu)) END
        FROM #tmp_import t
        LEFT JOIN #tmp_dup d ON d.DNI = t.DNI               -- excluye casos de DNI duplicados en archivo
        WHERE d.DNI IS NULL
          AND t.DNI IS NOT NULL
          AND LEN(LTRIM(RTRIM(t.DNI))) = 8
          AND TRY_CONVERT(INT, LTRIM(RTRIM(t.DNI))) BETWEEN 10000000 AND 99999999
          AND NOT EXISTS (SELECT 1 FROM Persona p WHERE p.DNI = TRY_CONVERT(CHAR(8), LTRIM(RTRIM(t.DNI))))
          AND (t.cbu_cvu IS NULL OR LTRIM(RTRIM(t.cbu_cvu)) = '' OR LEN(LTRIM(RTRIM(t.cbu_cvu))) = 22)
          AND TRY_CONVERT(INT, t.inquilino) IN (0,1)
          AND t.nombre IS NOT NULL AND t.nombre <> ''
          AND t.apellido IS NOT NULL AND t.apellido <> ''
          AND (t.email_personal IS NULL OR t.email_personal = '' OR t.email_personal LIKE '%_@_%._%');

        --elimino duplicados internos de la tabla 
        IF OBJECT_ID('tempdb..#tmp_validos_nodup') IS NOT NULL DROP TABLE #tmp_validos_nodup;
        SELECT *
        INTO #tmp_validos_nodup
        FROM (
            SELECT v.*,
                   ROW_NUMBER() OVER (PARTITION BY DNI_valido ORDER BY (SELECT NULL)) AS rn
            FROM #tmp_validos v
        ) x
        WHERE rn = 1;

       --inserto en persona volviendo a chequear 
        INSERT INTO Persona (DNI, id_tipo_ocupante, nombre, apellido, email_personal, telefono, cbu_cvu)
        SELECT v.DNI_valido, v.id_tipo_ocupante, v.nombre, v.apellido, v.email_personal, v.telefono, v.cbu_cvu
        FROM #tmp_validos_nodup v
        WHERE NOT EXISTS (SELECT 1 FROM Persona p WHERE p.DNI = v.DNI_valido);

        -- limpia temporales
        DROP TABLE IF EXISTS #tmp_dupfile;
        DROP TABLE IF EXISTS #tmp_validos;
        DROP TABLE IF EXISTS #tmp_validos_nodup;
        DROP TABLE IF EXISTS #tmp_import;

        RETURN 0;

    END TRY
    BEGIN CATCH
        -- Si ocurre error crítico,lo registro y no dejo la transacción abierta
        IF @@TRANCOUNT > 0 ROLLBACK;

        INSERT INTO ErrorLogs (tipo_archivo, nombre_archivo, origen_sp, campo_error, error_descripcion)
        VALUES ('CSV', @rutaArchivo, 'sp_importar_csv_inquilino_propietarios_datos', NULL, ERROR_MESSAGE());

        -- limpio temporales 
        DROP TABLE IF EXISTS #tmp_dupfile;
        DROP TABLE IF EXISTS #tmp_validos;
        DROP TABLE IF EXISTS #tmp_validos_nodup;
        DROP TABLE IF EXISTS #tmp_import;

        THROW;
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

SP para importar "Servicios.Servicios.json" en la tabla Servicio
*/

CREATE OR ALTER PROCEDURE sp_ImportarServicios
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#Servicios_Temp') IS NOT NULL--si existe la tabla temporal, la elimino
            DROP TABLE #Servicios_Temp;

        CREATE TABLE #Servicios_Temp (--creo tabla temporal de servicios
            NombreConsorcio NVARCHAR(100),
            Mes NVARCHAR(20),
            BANCARIOS NVARCHAR(50),
            LIMPIEZA NVARCHAR(50),
            ADMINISTRACION NVARCHAR(50),
            SEGUROS NVARCHAR(50),
            [GASTOS GENERALES] NVARCHAR(50),
            [SERVICIOS PUBLICOS-Agua] NVARCHAR(50),
            [SERVICIOS PUBLICOS-Luz] NVARCHAR(50)
        );

        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @json NVARCHAR(MAX);

        --Leo el archivo JSON con sql dinámico y OPENROWSET
        SET @SQL = N'
            SELECT @json = BulkColumn
            FROM OPENROWSET(BULK ''' + @RutaArchivo + N''', SINGLE_CLOB) AS j;';

        EXEC sp_executesql @SQL, N'@json NVARCHAR(MAX) OUTPUT', @json = @json OUTPUT;--output para que la variable @json sea un parametro de salida y no se quede encerrado en el sql dinamico

        IF @json IS NULL--si el archivo está vacio hago rollback 
        BEGIN
            RAISERROR('Error al abrir JSON o está vacío.', 16, 1);--jair nos permitió usar RAISERROR, el 16 indica la severidad de error que 
            ROLLBACK TRANSACTION;                                             --es un error de usuario y se captura en CATCH, y el 1 es el estado
            RETURN;
        END;

        --Cargo los datos del json a la tabla temporal creada
        INSERT INTO #Servicios_Temp
        SELECT
            j.[Nombre del consorcio],
            j.[Mes],
            j.[BANCARIOS],
            j.[LIMPIEZA],
            j.[ADMINISTRACION],
            j.[SEGUROS],
            j.[GASTOS GENERALES],
            j.[SERVICIOS PUBLICOS-Agua],
            j.[SERVICIOS PUBLICOS-Luz]
        FROM OPENJSON(@json)
        WITH (--no es CTE, solo uso WITH para decirle como leer el archivo (mapeo de datos)
            [Nombre del consorcio] NVARCHAR(100) '$."Nombre del consorcio"',--le digo de donde sacar el dato (ruta dentro del json)
            [Mes] NVARCHAR(20) '$.Mes',--ejemplo, trae el dato que esta en mes del json y lo guarda en [Mes]
            [BANCARIOS] NVARCHAR(50) '$.BANCARIOS',
            [LIMPIEZA] NVARCHAR(50) '$.LIMPIEZA',
            [ADMINISTRACION] NVARCHAR(50) '$.ADMINISTRACION',
            [SEGUROS] NVARCHAR(50) '$.SEGUROS',
            [GASTOS GENERALES] NVARCHAR(50) '$."GASTOS GENERALES"',
            [SERVICIOS PUBLICOS-Agua] NVARCHAR(50) '$."SERVICIOS PUBLICOS-Agua"',--comilla doble porque tiene espacio
            [SERVICIOS PUBLICOS-Luz] NVARCHAR(50) '$."SERVICIOS PUBLICOS-Luz"'
        ) AS j;

        PRINT 'Archivo JSON cargado correctamente.';

		INSERT INTO ErrorLogs (
            tipo_archivo, nombre_archivo, origen_sp,
            campo_error, error_descripcion
        )
        SELECT 
            'JSON',
            @RutaArchivo,
            'sp_ImportarServicios',
            CASE
                WHEN NombreConsorcio IS NULL OR LTRIM(RTRIM(NombreConsorcio)) = '' 
                    THEN 'Nombre del consorcio vacío'
                WHEN Mes IS NULL OR LTRIM(RTRIM(Mes)) = ''
                    THEN 'Mes vacío'
            END,
            CASE
                WHEN NombreConsorcio IS NULL OR LTRIM(RTRIM(NombreConsorcio)) = '' 
                    THEN 'El nombre del consorcio no puede estar vacío'
                WHEN Mes IS NULL OR LTRIM(RTRIM(Mes)) = ''
                    THEN 'El mes no puede estar vacío'
            END
        FROM #Servicios_Temp
        WHERE 
            (NombreConsorcio IS NULL OR LTRIM(RTRIM(NombreConsorcio)) = '')
            OR (Mes IS NULL OR LTRIM(RTRIM(Mes)) = '');

       --LOG de importes no parseados
        ;WITH tabla_tempora_norm_log AS (
            SELECT
                NombreConsorcio = LTRIM(RTRIM(LOWER(NombreConsorcio))),
                Mes             = LTRIM(RTRIM(LOWER(Mes))),
                BANCARIOS, LIMPIEZA, ADMINISTRACION, SEGUROS,
                [GASTOS GENERALES], [SERVICIOS PUBLICOS-Agua], [SERVICIOS PUBLICOS-Luz]
            FROM #Servicios_Temp
        ),
        despivotar_log AS (
            SELECT
                s.NombreConsorcio,
                s.Mes,
                v.Categoria,
                ImporteRaw = v.Importe
            FROM tabla_tempora_norm_log s
            CROSS APPLY (VALUES
                ('BANCARIOS',               s.BANCARIOS),
                ('LIMPIEZA',                s.LIMPIEZA),
                ('ADMINISTRACION',          s.ADMINISTRACION),
                ('SEGUROS',                 s.SEGUROS),
                ('GASTOS GENERALES',        s.[GASTOS GENERALES]),
                ('SERVICIOS PUBLICOS-Agua', s.[SERVICIOS PUBLICOS-Agua]),
                ('SERVICIOS PUBLICOS-Luz',  s.[SERVICIOS PUBLICOS-Luz])
            ) v(Categoria, Importe)
        ),
        convertidos_log AS (
            SELECT
                u.NombreConsorcio,
                u.Mes,
                u.Categoria,
                u.ImporteRaw,
                Valor = u.ImporteRaw
                    )
            FROM despivotar_log u
        )
        INSERT INTO ErrorLogs (
            tipo_archivo, nombre_archivo, origen_sp,
            campo_error, error_descripcion
        )
        SELECT
            'JSON',
            @RutaArchivo,
            'sp_ImportarServicios',
            'Importe inválido',
            CONCAT('No se pudo convertir el importe "', ISNULL(LTRIM(RTRIM(ImporteRaw)),'(NULL)'),
                   '" para categoría ', Categoria, 
                   ', consorcio ', NombreConsorcio, ', mes ', Mes, '.')
        FROM convertidos_log
        WHERE
            (ImporteRaw IS NOT NULL AND LTRIM(RTRIM(ImporteRaw)) <> '')
            AND Valor IS NULL;

         --LOG de mapeo de consorcio (0 o > 1 coincidencias)
        ;WITH nombres_distintos AS (
            SELECT DISTINCT LTRIM(RTRIM(LOWER(NombreConsorcio))) AS NombreConsorcio
            FROM #Servicios_Temp
            WHERE NombreConsorcio IS NOT NULL AND LTRIM(RTRIM(NombreConsorcio)) <> ''
        ),
        conteos AS (
            SELECT
                n.NombreConsorcio,
                Cnt = (SELECT COUNT(*) FROM dbo.Consorcio c WHERE c.nombre = n.NombreConsorcio)
            FROM nombres_distintos n
        )
        INSERT INTO ErrorLogs (
            tipo_archivo, nombre_archivo, origen_sp,
            campo_error, error_descripcion
        )
        SELECT
            'JSON',
            @RutaArchivo,
            'sp_ImportarServicios',
            CASE WHEN Cnt = 0 THEN 'Consorcio inexistente'
                 WHEN Cnt > 1 THEN 'Consorcio duplicado'
            END,
            CASE WHEN Cnt = 0 THEN CONCAT('No existe consorcio con nombre "', NombreConsorcio, '".')
                 WHEN Cnt > 1 THEN CONCAT('Hay múltiples consorcios con nombre "', NombreConsorcio, '".')
            END
        FROM conteos
        WHERE Cnt <> 1;


		-- Inserta los servicios unificados (unpivot) y normaliza montos
		-- uso CTE para la insercción de datos
		-- Tomo la tabla temporal y limpiamos de posibles espacios en nombre de consorcio y mes
		WITH tabla_tempora_norm AS (
			SELECT
				NombreConsorcio = LTRIM(RTRIM(LOWER(NombreConsorcio))), --limpio espacios
				Mes        = LTRIM(RTRIM(LOWER(Mes))), --limpio espacios
				BANCARIOS,
				LIMPIEZA,
				ADMINISTRACION,
				SEGUROS,
				[GASTOS GENERALES],
				[SERVICIOS PUBLICOS-Agua],
				[SERVICIOS PUBLICOS-Luz]
			FROM #Servicios_Temp
		),
		-- con cross apply convierto las 7 columnas de gastos en filas con dos campos: categoria e importeFila
		despivotar AS (
			SELECT
				s.NombreConsorcio,
				s.Mes,
				v.Categoria,
				importeFila = v.Importe
			FROM tabla_tempora_norm s
			CROSS APPLY (VALUES
				('BANCARIOS',               s.BANCARIOS),
				('LIMPIEZA',                s.LIMPIEZA),
				('ADMINISTRACION',          s.ADMINISTRACION),
				('SEGUROS',                 s.SEGUROS),
				('GASTOS GENERALES',        s.[GASTOS GENERALES]),
				('SERVICIOS PUBLICOS-Agua', s.[SERVICIOS PUBLICOS-Agua]),
				('SERVICIOS PUBLICOS-Luz',  s.[SERVICIOS PUBLICOS-Luz])
			) v(Categoria, Importe)
		),
		-- con REPLACE quito posibles espacios ' '
		-- con TRY_PARSE, USING parseo importeFila a DECIMAL(10,2) y valido si esta con los siguientes formatos: es-AR -> 00.000,00, en-US -> 00,000.00 
		-- con COALESCE devuelve el primer valor no nulo de las dos opciones.
		convertidos AS (
			SELECT
				u.NombreConsorcio,
				u.Mes,
				u.Categoria,
				Valor =
					CASE
						-- Intento normal es-AR (punto miles, coma decimal)
						WHEN TRY_PARSE(REPLACE(REPLACE(u.importeFila, CHAR(160), ''), ' ', '') AS DECIMAL(10,2) USING 'es-AR') IS NOT NULL
						THEN TRY_PARSE(REPLACE(REPLACE(u.importeFila, CHAR(160), ''), ' ', '') AS DECIMAL(10,2) USING 'es-AR')

						-- Si es-AR falla, pruebo en-US.
						-- en-US lo parsea como 12,708,000.00, así que divido por 100 para recuperar 2 decimales.
						WHEN TRY_PARSE(REPLACE(REPLACE(u.importeFila, CHAR(160), ''), ' ', '') AS DECIMAL(10,2) USING 'en-US') IS NOT NULL
							 AND (LEN(REPLACE(REPLACE(u.importeFila, CHAR(160), ''), ' ', '')) 
								  - LEN(REPLACE(REPLACE(REPLACE(u.importeFila, CHAR(160), ''), ' ', ''), ',', ''))) > 1
							 AND CHARINDEX('.', REPLACE(REPLACE(u.importeFila, CHAR(160), ''), ' ', '')) = 0
						THEN TRY_PARSE(REPLACE(REPLACE(u.importeFila, CHAR(160), ''), ' ', '') AS DECIMAL(10,2) USING 'en-US') / 100.0

						-- Resto de casos: en-US tal cual (o NULL si tampoco aplica)
						ELSE TRY_PARSE(REPLACE(REPLACE(u.importeFila, CHAR(160), ''), ' ', '') AS DECIMAL(10,2) USING 'en-US')
					END
				)
			FROM despivotar u
		)
		-- Inserto valores finales a la tabla servicio, valido que valor no sea nulo ni sea 0
		INSERT INTO Servicio (ref_consorcio, mes, categoria, valor)
		SELECT
			(select id_consorcio from [dbo].[Consorcio] where nombre = NombreConsorcio),
			Mes,
			Categoria,
			Valor
		FROM convertidos
		WHERE Valor IS NOT NULL AND Valor > 0;


        COMMIT TRANSACTION;
        PRINT 'Servicios importados correctamente.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
			PRINT 'Error crítico. Ejecuto ROLLBACK.';
			PRINT 'Mensaje de error del sys: ' + ERROR_MESSAGE();
    END CATCH;
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

SP para lote de prueba tabla Expensa
*/


USE Com2900G09
GO

CREATE OR ALTER PROCEDURE sp_lote_expensas
AS
BEGIN
    SET NOCOUNT ON;

    /*
       Genera una expensa por cada combinación de:
       - Consorcio
       - Mes existente en Servicio
       Y asigna un importe base entre 150k y 250k
    */

    DECLARE @min_importe DECIMAL(10,2) = 150000;
    DECLARE @max_importe DECIMAL(10,2) = 250000;

    INSERT INTO Expensa (id_consorcio, mes, importe_total)
    SELECT 
        s.ref_consorcio,
        s.mes,
        @min_importe +
        (ABS(CHECKSUM(NEWID())) % (CAST(@max_importe - @min_importe AS INT)))
    FROM Servicio s
    GROUP BY s.ref_consorcio, s.mes;
END
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

SP para lote de prueba de tabla Factura
*/


USE Com2900G09
GO

CREATE OR ALTER PROCEDURE sp_generar_facturas_prueba
AS
BEGIN
    SET NOCOUNT ON;

    /*
        Genera las facturas basado en los servicios cargados.
        Luego actualiza la tabla Expensa sumando todos
        los importes facturados.
    */

    ------------------------------------
    -- 1) Insertar facturas
    ------------------------------------
    INSERT INTO Factura (id_servicio, id_expensa, fecha_emision, fecha_vencimiento, importe, detalle)
    SELECT
        s.id_servicio,
        e.id_expensa,
        GETDATE(),
        DATEADD(DAY, 30, GETDATE()),
        s.valor,
        'Pago de ' + s.categoria
    FROM Servicio s
    INNER JOIN Expensa e
        ON e.id_consorcio = s.ref_consorcio
        AND e.mes = s.mes;   -- 🔥 ahora coincide con los valores reales


    ------------------------------------
    -- 2) Actualizar Expensa con suma total
    ------------------------------------
    UPDATE e
    SET e.importe_total = e.importe_total + t.total_facturas
    FROM Expensa e
    INNER JOIN (
        SELECT id_expensa, SUM(importe) AS total_facturas
        FROM Factura
        GROUP BY id_expensa
    ) t ON t.id_expensa = e.id_expensa;

END
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

SP para generar lote de prueba a expensa_detalle
*/



CREATE OR ALTER PROCEDURE sp_generar_expensa_detalle_prueba
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fecha_base DATE = GETDATE();

    INSERT INTO Expensa_Detalle 
        (id_expensa, nro_cuota, total_cuotas, descripcion, fecha_venc, importe_uf, estado)
    SELECT
        e.id_expensa,
        d.nro_cuota,
        d.total_cuotas,
        'Expensa mensual - cuota ' + CAST(d.nro_cuota AS VARCHAR) + ' de ' + CAST(d.total_cuotas AS VARCHAR),
        -- Fecha de vencimiento: 10 de cada mes, sumando nro_cuota-1 meses
        DATEADD(MONTH, d.nro_cuota - 1, DATEFROMPARTS(YEAR(@fecha_base), MONTH(@fecha_base), 10)),
        ROUND(e.importe_total / d.total_cuotas, 2),
        CASE 
            WHEN DATEADD(MONTH, d.nro_cuota - 1, DATEFROMPARTS(YEAR(@fecha_base), MONTH(@fecha_base), 10)) < CAST(GETDATE() AS DATE)
                THEN 'Vencido'
            ELSE 'Pendiente'
        END
    FROM Expensa e
    CROSS APPLY (
        -- Generar total de cuotas (1, 3 o 6) de manera aleatoria
        SELECT 
            CASE ABS(CHECKSUM(NEWID())) % 3
                WHEN 0 THEN 1
                WHEN 1 THEN 3
                WHEN 2 THEN 6
            END AS total_cuotas
    ) tc
    CROSS APPLY (
        -- Generar una fila por cada cuota
        SELECT 
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS nro_cuota,
            tc.total_cuotas
        FROM master.dbo.spt_values
        WHERE type = 'P' AND number BETWEEN 1 AND tc.total_cuotas
    ) d;
END
GO


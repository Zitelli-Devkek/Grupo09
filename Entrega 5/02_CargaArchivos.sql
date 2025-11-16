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

-- ===============================================
-- DATOS DE PRUEBA PARA TABLAS DE CONSORCIO Y UF
-- ===============================================


------------------------------
-- DATOS DE PRUEBA
------------------------------
INSERT INTO Consorcio (nombre, cuit, cant_UF, m2)
VALUES
('Consorcio Las Rosas', '30711234567', 12, 850),
('Consorcio Avenida Center', '30719876543', 20, 1450);

INSERT INTO Tipo_Ocupante (descripcion)
VALUES ('Propietario'), ('Inquilino'), ('Administrador');

INSERT INTO Persona (DNI, id_tipo_ocupante, nombre, apellido, email_personal, telefono, cbu_cvu)
VALUES
('20333444', 1, 'Juan', 'Pérez', 'juan@gmail.com', '1122334455', '2850590940090412345678'),
('25444555', 2, 'María', 'Gómez', 'maria@gmail.com', '1166778899', '0170202340000001234567'),
('27888999', 1, 'Carlos', 'López', NULL, '1144556677', '2850590940090499999999'),
('30444555', 3, 'Ana', 'Martínez', 'ana@gmail.com', '1199988877', '0170202340000008888888'),
('28999111', 1, 'Luis', 'García', 'luis@gmail.com', '1112345678', '2850590940090411111111'),
('26555111', 2, 'Sofía', 'Ramírez', 'sofi@gmail.com', '1188877766', '2850590940090422222222');

INSERT INTO Unidad_Funcional (id_consorcio, nr_uf, piso, departamento, coeficiente, m2)
VALUES
(1, 1, 'PB', 'A', 8.50, 55.0),
(1, 2, '1', 'B', 9.20, 60.0),
(1, 3, '2', 'A', 9.80, 65.0),
(2, 1, '1', 'A', 6.50, 42.0),
(2, 2, '1', 'B', 7.00, 45.0);

INSERT INTO Complemento (id_uf, m2, tipo_complemento)
VALUES
(1, 3.0, 'Baulera'),
(1, 12.0, 'Cochera'),
(3, 10.5, 'Cochera'),
(5, 2.5, 'Baulera');

INSERT INTO Servicio (nro_cuenta, mes, categoria, valor)
VALUES
('AGUA001', '2025-01', 'Agua', 45000),
('LUZ002', '2025-01', 'Electricidad', 72000),
('LIMP003', '2025-01', 'Limpieza', 35000),
('ASC004', '2025-01', 'Ascensor', 52000);

INSERT INTO Expensa (id_consorcio, DNI, mes, importe_total)
VALUES
(1, '20333444', '2025-01', 250000), -- Juan Pérez
(1, '28999111', '2025-02', 255000), -- Luis García
(2, '25444555', '2025-01', 390000), -- María Gómez
(2, '26555111', '2025-02', 400000); -- Sofía Ramírez

INSERT INTO Proveedor (id_proveedor, nombre_consorcio, categoria, nombre_proveedor, detalle)
VALUES
(1, 'Consorcio Las Rosas', 'Limpieza', 'CleanMax', 'Limpieza mensual'),
(2, 'Consorcio Las Rosas', 'Mantenimiento', 'ElevatorFix', 'Ascensores'),
(3, 'Consorcio Avenida Center', 'Agua', 'Aguas Argentinas', 'Servicio de agua'),
(4, 'Consorcio Avenida Center', 'Electricidad', 'Edesur', 'Servicio eléctrico');

INSERT INTO Factura (id_servicio, id_expensa, id_proveedor, fecha_emision, fecha_vencimiento, importe, detalle)
VALUES
(1, 1, 3, '2025-01-02', '2025-01-15', 45000, 'Agua enero'),
(2, 3, 4, '2025-01-05', '2025-01-20', 72000, 'Luz enero'),
(3, 1, 1, '2025-01-03', '2025-01-10', 35000, 'Limpieza general'),
(4, 1, 2, '2025-01-04', '2025-01-25', 52000, 'Ascensor enero');

INSERT INTO Expensa_Detalle (id_expensa, nro_cuota, total_cuotas, descripcion, fecha_venc, importe_uf, estado)
VALUES
(1, 1, 1, 'Expensa común enero', '2025-02-10', 18000, 'Pendiente'),
(1, 1, 3, 'Ascensor Cuota 1', '2025-02-15', 6200, 'Pendiente'),
(1, 2, 3, 'Ascensor Cuota 2', '2025-03-15', 6200, 'Pendiente'),
(3, 1, 1, 'Expensa común enero', '2025-02-12', 24000, 'Pagado'),
(4, 1, 1, 'Expensa común febrero', '2025-03-12', 25000, 'Pendiente'),
(2, 1, 1, 'Expensa común febrero', '2025-03-10', 18500, 'Pendiente');

INSERT INTO Pago (id_pago, id_exp_detalle, fecha, cvu_cbu, valor)
VALUES
(1, 1, '2025-02-05', '2850590940090412345678', 18000),
(2, 4, '2025-02-01', '0170202340000001234567', 24000),
(3, 6, '2025-03-05', '2850590940090422222222', 18500);

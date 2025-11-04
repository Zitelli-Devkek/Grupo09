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

Creacion de SP para importacion de pagos_consorcios.csv
*/

CREATE OR ALTER PROCEDURE sp_ImportarPagosCSV
    @RutaArchivo NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @SQL NVARCHAR(MAX); 
    --Para generar reportes acerca de la importacion del archivo
    DECLARE @TotalFilasBrutas INT = 0;
    DECLARE @FilasInsertadas INT = 0;
    DECLARE @FilasIgnoradas_Duplicados INT = 0;
    DECLARE @FilasIgnoradas INT = 0;
    
    
    CREATE TABLE #TempPagos (--Creo tabla temporal para la lectura de los datos como VARCHAR
        [Id de pago] VARCHAR(50),
        [fecha] VARCHAR(50),
        [CVU/CBU] VARCHAR(50),
        [Valor ] VARCHAR(50) 
    );

    --Aplicar logica de doble lectura BULK por si falla la primera
    -- el intento 1 del bulk es con la Configuración Windows/ANSI (Más probable si falla UTF-8)
    BEGIN TRY
        SET @SQL = N'
        BULK INSERT #TempPagos
        FROM ''' + @RutaArchivo + N'''
        WITH (FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', FIRSTROW = 2, CODEPAGE = ''1252'');';--0x0d0a es para decirle que el archivo se hizo en el formato de windows
        
        EXEC sp_executesql @SQL;
        SELECT @TotalFilasBrutas = COUNT(*) FROM #TempPagos;--cuento las filas para el reporte
    END TRY
    BEGIN CATCH
        -- Si falla el Intento 1 por permisos o ruta, el error será reportado al final.
        
    END CATCH--el segundo intento se ejecuta si es un error de lectura (del primer bulk)
    
    IF @TotalFilasBrutas = 0--condicion para que ejecute la segunda lectura
    BEGIN
        PRINT 'Primera lectura fallida, se vuelve a intentar con UTF-8';
        TRUNCATE TABLE #TempPagos; --vacia la tabla temporal

        BEGIN TRY--hago el BULK pero con UTF-8 con su codepage correspondiente
            SET @SQL = N'
            BULK INSERT #TempPagos
            FROM ''' + @RutaArchivo + N'''
            WITH (FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', FIRSTROW = 2, CODEPAGE = ''65001'');';
            
            EXEC sp_executesql @SQL;
            SELECT @TotalFilasBrutas = COUNT(*) FROM #TempPagos;--cuento filas brutas (VARCHAR)

        END TRY
        BEGIN CATCH--si vuelve a fallar, salimos y reportamos el error
            PRINT 'ERROR: AMBAS LECTURAS FALLARON.';
            IF OBJECT_ID('tempdb..#TempPagos') IS NOT NULL DROP TABLE #TempPagos;--dropeo la tabla temporal
            RETURN -1;
        END CATCH
    END

    IF @TotalFilasBrutas = 0--si no se leyeron filas tiro el error de que no se pudieron leer las filas del csv
    BEGIN
        PRINT 'Error: No se pudieron leer filas del archivo CSV después de dos intentos.';
        RETURN -1;
    END
    
    --USO CTEs PARA MODULAR EL CODIGO 

    --CTE para limpieza de datos y casteo
    ;WITH DatosLimpios AS (
        SELECT
            TRY_CAST(LTRIM(RTRIM([Id de pago])) AS INT) AS IdPago_limpio,--elimino espacios a los lados y lo guardo como INT con try_cast
            TRY_CONVERT(DATE, LTRIM(RTRIM([fecha])), 103) AS Fecha_limpio,---- 103 es el código de formato para DD/MM/YYYY.
            REPLACE(LTRIM(RTRIM([CVU/CBU])), ' ', '') AS CBU_limpio,--elimina espacios intermedios y en blanco
            TRY_CAST(REPLACE(REPLACE(LTRIM(RTRIM([Valor ])), '$', ''), '.', '') AS DECIMAL(10,2)) AS Valor_limpio--elimina los signos para juntar todo el dato
        FROM #TempPagos
    ),
    
    --CTE para validar datos
    validacion AS (
        SELECT
            c.IdPago_limpio, c.Fecha_limpio, c.Valor_limpio, c.CBU_limpio,
            'Transferencia CVU/CBU' AS MedioPago, --defino el medio de pago que no llega directamente por archivo
            NULL AS id_exp_detalle, --asigno NULL ya que el archivo no lo tiene
            bandera = --genero una bandera para poner las columnas "buenas=0" y las "malas=1"
            CASE
                WHEN c.IdPago_limpio IS NULL OR c.IdPago_limpio <= 0 THEN 1 --El ID de Pago debe ser un número entero válido y mayor que cero.
                WHEN c.Fecha_limpio IS NULL THEN 1 --Que no haya fallado la conversion ed la fecha (fecha_limpio no debe ser NULL).
                WHEN c.Valor_limpio IS NULL OR c.Valor_limpio <= 0 THEN 1 --El Valor debe ser un número decimal válido y mayor que cero.
                WHEN c.CBU_limpio IS NULL OR c.CBU_limpio = '' THEN 1 --El CBU/CVU es obligatorio.
                ELSE 0--si cumple todo, entonces se asigna un 0 a la bandera
            END
        FROM DatosLimpios c
    )
    
    --ACA REALIZO EL FILTRADO DE DATOS BUENOS
    SELECT vd.*
    INTO #TempInsert--TABLA TEMPORAL LOCAL DE SQL SERVER
    FROM validacion vd
    WHERE vd.bandera = 0;--INSERTO SOLO LAS FILAS BUENAS EN LA TABLA TEMPORAL


    --CONTEO PARA EL REPORTE FINAL
    DECLARE @TotalFilasTemp INT;
    SELECT @TotalFilasTemp = COUNT(*) FROM #TempInsert;
    SELECT @FilasIgnoradas = @TotalFilasBrutas - @TotalFilasTemp;

    
    BEGIN TRANSACTION;-- Se usa transacción para asegurar que Pago y Pago_Importado se inserten juntas
    
    BEGIN TRY
        
        --hago la insercion a la tabla pagos
        INSERT INTO dbo.Pago (id_pago, fecha, medio_pago, valor, id_exp_detalle)
        SELECT
            ti.IdPago_limpio, ti.Fecha_limpio, ti.MedioPago, ti.Valor_limpio, ti.id_exp_detalle
        FROM #TempInsert ti
        WHERE
            NOT EXISTS (SELECT 1 FROM dbo.Pago p WHERE p.id_pago = ti.IdPago_limpio);--si no existe id_pago en la tabla dbo.Pago
            
        SET @FilasInsertadas = @@ROWCOUNT;--contar cuantas filas se afectaron en la operacion anterior

        --insercion a la tabla Pago_Importado 
        INSERT INTO dbo.Pago_Importado (id_pago, fecha_importacion, cuenta_origen)
        SELECT
            ti.IdPago_limpio, GETDATE(), ti.CBU_limpio--gatedate por la fecha de importacion ya que no tiene que ser nula
        FROM #TempInsert ti
        WHERE
            EXISTS (SELECT 1 FROM dbo.Pago p WHERE p.id_pago = ti.IdPago_limpio);--si el id existe en la tabla pago

        
        SELECT @FilasIgnoradas_Duplicados = @TotalFilasTemp - @FilasInsertadas;--para saber al cant de duplicados

        COMMIT TRANSACTION;-- se commitea la transaccion
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;--ROLLBACK si es que hay transacciones ejecutandose
        PRINT 'Error durante la inserción de datos. Se ejecuta ROLLBACK';
        SET @FilasInsertadas = 0; --para informar en el reporte
    END CATCH

    
    --REPORTE
    PRINT 'Filas totales leidas brutas (VARCHAR): ' + CAST(@TotalFilasBrutas AS VARCHAR(10));
    PRINT 'Filas insertadas exitosamente en Pago y Pago_Importado: ' + CAST(@FilasInsertadas AS VARCHAR(10));
    PRINT 'Filas ignoradas (Id de Pago Duplicado): ' + CAST(@FilasIgnoradas_Duplicados AS VARCHAR(10));
    PRINT 'Filas ignoradas (Datos inválidos o espacios vacios): ' + CAST(@FilasIgnoradas AS VARCHAR(10));

    --LIMPIEZA DE TABLAS TEMPORALES
    IF OBJECT_ID('tempdb..#TempPagos') IS NOT NULL DROP TABLE #TempPagos;
    IF OBJECT_ID('tempdb..#TempInsert') IS NOT NULL DROP TABLE #TempInsert;

    SET NOCOUNT OFF;
END
GO

--EXEC sp_ImportarPagosCSV @RutaArchivo = 'D:\Universidad\Materias\Bdd_Aplicada\Archivos\pagos_consorcios.csv'
--GO

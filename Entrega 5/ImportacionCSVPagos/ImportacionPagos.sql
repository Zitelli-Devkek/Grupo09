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

SP para importacion de pagos_consorcios.csv
*/

USE Com2900G09
GO

CREATE OR ALTER PROCEDURE sp_ImportarPagos_Consorcio
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Si existe tabla temporal la elimino
        IF OBJECT_ID('tempdb..#PagosTemp') IS NOT NULL
            DROP TABLE #PagosTemp;

        CREATE TABLE #PagosTemp (
            id_pago NVARCHAR(50),
            fecha NVARCHAR(20),
            cvu_cbu NVARCHAR(25),
            valor NVARCHAR(50)
        );

        -- Cargar el archivo CSV
        DECLARE @sql NVARCHAR(MAX) = '
            BULK INSERT #PagosTemp
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''\n'',
                FIRSTROW = 2,
                CODEPAGE = ''65001''
            );';

        EXEC(@sql);

        -- Insertar solo los registros válidos y no duplicados
        INSERT INTO Pago (id_pago, fecha, cvu_cbu, valor)
        SELECT 
            TRY_CAST(id_pago AS INT),
            TRY_CAST(fecha AS DATE),
            LTRIM(RTRIM(cvu_cbu)),
            TRY_CAST(REPLACE(REPLACE(valor, '$', ''), '.', '') AS DECIMAL(10,2)) / 100
        FROM #PagosTemp AS t
        WHERE 
            TRY_CAST(id_pago AS INT) IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM Pago p WHERE p.id_pago = TRY_CAST(t.id_pago AS INT));

        COMMIT TRANSACTION;
        PRINT 'Importación finalizada correctamente.';
        PRINT 'Importación a Pagos completada.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'Error crítico: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

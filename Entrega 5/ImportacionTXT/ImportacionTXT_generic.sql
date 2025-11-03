CREATE OR ALTER PROCEDURE sp_ImportarDatosTXT
    @RutaArchivo NVARCHAR(500),
    @Delimitador CHAR(1) = NULL--como no se puede poner (char(9)) que referencia al ASCII lo asigno abajo
AS
BEGIN
    SET NOCOUNT ON;

   
    IF @Delimitador IS NULL
        SET @Delimitador = CHAR(9); -- Asigna TAB (CHAR(9)) por defecto si no se pasa el parámetro (TAB del ASCII)

    BEGIN TRANSACTION;
    BEGIN TRY

       
        IF OBJECT_ID('tempdb..#tablaTemporal') IS NOT NULL --si ya esxiste una tabla temporal con ese nombre, la borra
            DROP TABLE #tablaTemporal;

        CREATE TABLE #tablaTemporal (--crea la tabla temporal
            [Nombre del consorcio]  NVARCHAR(100),
            [nroUnidadFuncional]    INT,
            [Piso]                  NVARCHAR(10),
            [departamento]          NVARCHAR(10),
            [coeficiente]           NVARCHAR(50),
            [m2_unidad_funcional]   INT,
            [bauleras]              VARCHAR(2),
            [cochera]               VARCHAR(2),
            [m2_baulera]            INT,
            [m2_cochera]            INT
        );

       
        DECLARE @Sql NVARCHAR(MAX);--BULK INSERT a tabla temporal
        DECLARE @RutaSegura NVARCHAR(1000);
        --para "escapar" de '' uso el replace de abajo
        SET @RutaSegura = N'''' + REPLACE(@RutaArchivo, '''', '''''') + N'''';--concatenar la ruta d earchivo
        DECLARE @DelimSeguro NVARCHAR(10);
        SET @DelimSeguro = N'''' + REPLACE(@Delimitador, '''', '''''') + N''''; --para el delimitador

        SET @Sql = N'
            BULK INSERT #tablaTemporal
            FROM ' + @RutaSegura + N'
            WITH (
                FIELDTERMINATOR = ' + @DelimSeguro + N',
                FIRSTROW = 2,
                CODEPAGE = ''ACP''
            );';--sql dinamico

        EXEC sp_executesql @Sql;--ejecutar sql dinamico
        PRINT 'BULK INSERT a tabla temporal completado.';


        INSERT INTO dbo.consorcio ( --Insertar en dbo.consorcio (Maestro)
            nombre
        )
        SELECT
            DISTINCT 
            tt.[Nombre del consorcio]
        FROM
            #tablaTemporal tt
        WHERE
            tt.[Nombre del consorcio] IS NOT NULL --filtro para ignorar lineas en blanco
            
            AND NOT EXISTS (
                SELECT *
                FROM dbo.consorcio tp
                WHERE tp.nombre = tt.[Nombre del consorcio]
            );
            

        INSERT INTO dbo.unidad_funcional (--Insertar en dbo.unidad_funcional (Detalle)
            id_consorcio,  nr_uf, piso, departamento, coeficiente, m2             
        )
        SELECT
            tp.id_consorcio, 
            tt.[nroUnidadFuncional],
            tt.[Piso],
            tt.[departamento],
            TRY_CONVERT(DECIMAL(10, 2), REPLACE(tt.[coeficiente], ',', '.')), 
            tt.[m2_unidad_funcional]
        FROM
            #tablaTemporal tt
        JOIN
            dbo.consorcio tp ON tt.[Nombre del consorcio] = tp.nombre
        WHERE
            NOT EXISTS (
                SELECT *
                FROM dbo.unidad_funcional uf
                WHERE uf.id_consorcio = tp.id_consorcio
                  AND uf.nr_uf = tt.[nroUnidadFuncional]
            )
            AND TRY_CONVERT(DECIMAL(10, 2), REPLACE(tt.[coeficiente], ',', '.')) IS NOT NULL;

        PRINT 'Inserción en dbo.unidad_funcional completada (filas con error de coeficiente omitidas).';

        ;WITH ComplementosAIngresar (id_uf, m2, tipo_complemento) AS (--Insertar en dbo.Complemento (Bauleras y Cocheras unificadas)
            --Bauleras
            SELECT
                uf.id_uf, tt.[m2_baulera], 'Baulera' AS tipo_complemento
            FROM
                #tablaTemporal tt
            JOIN 
                dbo.consorcio c ON tt.[Nombre del consorcio] = c.nombre
            JOIN 
                dbo.unidad_funcional uf ON c.id_consorcio = uf.id_consorcio 
                                        AND tt.[nroUnidadFuncional] = uf.nr_uf
            WHERE
                tt.[bauleras] = 'SI' AND tt.[m2_baulera] > 0

            UNION ALL 
            --Cocheras
            SELECT
                uf.id_uf, tt.[m2_cochera], 'Cochera' AS tipo_complemento
            FROM
                #tablaTemporal tt
            JOIN 
                dbo.consorcio c ON tt.[Nombre del consorcio] = c.nombre
            JOIN 
                dbo.unidad_funcional uf ON c.id_consorcio = uf.id_consorcio 
                                        AND tt.[nroUnidadFuncional] = uf.nr_uf
            WHERE
                tt.[cochera] = 'SI' AND tt.[m2_cochera] > 0
        )
        INSERT INTO dbo.Complemento (
            id_uf, m2, tipo_complemento
        )
        SELECT
            cte.id_uf, cte.m2, cte.tipo_complemento
        FROM
            ComplementosAIngresar cte
        WHERE
            NOT EXISTS (
                SELECT 1
                FROM dbo.Complemento comp_existente
                WHERE comp_existente.id_uf = cte.id_uf
                  AND comp_existente.tipo_complemento = cte.tipo_complemento
            );

        PRINT 'Inserción en dbo.Complemento (Bauleras y Cocheras) completada.';

        COMMIT TRANSACTION;
        PRINT 'Proceso de importación finalizado. Se guardaron los datos buenos.';

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error crítico durante la importación. Se ha revertido la transacción.';
        THROW; 
        
    END CATCH

    IF OBJECT_ID('tempdb..#tablaTemporal') IS NOT NULL--elimino tabla temporal
        DROP TABLE #tablaTemporal;

END
GO

--EJECUTAR SP
EXEC sp_ImportarDatosTXT 
    @RutaArchivo = 'D:\Universidad\Materias\Bdd_Aplicada\Archivos\UF por consorcio.txt'
GO

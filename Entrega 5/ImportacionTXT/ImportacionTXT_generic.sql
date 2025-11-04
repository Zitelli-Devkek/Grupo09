CREATE OR ALTER PROCEDURE sp_ImportarUF_TXT
    @RutaArchivo NVARCHAR(500),
    @Delimitador CHAR(1) = NULL--como no puedo poner aca el delimitador con ASCII pongo NULL y lo seteo abajo
AS
BEGIN
    SET NOCOUNT ON;

    IF @Delimitador IS NULL
        SET @Delimitador = CHAR(9); -- Asigna TAB del ASCII (CHAR(9)) por defecto si no se pasa el parámetro

    BEGIN TRANSACTION;
    BEGIN TRY
       
        -- Si existe una tt con ese nombre la borra
        IF OBJECT_ID('tempdb..#tablaTemporal') IS NOT NULL
            DROP TABLE #tablaTemporal;

        -- Crea la tabla temporal con tipos de datos seguros (NVARCHAR) para evitar que BULK INSERT falle
        CREATE TABLE #tablaTemporal (
            [Nombre del consorcio]  NVARCHAR(100),
            [nroUnidadFuncional]    NVARCHAR(50), 
            [Piso]                  NVARCHAR(10),
            [departamento]          NVARCHAR(10),
            [coeficiente]           NVARCHAR(50),
            [m2_unidad_funcional]   NVARCHAR(50), 
            [bauleras]              VARCHAR(2),
            [cochera]               VARCHAR(2),
            [m2_baulera]            NVARCHAR(50),
            [m2_cochera]            NVARCHAR(50)  
        );

       
        -- BULK INSERT a tabla temporal (SQL dinámico)
        DECLARE @Sql NVARCHAR(MAX);
        DECLARE @RutaSegura NVARCHAR(1000) = N'''' + REPLACE(@RutaArchivo, '''', '''''') + N'''';
        DECLARE @DelimSeguro NVARCHAR(10) = N'''' + REPLACE(@Delimitador, '''', '''''') + N'''';

        SET @Sql = N'
            BULK INSERT #tablaTemporal
            FROM ' + @RutaSegura + N'
            WITH (
                FIELDTERMINATOR = ' + @DelimSeguro + N',
                FIRSTROW = 2,
                DATAFILETYPE = ''char'' -- char para mayor compatibilidad
            );';

        EXEC sp_executesql @Sql;
        PRINT 'BULK INSERT a la tabla temporal completado.';


        -- Insertar en tabla consorcio
        INSERT INTO dbo.consorcio (nombre)
        SELECT
            DISTINCT  tt.[Nombre del consorcio]
        FROM #tablaTemporal tt
        WHERE
            tt.[Nombre del consorcio] IS NOT NULL            
            AND NOT EXISTS (
                SELECT 1 FROM dbo.consorcio tp WHERE tp.nombre = tt.[Nombre del consorcio]
            );
        
        PRINT 'Inserción en dbo.consorcio completada.';


        -- Insertar en unidad_funcional
        INSERT INTO dbo.unidad_funcional (
            id_consorcio,  nr_uf, piso, departamento, coeficiente, m2             
        )
        SELECT
            tp.id_consorcio, 
            TRY_CONVERT(INT, tt.[nroUnidadFuncional]), -- Conversión segura a INT
            tt.[Piso],
            tt.[departamento],
            TRY_CONVERT(DECIMAL(6, 3), REPLACE(tt.[coeficiente], ',', '.')), -- Conversión y limpieza de coma para tipo de dato
            TRY_CONVERT(DECIMAL(10, 2), tt.[m2_unidad_funcional]) -- Conversión segura a DECIMAL
        FROM
            #tablaTemporal tt
        JOIN
            dbo.consorcio tp ON tt.[Nombre del consorcio] = tp.nombre
        WHERE
            NOT EXISTS (
                SELECT 1 FROM dbo.unidad_funcional uf
                WHERE uf.id_consorcio = tp.id_consorcio AND uf.nr_uf = TRY_CONVERT(INT, tt.[nroUnidadFuncional])
            )
            -- Filtramos cualquier fila que no pudo convertir los campos clave
            AND TRY_CONVERT(INT, tt.[nroUnidadFuncional]) IS NOT NULL 
            AND TRY_CONVERT(DECIMAL(6, 3), REPLACE(tt.[coeficiente], ',', '.')) IS NOT NULL;

        PRINT 'Inserción en dbo.unidad_funcional completada (filas con error de formato omitidas).';

        
        -- Insertar en tabla complemento usando CTE
        ;WITH ComplementosAIngresar (id_uf, m2, tipo_complemento) AS (
            -- Bauleras
            SELECT
                uf.id_uf, TRY_CONVERT(DECIMAL(10, 2), tt.[m2_baulera]), 'Baulera' AS tipo_complemento
            FROM #tablaTemporal tt
            JOIN dbo.consorcio c ON tt.[Nombre del consorcio] = c.nombre
            JOIN dbo.unidad_funcional uf ON c.id_consorcio = uf.id_consorcio AND TRY_CONVERT(INT, tt.[nroUnidadFuncional]) = uf.nr_uf
            WHERE tt.[bauleras] = 'SI' AND TRY_CONVERT(DECIMAL(10, 2), tt.[m2_baulera]) IS NOT NULL AND TRY_CONVERT(DECIMAL(10, 2), tt.[m2_baulera]) > 0

            UNION ALL 
            -- Cocheras
            SELECT
                uf.id_uf, TRY_CONVERT(DECIMAL(10, 2), tt.[m2_cochera]), 'Cochera' AS tipo_complemento
            FROM #tablaTemporal tt
            JOIN dbo.consorcio c ON tt.[Nombre del consorcio] = c.nombre
            JOIN dbo.unidad_funcional uf ON c.id_consorcio = uf.id_consorcio AND TRY_CONVERT(INT, tt.[nroUnidadFuncional]) = uf.nr_uf
            WHERE tt.[cochera] = 'SI' AND TRY_CONVERT(DECIMAL(10, 2), tt.[m2_cochera]) IS NOT NULL AND TRY_CONVERT(DECIMAL(10, 2), tt.[m2_cochera]) > 0
        ) -- ¡Aquí terminaba el corte!
        
        --Insercion en complemento
        INSERT INTO dbo.Complemento (id_uf, m2, tipo_complemento)
        SELECT
            cte.id_uf, cte.m2, cte.tipo_complemento
        FROM ComplementosAIngresar cte
        WHERE
            NOT EXISTS (
                SELECT 1 FROM dbo.Complemento comp_existente
                WHERE comp_existente.id_uf = cte.id_uf AND comp_existente.tipo_complemento = cte.tipo_complemento
            );

        PRINT 'Inserción en tabla complemento finalizada.';

        COMMIT TRANSACTION;

        PRINT 'Proceso de importación de UF finalizado.';

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error crítico durante la importación. Se ha revertido la transacción.';
        THROW; 
    END CATCH

    -- Elimino tabla temporal
    IF OBJECT_ID('tempdb..#tablaTemporal') IS NOT NULL
        DROP TABLE #tablaTemporal;

END
GO

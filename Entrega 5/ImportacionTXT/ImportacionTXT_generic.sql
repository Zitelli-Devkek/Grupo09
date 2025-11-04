CREATE OR ALTER PROCEDURE sp_ImportarUF_TXT
    @RutaArchivo NVARCHAR(500),
    @Delimitador CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Delimitador IS NULL
        SET @Delimitador = CHAR(9); --Asigna TAB del ASCII (CHAR(9)) por defecto si no se pasa el parámetro

    BEGIN TRANSACTION;
    BEGIN TRY
       
        
        IF OBJECT_ID('tempdb..#tablaTemporal') IS NOT NULL--si existe una tt con ese nombre la borra
            DROP TABLE #tablaTemporal;

        CREATE TABLE #tablaTemporal (--Crea la tabla temporal con tipos de datos seguros (NVARCHAR)
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

       
        
        DECLARE @Sql NVARCHAR(MAX);--BULK INSERT a tabla temporal (SQL dinámico)
        DECLARE @RutaSegura NVARCHAR(1000) = N'''' + REPLACE(@RutaArchivo, '''', '''''') + N'''';
        DECLARE @DelimSeguro NVARCHAR(10) = N'''' + REPLACE(@Delimitador, '''', '''''') + N'''';

        SET @Sql = N'
            BULK INSERT #tablaTemporal
            FROM ' + @RutaSegura + N'
            WITH (
                FIELDTERMINATOR = ' + @DelimSeguro + N',
                FIRSTROW = 2,
                DATAFILETYPE = ''char'' --char para mayor compatibilidad
            );';

        EXEC sp_executesql @Sql;
        PRINT 'BULK INSERT a la tabla temporal completado.';


        
   INSERT INTO dbo.consorcio (nombre, direccion, admin_cuit) 
        SELECT
             DISTINCT tt.[Nombre del consorcio],
                'DIRECCION PENDIENTE', 
                -- 1. Usamos VARCHAR(3) para que quepan 142 filas.
                -- 2. Concatenamos 8 ceros ('00000000') para que el total sea 11 caracteres (8 + 3 = 11).
                '00000000' + RIGHT('00' + CAST(ROW_NUMBER() OVER (ORDER BY tt.[Nombre del consorcio]) AS VARCHAR(3)), 3)
                FROM #tablaTemporal tt
                    WHERE
                         tt.[Nombre del consorcio] IS NOT NULL
                            AND NOT EXISTS (
                             SELECT 1 FROM dbo.consorcio tp WHERE tp.nombre = tt.[Nombre del consorcio]
                             );
 
   INSERT INTO dbo.unidad_funcional ( id_consorcio,  nr_uf, piso, departamento, coeficiente, m2)
          
          SELECT tp.id_consorcio, 
             TRY_CONVERT(INT, tt.[nroUnidadFuncional]), 
                            tt.[Piso],
                             tt.[departamento],
    -- ¡La división por 100.0 resuelve el CHECK!
    TRY_CONVERT(DECIMAL(6, 3), REPLACE(tt.[coeficiente], ',', '.')) / 100.0 AS coeficiente, --divido por 100 el coeficiente para cumplir con nuestra condicion de check en nuestra tabla
    TRY_CONVERT(DECIMAL(10, 2), tt.[m2_unidad_funcional]) 
         FROM
             #tablaTemporal tt
            JOIN
            dbo.consorcio tp ON tt.[Nombre del consorcio] = tp.nombre
        WHERE
            NOT EXISTS (
                SELECT 1 FROM dbo.unidad_funcional uf
                WHERE uf.id_consorcio = tp.id_consorcio AND uf.nr_uf = TRY_CONVERT(INT, tt.[nroUnidadFuncional])
            )
            AND TRY_CONVERT(INT, tt.[nroUnidadFuncional]) IS NOT NULL 
            -- Filtro de seguridad adicional: solo insertamos si la división por 100 nos da un valor válido.
            AND TRY_CONVERT(DECIMAL(6, 3), REPLACE(tt.[coeficiente], ',', '.')) / 100.0 IS NOT NULL;

                PRINT 'Se insertaron los datos en la tabla unidad funcional.';

        
        
        ;WITH ComplementosAIngresar (id_uf, m2, tipo_complemento) AS (--Insertar en tabla complemento usando CTE
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
        )
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

    IF OBJECT_ID('tempdb..#tablaTemporal') IS NOT NULL
        DROP TABLE #tablaTemporal;

END
GO


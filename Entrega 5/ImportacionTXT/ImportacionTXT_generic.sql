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
            [bauleras]              VARCHAR(2),--en estos varchar simples va "si" o "no" de las bauleras/cocheras
            [cochera]               VARCHAR(2),
            [m2_baulera]            NVARCHAR(50),
            [m2_cochera]            NVARCHAR(50)  
        );

       
        
        DECLARE @Sql NVARCHAR(MAX);--BULK INSERT a tabla temporal (SQL dinámico)
        --lei que asi se hacen las variables seguras para prevenir inyección SQL al usar comillas.
        DECLARE @RutaSegura NVARCHAR(1000) = N'''' + REPLACE(@RutaArchivo, '''', '''''') + N'''';
        DECLARE @DelimSeguro NVARCHAR(10) = N'''' + REPLACE(@Delimitador, '''', '''''') + N'''';

        SET @Sql = N'
            BULK INSERT #tablaTemporal
            FROM ' + @RutaSegura + N'
            WITH (
                FIELDTERMINATOR = ' + @DelimSeguro + N',
                FIRSTROW = 2,
                DATAFILETYPE = ''char'' --indica que el archivo es de caracteres (texto plano)
            );';

        EXEC sp_executesql @Sql;
        PRINT 'BULK INSERT a la tabla temporal completado.';


        
   INSERT INTO dbo.consorcio (nombre, direccion, admin_cuit) 
        SELECT
             DISTINCT tt.[Nombre del consorcio],--solo nombres unicos de consorcio
                'DIRECCION PENDIENTE', --por defecto, ya que la dirección no está en el archivo.
                --Se crea un CUIT  de 11 dígitos.
                '00000000' + RIGHT('00' + CAST(ROW_NUMBER() OVER (ORDER BY tt.[Nombre del consorcio]) AS VARCHAR(3)), 3)
                FROM #tablaTemporal tt
                    WHERE
                         tt.[Nombre del consorcio] IS NOT NULL--que el nombre no sea nulo
                            AND NOT EXISTS (--para excluir a los consorcios que ya existen en la tabla final
                             SELECT 1 FROM dbo.consorcio tp WHERE tp.nombre = tt.[Nombre del consorcio]
                             );
 
   INSERT INTO dbo.unidad_funcional ( id_consorcio,  nr_uf, piso, departamento, coeficiente, m2)
          
          SELECT tp.id_consorcio, 
             TRY_CONVERT(INT, tt.[nroUnidadFuncional]), -- Conversión segura del número de UF
                            tt.[Piso],
                             tt.[departamento],
    --Limpia la coma por punto y divide por 100 ya que teniamos una constraint CHECK de 0 a 1 (a cambiar)
    TRY_CONVERT(DECIMAL(6, 3), REPLACE(tt.[coeficiente], ',', '.')) / 100.0 AS coeficiente, --divido por 100 el coeficiente 
    TRY_CONVERT(DECIMAL(10, 2), tt.[m2_unidad_funcional]) 
         FROM
             #tablaTemporal tt
            JOIN
            dbo.consorcio tp ON tt.[Nombre del consorcio] = tp.nombre
        WHERE
            NOT EXISTS (--no inserto UF duplicados (por Consorcio ID y número de UF)
                SELECT 1 FROM dbo.unidad_funcional uf
                WHERE uf.id_consorcio = tp.id_consorcio AND uf.nr_uf = TRY_CONVERT(INT, tt.[nroUnidadFuncional])
            )
            AND TRY_CONVERT(INT, tt.[nroUnidadFuncional]) IS NOT NULL --para que el número de UF sea válido
            --solo insertamos si la división por 100 nos da un valor válido.
            AND TRY_CONVERT(DECIMAL(6, 3), REPLACE(tt.[coeficiente], ',', '.')) / 100.0 IS NOT NULL;

                PRINT 'Se insertaron los datos en la tabla unidad funcional.';

        
        --USO CTE PARA INSERTAR EN LA TABLA COMPLEMENTO
        ;WITH ComplementosAIngresar (id_uf, m2, tipo_complemento) AS (
            -- Bauleras
            SELECT
                uf.id_uf, TRY_CONVERT(DECIMAL(10, 2), tt.[m2_baulera]), 'Baulera' AS tipo_complemento
            FROM #tablaTemporal tt
            JOIN dbo.consorcio c ON tt.[Nombre del consorcio] = c.nombre--este join encuentra el ID de Consorcio para el nombre dado.
            JOIN dbo.unidad_funcional uf ON c.id_consorcio = uf.id_consorcio AND TRY_CONVERT(INT, tt.[nroUnidadFuncional]) = uf.nr_uf
                --el segundo JOIN usa el ID de Consorcio y el número de UF para encontrar el id_uf de la base de datos, para la insercion final.
                --Si la columna dice 'SI' Y los m2 son válidos y > 0
            WHERE tt.[bauleras] = 'SI' AND TRY_CONVERT(DECIMAL(10, 2), tt.[m2_baulera]) IS NOT NULL AND TRY_CONVERT(DECIMAL(10, 2), tt.[m2_baulera]) > 0

            UNION ALL -- Combina los resultados 
            -- Cocheras
            SELECT
                uf.id_uf, TRY_CONVERT(DECIMAL(10, 2), tt.[m2_cochera]), 'Cochera' AS tipo_complemento
            FROM #tablaTemporal tt
            JOIN dbo.consorcio c ON tt.[Nombre del consorcio] = c.nombre
            JOIN dbo.unidad_funcional uf ON c.id_consorcio = uf.id_consorcio AND TRY_CONVERT(INT, tt.[nroUnidadFuncional]) = uf.nr_uf
            --mismo procedimiento que antes, si la columna dice 'SI' Y los m2 son válidos y > 0
            WHERE tt.[cochera] = 'SI' AND TRY_CONVERT(DECIMAL(10, 2), tt.[m2_cochera]) IS NOT NULL AND TRY_CONVERT(DECIMAL(10, 2), tt.[m2_cochera]) > 0
        )

        --AHORA TOMO LOS DATOS DE LA CTE ANTERIOR
        INSERT INTO dbo.Complemento (id_uf, m2, tipo_complemento)
        SELECT
            cte.id_uf, cte.m2, cte.tipo_complemento
        FROM ComplementosAIngresar cte
        WHERE
            NOT EXISTS (--para evitar duplicados, no inserta si ya existe un complemento del mismo tipo (ej. 2 Bauleras) para esa misma UF.
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
        PRINT 'Ocurrió un error en la importacion. Se ejecuta ROLLBACK';
        THROW; 
    END CATCH

    IF OBJECT_ID('tempdb..#tablaTemporal') IS NOT NULL
        DROP TABLE #tablaTemporal;

END
GO


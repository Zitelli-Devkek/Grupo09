CREATE OR ALTER PROCEDURE sp_ImportarDatosTXT
    @RutaArchivo NVARCHAR(500),
    @Delimitador CHAR(1) = '\t'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY

        --Primero creo la tabla temporal (la borro si ya existe una con ese nombre)
        IF OBJECT_ID('tempdb..#tablaTemporal') IS NOT NULL
            DROP TABLE #tablaTemporal;

        CREATE TABLE #tablaTemporal (
            [Nombre del consorcio]  NVARCHAR(100),
            [nroUnidadFuncional]    INT,
            [Piso]                  NVARCHAR(10),
            [departamento]          NVARCHAR(10),
            [coeficiente]           NVARCHAR(50), --Pasar como texto porque en el archivo hay una ',' cuando tiene que ir '.'
            [m2_unidad_funcional]   INT,
            [bauleras]              VARCHAR(2),
            [cochera]               VARCHAR(2),
            [m2_baulera]            INT,
            [m2_cochera]            INT
        );


          --Hago el BULK INSERT
        DECLARE @Sql NVARCHAR(MAX);
        SET @Sql = N'
            BULK INSERT #tablaTemporal
            FROM @RutaParam
            WITH (
                FIELDTERMINATOR = @DelimParam,
                ROWTERMINATOR = ''\n'',
                FIRSTROW = 2,
                CODEPAGE = ''ACP'' -- Agregado: bueno para tildes
            );';

        EXEC sp_executesql @Sql,
            N'@RutaParam NVARCHAR(500), @DelimParam CHAR(1)',
            @RutaParam = @RutaArchivo, -- Para evitar injectionSQL hago variable y la igualo al parametro de la ruta y delim
            @DelimParam = @Delimitador; 
            
        PRINT 'BULK INSERT a tabla temporal completado.';

        --INSERTAR A TABLA PRINCIPAL
        INSERT INTO dbo.consorcio (
            nombre,
            -- Agregar campos si hacen falta (o sea, que esten en el archivo)
        )
        SELECT
            DISTINCT 
            tt.[Nombre del consorcio]
            -- Agregar columnas si es que agregue antes.
        FROM
            #tablaTemporal tt
        WHERE
            -- Controla duplicados (comparando con la columna 'nombre')
            NOT EXISTS (
                SELECT *
                FROM dbo.consorcio tp
                WHERE tp.nombre = tt.[Nombre del consorcio]
            );
            
        PRINT 'Inserción en dbo.consorcio completada.';
        
        
        --Insertar en la Tabla de Detalle (unidad_funcional)
        -- Inserta solo los datos de la unidad funcional, no bauleras y cocheras

        INSERT INTO dbo.unidad_funcional (
            id_consorcio,   -- FK 
            nr_uf,          
            piso,           
            departamento,   
            coeficiente,    
            m2              
        )
        SELECT
            -- Buscamos la PK (id_consorcio) de la tabla padre
            tp.id_consorcio, 
            tt.[nroUnidadFuncional],
            tt.[Piso],
            tt.[departamento],
            -- Conversión de decimal (coma a punto, que es lo que estaba mal)
            CONVERT(DECIMAL(10, 2), REPLACE(tt.[coeficiente], ',', '.')),
            tt.[m2_unidad_funcional]
        FROM
            #tablaTemporal tt
        -- JOIN para encontrar el ID del padre (usando la clave)
        JOIN
            dbo.consorcio tp ON tt.[Nombre del consorcio] = tp.nombre
        WHERE
            -- Control de duplicados
            NOT EXISTS (
                SELECT 1
                FROM dbo.unidad_funcional uf
                WHERE uf.id_consorcio = tp.id_consorcio
                  AND uf.nr_uf = tt.[nroUnidadFuncional]
            );

        PRINT 'Inserción en dbo.unidad_funcional completada.';

        --Insertar en la tabla baulera

        INSERT INTO dbo.baulera (
            id_uf, -- FK unidad_funcional 
            m2    
        )
        SELECT
            --Hay que buscar el 'id_uf' (PK) que se creó
            uf.id_uf, 
            tt.[m2_baulera]
        FROM
            #tablaTemporal tt
        -- Hacemos 2 JOINs para conectar el archivo temporal con la tabla de UF
        JOIN 
            dbo.consorcio c ON tt.[Nombre del consorcio] = c.nombre
        JOIN 
            dbo.unidad_funcional uf ON c.id_consorcio = uf.id_consorcio 
                                   AND tt.[nroUnidadFuncional] = uf.nr_uf
        WHERE
            tt.[bauleras] = 'SI' -- Solo inserta si el archivo dice 'SI'
            AND tt.[m2_baulera] > 0
        -- Control de duplicados para la baulera
        AND NOT EXISTS (
                SELECT 1
                FROM dbo.baulera b
                WHERE b.id_uf = uf.id_uf
            );

        PRINT 'Inserción en dbo.baulera completada.';

        --INSERTA EN TABLA COCHERA

        INSERT INTO dbo.cochera (
            id_uf, -- FK unidad_funcional
            m2     --DER
        )
        SELECT
            -- Buscamos el 'id_uf' (PK) que se creó
            uf.id_uf,
            tt.[m2_cochera]
        FROM
            #tablaTemporal tt
        --2 JOINs para conectar el archivo temporal con la tabla de UF
        JOIN 
            dbo.consorcio c ON tt.[Nombre del consorcio] = c.nombre
        JOIN 
            dbo.unidad_funcional uf ON c.id_consorcio = uf.id_consorcio 
                 AND tt.[nroUnidadFuncional] = uf.nr_uf

        WHERE
            tt.[cochera] = 'SI' -- Solo inserta si el archivo dice 'SI'
            AND tt.[m2_cochera] > 0
        -- Control de duplicados para la cochera
        AND NOT EXISTS (
                SELECT 1
                FROM dbo.cochera co
                WHERE co.id_uf = uf.id_uf
            );

        PRINT 'Inserción en dbo.cochera completada.';

        COMMIT TRANSACTION;
        
        PRINT 'Proceso de importación finalizado.';

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0 --controla si se está ejecutando una transaccion
            ROLLBACK TRANSACTION;

        PRINT 'Error durante la importación. Se ha revertido la transacción.';
        THROW; 
        
    END CATCH

    IF OBJECT_ID('tempdb..#tablaTemporal') IS NOT NULL
        DROP TABLE #tablaTemporal;

END
GO
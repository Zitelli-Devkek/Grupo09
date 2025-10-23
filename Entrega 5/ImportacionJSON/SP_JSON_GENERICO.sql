CREATE OR ALTER PROCEDURE sp_ImportarDatosJSON
    @RutaArchivo NVARCHAR(500) --para cargar la ruta de archivo
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @JsonData NVARCHAR(MAX); --es una variable que guarda todo el contenido del JSON 
    DECLARE @ErrorMessage NVARCHAR(500);

    BEGIN TRY

        SELECT @JsonData = BulkColumn--guarda los datos que lee con OPENROWSET Y BULK en bulkcolumn(nombre por defecto) y de ahi los pasa a la variable
        FROM OPENROWSET(BULK @RutaArchivo, SINGLE_NCLOB) AS j;
    END TRY
    BEGIN CATCH
        PRINT ('Error al abrir archivo JSON');
        THROW;
    END CATCH;

    BEGIN TRY--INSERTAR EN TABLA FINAL (MANEJANDO DUPLICADOS) USANDO OPENJSON
        BEGIN TRANSACTION;

        MERGE INTO [tabla] AS COMPARACION --uso merge para comparar tablas y ver si hay duplicados
        USING (
            SELECT *
            FROM OPENJSON(@JsonData) --El OPENJSON parsea el texto y lo convierte en filas/columnas
            WITH (--WITH lo que hace es, armar la estructura.Le dice que datos quiero extraer y, cómo debe ser la tabla virtual resultante.                
                [ID] INT           '$.campo', --donde puse campo hay que poner el que corresponda al nombre de columna
                [campo1] tipodedato  '$.campo',    --tipodedato hay que poner el que corresponda segun el JSON
                [campo2] tipodedato '$.campo',
            )
        ) AS TablaRef

        ON (COMPARACION.[ID] = TablaRef.[ID]) --Condicion de duplicado (no se si está bien)

     
        WHEN NOT MATCHED BY COMPARACION THEN --si no hay coincidencias hace el insert
            INSERT (
                [ID],
                [campo1],
                [campo2]
            )
            VALUES (
                TablaRef.[ID],
                TablaRef.[campo1],
                TablaRef.[campo2]
            );
        
        COMMIT TRANSACTION;--para confirmar transaccion si se pudo ejecutar bien

        PRINT 'Se importó correctamente el JSON'; --esto si queremos lo sacamos, lo puse por si queremos saberlo

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 --es una variable del sistema que retiene la cantidad de transacciones que están abiertas ahpora
            ROLLBACK TRANSACTION; --si falla, hago ROLLBACK para abortar transaccion
        PRINT 'Ocurrió un error al querer importar el JSON'
        THROW;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO
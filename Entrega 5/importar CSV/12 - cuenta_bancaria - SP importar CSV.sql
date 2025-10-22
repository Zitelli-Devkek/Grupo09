USE AltosSaintJust
GO

CREATE OR ALTER PROCEDURE sp_importar_csv_cuenta_bancaria
    @rutaArchivo NVARCHAR(500) -- parametro de entrada, es donde va a ir la ruta que le tengo que mandar por parametro
    
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY -- el try es para que, en caso de haber problemas, ejecute el begin catch en vez de abortar todo.

        DECLARE @sql NVARCHAR(MAX);

        SET @sql = N'
            BULK INSERT cuenta_bancaria -- para la importacion de archivos
            FROM ''' + @rutaArchivo + N'''
            WITH (
                FIRSTROW = 2,                -- Empezar a leer desde la segunda fila para saltar el encabezado
                FIELDTERMINATOR = '';'',     -- el delimitador de mi archivo es ;
                ROWTERMINATOR = ''\n'',      -- para saltar filas
                CODEPAGE = ''ACP''           -- usa lenguaje con el que este el sistema operativo para saber como leer caracteres como la � o tildes.
            );
        ';

        EXEC sp_executesql @sql;

    END TRY -- END del begin try

    BEGIN CATCH -- se ejecuta en caso de haber problema con el begin try

        PRINT 'Error: No se pudo importar el archivo .csv'; -- printea error que le digo yo con PRINT
        THROW; -- me printea el error original 

    END CATCH -- END del begin catch
END
GO
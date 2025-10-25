EXEC sp_configure 'show advanced options', 1;    --Este es para poder editar los permisos avanzados.
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;    -- Aqui habilitamos esta opcion avanzada
RECONFIGURE;
GO

DECLARE @url NVARCHAR(256) = 'https://dolarapi.com/v1/dolares';
DECLARE @Object INT;
DECLARE @respuesta NVARCHAR(MAX);
DECLARE @json TABLE(DATA NVARCHAR(MAX));

-- Creamos el objeto COM
EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;

-- Configuramos el método y la URL
EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE';

-- Enviamos la solicitud
EXEC sp_OAMethod @Object, 'SEND';

-- Obtenemos la respuesta en formato JSON
EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT, @json OUTPUT;

-- Insertamos el JSON en la tabla temporal
INSERT INTO @json 
EXEC sp_OAGetProperty @Object, 'RESPONSETEXT';

-- Guardamos el texto JSON en una variable
DECLARE @datos NVARCHAR(MAX) = (SELECT DATA FROM @json);

CREATE TABLE #DolarHistorico (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tipo NVARCHAR(50),
    compra DECIMAL(10,2),
    venta DECIMAL(10,2),
    fecha DATETIME DEFAULT GETDATE()
);


CREATE OR ALTER PROCEDURE dbo.ActualizarDolar
AS
BEGIN
    DECLARE @url NVARCHAR(256) = 'https://dolarapi.com/v1/dolares';
    DECLARE @Object INT;
    DECLARE @json TABLE(DATA NVARCHAR(MAX));
    DECLARE @respuesta NVARCHAR(MAX);

    EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
    EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE';
    EXEC sp_OAMethod @Object, 'SEND';
    EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT, @json OUTPUT;
    INSERT INTO @json EXEC sp_OAGetProperty @Object, 'RESPONSETEXT';
    DECLARE @datos NVARCHAR(MAX) = (SELECT DATA FROM @json);

    INSERT INTO #DolarHistorico (tipo, compra, venta)
    SELECT 
        nombre,
        compra,
        venta
    FROM OPENJSON(@datos)
    WITH (
        nombre NVARCHAR(50) '$.nombre',
        compra DECIMAL(10,2) '$.compra',
        venta DECIMAL(10,2) '$.venta'
    );
END;
GO

EXEC dbo.ActualizarDolar;
SELECT * FROM #DolarHistorico ORDER BY fecha DESC;

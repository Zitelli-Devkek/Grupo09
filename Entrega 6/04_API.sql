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


Genere índices para optimizar la ejecución de las consultas de los reportes. Debe existir un
script adicional con la generación de índices.*/

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO

-- CREACIÓN DE TABLA TEMPORAL

IF OBJECT_ID('tempdb..##DolarHistorico') IS NOT NULL
    DROP TABLE ##DolarHistorico;

DROP TABLE IF EXISTS ##DolarHistorico;
CREATE TABLE ##DolarHistorico (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tipo NVARCHAR(50),
    compra DECIMAL(10,2),
    venta DECIMAL(10,2),
    fecha DATETIME DEFAULT GETDATE()
);
GO 

-- CREACIÓN DEL PROCEDIMIENTO 

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

    INSERT INTO @json EXEC sp_OAGetProperty @Object, 'RESPONSETEXT';
    DECLARE @datos NVARCHAR(MAX) = (SELECT DATA FROM @json);

    INSERT INTO ##DolarHistorico (tipo, compra, venta)
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

SELECT * FROM ##DolarHistorico ORDER BY fecha DESC;
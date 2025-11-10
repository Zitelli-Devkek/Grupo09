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

Consigna: En ste script se importa el archivo Servicios.Servicios.json y se carga en la tabla servicio
*/

USE Com2900G09;
GO

CREATE OR ALTER PROCEDURE sp_ImportarServicios
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#Servicios_Temp') IS NOT NULL--si existe la tabla temporal, la elimino
            DROP TABLE #Servicios_Temp;

        CREATE TABLE #Servicios_Temp (--creo tabla temporal de servicios
            NombreConsorcio NVARCHAR(100),
            Mes NVARCHAR(20),
            BANCARIOS NVARCHAR(50),
            LIMPIEZA NVARCHAR(50),
            ADMINISTRACION NVARCHAR(50),
            SEGUROS NVARCHAR(50),
            [GASTOS GENERALES] NVARCHAR(50),
            [SERVICIOS PUBLICOS-Agua] NVARCHAR(50),
            [SERVICIOS PUBLICOS-Luz] NVARCHAR(50)
        );

        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @json NVARCHAR(MAX);

        --Leo el archivo JSON con sql dinámico y OPENROWSET
        SET @SQL = N'
            SELECT @json = BulkColumn
            FROM OPENROWSET(BULK ''' + @RutaArchivo + N''', SINGLE_CLOB) AS j;';

        EXEC sp_executesql @SQL, N'@json NVARCHAR(MAX) OUTPUT', @json = @json OUTPUT;--output para que la variable @json sea un parametro de salida y no se quede encerrado en el sql dinamico

        IF @json IS NULL--si el archivo está vacio hago rollback 
        BEGIN
            RAISERROR('Error al abrir JSON o está vacío.', 16, 1);--jair nos permitió usar RAISERROR, el 16 indica la severidad de error que 
            ROLLBACK TRANSACTION;                                             --es un error de usuario y se captura en CATCH, y el 1 es el estado
            RETURN;
        END;

        --Cargo los datos del json a la tabla temporal creada
        INSERT INTO #Servicios_Temp
        SELECT
            j.[Nombre del consorcio],
            j.[Mes],
            j.[BANCARIOS],
            j.[LIMPIEZA],
            j.[ADMINISTRACION],
            j.[SEGUROS],
            j.[GASTOS GENERALES],
            j.[SERVICIOS PUBLICOS-Agua],
            j.[SERVICIOS PUBLICOS-Luz]
        FROM OPENJSON(@json)
        WITH (--no es CTE, solo uso WITH para decirle como leer el archivo (mapeo de datos)
            [Nombre del consorcio] NVARCHAR(100) '$."Nombre del consorcio"',--le digo de donde sacar el dato (ruta dentro del json)
            [Mes] NVARCHAR(20) '$.Mes',--ejemplo, trae el dato que esta en mes del json y lo guarda en [Mes]
            [BANCARIOS] NVARCHAR(50) '$.BANCARIOS',
            [LIMPIEZA] NVARCHAR(50) '$.LIMPIEZA',
            [ADMINISTRACION] NVARCHAR(50) '$.ADMINISTRACION',
            [SEGUROS] NVARCHAR(50) '$.SEGUROS',
            [GASTOS GENERALES] NVARCHAR(50) '$."GASTOS GENERALES"',
            [SERVICIOS PUBLICOS-Agua] NVARCHAR(50) '$."SERVICIOS PUBLICOS-Agua"',--comilla doble porque tiene espacio
            [SERVICIOS PUBLICOS-Luz] NVARCHAR(50) '$."SERVICIOS PUBLICOS-Luz"'
        ) AS j;

        PRINT 'Archivo JSON cargado correctamente.';

		-- Inserta los servicios unificados (unpivot) y normaliza montos
		-- uso CTE para la insercción de datos
		-- Tomo la tabla temporal y limpiamos de posibles espacios en nombre de consorcio y mes
		WITH tabla_tempora_norm AS (
			SELECT
				NombreConsorcio = LTRIM(RTRIM(NombreConsorcio)), --limpio espacios
				MesCanon        = LTRIM(RTRIM(Mes)), --limpio espacios
				BANCARIOS,
				LIMPIEZA,
				ADMINISTRACION,
				SEGUROS,
				[GASTOS GENERALES],
				[SERVICIOS PUBLICOS-Agua],
				[SERVICIOS PUBLICOS-Luz]
			FROM #Servicios_Temp
		),
		-- con cross apply convierto las 7 columnas de gastos en filas con dos campos: categoria e importeFila
		despivotar AS (
			SELECT
				s.NombreConsorcio,
				s.MesCanon,
				v.Categoria,
				importeFila = v.Importe
			FROM tabla_tempora_norm s
			CROSS APPLY (VALUES
				('BANCARIOS',               s.BANCARIOS),
				('LIMPIEZA',                s.LIMPIEZA),
				('ADMINISTRACION',          s.ADMINISTRACION),
				('SEGUROS',                 s.SEGUROS),
				('GASTOS GENERALES',        s.[GASTOS GENERALES]),
				('SERVICIOS PUBLICOS-Agua', s.[SERVICIOS PUBLICOS-Agua]),
				('SERVICIOS PUBLICOS-Luz',  s.[SERVICIOS PUBLICOS-Luz])
			) v(Categoria, Importe)
		),
		-- con REPLACE quito posibles espacios ' '
		-- con TRY_PARSE, USING parseo importeFila a DECIMAL(10,2) y valido si esta con los siguientes formatos: es-AR -> 00.000,00, en-US -> 00,000.00 
		-- con COALESCE devuelve el primer valor no nulo de las dos opciones.
		convertidos AS (
			SELECT
				u.NombreConsorcio,
				u.MesCanon,
				u.Categoria,
				Valor =
					COALESCE(
					TRY_PARSE(REPLACE(u.importeFila, ' ', '') AS DECIMAL(10,2) USING 'es-AR'),
					TRY_PARSE(REPLACE(u.importeFila, ' ', '') AS DECIMAL(10,2) USING 'en-US')
				)
			FROM despivotar u
		)
		-- Inserto valores finales a la tabla servicio, valido que valor no sea nulo ni sea 0
		INSERT INTO Servicio (nro_cuenta, mes, categoria, valor)
		SELECT
			NombreConsorcio,
			MesCanon,
			Categoria,
			Valor
		FROM convertidos
		WHERE Valor IS NOT NULL AND Valor > 0;


        COMMIT TRANSACTION;
        PRINT 'Servicios importados correctamente.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
			PRINT 'Error crítico. Ejecuto ROLLBACK.';
			PRINT 'Mensaje de error del sys: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

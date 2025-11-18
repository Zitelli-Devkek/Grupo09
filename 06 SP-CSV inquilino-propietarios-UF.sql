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

Consigna: En este script se importa el archivo inquilino-propietarios-UF.csv y se carga la tabla "Persona_Uf"
*/

USE Com2900G09;
GO

CREATE OR ALTER PROCEDURE sp_importar_csv_inquilino_propietarios_UF
    @rutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Si existe la tabla temporal la elimino. Para que no tire error al ejecutar dos veces
    IF OBJECT_ID('tempdb..#inquilino_propietarios_UF_tmp') IS NOT NULL
        DROP TABLE #inquilinopropietariosUFtmp;

    CREATE TABLE #inquilino_propietarios_UF_tmp (
        cbu_cvu NVARCHAR(22),
        nombre NVARCHAR(100),
        nr_uf NVARCHAR(50),
        piso NVARCHAR(100),
        departamento NVARCHAR(50)
    );

    -- Me fijo si existe el archivo a importar
    DECLARE @existe INT;
    EXEC master.dbo.xp_fileexist @rutaArchivo, @existe OUTPUT;

    IF @existe = 0
    BEGIN
        RAISERROR('Escribiste mal la ruta, o el archivo no existe.', 16, 1);
        RETURN;
    END

    -- Inicio una transacción. O cargamos todo o no cargamos nada
    BEGIN TRY
        BEGIN TRAN;

        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #inquilino_propietarios_UF_tmp
            FROM ''' + @rutaArchivo + N'''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''|'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''ACP''
            );
        ';
        EXEC sp_executesql @sql;
       

        -- Cargo los registros en la tabla Persona_uf, filtrando repetidos en la consulta

INSERT INTO Persona_UF (DNI, id_uf)
SELECT 
    p.DNI,
    uf.id_uf
FROM #inquilino_propietarios_UF_tmp AS c --la tabla temporal carga todo bien
JOIN Persona AS p
      ON p.cbu_cvu = c.cbu_cvu --hasta acá tiene que estar todo bien
JOIN Consorcio AS cons
      ON cons.nombre = c.nombre
JOIN Unidad_Funcional AS uf
      ON uf.id_consorcio = cons.id_consorcio
     AND uf.nr_uf        = c.nr_uf
     AND uf.piso         = c.piso
     AND uf.departamento = c.departamento
     WHERE NOT EXISTS (
    SELECT 1 FROM Persona_UF pu
    WHERE pu.DNI = p.DNI
       OR pu.id_uf = uf.id_uf
);
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        PRINT 'Error: Lo siento, no se pudo importar el archivo .csv';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO
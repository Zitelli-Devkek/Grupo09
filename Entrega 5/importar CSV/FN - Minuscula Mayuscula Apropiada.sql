USE Com2900G09
GO

CREATE OR ALTER FUNCTION dbo.fn_ProperCase(@texto NVARCHAR(100))
RETURNS NVARCHAR(200)
AS
BEGIN
    IF @texto IS NULL OR LTRIM(RTRIM(@texto)) = ''
        RETURN NULL;

    DECLARE @resultado NVARCHAR(100) = '';

    DECLARE @tbl TABLE (
        parte NVARCHAR(100)
    );

    DECLARE @palabra NVARCHAR(100);

    -- Inserto palabras normalizadas
    INSERT INTO @tbl(parte)
    SELECT CONCAT(
               UPPER(LEFT(TRIM(value),1)), --Primera letra mayúscula
               LOWER(SUBSTRING(TRIM(value),2,99)) --segunda letra, minúscula
           )
    FROM STRING_SPLIT(@texto, ' ')
    WHERE TRIM(value) <> '';

    -- Concateno todas las palabras, para nombres o apellidos compuestos
    DECLARE cur CURSOR FOR SELECT parte FROM @tbl;

    OPEN cur;
    FETCH NEXT FROM cur INTO @palabra;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @resultado =
            CASE WHEN @resultado = '' THEN @palabra
                 ELSE @resultado + ' ' + @palabra
            END;

        FETCH NEXT FROM cur INTO @palabra;
    END

    CLOSE cur;
    DEALLOCATE cur;

    RETURN @resultado;
END;
GO

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


Reporte 5
Obtenga los 3 (tres) propietarios con mayor morosidad. Presente información de contacto y
DNI de los propietarios para que la administración los pueda contactar o remitir el trámite al
estudio jurídico.*/

CREATE OR ALTER PROCEDURE sp_Reporte5_MayorMorosidad
    @Anio INT,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 3
        p.DNI AS '@DNI',
        per.nombre AS 'Nombre',
        per.apellido AS 'Apellido',
        per.email_personal AS 'Email',
        per.telefono AS 'Telefono',
        COUNT(*) AS 'CantidadVencidas'
    FROM Expensa_Detalle ed
    INNER JOIN Expensa e ON e.id_expensa = ed.id_expensa
    INNER JOIN Unidad_Funcional uf ON uf.id_uf = e.id_uf
    INNER JOIN Persona_UF p ON p.id_uf = uf.id_uf
    INNER JOIN Persona per ON per.DNI = p.DNI
    WHERE ed.estado = 'Vencido'
      AND YEAR(e.vencimiento) = @Anio
      AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
    GROUP BY p.DNI, per.nombre, per.apellido, per.email_personal, per.telefono
    ORDER BY CantidadVencidas DESC
    FOR XML PATH('Moroso'), ROOT('MayoresMorosos'), ELEMENTS;
END;
GO

/*
CREATE OR ALTER PROCEDURE sp_Reporte5_MayorMorosidad
    @Anio INT,
    @IdConsorcio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 3
        p.DNI,
        per.nombre,
        per.apellido,
        per.email_personal,
        per.telefono,
        COUNT(*) AS CantidadVencidas
    FROM Expensa_Detalle ed
    INNER JOIN Expensa e ON e.id_expensa = ed.id_expensa
    INNER JOIN Unidad_Funcional uf ON uf.id_uf = e.id_uf
    INNER JOIN Persona_UF p ON p.id_uf = uf.id_uf
    INNER JOIN Persona per ON per.DNI = p.DNI
    WHERE ed.estado = 'Vencido'
      AND YEAR(e.vencimiento) = @Anio
      AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
    GROUP BY p.DNI, per.nombre, per.apellido, per.email_personal, per.telefono
    ORDER BY CantidadVencidas DESC;
END;
GO
*/
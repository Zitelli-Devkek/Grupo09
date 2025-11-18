-- Esto se ejecuta en la base de datos 'master'


CREATE OR ALTER PROCEDURE dbo.sp_crear_logins
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = N'
    
    -- Los comandos CREATE LOGIN deben ejecutarse en un contexto seguro y con permisos elevados.

    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N''login_general_1'')
        CREATE LOGIN login_general_1 WITH PASSWORD = ''password_general'', CHECK_POLICY = OFF;
    
    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N''login_bancario_1'')
        CREATE LOGIN login_bancario_1 WITH PASSWORD = ''password_bancario'', CHECK_POLICY = OFF;
        
    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N''login_operativo_1'')
        CREATE LOGIN login_operativo_1 WITH PASSWORD = ''password_operativo'', CHECK_POLICY = OFF;
        
    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N''login_sistemas_1'')
        CREATE LOGIN login_sistemas_1 WITH PASSWORD = ''password_sistemas'', CHECK_POLICY = OFF;
    ';
    
    -- La ejecución de este SP requiere el permiso 'ALTER ANY LOGIN' o ser un sysadmin.
    EXEC sys.sp_executesql @SQL;
    
    PRINT 'Logins de servidor creados o verificados.';
END
GO


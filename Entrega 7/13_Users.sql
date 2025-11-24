USE Com2900G09;
GO

CREATE OR ALTER PROCEDURE dbo.spcrear_usuarios
AS
BEGIN
    SET NOCOUNT ON;

    
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_general_1')
        CREATE USER [usuario_general_1] FOR LOGIN [login_general_1];
    
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_bancario_1')
        CREATE USER [usuario_bancario_1] FOR LOGIN [login_bancario_1];
    
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_operativo_1')
        CREATE USER [usuario_operativo_1] FOR LOGIN [login_operativo_1];
        
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_sistemas_1')
        CREATE USER [usuario_sistemas_1] FOR LOGIN [login_sistemas_1];


END
GO

EXEC dbo.spcrear_usuarios

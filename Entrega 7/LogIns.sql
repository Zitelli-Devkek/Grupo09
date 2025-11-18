-- Esto se ejecuta en la base de datos 'master'
USE master; 
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_general_1')
BEGIN
    CREATE LOGIN login_general_1 
        WITH PASSWORD = 'password_general';
END
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_bancario_1')
BEGIN
    CREATE LOGIN login_bancario_1 
        WITH PASSWORD = 'password_bancario';
END
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_operativo_1')
BEGIN
    CREATE LOGIN login_operativo_1 
        WITH PASSWORD = 'password_operativo';
END
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_sistemas_1')
BEGIN
    CREATE LOGIN login_sistemas_1 
        WITH PASSWORD = 'password_sistemas';
END
GO

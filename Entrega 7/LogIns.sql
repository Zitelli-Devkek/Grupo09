-- Esto se ejecuta en la base de datos 'master'

CREATE OR ALTER PROCEDURE dbo.sp_logins_users

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

-- ---   CREACION DE USUARIOS ---
USE Com2900G09;
GO

    
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_general_1')
BEGIN
    CREATE USER [usuario_general_1] FOR LOGIN [login_general_1];
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_bancario_1')
BEGIN
    CREATE USER [usuario_bancario_1] FOR LOGIN [login_bancario_1];
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_operativo_1')
BEGIN
    CREATE USER [usuario_operativo_1] FOR LOGIN [login_operativo_1];
END
GO
    
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_sistemas_1')
BEGIN
    CREATE USER [usuario_sistemas_1] FOR LOGIN [login_sistemas_1];
END
GO

END;
GO

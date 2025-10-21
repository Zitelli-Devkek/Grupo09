CREATE DATABASE AltosSaintJust
GO

USE AltosSaintJust
GO

/*CREATE SCHEMA Consorcio
GO*/

CREATE TABLE Consorcio.Proveedor (
    id_proveedor INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    nro_cuenta VARCHAR(20) NULL,
    descripcion NVARCHAR(200) NULL,
    cuit CHAR(13) NOT NULL UNIQUE, -- con guiones
    email NVARCHAR(100) NULL,
    telefono VARCHAR(20) NULL
);
USE AltosSaintJust
GO

CREATE TABLE Consorcio.Proveedor (
    id_proveedor INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    nro_cuenta VARCHAR(20) NULL,
    descripcion NVARCHAR(200) NULL,
    cuit CHAR(13) NOT NULL UNIQUE, -- con guiones
    email NVARCHAR(100) NULL,
    telefono VARCHAR(20) NULL
);

CREATE TABLE Consorcio.Consorcio (
    id_consorcio INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    direccion VARCHAR(30) NULL,
    admin_nombre NVARCHAR(100) NULL,
    admin_cuit CHAR(13) NOT NULL UNIQUE, -- con guiones
    admin_email NVARCHAR(100) NULL
);

CREATE TABLE Consorcio.gasto_extraordinario (
    id_gasto_ext INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio INT NOT NULL,
    id_proveedor INT NOT NULL,
    nro_cuota TINYINT NOT NULL,
    total_cuotas TINYINT NOT NULL,
    detalle VARCHAR(100),
    importe DECIMAL(12,2) NOT NULL CHECK (importe >= 0),
    CONSTRAINT FK_id_consorcio 
        FOREIGN KEY (id_consorcio) 
        REFERENCES Consorcio.Consorcio(id_consorcio),
    CONSTRAINT FK_id_proveedor 
        FOREIGN KEY (id_proveedor) 
        REFERENCES Consorcio.Proveedor(id_proveedor),
    CONSTRAINT CK_cuotas CHECK (nro_cuota <= total_cuotas)
);

CREATE TABLE Consorcio.gasto_ordinario (
    id_gasto_ext INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio INT NOT NULL,
    id_proveedor INT NOT NULL,
    periodo DATE NOT NULL,
    nro_factura TINYINT NOT NULL,
    detalle VARCHAR(100),
    importe DECIMAL(12,2) NOT NULL CHECK (importe >= 0),
    CONSTRAINT FK_id_consorcio 
        FOREIGN KEY (id_consorcio) 
        REFERENCES Consorcio.Consorcio(id_consorcio),
    CONSTRAINT FK_id_proveedor 
        FOREIGN KEY (id_proveedor) 
        REFERENCES Consorcio.Proveedor(id_proveedor)
);

CREATE TABLE Consorcio.servicio (
    id_servicio INT IDENTITY(1,1) PRIMARY KEY,
    nro_cuenta INT NOT NULL,
    mes TINYINT NOT NULL,
    categoria NVARCHAR(8) NOT NULL,
    valor DECIMAL(12,2),
    CONSTRAINT CK_mes CHECK (mes BETWEEN 1 AND 12),
    CONSTRAINT CK_categoria CHECK (categoria IN ('Luz', 'Agua', 'Internet'))
);
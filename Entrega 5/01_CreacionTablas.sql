USE AltosSaintJust
GO

DROP TABLE IF EXISTS Pago_Importado;
DROP TABLE IF EXISTS Pago;
DROP TABLE IF EXISTS Expensa_Detalle;
DROP TABLE IF EXISTS Gasto_Extraordinario;
DROP TABLE IF EXISTS Gasto_Ordinario;
DROP TABLE IF EXISTS Expensa;
DROP TABLE IF EXISTS Proveedor;
DROP TABLE IF EXISTS Servicio;
DROP TABLE IF EXISTS Persona_UF;
DROP TABLE IF EXISTS Persona;
DROP TABLE IF EXISTS Tipo_Ocupante;
DROP TABLE IF EXISTS Complemento;
DROP TABLE IF EXISTS Unidad_Funcional;
DROP TABLE IF EXISTS Consorcio;

DROP TABLE IF EXISTS Consorcio;
CREATE TABLE Consorcio (
    id_consorcio INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    admin_nombre VARCHAR(100),
    admin_cuit CHAR(11) NOT NULL UNIQUE,
    admin_email VARCHAR(100) CHECK (admin_email IS NULL OR admin_email LIKE '%_@_%._%')
);


DROP TABLE IF EXISTS Unidad_Funcional;
CREATE TABLE Unidad_Funcional (
    id_uf INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio INT NOT NULL
        CONSTRAINT FK_UF_Consorcio FOREIGN KEY REFERENCES Consorcio(id_consorcio),
    nr_uf INT NOT NULL CHECK (nr_uf > 0),
    piso VARCHAR(10),
    departamento VARCHAR(10),
    coeficiente DECIMAL(6,3) CHECK (coeficiente >= 0 AND coeficiente <= 1),
    m2 DECIMAL(10,2) CHECK (m2 > 0)
);

DROP TABLE IF EXISTS Complemento;
CREATE TABLE Complemento (
    id_complemento INT IDENTITY(1,1) PRIMARY KEY,
    id_uf INT NOT NULL
        CONSTRAINT FK_Complemento_UF FOREIGN KEY REFERENCES Unidad_Funcional(id_uf),
    m2 DECIMAL(10,2) CHECK (m2 > 0),
    tipo_complemento VARCHAR(50) CHECK (tipo_complemento IN ('Baulera', 'Cochera'))
);

DROP TABLE IF EXISTS Tipo_Ocupante;
CREATE TABLE Tipo_Ocupante (
    id_tipo_ocupante INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL
);

DROP TABLE IF EXISTS Persona;
CREATE TABLE Persona (
    DNI CHAR(8) PRIMARY KEY CHECK (DNI BETWEEN 10000000 AND 99999999),
    id_tipo_ocupante INT NOT NULL
        CONSTRAINT FK_Persona_Tipo FOREIGN KEY REFERENCES Tipo_Ocupante(id_tipo_ocupante),
    nombre VARCHAR(100) NOT NULL, 
    apellido VARCHAR(100) NOT NULL,
    email_personal VARCHAR(100) CHECK (email_personal IS NULL OR email_personal LIKE '%_@_%._%'),
    telefono VARCHAR(20) NULL,
    cbu_cvu VARCHAR(22) NOT NULL
);

DROP TABLE IF EXISTS Persona_UF;
CREATE TABLE Persona_UF (
    id_persona_uf INT IDENTITY(1,1) PRIMARY KEY,
    DNI CHAR(8) NOT NULL
        CONSTRAINT FK_PUF_Persona FOREIGN KEY REFERENCES Persona(DNI),
    id_uf INT NOT NULL 
        CONSTRAINT FK_PUF_UF FOREIGN KEY REFERENCES Unidad_Funcional(id_uf),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL
);

DROP TABLE IF EXISTS Servicio;
CREATE TABLE Servicio (
    id_servicio INT IDENTITY(1,1) PRIMARY KEY,
    nro_cuenta VARCHAR(30),
    mes TINYINT NOT NULL CHECK (mes BETWEEN 1 AND 12),
    categoria VARCHAR(50),
    valor DECIMAL (10,2) NOT NULL 
);

DROP TABLE IF EXISTS Proveedor;
CREATE TABLE Proveedor (
    id_proveedor INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nro_cuenta VARCHAR(30),
    descripcion VARCHAR(150),
    cuit CHAR(11) NOT NULL UNIQUE,
    email VARCHAR(100)  CHECK (email IS NULL OR email LIKE '%_@_%._%'),
    telefono VARCHAR(20)
);

DROP TABLE IF EXISTS Expensa;
CREATE TABLE Expensa (
    id_expensa INT IDENTITY(1,1) PRIMARY KEY,
    id_uf INT NOT NULL
         CONSTRAINT FK_Expensa_UF FOREIGN KEY REFERENCES Unidad_Funcional(id_uf),
    mes CHAR(7) NOT NULL,
    vencimiento DATE NOT NULL,
    valor DECIMAL(10,2) CHECK (valor >= 0),
);

DROP TABLE IF EXISTS Gasto_Ordinario;
CREATE TABLE Gasto_Ordinario (
    id_gasto_ord INT IDENTITY(1,1) PRIMARY KEY,
    id_expensa INT NOT NULL
        CONSTRAINT FK_GOrd_Exp FOREIGN KEY REFERENCES Expensa(id_expensa),
    id_proveedor INT
        CONSTRAINT FK_GOrd_Prov FOREIGN KEY REFERENCES Proveedor(id_proveedor),
    id_servicio INT
        CONSTRAINT FK_GOrd_Serv FOREIGN KEY REFERENCES Servicio(id_servicio),
    periodo CHAR(7),
    nro_factura VARCHAR(30),
    detalle VARCHAR(150),
    importe DECIMAL(10,2) CHECK (importe >= 0)
);

DROP TABLE IF EXISTS Gasto_Extraordinario;
CREATE TABLE Gasto_Extraordinario (
    id_gasto_ext INT IDENTITY(1,1) PRIMARY KEY,
    id_expensa INT NOT NULL
         CONSTRAINT FK_GExt_Exp FOREIGN KEY REFERENCES Expensa(id_expensa),
    id_proveedor INT NULL
        CONSTRAINT FK_GExt_Prov FOREIGN KEY REFERENCES Proveedor(id_proveedor),
    total_cuotas INT DEFAULT 1,
    nro_cuota INT DEFAULT 1,
    detalle VARCHAR(150),
    importe DECIMAL(10,2) CHECK (importe >= 0),

);

DROP TABLE IF EXISTS Expensa_Detalle;
CREATE TABLE Expensa_Detalle (
    id_exp_detalle INT IDENTITY(1,1) PRIMARY KEY,
    id_expensa INT NOT NULL
         CONSTRAINT FK_ED_Exp FOREIGN KEY REFERENCES Expensa(id_expensa),
    tipo_gasto VARCHAR(50) CHECK (tipo_gasto IN ('Ordinario','Extraordinario')),
    fecha_venc DATE,
    importe_uf DECIMAL(10,2) CHECK (importe_uf >= 0),
    estado VARCHAR(20) CHECK (estado IN ('Pendiente','Pagado','Vencido')),
);

DROP TABLE IF EXISTS Pago;
CREATE TABLE Pago (
    id_pago INT IDENTITY(1,1) PRIMARY KEY,
    id_uf INT NULL
        CONSTRAINT FK_Pago_UF FOREIGN KEY REFERENCES Unidad_Funcional(id_uf),
    fecha DATE NOT NULL,
    medio_pago VARCHAR(50),
    valor DECIMAL(10,2) CHECK (valor > 0),
   
);

DROP TABLE IF EXISTS Pago_Importado;
CREATE TABLE Pago_Importado (
    id_pago_imp INT IDENTITY(1,1) PRIMARY KEY,
    id_pago INT NOT NULL,
    fecha_importacion DATE NOT NULL,
    cuenta_origen VARCHAR(22),
    CONSTRAINT FK_PagoImportado_Pago FOREIGN KEY (id_pago) REFERENCES Pago(id_pago),
    CONSTRAINT UQ_PagoImportado_id_pago UNIQUE (id_pago)
);

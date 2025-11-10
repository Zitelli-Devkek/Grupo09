USE Com2900G09
GO

DROP TABLE IF EXISTS Pago;
DROP TABLE IF EXISTS Expensa_Detalle;
DROP TABLE IF EXISTS Factura;
DROP TABLE IF EXISTS Expensa;
DROP TABLE IF EXISTS Persona_UF;
DROP TABLE IF EXISTS Complemento;
DROP TABLE IF EXISTS Persona;
DROP TABLE IF EXISTS Tipo_Ocupante;
DROP TABLE IF EXISTS Unidad_Funcional;
DROP TABLE IF EXISTS Servicio;
DROP TABLE IF EXISTS Consorcio;


CREATE TABLE Consorcio (
    id_consorcio INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    cuit CHAR(11) NOT NULL UNIQUE
);


CREATE TABLE Unidad_Funcional ( 
    id_uf INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio INT NOT NULL
        CONSTRAINT FK_UF_Consorcio FOREIGN KEY REFERENCES Consorcio(id_consorcio),
    nr_uf INT NOT NULL CHECK (nr_uf > 0),
    piso VARCHAR(10),
    departamento VARCHAR(10),
    coeficiente DECIMAL(4,2) NOT NULL,
    m2 DECIMAL(4,2) NOT NULL CHECK (m2 > 0)
);


CREATE TABLE Complemento (
    id_complemento INT IDENTITY(1,1) PRIMARY KEY,
    id_uf INT NOT NULL
        CONSTRAINT FK_Complemento_UF FOREIGN KEY REFERENCES Unidad_Funcional(id_uf),
    m2 DECIMAL(4,2) NOT NULL CHECK (m2 > 0),
    tipo_complemento VARCHAR(50) NOT NULL CHECK (tipo_complemento IN ('Baulera', 'Cochera'))
);


CREATE TABLE Tipo_Ocupante (
    id_tipo_ocupante INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL
);


CREATE TABLE Persona (
    DNI CHAR(8) PRIMARY KEY CHECK (DNI BETWEEN 10000000 AND 99999999),
    id_tipo_ocupante INT NOT NULL
        CONSTRAINT FK_Persona_Tipo FOREIGN KEY REFERENCES Tipo_Ocupante(id_tipo_ocupante),
    nombre VARCHAR(100) NOT NULL, 
    apellido VARCHAR(100) NOT NULL,
    email_personal VARCHAR(100) CHECK (email_personal IS NULL OR email_personal LIKE '%_@_%._%'),
    telefono VARCHAR(20) NULL,
    cbu_cvu CHAR(22) NOT NULL
);


CREATE TABLE Persona_UF (
    id_persona_uf INT IDENTITY(1,1) PRIMARY KEY,
    DNI CHAR(8) NOT NULL
        CONSTRAINT FK_PUF_Persona FOREIGN KEY REFERENCES Persona(DNI),
    id_uf INT NOT NULL 
        CONSTRAINT FK_PUF_UF FOREIGN KEY REFERENCES Unidad_Funcional(id_uf),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL
);


CREATE TABLE Servicio (
    id_servicio INT IDENTITY(1,1) PRIMARY KEY,
    nro_cuenta VARCHAR(30) NOT NULL,
    mes TINYINT NOT NULL CHECK (mes BETWEEN 1 AND 12),
    categoria VARCHAR(50) NOT NULL,
    valor DECIMAL (10,2) NOT NULL CHECK (valor >= 0)
);


CREATE TABLE Expensa (
    id_expensa INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio INT NOT NULL
        CONSTRAINT FK_UF_Consorcio2 FOREIGN KEY REFERENCES Consorcio(id_consorcio),
    mes CHAR(7) NOT NULL,
    importe_total DECIMAL(10,2) NOT NULL CHECK (importe_total >= 0)
);

CREATE TABLE Factura (
    nro_factura INT IDENTITY(1,1) PRIMARY KEY,
    id_servicio INT NOT NULL
        CONSTRAINT FK_Servicio FOREIGN KEY REFERENCES Servicio(id_servicio),
    id_expensa INT NOT NULL
         CONSTRAINT FK_ED_Exp FOREIGN KEY REFERENCES Expensa(id_expensa),
    fecha_emision DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    importe DECIMAL(10,2) NOT NULL,
    detalle VARCHAR(50)
);


CREATE TABLE Expensa_Detalle (
    id_exp_detalle INT IDENTITY(1,1) PRIMARY KEY,
    id_expensa INT NOT NULL
         CONSTRAINT FK_ED_Exp2 FOREIGN KEY REFERENCES Expensa(id_expensa),
    nro_cuota INT NOT NULL DEFAULT 1,
    total_cuotas INT NOT NULL DEFAULT 1,
    descripcion VARCHAR(50),
    fecha_venc DATE,
    importe_uf DECIMAL(10,2) CHECK (importe_uf >= 0),
    estado VARCHAR(20) CHECK (estado IN ('Pendiente','Pagado','Vencido'))
);


CREATE TABLE Pago (
    id_pago INT PRIMARY KEY,
    id_exp_detalle INT NULL
        CONSTRAINT FK_exp_detalle FOREIGN KEY REFERENCES Expensa_Detalle(id_exp_detalle),
    fecha DATE NOT NULL,
    cvu_cbu CHAR(30) NOT NULL,
    valor DECIMAL(10,2) NOT NULL CHECK (valor > 0)
  
);

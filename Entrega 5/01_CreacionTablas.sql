USE AltosSaintJust
GO

CREATE TABLE Consorcio (
    id_consorcio INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    admin_nombre VARCHAR(100),
    admin_cuit CHAR(11),
    admin_email VARCHAR(100)
);

CREATE TABLE Unidad_Funcional (
    id_uf INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio INT NOT NULL,
    nr_uf INT NOT NULL,
    piso VARCHAR(10),
    departamento VARCHAR(10),
    coeficiente DECIMAL(6,3),
    m2 DECIMAL(10,2),
    FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id_consorcio)
);

CREATE TABLE Complemento (
    id_complemento INT IDENTITY(1,1) PRIMARY KEY,
    id_uf INT NOT NULL,
    m2 DECIMAL(10,2),
    tipo_complemento VARCHAR(50) CHECK (tipo_complemento IN ('Baulera', 'Cochera')),
    FOREIGN KEY (id_uf) REFERENCES Unidad_Funcional(id_uf)
);

CREATE TABLE Tipo_Ocupante (
    id_tipo_ocupante INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL
);

CREATE TABLE Persona (
    DNI CHAR(8) PRIMARY KEY,
    id_tipo_ocupante INT NOT NULL,
    nombre VARCHAR(100),
    apellido VARCHAR(100),
    email_personal VARCHAR(100),
    telefono VARCHAR(20),
    cbu_cvu VARCHAR(22),
    FOREIGN KEY (id_tipo_ocupante) REFERENCES Tipo_Ocupante(id_tipo_ocupante)
);

CREATE TABLE Persona_UF (
    id_persona_uf INT IDENTITY(1,1) PRIMARY KEY,
    DNI CHAR(8) NOT NULL,
    id_uf INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    FOREIGN KEY (DNI) REFERENCES Persona(DNI),
    FOREIGN KEY (id_uf) REFERENCES Unidad_Funcional(id_uf)
);

CREATE TABLE Servicio (
    id_servicio INT IDENTITY(1,1) PRIMARY KEY,
    nro_cuenta VARCHAR(30),
    mes CHAR(7) NOT NULL,
    nombre VARCHAR(100),
    categoria VARCHAR(50)
);

CREATE TABLE Proveedor (
    id_proveedor INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nro_cuenta VARCHAR(30),
    descripcion VARCHAR(150),
    cuit CHAR(11),
    email VARCHAR(100),
    telefono VARCHAR(20)
);

CREATE TABLE Expensa (
    id_expensa INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio INT NOT NULL,
    id_uf INT NOT NULL,
    mes CHAR(7) NOT NULL,
    vencimiento DATE NOT NULL,
    valor DECIMAL(12,2),
    FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id_consorcio),
    FOREIGN KEY (id_uf) REFERENCES Unidad_Funcional(id_uf)
);

CREATE TABLE Gasto_Ordinario (
    id_gasto_ord INT IDENTITY(1,1) PRIMARY KEY,
    id_expensa INT NOT NULL,
    id_proveedor INT,
    id_servicio INT,
    periodo CHAR(7),
    nro_factura VARCHAR(30),
    detalle VARCHAR(150),
    importe DECIMAL(12,2),
    FOREIGN KEY (id_expensa) REFERENCES Expensa(id_expensa),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedor(id_proveedor),
    FOREIGN KEY (id_servicio) REFERENCES Servicio(id_servicio)
);

CREATE TABLE Gasto_Extraordinario (
    id_gasto_ext INT IDENTITY(1,1) PRIMARY KEY,
    id_expensa INT NOT NULL,
    id_proveedor INT,
    nro_cuota INT DEFAULT 1,
    total_cuotas INT DEFAULT 1,
    detalle VARCHAR(150),
    importe DECIMAL(12,2),
    FOREIGN KEY (id_expensa) REFERENCES Expensa(id_expensa),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedor(id_proveedor)
);

CREATE TABLE Expensa_Detalle (
    id_exp_detalle INT IDENTITY(1,1) PRIMARY KEY,
    id_expensa INT NOT NULL,
    tipo_gasto VARCHAR(50) CHECK (tipo_gasto IN ('Ordinario','Extraordinario')),
    fecha_venc DATE,
    importe_uf DECIMAL(12,2),
    estado VARCHAR(20) CHECK (estado IN ('Pendiente','Pagado','Vencido')),
    FOREIGN KEY (id_expensa) REFERENCES Expensa(id_expensa)
);

CREATE TABLE Pago (
    id_pago INT IDENTITY(1,1) PRIMARY KEY,
    id_uf INT NULL,
    fecha DATE NOT NULL,
    medio_pago VARCHAR(50),
    valor DECIMAL(12,2),
    FOREIGN KEY (id_uf) REFERENCES Unidad_Funcional(id_uf)
);

CREATE TABLE Pago_Importado (
    id_pago_imp INT IDENTITY(1,1) PRIMARY KEY,
    id_pago INT NOT NULL,
    fecha_importacion DATE NOT NULL,
    cuenta_origen VARCHAR(22),
    CONSTRAINT FK_PagoImportado_Pago FOREIGN KEY (id_pago) REFERENCES Pago(id_pago),
    CONSTRAINT UQ_PagoImportado_id_pago UNIQUE (id_pago)
);

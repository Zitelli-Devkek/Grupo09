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







/*
CREATE TABLE Proveedor (
    id_proveedor INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    nro_cuenta VARCHAR(20) NULL,
    descripcion NVARCHAR(200) NULL,
    cuit CHAR(13) NOT NULL UNIQUE,
    email NVARCHAR(100) NULL,
    telefono VARCHAR(20) NULL
);

CREATE TABLE Consorcio (
    id_consorcio INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    direccion NVARCHAR(100) NULL,
    admin_nombre NVARCHAR(100) NULL,
    admin_cuit CHAR(13) NOT NULL UNIQUE,
    admin_email NVARCHAR(100) NULL
);

CREATE TABLE Gasto_Extraordinario (
    id_gasto_extraordinario INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio INT NOT NULL,
    id_proveedor INT NOT NULL,
    nro_cuota TINYINT NOT NULL,
    total_cuotas TINYINT NOT NULL,
    detalle NVARCHAR(100) NULL,
    importe DECIMAL(12,2) NOT NULL CHECK (importe >= 0),
    CONSTRAINT CK_GastoExtra_Cuotas CHECK (nro_cuota <= total_cuotas),
    CONSTRAINT FK_GastoExtra_Consorcio FOREIGN KEY (id_consorcio) 
        REFERENCES Consorcio(id_consorcio),
    CONSTRAINT FK_GastoExtra_Proveedor FOREIGN KEY (id_proveedor) 
        REFERENCES Proveedor(id_proveedor)
);

CREATE TABLE Gasto_Ordinario (
    id_gasto_ordinario INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio INT NOT NULL,
    id_proveedor INT NOT NULL,
    periodo DATE NOT NULL,
    nro_factura TINYINT NOT NULL,
    detalle NVARCHAR(100) NULL,
    importe DECIMAL(12,2) NOT NULL CHECK (importe >= 0),
    CONSTRAINT FK_GastoOrdinario_Consorcio FOREIGN KEY (id_consorcio) 
        REFERENCES Consorcio(id_consorcio),
    CONSTRAINT FK_GastoOrdinario_Proveedor FOREIGN KEY (id_proveedor) 
        REFERENCES Proveedor(id_proveedor)
);

CREATE TABLE Servicio (
    id_servicio INT IDENTITY(1,1) PRIMARY KEY,
    nro_cuenta INT NOT NULL,
    mes TINYINT NOT NULL CHECK (mes BETWEEN 1 AND 12),
    categoria NVARCHAR(8) NOT NULL CHECK (categoria IN ('LUZ','AGUA','INTERNET')),
    valor DECIMAL(12,2) NOT NULL
);

CREATE TABLE Persona
(
    DNI INT 
        CONSTRAINT PK_Persona PRIMARY KEY,
        CONSTRAINT CK_Persona_DNI CHECK (DNI BETWEEN 10000000 AND 99999999),

    nombre NVARCHAR(100) NOT NULL,
        CONSTRAINT CK_Persona_Nombre CHECK (nombre NOT LIKE '%[0-9]%'),

    apellido NVARCHAR(20) NULL,
        CONSTRAINT CK_Persona_Apellido CHECK (apellido IS NULL OR apellido NOT LIKE '%[0-9]%'),

    email_personal NVARCHAR(200) NULL,
        CONSTRAINT CK_Persona_Email CHECK (email_personal IS NULL OR email_personal LIKE '%_@_%._%'),

    rol CHAR(13) NOT NULL,

    telefono VARCHAR(20) NULL,
        CONSTRAINT CK_Persona_Telefono CHECK (telefono IS NULL OR LEN(telefono) BETWEEN 8 AND 15)
);

CREATE TABLE cuenta_bancaria
(
    DNI INT NOT NULL
        CONSTRAINT FK_Cuenta_Persona FOREIGN KEY REFERENCES Persona(DNI),
        CONSTRAINT CK_Cuenta_DNI CHECK (DNI BETWEEN 10000000 AND 99999999),

    cbu_cvu BIGINT NOT NULL,

    CONSTRAINT PK_Cuenta PRIMARY KEY (DNI, cbu_cvu)
);

CREATE TABLE unidad_funcional
(
    id_uf INT IDENTITY(1,1) PRIMARY KEY,

    id_consorcio INT NOT NULL
        CONSTRAINT FK_UF_Consorcio FOREIGN KEY REFERENCES Consorcio(id_consorcio),

    nr_uf INT NOT NULL
        CONSTRAINT CK_UF_Numero CHECK (nr_uf > 0),

    piso INT NOT NULL
        CONSTRAINT CK_UF_Piso CHECK (piso >= 0),

    departamento NVARCHAR(10) NOT NULL
        CONSTRAINT CK_UF_Departamento CHECK (LEN(departamento) > 0),

    tipo CHAR(10) NOT NULL
        CONSTRAINT CK_UF_Tipo CHECK (tipo IN ('VIVIENDA', 'LOCAL', 'COCHERA')),

    coeficiente DECIMAL(5,4) NOT NULL
        CONSTRAINT CK_UF_Coeficiente CHECK (coeficiente >= 0 AND coeficiente <= 1),

    m2 INT NOT NULL
        CONSTRAINT CK_UF_M2 CHECK (m2 > 0),

    obs VARCHAR(200) NULL
);

CREATE TABLE expensa
(
    id_expensa INT IDENTITY(1,1) PRIMARY KEY,

    id_uf INT NOT NULL
        CONSTRAINT FK_Expensa_UF FOREIGN KEY REFERENCES unidad_funcional(id_uf),

    DNI INT NOT NULL
        CONSTRAINT FK_Expensa_Persona FOREIGN KEY REFERENCES Persona(DNI)
        CONSTRAINT CK_Expensa_DNI CHECK (DNI BETWEEN 10000000 AND 99999999),

    mes TINYINT NOT NULL
        CONSTRAINT CK_Expensa_Mes CHECK (mes BETWEEN 1 AND 12),

    vencimiento DATE NOT NULL,

    saldo_anterior DECIMAL(10,2) NOT NULL
        CONSTRAINT CK_Expensa_SaldoAnterior CHECK (saldo_anterior >= 0),

    valor DECIMAL(10,2) NOT NULL
        CONSTRAINT CK_Expensa_Valor CHECK (valor >= 0),

    estado VARCHAR(15) NOT NULL
        CONSTRAINT CK_Expensa_Estado CHECK (estado IN ('PENDIENTE','PAGO','VENCIDA'))
);


CREATE TABLE pago
(
    id_pago INT IDENTITY(1,1) PRIMARY KEY,

    id_expensa INT NOT NULL
        CONSTRAINT FK_Pago_Expensa FOREIGN KEY REFERENCES expensa(id_expensa),

    fecha DATE NOT NULL
        CONSTRAINT CK_Pago_Fecha CHECK (fecha <= GETDATE()),

    medio_pago VARCHAR(20) NOT NULL
        CONSTRAINT CK_Pago_Medio CHECK (medio_pago IN ('EFECTIVO','TRANSFERENCIA','DEBITO','CREDITO')),

    valor DECIMAL(10,2) NOT NULL
        CONSTRAINT CK_Pago_Valor CHECK (valor > 0)
);

CREATE TABLE pago_importado
(
    id_pago_imp INT IDENTITY(1,1) PRIMARY KEY,

    id_pago INT NOT NULL
        CONSTRAINT FK_PagoImp_Pago FOREIGN KEY REFERENCES pago(id_pago),

    fecha_importacion DATE NOT NULL
        CONSTRAINT CK_PagoImp_FImport CHECK (fecha_importacion <= GETDATE()),

    fecha DATE NOT NULL
        CONSTRAINT CK_PagoImp_Fecha CHECK (fecha <= GETDATE()),

    cuenta_origen NVARCHAR(50) NOT NULL
        CONSTRAINT CK_PagoImp_Cuenta CHECK (LEN(cuenta_origen) > 5),

    asociado NVARCHAR(100) NOT NULL
        CONSTRAINT CK_PagoImp_Asociado CHECK (LEN(asociado) >= 3),

    valor DECIMAL(10,2) NOT NULL
        CONSTRAINT CK_PagoImp_Valor CHECK (valor > 0)
);

CREATE TABLE Expensa_Detalle (
    id_detalle INT IDENTITY(1,1) PRIMARY KEY,
    id_expensa INT NOT NULL,
    id_gasto_ordinario INT NULL,
    id_gasto_extraordinario INT NULL,
    tipo_gasto NVARCHAR(15) NOT NULL,
    fecha_venc DATE NOT NULL,
    importe_uf DECIMAL(12,2) NOT NULL CHECK (importe_uf >= 0),
    CONSTRAINT FK_ExpensaDetalle_Expensa FOREIGN KEY (id_expensa)
        REFERENCES Expensa(id_expensa),
    CONSTRAINT FK_ExpensaDetalle_GastoOrdinario FOREIGN KEY (id_gasto_ordinario)
        REFERENCES Gasto_Ordinario(id_gasto_ordinario),
    CONSTRAINT FK_ExpensaDetalle_GastoExtraordinario FOREIGN KEY (id_gasto_extraordinario)
        REFERENCES Gasto_Extraordinario(id_gasto_extraordinario)
);
*/
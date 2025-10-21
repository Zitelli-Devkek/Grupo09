
CREATE TABLE Consorcio.Persona
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

CREATE TABLE Consorcio.cuenta_bancaria
(
    DNI INT NOT NULL
        CONSTRAINT FK_Cuenta_Persona FOREIGN KEY REFERENCES Consorcio.Persona(DNI),
        CONSTRAINT CK_Cuenta_DNI CHECK (DNI BETWEEN 10000000 AND 99999999),

    cbu_cvu BIGINT NOT NULL,

    CONSTRAINT PK_Cuenta PRIMARY KEY (DNI, cbu_cvu)
);

--CREATE TABLE Consorcio.Consorcio (
--    id_consorcio INT IDENTITY(1,1) PRIMARY KEY,
--    nombre NVARCHAR(100) NOT NULL,
--    direccion VARCHAR(30) NULL,
--    admin_nombre NVARCHAR(100) NULL,
--    admin_cuit CHAR(13) NOT NULL UNIQUE, -- con guiones
--    admin_email NVARCHAR(100) NULL
--);

CREATE TABLE Consorcio.unidad_funcional
(
    id_uf INT IDENTITY(1,1) PRIMARY KEY,

    id_consorcio INT NOT NULL
        CONSTRAINT FK_UF_Consorcio FOREIGN KEY REFERENCES Consorcio.Consorcio(id_consorcio),

    nr_uf INT NOT NULL
        CONSTRAINT CK_UF_Numero CHECK (nr_uf > 0),

    piso INT NOT NULL
        CONSTRAINT CK_UF_Piso CHECK (piso >= 0),

    departamento NVARCHAR(10) NOT NULL
        CONSTRAINT CK_UF_Departamento CHECK (LEN(departamento) > 0),

    tipo CHAR(10) NOT NULL
        CONSTRAINT CK_UF_Tipo CHECK (tipo IN ('VIVIENDA', 'LOCAL', 'COCHERA')), --Revisar esta validacion

    coeficiente DECIMAL(5,4) NOT NULL
        CONSTRAINT CK_UF_Coeficiente CHECK (coeficiente > 0),

    m2 INT NOT NULL
        CONSTRAINT CK_UF_M2 CHECK (m2 > 0),

    obs VARCHAR(200) NULL
);

CREATE TABLE Consorcio.expensa
(
    id_expensa INT IDENTITY(1,1) PRIMARY KEY,

    id_uf INT NOT NULL
        CONSTRAINT FK_Expensa_UF FOREIGN KEY REFERENCES Consorcio.unidad_funcional(id_uf),

    DNI INT NOT NULL
        CONSTRAINT FK_Expensa_Persona FOREIGN KEY REFERENCES Consorcio.Persona(DNI)
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


CREATE TABLE Consorcio.pago
(
    id_pago INT IDENTITY(1,1) PRIMARY KEY,

    id_expensa INT NOT NULL
        CONSTRAINT FK_Pago_Expensa FOREIGN KEY REFERENCES Consorcio.expensa(id_expensa),

    fecha DATE NOT NULL
        CONSTRAINT CK_Pago_Fecha CHECK (fecha <= GETDATE()),

    medio_pago VARCHAR(20) NOT NULL
        CONSTRAINT CK_Pago_Medio CHECK (medio_pago IN ('EFECTIVO','TRANSFERENCIA','DEBITO','CREDITO')),

    valor DECIMAL(10,2) NOT NULL
        CONSTRAINT CK_Pago_Valor CHECK (valor > 0)
);

CREATE TABLE Consorcio.pago_importado
(
    id_pago_imp INT IDENTITY(1,1) PRIMARY KEY,

    id_pago INT NOT NULL
        CONSTRAINT FK_PagoImp_Pago FOREIGN KEY REFERENCES Consorcio.pago(id_pago),

    fecha_importacion DATE NOT NULL
        CONSTRAINT CK_PagoImp_FImport CHECK (fecha_importacion <= GETDATE()),

    fecha DATE NOT NULL
        CONSTRAINT CK_PagoImp_Fecha CHECK (fecha <= GETDATE()),

    cuenta_origen NVARCHAR(50) NOT NULL
        CONSTRAINT CK_PagoImp_Cuenta CHECK (LEN(cuenta_origen) > 5), --Revisar

    asociado NVARCHAR(100) NOT NULL
        CONSTRAINT CK_PagoImp_Asociado CHECK (LEN(asociado) >= 3), --Revisar

    valor DECIMAL(10,2) NOT NULL
        CONSTRAINT CK_PagoImp_Valor CHECK (valor > 0)
);
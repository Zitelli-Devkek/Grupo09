
USE Com2900G09;
GO

-- ===============================================
-- DATOS DE PRUEBA PARA TABLAS DE CONSORCIO Y UF
-- ===============================================

INSERT INTO Consorcio (nombre, cuit)
VALUES
('Consorcio Av. Libertador 1234', '30712345001'),
('Consorcio Rivadavia 5678', '30712345002');

INSERT INTO Unidad_Funcional (id_consorcio, nr_uf, piso, departamento, coeficiente, m2)
VALUES
(1, 1, '1', 'A', 10.50, 50.00),
(1, 2, '2', 'B', 9.50, 45.00),
(2, 1, 'PB', '1', 12.00, 60.00),
(2, 2, '1', 'A', 8.00, 40.00);

INSERT INTO Complemento (id_uf, m2, tipo_complemento)
VALUES
(1, 10, 'Cochera'),
(1, 5, 'Baulera'),
(2, 12, 'Cochera'),
(3, 8, 'Baulera'),
(4, 10, 'Cochera');

-- ===============================================
-- TIPOS DE OCUPANTE Y PERSONAS
-- ===============================================

INSERT INTO Tipo_Ocupante (descripcion)
VALUES ('Propietario'), ('Inquilino');

INSERT INTO Persona (DNI, id_tipo_ocupante, nombre, apellido, email_personal, telefono, cbu_cvu)
VALUES
('30123456', 1, 'Juan', 'Pérez', 'juanp@gmail.com', '1156789999', '2850590940090418123456'),
('30234567', 1, 'María', 'Gómez', 'mariagomez@gmail.com', '1156798888', '2850590940090418456789'),
('30345678', 2, 'Lucas', 'Díaz', 'lucasd@gmail.com', '1156791111', '2850590940090418451234'),
('30456789', 2, 'Ana', 'Ruiz', 'anar@gmail.com', '1156792222', '2850590940090418456781');

INSERT INTO Persona_UF (DNI, id_uf, fecha_inicio, fecha_fin)
VALUES
('30123456', 1, '2023-01-01', NULL),
('30234567', 2, '2023-03-01', NULL),
('30345678', 3, '2023-02-01', '2024-02-01'),
('30456789', 4, '2023-05-01', NULL);

-- ===============================================
-- SERVICIOS Y EXPENSAS
-- ===============================================

INSERT INTO Servicio (nro_cuenta, mes, categoria, valor)
VALUES
('Luz-001', 1, 'Luz', 30000),
('Agua-002', 1, 'Agua', 20000),
('Gas-003', 2, 'Gas', 25000),
('Internet-004', 2, 'Internet', 15000);

INSERT INTO Expensa (id_consorcio, mes, importe_total)
VALUES
(1, '2024-01', 80000),
(1, '2024-02', 85000),
(2, '2024-01', 70000),
(2, '2024-02', 90000);

INSERT INTO Factura (id_servicio, id_expensa, fecha_emision, fecha_vencimiento, importe, detalle)
VALUES
(1, 1, '2024-01-05', '2024-01-20', 30000, 'Factura Luz'),
(2, 1, '2024-01-06', '2024-01-25', 20000, 'Factura Agua'),
(3, 2, '2024-02-07', '2024-02-20', 25000, 'Factura Gas'),
(4, 2, '2024-02-07', '2024-02-25', 15000, 'Factura Internet');

-- ===============================================
-- DETALLES DE EXPENSAS
-- ===============================================

INSERT INTO Expensa_Detalle (id_expensa, nro_cuota, total_cuotas, descripcion, fecha_venc, importe_uf, estado)
VALUES
(1, 1, 1, 'Expensa Ordinaria Ene', '2024-01-15', 40000, 'Pagado'),
(1, 1, 1, 'Expensa Extraordinaria', '2024-01-20', 15000, 'Pagado'),
(2, 1, 1, 'Expensa Ordinaria Feb', '2024-02-15', 45000, 'Pendiente'),
(3, 1, 1, 'Expensa Ordinaria Ene', '2024-01-18', 35000, 'Pagado'),
(4, 1, 1, 'Expensa Extraordinaria Feb', '2024-02-18', 50000, 'Pagado');

-- ===============================================
-- PAGOS
-- ===============================================

INSERT INTO Pago (id_pago, id_exp_detalle, fecha, cvu_cbu, valor)
VALUES
(1, 1, '2024-01-14', '28505909400904181234', 40000),
(2, 2, '2024-01-19', '28505909400904184567', 15000),
(3, 4, '2024-01-17', '28505909400904184512', 35000),
(4, 5, '2024-02-19', '28505909400904184567', 50000);

Select * from Pago

INSERT INTO Pago (id_pago, id_exp_detalle, fecha, cvu_cbu, valor)
VALUES (10, 1, '2024-01-14', '2850590940090418123456', 40000); 
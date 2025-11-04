-- =============================================================
-- LOTE DE DATOS DE PRUEBA PARA SISTEMA DE CONSORCIOS
-- =============================================================

-- Limpiar datos (sin borrar estructura)
DELETE FROM Pago_Importado;
DELETE FROM Pago;
DELETE FROM Expensa_Detalle;
DELETE FROM Gasto_Extraordinario;
DELETE FROM Gasto_Ordinario;
DELETE FROM Expensa;
DELETE FROM Proveedor;
DELETE FROM Servicio;
DELETE FROM Persona_UF;
DELETE FROM Persona;
DELETE FROM Tipo_Ocupante;
DELETE FROM Complemento;
DELETE FROM Unidad_Funcional;
DELETE FROM Consorcio;

INSERT INTO Consorcio (nombre, direccion, admin_nombre, admin_cuit, admin_email)
VALUES 
('Altos de Saint Just', 'Av. San Martín 1234', 'María González', '20345678901', 'admin1@altos.com'),
('Torre Mitre', 'Mitre 456', 'Jorge Pérez', '20123456789', 'jorgep@mitre.com');

INSERT INTO Unidad_Funcional (id_consorcio, nr_uf, piso, departamento, coeficiente, m2)
VALUES
(1, 1, '1', 'A', 0.10, 55.50),
(1, 2, '1', 'B', 0.10, 60.00),
(2, 1, 'PB', 'A', 0.20, 80.00),
(2, 2, '2', 'A', 0.15, 70.00);

INSERT INTO Complemento (id_uf, m2, tipo_complemento)
VALUES
(1, 5.00, 'Cochera'),
(2, 3.00, 'Baulera'),
(3, 6.00, 'Cochera');

INSERT INTO Tipo_Ocupante (descripcion)
VALUES ('Propietario'), ('Inquilino'), ('Administrador');

INSERT INTO Persona (DNI, id_tipo_ocupante, nombre, apellido, email_personal, telefono, cbu_cvu)
VALUES
('30123456', 1, 'Lucía', 'Martínez', 'lucia@gmail.com', '1122334455', '1234567890123456789012'),
('40234567', 2, 'Carlos', 'Fernández', 'carlosf@gmail.com', '1199887766', '9876543210987654321098'),
('50345678', 3, 'María', 'González', 'admin1@altos.com', '1144556677', '4567891234567891234567');

INSERT INTO Persona_UF (DNI, id_uf, fecha_inicio, fecha_fin)
VALUES
('30123456', 1, '2023-01-01', NULL),
('40234567', 2, '2023-06-01', NULL),
('50345678', 3, '2022-01-01', NULL);

INSERT INTO Servicio (nro_cuenta, mes, categoria, valor)
VALUES
('123-456', 10, 'Luz', 5000.00),
('789-123', 10, 'Agua', 3500.00),
('456-789', 10, 'Gas', 4200.00);

INSERT INTO Proveedor (nombre, nro_cuenta, descripcion, cuit, email, telefono)
VALUES
('Edesur', 'ACC-001', 'Electricidad', '30765432109', 'contacto@edesur.com', '1140000000'),
('Aysa', 'ACC-002', 'Agua potable', '30876543210', 'info@aysa.com', '1130000000'),
('Metrogas', 'ACC-003', 'Gas natural', '30987654321', 'servicio@metrogas.com', '1120000000');

INSERT INTO Expensa (id_uf, mes, vencimiento, valor)
VALUES
(1, '2024-09', '2024-09-10', 20000.00),
(2, '2024-09', '2024-09-10', 22000.00),
(3, '2024-09', '2024-09-10', 30000.00);

INSERT INTO Gasto_Ordinario (id_expensa, id_proveedor, id_servicio, periodo, nro_factura, detalle, importe)
VALUES
(1, 1, 1, '2024-09', 'F001-0001', 'Electricidad septiembre', 5000.00),
(2, 2, 2, '2024-09', 'A001-0001', 'Agua septiembre', 3500.00),
(3, 3, 3, '2024-09', 'G001-0001', 'Gas septiembre', 4200.00);

INSERT INTO Gasto_Extraordinario (id_expensa, id_proveedor, total_cuotas, nro_cuota, detalle, importe)
VALUES
(1, 1, 3, 1, 'Pintura fachada', 15000.00),
(2, 2, 2, 1, 'Reparación tanque', 10000.00),
(3, 3, 1, 1, 'Cambio portón', 20000.00);

INSERT INTO Expensa_Detalle (id_expensa, tipo_gasto, fecha_venc, importe_uf, estado)
VALUES
(1, 'Ordinario', '2024-09-10', 5000.00, 'Pagado'),
(1, 'Extraordinario', '2024-09-15', 15000.00, 'Pendiente'),
(2, 'Ordinario', '2024-09-10', 3500.00, 'Pagado'),
(3, 'Extraordinario', '2024-09-15', 20000.00, 'Vencido');

INSERT INTO Pago (id_uf, fecha, medio_pago, valor)
VALUES
(1, '2024-09-05', 'Transferencia', 5000.00),
(1, '2024-09-15', 'Efectivo', 15000.00),
(2, '2024-09-06', 'Tarjeta', 3500.00),
(3, '2024-09-20', 'Transferencia', 20000.00);

INSERT INTO Pago_Importado (id_pago, fecha_importacion, cuenta_origen)
VALUES
(1, '2024-09-06', '1234567890123456789012'),
(2, '2024-09-16', '1234567890123456789012'),
(3, '2024-09-07', '9876543210987654321098'),
(4, '2024-09-21', '4567891234567891234567');


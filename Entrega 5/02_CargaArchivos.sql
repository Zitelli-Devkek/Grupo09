/*
BASE DE DATOS APLICADA

GRUPO 9

Alumnos:
Jiménez Damián (DNI 43.194.984)
Mendoza Gonzalo (DNI 44.597.456)
Demis Colman (DNI 37.174.947)
Feiertag Mateo (DNI 46.293.138)
Suriano Lautaro (DNI 44.792.129)
Zitelli Emanuel (DNI 45.064.107)

CARGA DE ARCHIVOS PARA EL PROYECTO
*/

USE Com2900G09;
GO

-- ===============================================
-- DATOS DE PRUEBA PARA TABLAS DE CONSORCIO Y UF
-- ===============================================


------------------------------
-- DATOS DE PRUEBA
------------------------------
INSERT INTO Consorcio (nombre, cuit, cant_UF, m2)
VALUES
('Consorcio Las Rosas', '30711234567', 12, 850),
('Consorcio Avenida Center', '30719876543', 20, 1450);

INSERT INTO Tipo_Ocupante (descripcion)
VALUES ('Propietario'), ('Inquilino'), ('Administrador');

INSERT INTO Persona (DNI, id_tipo_ocupante, nombre, apellido, email_personal, telefono, cbu_cvu)
VALUES
('20333444', 1, 'Juan', 'Pérez', 'juan@gmail.com', '1122334455', '2850590940090412345678'),
('25444555', 2, 'María', 'Gómez', 'maria@gmail.com', '1166778899', '0170202340000001234567'),
('27888999', 1, 'Carlos', 'López', NULL, '1144556677', '2850590940090499999999'),
('30444555', 3, 'Ana', 'Martínez', 'ana@gmail.com', '1199988877', '0170202340000008888888'),
('28999111', 1, 'Luis', 'García', 'luis@gmail.com', '1112345678', '2850590940090411111111'),
('26555111', 2, 'Sofía', 'Ramírez', 'sofi@gmail.com', '1188877766', '2850590940090422222222');

INSERT INTO Unidad_Funcional (id_consorcio, nr_uf, piso, departamento, coeficiente, m2)
VALUES
(1, 1, 'PB', 'A', 8.50, 55.0),
(1, 2, '1', 'B', 9.20, 60.0),
(1, 3, '2', 'A', 9.80, 65.0),
(2, 1, '1', 'A', 6.50, 42.0),
(2, 2, '1', 'B', 7.00, 45.0);

INSERT INTO Complemento (id_uf, m2, tipo_complemento)
VALUES
(1, 3.0, 'Baulera'),
(1, 12.0, 'Cochera'),
(3, 10.5, 'Cochera'),
(5, 2.5, 'Baulera');

INSERT INTO Servicio (nro_cuenta, mes, categoria, valor)
VALUES
('AGUA001', '2025-01', 'Agua', 45000),
('LUZ002', '2025-01', 'Electricidad', 72000),
('LIMP003', '2025-01', 'Limpieza', 35000),
('ASC004', '2025-01', 'Ascensor', 52000);

INSERT INTO Expensa (id_consorcio, DNI, mes, importe_total)
VALUES
(1, '20333444', '2025-01', 250000), -- Juan Pérez
(1, '28999111', '2025-02', 255000), -- Luis García
(2, '25444555', '2025-01', 390000), -- María Gómez
(2, '26555111', '2025-02', 400000); -- Sofía Ramírez

INSERT INTO Proveedor (id_proveedor, nombre_consorcio, categoria, nombre_proveedor, detalle)
VALUES
(1, 'Consorcio Las Rosas', 'Limpieza', 'CleanMax', 'Limpieza mensual'),
(2, 'Consorcio Las Rosas', 'Mantenimiento', 'ElevatorFix', 'Ascensores'),
(3, 'Consorcio Avenida Center', 'Agua', 'Aguas Argentinas', 'Servicio de agua'),
(4, 'Consorcio Avenida Center', 'Electricidad', 'Edesur', 'Servicio eléctrico');

INSERT INTO Factura (id_servicio, id_expensa, id_proveedor, fecha_emision, fecha_vencimiento, importe, detalle)
VALUES
(1, 1, 3, '2025-01-02', '2025-01-15', 45000, 'Agua enero'),
(2, 3, 4, '2025-01-05', '2025-01-20', 72000, 'Luz enero'),
(3, 1, 1, '2025-01-03', '2025-01-10', 35000, 'Limpieza general'),
(4, 1, 2, '2025-01-04', '2025-01-25', 52000, 'Ascensor enero');

INSERT INTO Expensa_Detalle (id_expensa, nro_cuota, total_cuotas, descripcion, fecha_venc, importe_uf, estado)
VALUES
(1, 1, 1, 'Expensa común enero', '2025-02-10', 18000, 'Pendiente'),
(1, 1, 3, 'Ascensor Cuota 1', '2025-02-15', 6200, 'Pendiente'),
(1, 2, 3, 'Ascensor Cuota 2', '2025-03-15', 6200, 'Pendiente'),
(3, 1, 1, 'Expensa común enero', '2025-02-12', 24000, 'Pagado'),
(4, 1, 1, 'Expensa común febrero', '2025-03-12', 25000, 'Pendiente'),
(2, 1, 1, 'Expensa común febrero', '2025-03-10', 18500, 'Pendiente');

INSERT INTO Pago (id_pago, id_exp_detalle, fecha, cvu_cbu, valor)
VALUES
(1, 1, '2025-02-05', '2850590940090412345678', 18000),
(2, 4, '2025-02-01', '0170202340000001234567', 24000),
(3, 6, '2025-03-05', '2850590940090422222222', 18500);

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


Genere índices para optimizar la ejecución de las consultas de los reportes. Debe existir un
script adicional con la generación de índices.*/

USE Com2900G09;
GO

SET NOCOUNT ON;
GO

-- Índices en Pago
CREATE INDEX IF NOT EXISTS IX_Pago_fecha ON Pago(fecha);
CREATE INDEX IF NOT EXISTS IX_Pago_cvu_cbu ON Pago(cvu_cbu);
CREATE INDEX IF NOT EXISTS IX_Pago_id_exp_detalle ON Pago(id_exp_detalle);

-- Índices en Expensa y Expensa_Detalle
CREATE INDEX IF NOT EXISTS IX_Expensa_id_consorcio_mes ON Expensa(id_consorcio, mes);
CREATE INDEX IF NOT EXISTS IX_ExpensaDetalle_id_expensa_fecha ON Expensa_Detalle(id_expensa, fecha_venc);
CREATE INDEX IF NOT EXISTS IX_ExpensaDetalle_descripcion ON Expensa_Detalle(descripcion);

-- Personas / relacion
CREATE INDEX IF NOT EXISTS IX_Persona_cbu_cvu ON Persona(cbu_cvu);
CREATE INDEX IF NOT EXISTS IX_Persona_id_tipo_ocupante ON Persona(id_tipo_ocupante);

-- Unidad Funcional
CREATE INDEX IF NOT EXISTS IX_UF_id_consorcio_departamento ON Unidad_Funcional(id_consorcio, departamento);

-- Factura / Servicio
CREATE INDEX IF NOT EXISTS IX_Factura_id_expensa_fecha ON Factura(id_expensa, fecha_emision);
CREATE INDEX IF NOT EXISTS IX_Factura_id_servicio ON Factura(id_servicio);

-- Tipo_Ocupante (poco crítico, pero OK)
CREATE INDEX IF NOT EXISTS IX_Persona_Tipo ON Persona(id_tipo_ocupante);
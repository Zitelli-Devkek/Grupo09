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

--Estos son fundamentales porque los procedimientos usan muchos JOIN entre esas tablas.
CREATE INDEX IX_UF_id_consorcio ON Unidad_Funcional (id_consorcio);
CREATE INDEX IX_Complemento_id_uf ON Complemento (id_uf);
CREATE INDEX IX_Persona_id_tipo_ocupante ON Persona (id_tipo_ocupante);
CREATE INDEX IX_PersonaUF_DNI ON Persona_UF (DNI);
CREATE INDEX IX_PersonaUF_id_uf ON Persona_UF (id_uf);
CREATE INDEX IX_Expensa_id_consorcio ON Expensa (id_consorcio);
CREATE INDEX IX_Factura_id_expensa ON Factura (id_expensa);
CREATE INDEX IX_Factura_id_servicio ON Factura (id_servicio);
CREATE INDEX IX_ExpensaDet_id_expensa ON Expensa_Detalle (id_expensa);
CREATE INDEX IX_Pago_id_exp_detalle ON Pago (id_exp_detalle);

--Usada en varios reportes por fecha y id_exp_detalle.
CREATE INDEX IX_Pago_fecha ON Pago (fecha);
CREATE INDEX IX_Pago_cvu_cbu ON Pago (cvu_cbu);
CREATE INDEX IX_Pago_id_exp_detalle_fecha ON Pago (id_exp_detalle, fecha);

--Esto acelera los procedimientos que separan pagos “ordinarios / extraordinarios”.
CREATE INDEX IX_ExpensaDetalle_fecha_venc ON Expensa_Detalle (fecha_venc);
CREATE INDEX IX_ExpensaDetalle_id_expensa_descripcion ON Expensa_Detalle (id_expensa, descripcion);

--Optimiza sp_Report_Top5GastosIngresos.
CREATE INDEX IX_Factura_fecha_emision ON Factura (fecha_emision);
CREATE INDEX IX_Factura_id_expensa_fecha_emision ON Factura (id_expensa, fecha_emision);

--Consultada por id_consorcio y a veces mes.
CREATE INDEX IX_Expensa_id_consorcio_mes ON Expensa (id_consorcio, mes);

--Mapeada por cbu_cvu y DNI en sp_Report_Top3Morosos_XML.
CREATE INDEX IX_Persona_cbu_cvu ON Persona (cbu_cvu);

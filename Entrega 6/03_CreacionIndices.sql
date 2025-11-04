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




USE AltosSaintJust
GO

DROP INDEX IF EXISTS IX_Pago_fecha ON dbo.Pago;
CREATE INDEX IX_Pago_fecha ON dbo.Pago(fecha);

DROP INDEX IF EXISTS IX_Pago_id_uf ON dbo.Pago;
CREATE INDEX IX_Pago_id_uf ON dbo.Pago(id_uf);

DROP INDEX IF EXISTS IX_Pago_valor ON dbo.Pago;
CREATE INDEX IX_Pago_valor ON dbo.Pago(valor);

DROP INDEX IF EXISTS IX_Expensa_mes ON dbo.Expensa;
CREATE INDEX IX_Expensa_mes ON dbo.Expensa(mes);

DROP INDEX IF EXISTS IX_Expensa_id_uf ON dbo.Expensa;
CREATE INDEX IX_Expensa_id_uf ON dbo.Expensa(id_uf);

DROP INDEX IF EXISTS IX_Expensa_vencimiento ON dbo.Expensa;
CREATE INDEX IX_Expensa_vencimiento ON dbo.Expensa(vencimiento);

DROP INDEX IF EXISTS IX_ExpensaDet_id_expensa ON dbo.Expensa_Detalle;
CREATE INDEX IX_ExpensaDet_id_expensa ON dbo.Expensa_Detalle(id_expensa);

DROP INDEX IF EXISTS IX_ExpensaDet_tipo_gasto ON dbo.Expensa_Detalle;
CREATE INDEX IX_ExpensaDet_tipo_gasto ON dbo.Expensa_Detalle(tipo_gasto);

DROP INDEX IF EXISTS IX_ExpensaDet_fecha_venc ON dbo.Expensa_Detalle;
CREATE INDEX IX_ExpensaDet_fecha_venc ON dbo.Expensa_Detalle(fecha_venc);

DROP INDEX IF EXISTS IX_GastoOrd_id_expensa ON dbo.Gasto_Ordinario;
CREATE INDEX IX_GastoOrd_id_expensa ON dbo.Gasto_Ordinario(id_expensa);

DROP INDEX IF EXISTS IX_GastoOrd_importe ON dbo.Gasto_Ordinario;
CREATE INDEX IX_GastoOrd_importe ON dbo.Gasto_Ordinario(importe);

DROP INDEX IF EXISTS IX_GastoExt_id_expensa ON dbo.Gasto_Extraordinario;
CREATE INDEX IX_GastoExt_id_expensa ON dbo.Gasto_Extraordinario(id_expensa);

DROP INDEX IF EXISTS IX_GastoExt_importe ON dbo.Gasto_Extraordinario;
CREATE INDEX IX_GastoExt_importe ON dbo.Gasto_Extraordinario(importe);

DROP INDEX IF EXISTS IX_UF_id_consorcio ON dbo.Unidad_Funcional;
CREATE INDEX IX_UF_id_consorcio ON dbo.Unidad_Funcional(id_consorcio);

DROP INDEX IF EXISTS IX_PersonaUF_DNI ON dbo.Persona_UF;
CREATE INDEX IX_PersonaUF_DNI ON dbo.Persona_UF(DNI);

DROP INDEX IF EXISTS IX_PersonaUF_id_uf ON dbo.Persona_UF;
CREATE INDEX IX_PersonaUF_id_uf ON dbo.Persona_UF(id_uf);
USE AltosSaintJust
GO

IF COL_LENGTH('Pago','id_exp_detalle') IS NULL
BEGIN
    ALTER TABLE Pago
    ADD id_exp_detalle INT NULL;

    ALTER TABLE Pago
    ADD CONSTRAINT FK_Pago_ExpDet FOREIGN KEY (id_exp_detalle)
        REFERENCES Expensa_Detalle(id_exp_detalle);
END

CREATE INDEX IX_Pago_fecha ON dbo.Pago(fecha)
CREATE INDEX IX_Pago_id_uf ON Pago(id_uf)
CREATE INDEX IX_Pago_id_exp_detalle ON Pago(id_exp_detalle);

CREATE INDEX IX_ExpDet_id_expensa ON Expensa_Detalle(id_expensa);
CREATE INDEX IX_ExpDet_fecha_venc ON Expensa_Detalle(fecha_venc);
CREATE INDEX IX_ExpDet_tipo_gasto ON Expensa_Detalle(tipo_gasto);

CREATE INDEX IX_Expensa_id_consorcio ON Expensa(id_consorcio);
CREATE INDEX IX_Expensa_vencimiento ON Expensa(vencimiento);

CREATE INDEX IX_UF_id_consorcio ON Unidad_Funcional(id_consorcio);

CREATE INDEX IX_GastoOrd_id_expensa ON Gasto_Ordinario(id_expensa);
CREATE INDEX IX_GastoExt_id_expensa ON Gasto_Extraordinario(id_expensa);

CREATE INDEX IX_PersonaUF_id_uf ON Persona_UF(id_uf);
CREATE INDEX IX_PersonaUF_fechas ON Persona_UF(fecha_inicio, fecha_fin);

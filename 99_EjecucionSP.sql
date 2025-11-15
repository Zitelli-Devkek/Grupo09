USE Com2900G09

--ENTREGA 5

EXEC sp_creacionBD
EXEC sp_CreacionTablas
EXEC sp_CreacionIndices
EXEC sp_creacionTablaAPI
EXEC sp_ActualizarDolar


--ENTREGA 6
-- 1) Flujo de caja semanal
EXEC dbo.sp_Report_FlujoCajaSemanal
    @id_consorcio = 1,
    @fecha_inicio = '2024-01-01',
    @fecha_fin = '2025-10-31';

-- 2) Recaudación por mes y departamento (pivot)
EXEC dbo.sp_Reporte2_RecaudacionMensual 
    @Anio = 2025,
    @IdConsorcio = 1,
    @MesInicio = 1,
    @tipo_dolar = 'Blue';

-- 3) Recaudación por procedencia (Ordinario/Extra/Otro)
EXEC dbo.sp_Report_RecaudacionPorProcedencia_Unica
    @id_consorcio = 1,
    @fecha_inicio = '2024-01-01',
    @fecha_fin = '2025-10-31';

-- 4) Top 5 meses gastos / ingresos
EXEC dbo.sp_Report_Top5GastosIngresos
    @id_consorcio = 1,
    @fecha_inicio = '2024-01-01',
    @fecha_fin = '2025-10-31';

-- 5) Top 3 morosos (XML)
EXEC dbo.sp_Report_Top3Morosos_XML
    @id_consorcio = 1,
    @fecha_inicio = '2024-01-01',
    @fecha_fin = '2025-10-31';

-- 6) Pagos ordinarios por UF y días entre pagos (XML)
EXEC dbo.sp_Report_PagosOrdinariosPorUF_XML
    @id_consorcio = 1,
    @fecha_inicio = '2024-01-01',
    @fecha_fin = '2025-10-31';
    
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

Llamados a los reportes*/
USE Com2900G09;
GO

-- 1) Flujo de caja semanal
EXEC dbo.sp_Report_FlujoCajaSemanal
    @id_consorcio = 1,
    @fecha_inicio = '2024-01-01',
    @fecha_fin = '2025-10-31';

-- 2) Recaudación por mes y departamento (pivot)
EXEC dbo.sp_Report_RecaudacionMesDepartamento 
     @anio = 2024, 
     @id_consorcio = 2, 
     @tipo_moneda = 'PESOS';

EXEC dbo.sp_Report_RecaudacionMesDepartamento 
     @anio = 2024, 
     @id_consorcio = 1, 
     @tipo_moneda = 'USD';


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

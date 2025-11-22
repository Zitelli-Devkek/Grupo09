
--ENTREGA 5

--CREACION DE LA BDD
EXEC sp_creacionBD
GO

USE Com2900G09
GO

--CREACION DE TABLAS
EXEC sp_CreacionTablas;
GO
/*
EXEC sp_creacionLotes
GO*/

--LLENADO DE TABLAS CON IMPORTACIONES Y LOTES DE PRUEBA

EXEC sp_ImportarConsorcioExcel @RutaArchivo='D:\AAAMAIN\Z.Universidad\Bases de Datos Aplicadas\consorcios\datos varios.xlsx'
GO

EXEC sp_ImportarProveedoresDesdeExcel @RutaArchivo='D:\AAAMAIN\Z.Universidad\Bases de Datos Aplicadas\consorcios\datos varios.xlsx'
GO

--FUNCIONA
EXEC sp_Importar_UF_Complemento @RutaArchivo='D:\AAAMAIN\Z.Universidad\Bases de Datos Aplicadas\consorcios\UF por consorcio.txt'
GO
--FUNCIONA
EXEC sp_importar_csv_inquilino_propietarios_datos @RutaArchivo='D:\AAAMAIN\Z.Universidad\Bases de Datos Aplicadas\consorcios\Inquilino-propietarios-datos.csv'
GO
--FUNCIONA
EXEC sp_importar_csv_inquilino_propietarios_UF @RutaArchivo='D:\AAAMAIN\Z.Universidad\Bases de Datos Aplicadas\consorcios\Inquilino-propietarios-UF.csv'
GO

EXEC sp_ImportarServicios @RutaArchivo='D:\AAAMAIN\Z.Universidad\Bases de Datos Aplicadas\consorcios\Servicios.Servicios.json'
GO
--FUNCIONA
EXEC sp_lote_expensas;
GO
--FUNCIONA
EXEC sp_generar_facturas_prueba;
GO
--FUNCIONA
EXEC sp_CargarExpensaDetalle;
GO
--FUNCIONA
EXEC sp_importar_pagos_csv @RutaArchivo='D:\AAAMAIN\Z.Universidad\Bases de Datos Aplicadas\consorcios\pagos_consorcios.csv'
GO




-- PARA MOSTRAR TABLAS
/*
SELECT * FROM Persona

SELECT * FROM Tipo_Ocupante

SELECT * FROM Unidad_Funcional

SELECT * FROM Complemento

SELECT * FROM Persona_UF

SELECT * FROM Consorcio

SELECT * FROM Proveedor

SELECT * FROM Servicio

SELECT * FROM Factura

SELECT * FROM Expensa

SELECT * FROM Expensa_Detalle

SELECT * FROM Pago


--PARA MOSTRAR ERRORES TENEMOS LA TABLA DE ERRORLOGS

SELECT * FROM ErrorLogs*/

--EJECUCION DE APIS (prepara para entrega 6)

EXEC sp_CreacionIndices
EXEC sp_creacionTablaAPI
EXEC sp_ActualizarDolar

-----------------------------------------------------------------------------------------------------
--ENTREGA 6
-- 1) Flujo de caja semanal
EXEC dbo.sp_Report_FlujoCajaSemanal
    @id_consorcio = 1,
    @fecha_inicio = '2025-01-01',
    @fecha_fin = '2026-10-31';

-- 2) Recaudación por mes y departamento (pivot)
EXEC dbo.sp_Reporte2_RecaudacionMensual 
    @Anio = 2025,
    @IdConsorcio = 1,
    @MesInicio = 1,
    @tipo_dolar = 'Blue';

-- 3) Recaudación por procedencia (Ordinario/Extra/Otro)
EXEC dbo.sp_Report_RecaudacionPorProcedencia_Unica
    @id_consorcio = 1,
    @fecha_inicio = '2025-01-01',
    @fecha_fin = '2026-10-31';

-- 4) Top 5 meses gastos / ingresos
EXEC dbo.sp_Report_Top5GastosIngresos
    @id_consorcio = 1,
    @fecha_inicio = '2025-01-01',
    @fecha_fin = '2026-10-31';

-- 5) Top 3 morosos (XML)
EXEC dbo.sp_Report_Top3Morosos_XML
    @id_consorcio = 1,
    @fecha_inicio = '2025-01-01',
    @fecha_fin = '2026-10-31';

-- 6) Pagos ordinarios por UF y días entre pagos (XML)
EXEC dbo.sp_Report_PagosOrdinariosPorUF_XML
    @id_consorcio = 1,
    @fecha_inicio = '2025-01-01',
    @fecha_fin = '2026-10-31';
    

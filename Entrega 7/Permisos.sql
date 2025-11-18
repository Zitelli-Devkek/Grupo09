/*
-- =================================================================
-- Asignatura: Bases de Datos Aplicada
-- Comisión: 01-2900 
-- Grupo Nro: 09
-- Fecha de Entrega:
--
-- Enunciado: Creacion de roles
-- =================================================================
-- Integrantes:
-- Jiménez Damián (DNI 43.194.984)
-- Mendoza Gonzalo (DNI 44.597.456)
-- Demis Colman (DNI 37.174.947)
-- Feiertag Mateo (DNI 46.293.138)
-- Suriano Lautaro (DNI 44.792.129)
-- Zitelli Emanuel (DNI 45.064.107)
-- =================================================================
*/

USE Com2900G09;
GO

-- --- CREACION ROLES ---
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_administrativo_general' AND type = 'R')
BEGIN
    CREATE ROLE rol_administrativo_general;
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_administrativo_bancario' AND type = 'R')
BEGIN
    CREATE ROLE rol_administrativo_bancario;
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_administrativo_operativo' AND type = 'R')
BEGIN
    CREATE ROLE rol_administrativo_operativo;
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_sistemas' AND type = 'R')
BEGIN
    CREATE ROLE rol_sistemas;
END
GO

-- Rol base para reportes
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_reportes_lectura' AND type = 'R')
BEGIN
    CREATE ROLE rol_reportes_lectura;
END
GO


-- Permiso para ejecutar todos los SP de reportes
GRANT EXECUTE ON [dbo].[sp_Report_FlujoCajaSemanal] TO rol_reportes_lectura;
GRANT EXECUTE ON [dbo].[sp_Reporte2_RecaudacionMensual] TO rol_reportes_lectura;
GRANT EXECUTE ON [dbo].[sp_Report_RecaudacionPorProcedencia_Unica] TO rol_reportes_lectura;
GRANT EXECUTE ON [dbo].[sp_Report_Top5GastosIngresos] TO rol_reportes_lectura;
GRANT EXECUTE ON [dbo].[sp_Report_Top3Morosos_XML] TO rol_reportes_lectura;
GRANT EXECUTE ON [dbo].[sp_Report_PagosOrdinariosPorUF_XML] TO rol_reportes_lectura;

-- Permiso de SELECT en las tablas que leen los reportes
GRANT SELECT ON [dbo].[Pago] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Expensa_Detalle] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Factura] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Persona_UF] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Complemento] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Unidad_Funcional] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Expensa] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Servicio] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Persona] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Tipo_Ocupante] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Consorcio] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[Proveedor] TO rol_reportes_lectura;
GRANT SELECT ON [dbo].[ErrorLogs] TO rol_reportes_lectura;




-- ROL: adminstrativo general

GRANT EXECUTE ON [dbo].[sp_Importar_UF_Complemento] TO rol_administrativo_general;
GRANT EXECUTE ON [dbo].[sp_importar_csv_inquilino_propietarios_UF] TO rol_administrativo_general;
ALTER ROLE rol_reportes_lectura ADD MEMBER rol_administrativo_general; -- Hereda permisos de reportes
GO

-- ROL: Administrativo Bancario

GRANT EXECUTE ON [dbo].[sp_importar_csv_inquilino_propietarios_datos] TO rol_administrativo_bancario;
ALTER ROLE rol_reportes_lectura ADD MEMBER rol_administrativo_bancario; -- Hereda permisos de reportes
GO

-- ROL: Administrativo operativo

GRANT EXECUTE ON [dbo].[sp_Importar_UF_Complemento] TO rol_administrativo_operativo;
GRANT EXECUTE ON [dbo].[sp_importar_csv_inquilino_propietarios_UF] TO rol_administrativo_operativo;
ALTER ROLE rol_reportes_lectura ADD MEMBER rol_administrativo_operativo; -- Hereda permisos de reportes
GO

-- ROL: Sistemas

ALTER ROLE rol_reportes_lectura ADD MEMBER rol_sistemas; -- Hereda permisos de reportes
GO

-- Asignar usuarios a roles
ALTER ROLE rol_administrativo_general ADD MEMBER [usuario_general_1];
ALTER ROLE rol_administrativo_bancario ADD MEMBER [usuario_bancario_1];
ALTER ROLE rol_administrativo_operativo ADD MEMBER [usuario_operativo_1];
ALTER ROLE rol_sistemas ADD MEMBER [usuario_sistemas_1];



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

CREACION DE LA BASE DE DATOS PARA EL PROYECTO
*/


IF NOT EXISTS (SELECT * FROM sys.databases WHERE NAME = 'AltosSAintJust')
BEGIN
CREATE DATABASE AltosSaintJust
END
GO

USE AltosSaintJust
GO
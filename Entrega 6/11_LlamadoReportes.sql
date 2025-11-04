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

EXEC sp_Reporte1_FlujoSemanal '2020-01-01', '2025-12-31', 1;
EXEC sp_Reporte2_RecaudacionMensual 2024, 1, 8;
EXEC sp_Reporte3_RecaudacionPorTipo 2024, 1, 1;
EXEC sp_Reporte4_MayoresGastosIngresos 2024, 1;
EXEC sp_Reporte5_MayorMorosidad 2024, 2;
EXEC sp_Reporte6_DiasEntrePagos_XML 1, 2024;
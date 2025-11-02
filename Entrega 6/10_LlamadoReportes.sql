EXEC rpt_FlujoCaja_Semanal '2025-01-01','2025-03-31', NULL;

EXEC rpt_Recaudacion_Mes_Departamento_XML '2025-01','2025-03', 1;

EXEC rpt_Recaudacion_Por_Procedencia_XML '2025-01-01','2025-03-31', NULL, 'month';

EXEC rpt_Top5_Meses_Gastos_Ingresos '2024-01-01','2025-12-31', NULL, 5;

EXEC rpt_TopMorosos '2025-03-31', NULL, 3;

EXEC rpt_Pagos_UF_Intervalos '2024-01-01','2025-12-31', NULL, NULL;

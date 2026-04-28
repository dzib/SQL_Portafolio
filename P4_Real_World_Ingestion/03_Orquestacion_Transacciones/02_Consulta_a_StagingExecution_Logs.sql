/* 
============================================================
CONSULTA DE AUDITORÍA Y OBSERVABILIDAD
============================================================
*/
USE P4_Global_SupplyChain;
GO

-- ----------------------------------------------------------
-- 1. Ver el log de ejecución (Métricas de la Fase 4.3)
-- ----------------------------------------------------------
SELECT 
    LogID,
    PhaseName,
    FORMAT(RowsAffected, 'N0') AS Filas_Procesadas,
    CAST(ExecutionTime_MS AS VARCHAR) + ' ms' AS Duracion,
    Status,
    CreatedAt
FROM Staging.Execution_Logs
ORDER BY CreatedAt DESC;

-- ----------------------------------------------------------
-- 2. Muestra rápida de los datos en Analytics
-- ----------------------------------------------------------
SELECT TOP 10 * 
FROM Analytics.SupplyChain_Shipments;

/* 
========================================================================================================================
PROYECTO: P4_Real_World_Ingestion - Global Supply Chain Analytics (Kaggle Dataset)
FASE: 4.4.1 (SQL) - Análisis de Anomalías en la tabla de envíos.
ARCHIVO: Script de verificación de registros de anomalías marcadaas.
AUTOR: Alberto Dzib
VERSIÓN: 1.1
Descripción: 
    - Verificación de registros de anomalías en la tabla de envíos y revisión de logs de ejecución.
========================================================================================================================
*/

-- 02_Verificacion_reg.sql

SELECT 
    Is_Anomaly,
    CAST(COUNT(*) AS DECIMAL(10,2)) Total_Orders
FROM Analytics.SupplyChain_Shipments 
GROUP BY Is_Anomaly;

-- Verificación de los Logs, revisión de la tabla de control para ver el tiempo exacto de esta fase.
SELECT * FROM Staging.Execution_Logs ORDER BY CreatedAt DESC;

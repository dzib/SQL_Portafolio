/* 
======================================================================================================================================
PROYECTO: P4_Real_World_Ingestion
FASE: 4.5 (SQL) - Vistas Analíticas para Toma de Decisiones
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Creación de vistas analíticas en el esquema Analytics para facilitar la toma de decisiones estratégicas.
    - Materializar la lógica de negocio en SQL.
    - KPI_Shipping_Efficiency: Tasa de éxito de entregas por región.
    - KPI_Profit_Risk: Análisis de rentabilidad vs riesgo de entrega.
======================================================================================================================================
*/

USE P4_Global_SupplyChain;
GO
-- -- -----------------------------------------------------------------------------------------------------------------------------
-- 1. Vista de Eficiencia Logística por Región
-- -- -----------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER VIEW Analytics.vw_Shipping_Efficiency AS
SELECT 
    Order_Region,
    Delivery_Status,
    COUNT(*) AS Total_Orders,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY Order_Region) AS DECIMAL(10,2)) AS Percentage
FROM Analytics.SupplyChain_Shipments
WHERE Is_Anomaly = 0
GROUP BY Order_Region, Delivery_Status;
GO

-- -- -----------------------------------------------------------------------------------------------------------------------------
-- 2. Vista de Rentabilidad por Categoría
-- -- -----------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER VIEW Analytics.vw_Category_Performance AS
SELECT 
    Category_Name,
    SUM(Total_Sales) AS Total_Revenue,
    SUM(Profit) AS Total_Profit,
    (SUM(Profit) / NULLIF(SUM(Total_Sales), 0)) * 100 AS Profit_Margin_Pct
FROM Analytics.SupplyChain_Shipments
WHERE Is_Anomaly = 0
GROUP BY Category_Name;
GO

PRINT '==================================================================';
PRINT '✅ Vistas analíticas creadas exitosamente en el esquema Analytics.';
PRINT '==================================================================';
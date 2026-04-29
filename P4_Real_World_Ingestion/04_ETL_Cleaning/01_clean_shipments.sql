/* 
==================================================================================================================================
PROYECTO: P4_Real_World_Ingestion - Global Supply Chain Analytics (Kaggle Dataset)
FASE: 4.4 (SQL) - ETL y Normalización de Datos Crudos
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Estandarización de cadenas de texto (TRIM/UPPER).
    - Implementación de lógica de negocio para Riesgo de Entrega.
    - Auditoría de integridad financiera.
===================================================================================================================================
*/

USE P4_Global_SupplyChain;
GO
-- Si la columna ya existe, esto la limpia para empezar de cero.
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Analytics.SupplyChain_Shipments') AND name = 'Is_Anomaly')
BEGIN
    ALTER TABLE Analytics.SupplyChain_Shipments DROP COLUMN Is_Anomaly;
END
GO

DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();

BEGIN TRY
--- -- -----------------------------------------------------------------------------------------------------------------------------
    -- 1. LIMPIEZA DE CADENAS Y ESTANDARIZACIÓN
--- -- -----------------------------------------------------------------------------------------------------------------------------
    -- Normalizamos texto para evitar inconsistencias (ej. "New York" vs "new york").
    UPDATE Analytics.SupplyChain_Shipments
    SET 
        Customer_City = UPPER(TRIM(Customer_City)),
        Order_Region = UPPER(TRIM(Order_Region)),
        Category_Name = UPPER(TRIM(Category_Name)),
        Delivery_Status = UPPER(TRIM(Delivery_Status));

--- -- -----------------------------------------------------------------------------------------------------------------------------
    -- 2. NORMALIZACIÓN DE RIESGO (Enriquecimiento de datos)
--- -- -----------------------------------------------------------------------------------------------------------------------------
    -- Si Late_delivery_risk es 1, aseguramos que el estatus mencione el retraso de forma clara.
    UPDATE Analytics.SupplyChain_Shipments
    SET Delivery_Status = 'LATE DELIVERY (VERIFIED)'
    WHERE Late_delivery_risk = 1 AND Delivery_Status = 'LATE DELIVERY';

--- -- -----------------------------------------------------------------------------------------------------------------------------
-- 3. AUDITORÍA FINANCIERA (Marcado de anomalías con *SQL Dinámico*)
--- -- -----------------------------------------------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Analytics.SupplyChain_Shipments') AND name = 'Is_Anomaly')
    BEGIN
        ALTER TABLE Analytics.SupplyChain_Shipments ADD Is_Anomaly BIT DEFAULT 0;
    END

    -- Usamos EXEC para que el compilador lo procese como un simple "texto" y así evitar errores si la columna no existía previamente.
    EXEC sp_executesql N'
        UPDATE Analytics.SupplyChain_Shipments
        SET Is_Anomaly = 1
        WHERE Total_Sales <= 0 OR Profit < (Total_Sales * -1); 
    '; -- Marcar ventas sin ganancia o con pérdida excesiva como anomalías

--- -- -----------------------------------------------------------------------------------------------------------------------------
-- 4. REGISTRO DE MÉTRICAS EN LOGS
--- -- -----------------------------------------------------------------------------------------------------------------------------
    INSERT INTO Staging.Execution_Logs (PhaseName, RowsAffected, ExecutionTime_MS, Status)
    VALUES ('Fase 4.4: ETL & Cleaning', @@ROWCOUNT, DATEDIFF(MS, @StartTime, SYSUTCDATETIME()), 'SUCCESS');

    PRINT '==================================================================================';
    PRINT '✅ ETL completado. Datos normalizados y auditoría financiera finalizada.';
    PRINT '==================================================================================';
END TRY
BEGIN CATCH
    INSERT INTO Staging.Execution_Logs (PhaseName, RowsAffected, ExecutionTime_MS, Status, ErrorMsg)
    VALUES ('Fase 4.4: ETL & Cleaning', 0, DATEDIFF(MS, @StartTime, SYSUTCDATETIME()), 'ERROR', ERROR_MESSAGE());
    
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '❌ Error en Fase 4.4: ' + ERROR_MESSAGE();
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
END CATCH


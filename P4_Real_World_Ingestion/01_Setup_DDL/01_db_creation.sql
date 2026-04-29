/* 
==============================================================================================================================================
PROYECTO: P4_Real_World_Ingestion - Global Supply Chain Analytics (Kaggle Dataset)
FASE: 4.1 (SQL) - Arquitectura de Datos e Ingesta de Alto Desempeño (DDL)
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Creación de la base de datos e infraestructura de esquemas.
    - Implementación de tablas de Staging optimizadas para ingesta masiva (~27k reg/seg).
    - Configuración de constraints de integridad y tipos de datos de alta precisión.
==============================================================================================================================================
*/
-- ------------------------------------------------------------------------------------------------------------------------------------------
-- 1. CREACIÓN DE LA BASE DE DATOS (GARANTIZANDO IDEMPOTENCIA TOTAL)
-- ------------------------------------------------------------------------------------------------------------------------------------------
USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'P4_Global_SupplyChain')
BEGIN
    CREATE DATABASE P4_Global_SupplyChain;
    PRINT '✅ Base de datos P4_Global_SupplyChain creada con éxito.';
END
GO

USE P4_Global_SupplyChain;
GO -- Aquí termina el lote de cambio de base de datos

-- Iniciamos un nuevo lote para la creación de esquemas y tablas, con manejo de errores y métricas de tiempo.
DECLARE @StartTime DATETIME2 = SYSUTCDATETIME(); -- Para métricas de tiempo de ejecución.

BEGIN TRY
--- -- ------------------------------------------------------------------------------------------------------------------------------------------
--- -- 2. CREACIÓN DE ESQUEMAS (SEGMENTACIÓN LOGÍSTICA)
--- -- ------------------------------------------------------------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Staging') EXEC('CREATE SCHEMA Staging');
    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Analytics') EXEC('CREATE SCHEMA Analytics');
    
--- -- ------------------------------------------------------------------------------------------------------------------------------------------
--- -- 3. TABLA DE STAGING (BUFFER DE ALTA VELOCIDAD)
--- -- ------------------------------------------------------------------------------------------------------------------------------------------
    -- Diseñada para coincidir con las columnas crudas del dataset de DataCo/Kaggle y permitir una ingesta rápida sin transformaciones iniciales.
    IF OBJECT_ID('Staging.Kaggle_SupplyChain_Raw', 'U') IS NOT NULL 
        DROP TABLE Staging.Kaggle_SupplyChain_Raw;
    

    CREATE TABLE Staging.Kaggle_SupplyChain_Raw (
        StagingID INT IDENTITY(1,1) PRIMARY KEY,
        Type NVARCHAR(50),
        Days_for_shipping_real INT,
        Days_for_shipment_scheduled INT,
        Benefit_per_order DECIMAL(18,4), -- Caracterización de precisión para analítica financiera
        Sales_per_customer DECIMAL(18,4),
        Delivery_Status NVARCHAR(100),
        Late_delivery_risk INT,
        Category_ID INT,
        Category_Name NVARCHAR(200),
        Customer_City NVARCHAR(200),
        Customer_Country NVARCHAR(200),
        Order_Date_Raw NVARCHAR(100), -- Ingesta rápida como texto para limpiar en Fase 4
        Order_Region NVARCHAR(200),
        Order_Item_Total DECIMAL(18,4),
        -- Metadatos de control para el Log de Métricas
        Ingestion_Date DATETIME2 DEFAULT GETDATE(),
        DataSource NVARCHAR(100) DEFAULT 'Kaggle_DataCo'
    );
    
--- -- ------------------------------------------------------------------------------------------------------------------------------------------
--- -- 4. TABLA DE LOGS DE PERFORMANCE (ESTÁNDAR V7.0)
--- -- ------------------------------------------------------------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Staging].[Execution_Logs]') AND type in (N'U'))
    BEGIN
        CREATE TABLE Staging.Execution_Logs (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            PhaseName NVARCHAR(100),
            RowsAffected INT,
            ExecutionTime_MS INT,
            Status NVARCHAR(50),
            ErrorMsg NVARCHAR(MAX),
            CreatedAt DATETIME2 DEFAULT GETDATE()
        );
    END
    
--- -- ------------------------------------------------------------------------------------------------------------------------------------------
--- -- 5. MÉTRICAS DE VALIDACIÓN Y LOGGING
--- -- ------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '=====================================================';
    PRINT '✅ FASE 4.1: 🚀 Estructura DDL Creada con Éxito';
    PRINT '⏱️ Tiempo: ' + CAST(DATEDIFF(MS, @StartTime, SYSUTCDATETIME()) AS VARCHAR) + ' ms';
    PRINT '=====================================================';
END TRY 

BEGIN CATCH
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '❌ ERROR EN FASE 4.1: ' + ERROR_MESSAGE();
    PRINT '📍 Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
END CATCH

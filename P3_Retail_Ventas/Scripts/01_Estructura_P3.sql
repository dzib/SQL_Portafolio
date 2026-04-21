/* 
==================================================================================================================
PROYECTO: P3_Retail_Ventas -Simulacion de un punto de venta minorista (POS)
FASE: 3.1 (SQL) - Estructura de Datos Normalizada (DDL)
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Creación de esquemas y tablas finales.
    - Implementación de constraints de integridad.
    - Preparación para el proceso de limpieza desde Staging_Ventas.
===================================================================================================================
*/

USE P3_Retail_VentasDB;

DECLARE @StartTime DATETIME2 = SYSUTCDATETIME(); -- Para métricas de tiempo de ejecución.

BEGIN TRY
--- -- -------------------------------------------------------------------------------------------------------------
--- -- 1. ESQUEMAS (Organización lógica de tablas)
--- -- -------------------------------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Ventas')
        EXEC('CREATE SCHEMA Ventas'); -- Uso de EXEC para evitar erro de batch

    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Catalogos')
        EXEC('CREATE SCHEMA Catalogos');

--- -- -------------------------------------------------------------------------------------------------------------
--- -- 2. LIMPIEZA IDEMPOTENTE (Orden inverso por FKs)
--- -- -------------------------------------------------------------------------------------------------------------
    DROP TABLE IF EXISTS Ventas.DetalleVentas;
    DROP TABLE IF EXISTS Catalogos.Productos;

--- -- -------------------------------------------------------------------------------------------------------------
--- -- 3. CREACIÓN DE TABLAS (Con constraints de integridad y campos de auditoría)
--- -- -------------------------------------------------------------------------------------------------------------
    CREATE TABLE Catalogos.Productos (
        IdProducto INT IDENTITY(1,1) PRIMARY KEY,
        NombreProducto NVARCHAR(100) NOT NULL UNIQUE,
        PrecioBase DECIMAL(18,2)
    );

    CREATE TABLE Ventas.DetalleVentas (
        IdVenta INT PRIMARY KEY, -- No IDENTITY, se usa el IdVenta original de Staging para trazabilidad.
        IdProducto INT NOT NULL,
        FechaVenta DATETIME2 DEFAULT SYSUTCDATETIME(),
        Cantidad INT CHECK (Cantidad > 0),
        PrecioUnitario DECIMAL(18,2),
        TotalVenta DECIMAL(18,2),
        -- Campos de auditoría columna temporales para trazabilidad y debugging.
        Metadata_Cruda NVARCHAR(MAX), 
        CONSTRAINT FK_Ventas_Productos FOREIGN KEY (IdProducto) REFERENCES Catalogos.Productos(IdProducto)
    );
--- -- -------------------------------------------------------------------------------------------------------------
--- -- LOGICA DE METRICAS Y VALIDACIÓN
--- -- -------------------------------------------------------------------------------------------------------------
    PRINT '=====================================================';
    PRINT '✅ FASE 3.1: Estructura Creada con Éxito';
    PRINT '⏱️ Tiempo: ' + CAST(DATEDIFF(MS, @StartTime, SYSUTCDATETIME()) AS VARCHAR) + ' ms';
    PRINT '=====================================================';

END TRY
BEGIN CATCH
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '❌ ERROR EN FASE 3.1: ' + ERROR_MESSAGE();
    PRINT '📍 Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
END CATCH
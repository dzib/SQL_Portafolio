/* 
==================================================================================================
PROYECTO: P1_Inventario - Sistema de Gestión de Inventario
FASE: 1.1 (SQL) - Arquitectura de Datos e Integridad Referencial
AUTOR: Alberto Dzib
VERSIÓN: 2.0
DESCRIPCIÓN:
    - Implementación del esquema relacional bajo estándares SQL 2025.
    - Definición de la estructura de tablas e integridad referencial.
    - Segmentación por esquemas (Inventario, Operaciones).
    - Uso intencional de datos 'No Atómicos' (separados por '|') para demostrar
          capacidades de normalización y limpieza (Data Cleansing).
==================================================================================================
*/

-- -----------------------------------------------------------------------------------------------
-- 1. GESTIÓN DE BASE DE DATOS (IDEMPOTENCIA)
-- -----------------------------------------------------------------------------------------------
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'P1_Inventario')
BEGIN
    ALTER DATABASE P1_Inventario SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE P1_Inventario;
END;
GO

CREATE DATABASE P1_Inventario;
GO

USE P1_Inventario;
GO

-- -----------------------------------------------------------------------------------------------
-- 1.1 LIMPIEZA PREVIA (EN CASO DE REEJECUCIÓN)
-- Se eliminan tablas en orden inverso a las dependencias de FK
-- -----------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS Pagos;
DROP TABLE IF EXISTS DetallePedido;
DROP TABLE IF EXISTS Pedidos;
DROP TABLE IF EXISTS Ventas; 
DROP TABLE IF EXISTS Productos;
DROP TABLE IF EXISTS Categorias;
DROP TABLE IF EXISTS Proveedores;
DROP TABLE IF EXISTS Clientes;
GO

-- -----------------------------------------------------------------------------------------------
-- 2. CREACIÓN DE ESQUEMAS (ORGANIZACIÓN EMPRESARIAL)
-- Catálogos base (Nivel de normalización 1)
-- -----------------------------------------------------------------------------------------------
CREATE SCHEMA Inventario;
GO

CREATE SCHEMA Operaciones;
GO

DECLARE @StartTime DATETIME2 = SYSUTCDATETIME(); -- Para métricas de tiempo de ejecución.

BEGIN TRY
-- ----------------------------------------------------------------------------------------------
-- 3. TABLAS MAESTRAS (ESQUEMA INVENTARIO)
-- ----------------------------------------------------------------------------------------------
CREATE TABLE Inventario.Categorias (
    CategoriaID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL,  -- Formato: 'Nombre | Clasificación'
    Descripcion NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME()
);

CREATE TABLE Inventario.Proveedores (
    ProveedorID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL,  -- Formato: 'Razón Social | Tipo'
    Telefono NVARCHAR(50),
    Ciudad NVARCHAR(200),           -- Formato: 'Ciudad | Estado'
    IsActive BIT DEFAULT 1          -- 1 = Activo, 0 = Inactivo (Soft Delete)
);

CREATE TABLE Inventario.Productos (
    ProductoID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL,
    CategoriaID INT NOT NULL 
        CONSTRAINT FK_Prod_Cat FOREIGN KEY REFERENCES Inventario.Categorias(CategoriaID),
    ProveedorID INT NOT NULL 
        CONSTRAINT FK_Prod_Prov FOREIGN KEY REFERENCES Inventario.Proveedores(ProveedorID),
    PrecioVenta DECIMAL(12,2) NOT NULL 
        CONSTRAINT CHK_PrecioPos CHECK (PrecioVenta >= 0),
    StockActual INT NOT NULL 
        CONSTRAINT CHK_StockPos CHECK (StockActual >= 0),
    StockMinimo INT DEFAULT 5            -- Para alertas de Analytics
);

-- -----------------------------------------------------------------------------------------------
-- 4. TABLAS OPERATIVAS
-- Dependientes de las maestras (Nivel de normalización 2)
-- -----------------------------------------------------------------------------------------------
CREATE TABLE Operaciones.Clientes (
    ClienteID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) CONSTRAINT UQ_Cli_Email UNIQUE, -- Evitar duplicados
    Telefono NVARCHAR(20),
    Ciudad_Estado NVARCHAR(200),           -- Formato: 'Ciudad | Estado'
    FechaRegistro DATETIME2 DEFAULT SYSUTCDATETIME()
);

-- -----------------------------------------------------------------------------------------------
-- 5. TABLAS TRANSACCIONALES
-- Flujo operativo: pedidos, pagos y ventas de mostrador (Nivel de normalización 3)
-- -----------------------------------------------------------------------------------------------
-- Renombrado de Ventas para Claridad: Ventas en Mostrador (POS)
CREATE TABLE Operaciones.Ventas_Mostrador (
    VentaID INT PRIMARY KEY IDENTITY(1,1),
    ProductoID INT NOT NULL 
        CONSTRAINT FK_Vent_Prod FOREIGN KEY REFERENCES Inventario.Productos(ProductoID),
    Cantidad INT NOT NULL 
        CONSTRAINT CHK_CantPos CHECK (Cantidad > 0),
    PrecioAplicado DECIMAL(12,2) NOT NULL,
    FechaVenta DATETIME2 DEFAULT SYSUTCDATETIME(),
    Sucursal_Info NVARCHAR(200)          -- Formato: 'Sucursal | Ubicación'
);

CREATE TABLE Operaciones.Pedidos (
    PedidoID INT PRIMARY KEY IDENTITY(1,1),
    ClienteID INT NOT NULL 
        CONSTRAINT FK_Ped_Cli FOREIGN KEY REFERENCES Operaciones.Clientes(ClienteID),
    FechaPedido DATETIME2 DEFAULT SYSUTCDATETIME(),
    Estado_Info NVARCHAR(100)           -- Formato: 'Estado | Prioridad'
        CONSTRAINT CHK_FmtEstado CHECK (Estado_Info LIKE '%|%') -- Formato: 'Estado | Acción'
);

CREATE TABLE Operaciones.DetallePedido (
    DetalleID INT PRIMARY KEY IDENTITY(1,1),
    PedidoID INT NOT NULL 
        CONSTRAINT FK_Det_Ped FOREIGN KEY REFERENCES Operaciones.Pedidos(PedidoID) ON DELETE CASCADE,
    ProductoID INT NOT NULL 
        CONSTRAINT FK_Det_Prod FOREIGN KEY REFERENCES Inventario.Productos(ProductoID),
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    PrecioUnitario DECIMAL(12,2) NOT NULL -- Precio congelado al momento de la orden
);

CREATE TABLE Operaciones.Pagos (
    PagoID INT PRIMARY KEY IDENTITY(1,1),
    PedidoID INT NOT NULL 
        CONSTRAINT FK_Pag_Ped FOREIGN KEY REFERENCES Operaciones.Pedidos(PedidoID),
    Monto DECIMAL(12,2) NOT NULL,
    FechaPago DATETIME2 DEFAULT SYSUTCDATETIME(),
    Metodo_Info NVARCHAR(100)            -- Formato: 'Método | Institución'
);

-- -------------------------------------------------------------------------------------------------------------
-- 6. MÉTRICAS DE VALIDACIÓN Y LOGGING
-- -------------------------------------------------------------------------------------------------------------
    PRINT '=====================================================';
    PRINT '✅ FASE 1.1: 🚀 Arquitectura P1 Creada con Éxito';
    PRINT '⏱️ Tiempo de ejecución: ' + CAST(DATEDIFF(MS, @StartTime, SYSUTCDATETIME()) AS VARCHAR) + ' ms';
    PRINT '=====================================================';

END TRY
BEGIN CATCH
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '❌ Error en la ejecución: ' + ERROR_MESSAGE();
    PRINT '📍 Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';

    -- Si existe una transacción abierta en el futuro o en una actualización, aquí iría el ROLLBACK
END CATCH
GO
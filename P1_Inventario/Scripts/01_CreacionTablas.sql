/* 
================================================================================
PROYECTO: P1_Inventario -Sistema de Gestión de Inventario- | Fase 1: Arquitectura y Reglas de Negocio
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: Implementación del esquema relacional bajo estándares SQL 2025.
             Definición de la estructura de tablas e integridad referencial.
             Se diseñó con datos 'No Atómicos' (separados por '|') intencionales para demostrar 
             capacidades de normalización y limpieza (Data Cleansing).
================================================================================
*/

USE master;
GO

-- Se asegura que la base de datos sea creada desde cero
-- Forzar el cierre de todas las conexiones activas a la base de datos
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'P1_Inventario')
BEGIN
    ALTER DATABASE P1_Inventario SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE P1_Inventario;
END
GO

CREATE DATABASE P1_Inventario;
GO

USE P1_Inventario;
GO

-- -----------------------------------------------------------------------------
-- *Limpieza* (Idempotencia): Borrar tablas en orden inverso por las FK
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS Pagos;
DROP TABLE IF EXISTS DetallePedido;
DROP TABLE IF EXISTS Pedidos;
DROP TABLE IF EXISTS Ventas; 
DROP TABLE IF EXISTS Productos;
DROP TABLE IF EXISTS Categorias;
DROP TABLE IF EXISTS Proveedores;
DROP TABLE IF EXISTS Clientes;
GO

-- -----------------------------------------------------------------------------
-- 1. TABLAS MAESTRAS
--    CATÁLOGOS (Nivel de normalización 1), (Sin llaves foráneas externas).    
-- -----------------------------------------------------------------------------
CREATE TABLE Categorias (
    IdCategoria INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL, -- Formato esperado: 'Nombre | Clasificación' (Evitar categorias duplicadas)
    Descripcion NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME()
);

CREATE TABLE Proveedores (
    IdProveedor INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL, -- Formato esperado: 'Razón Social | Tipo'
    Telefono NVARCHAR(50),
    Ciudad NVARCHAR(200),          -- Formato esperado: 'Ciudad | Estado'
    IsActive BIT DEFAULT 1         -- Soft delete: 1 = Activo, 0 = Inactivo (borrado lógico)
);

-- -----------------------------------------------------------------------------
-- 2. TABLAS OPERATIVAS
--    (Nivel de normalización 2), (Dependencia de las maestras).
-- -----------------------------------------------------------------------------
CREATE TABLE Productos (
    IdProducto INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL,
    IdCategoria INT CONSTRAINT FK_Prod_Cat FOREIGN KEY REFERENCES Categorias(IdCategoria),   -- Relación con Categorías
    IdProveedor INT CONSTRAINT FK_Prod_Prov FOREIGN KEY REFERENCES Proveedores(IdProveedor), -- Relación con Proveedores
    Precio DECIMAL(12,2) NOT NULL CONSTRAINT CHK_PrecioPos CHECK (Precio >= 0),              -- Restricción de negocio evitar precios negativos
    Stock INT NOT NULL CONSTRAINT CHK_StockPos CHECK (Stock >= 0)                            -- Restricción de negocio evitar stock negativo
);

CREATE TABLE Clientes (
    IdCliente INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) CONSTRAINT UQ_Cli_Email UNIQUE,  -- El email debe ser único para evitar clientes duplicados
    Telefono NVARCHAR(20),
    Ciudad NVARCHAR(200),          -- Formato esperado: 'Ciudad | Estado'
    FechaRegistro DATETIME2 DEFAULT SYSUTCDATETIME()
);

-- -----------------------------------------------------------------------------
-- 3. TABLAS TRANSACCIONALES 
--    (Flujo operativos: ventas y pedidos)
-- -----------------------------------------------------------------------------
CREATE TABLE Pedidos (
    IdPedido INT PRIMARY KEY IDENTITY(1,1),
    IdCliente INT CONSTRAINT FK_Ped_Cli FOREIGN KEY REFERENCES Clientes(IdCliente),
    FechaPedido DATETIME2 DEFAULT SYSUTCDATETIME(),
    -- Ajustado para permitir el formato sucio 'Estado | Accion' que limpiaremos en el Script 04
    Estado NVARCHAR(100) CONSTRAINT CHK_FmtEstado CHECK (Estado LIKE '%|%')
);

CREATE TABLE DetallePedido (
    IdDetalle INT PRIMARY KEY IDENTITY(1,1),
    IdPedido INT CONSTRAINT FK_Det_Ped FOREIGN KEY REFERENCES Pedidos(IdPedido) ON DELETE CASCADE,
    IdProducto INT CONSTRAINT FK_Det_Prod FOREIGN KEY REFERENCES Productos(IdProducto),
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    PrecioUnitario DECIMAL(12,2) NOT NULL       -- Se guarda el precio al momento de la venta

);

CREATE TABLE Pagos (
    IdPago INT PRIMARY KEY IDENTITY(1,1),
    IdPedido INT CONSTRAINT FK_Pag_Ped FOREIGN KEY REFERENCES Pedidos(IdPedido),
    Monto DECIMAL(12,2) NOT NULL,
    FechaPago DATETIME2 DEFAULT SYSUTCDATETIME(),
    MetodoPago NVARCHAR(100)       -- Formato esperado: 'Método | Institución'
);

CREATE TABLE Ventas (
    IdVenta INT PRIMARY KEY IDENTITY(1,1),
    IdProducto INT CONSTRAINT FK_Vent_Prod FOREIGN KEY REFERENCES Productos(IdProducto),
    Cantidad INT NOT NULL,
    Sucursal NVARCHAR(200)         -- Formato esperado: 'Nombre Sucursal | Ubicación'
);
GO

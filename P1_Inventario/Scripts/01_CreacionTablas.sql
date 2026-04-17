/* 
================================================================================
PROYECTO: P1_Inventario - Sistema de Gestión de Inventario
FASE: 1 - Arquitectura y Reglas de Negocio
AUTOR: Alberto Dzib
VERSIÓN: 1.1
DESCRIPCIÓN:
    - Implementación del esquema relacional bajo estándares SQL 2025.
    - Definición de la estructura de tablas e integridad referencial.
    - Uso intencional de datos 'No Atómicos' (separados por '|') para demostrar
      capacidades de normalización y limpieza (Data Cleansing).
================================================================================
*/

-- -----------------------------------------------------------------------------
-- CREACIÓN DE BASE DE DATOS
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- LIMPIEZA PREVIA (Idempotencia)
-- Se eliminan tablas en orden inverso a las dependencias de FK
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
-- Catálogos base (Nivel de normalización 1)
-- -----------------------------------------------------------------------------
CREATE TABLE Categorias (
    IdCategoria INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL,  -- Ejemplo: 'Nombre | Clasificación'
    Descripcion NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME()
);

CREATE TABLE Proveedores (
    IdProveedor INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL,  -- Ejemplo: 'Razón Social | Tipo'
    Telefono NVARCHAR(50),
    Ciudad NVARCHAR(200),           -- Ejemplo: 'Ciudad | Estado'
    IsActive BIT DEFAULT 1          -- Soft delete: 1 = Activo, 0 = Inactivo
);

-- -----------------------------------------------------------------------------
-- 2. TABLAS OPERATIVAS
-- Dependientes de las maestras (Nivel de normalización 2)
-- -----------------------------------------------------------------------------
CREATE TABLE Productos (
    IdProducto INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL,
    IdCategoria INT NOT NULL 
        CONSTRAINT FK_Prod_Cat FOREIGN KEY REFERENCES Categorias(IdCategoria),
    IdProveedor INT NOT NULL 
        CONSTRAINT FK_Prod_Prov FOREIGN KEY REFERENCES Proveedores(IdProveedor),
    Precio DECIMAL(12,2) NOT NULL 
        CONSTRAINT CHK_PrecioPos CHECK (Precio >= 0),
    Stock INT NOT NULL 
        CONSTRAINT CHK_StockPos CHECK (Stock >= 0)
);

CREATE TABLE Clientes (
    IdCliente INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) CONSTRAINT UQ_Cli_Email UNIQUE, -- Evitar duplicados
    Telefono NVARCHAR(20),
    Ciudad NVARCHAR(200),           -- Ejemplo: 'Ciudad | Estado'
    FechaRegistro DATETIME2 DEFAULT SYSUTCDATETIME()
);

-- -----------------------------------------------------------------------------
-- 3. TABLAS TRANSACCIONALES
-- Flujo operativo: pedidos, pagos y ventas
-- -----------------------------------------------------------------------------
CREATE TABLE Pedidos (
    IdPedido INT PRIMARY KEY IDENTITY(1,1),
    IdCliente INT NOT NULL 
        CONSTRAINT FK_Ped_Cli FOREIGN KEY REFERENCES Clientes(IdCliente),
    FechaPedido DATETIME2 DEFAULT SYSUTCDATETIME(),
    Estado NVARCHAR(100) 
        CONSTRAINT CHK_FmtEstado CHECK (Estado LIKE '%|%') -- Ejemplo: 'Estado | Acción'
);

CREATE TABLE DetallePedido (
    IdDetalle INT PRIMARY KEY IDENTITY(1,1),
    IdPedido INT NOT NULL 
        CONSTRAINT FK_Det_Ped FOREIGN KEY REFERENCES Pedidos(IdPedido) ON DELETE CASCADE,
    IdProducto INT NOT NULL 
        CONSTRAINT FK_Det_Prod FOREIGN KEY REFERENCES Productos(IdProducto),
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    PrecioUnitario DECIMAL(12,2) NOT NULL -- Precio al momento de la venta
);

CREATE TABLE Pagos (
    IdPago INT PRIMARY KEY IDENTITY(1,1),
    IdPedido INT NOT NULL 
        CONSTRAINT FK_Pag_Ped FOREIGN KEY REFERENCES Pedidos(IdPedido),
    Monto DECIMAL(12,2) NOT NULL,
    FechaPago DATETIME2 DEFAULT SYSUTCDATETIME(),
    MetodoPago NVARCHAR(100) -- Ejemplo: 'Método | Institución'
);

CREATE TABLE Ventas (
    IdVenta INT PRIMARY KEY IDENTITY(1,1),
    IdProducto INT NOT NULL 
        CONSTRAINT FK_Vent_Prod FOREIGN KEY REFERENCES Productos(IdProducto),
    Cantidad INT NOT NULL,
    Fecha DATETIME2 DEFAULT SYSUTCDATETIME(),
    Sucursal NVARCHAR(200) -- Ejemplo: 'Sucursal | Ubicación'
);
GO


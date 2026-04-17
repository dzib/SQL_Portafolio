/* 
==================================================================================================
PROYECTO: P1_Inventario -Sistema de Gestión de Inventario- | Fase 4: Data Cleansing & ETL
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: Implementación de lógica de transformación para normalizar datos no atómicos.
             Se utilizan funciones de cadena (SUBSTRING, CHARINDEX, TRIM) para separar 
             atributos compuestos en columnas independientes, cumpliendo con la 1NF.
==================================================================================================
*/
USE P1_Inventario;
GO

PRINT '--- PASO 1: ELIMINANDO RESTRICCIONES DE FORMATO SUCIO ---';
-- Quitamos la regla que obliga a tener el '|' para poder dejar el texto limpio
IF EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CHK_FmtEstado')
    ALTER TABLE Pedidos DROP CONSTRAINT CHK_FmtEstado;
GO

PRINT '--- PASO 2: PREPARANDO NUEVA ESTRUCTURA ---';
-- Agregamos todas las columnas necesarias de una vez
IF NOT EXISTS (SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID('Categorias') AND name = 'Clasificacion')
    ALTER TABLE Categorias
    ADD Clasificacion NVARCHAR(100);

IF NOT EXISTS (SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID('Proveedores') AND name = 'Rubro')
    ALTER TABLE Proveedores
    ADD Rubro NVARCHAR(100), Estado NVARCHAR(100);

IF NOT EXISTS (SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID('Clientes') AND name = 'Estado')
    ALTER TABLE Clientes
    ADD Estado NVARCHAR(100);

IF NOT EXISTS (SELECT * FROM sys.columns
WHERE object_id = OBJECT_ID('Clientes') AND name = 'Segmento')
    ALTER TABLE Clientes
    ADD Segmento NVARCHAR(100);

IF NOT EXISTS (SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID('Pedidos') AND name = 'AccionPendiente')
    ALTER TABLE Pedidos
    ADD AccionPendiente NVARCHAR(100);

IF NOT EXISTS (SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID('Pagos') AND name = 'InstitucionFinanciera')
    ALTER TABLE Pagos
    ADD InstitucionFinanciera NVARCHAR(100);

IF NOT EXISTS (SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID('Ventas') AND name = 'UbicacionRegional')
    ALTER TABLE Ventas
    ADD UbicacionRegional NVARCHAR(100);
GO

PRINT '--- PASO 3: EJECUTANDO TRANSFORMACIÓN DE DATOS (ETL) ---';

-- ----------------------------------------------------------------------------------------------
-- 3.1 NORMALIZACIÓN DE CATEGORÍAS (Separar Nombre de Área/Clasificación)
-- ----------------------------------------------------------------------------------------------
PRINT 'Limpiando tabla: Categorias...';
UPDATE Categorias SET 
    Clasificacion = TRIM(SUBSTRING(Nombre, CHARINDEX('|', Nombre) + 1, LEN(Nombre))),
    Nombre = TRIM(LEFT(Nombre, CHARINDEX('|', Nombre) - 1))
WHERE Nombre LIKE '%|%';

-- ----------------------------------------------------------------------------------------------
-- 3.2. NORMALIZACIÓN DE PROVEEDORES CLIENTES (Separar Nombre de Empresa)
-- ----------------------------------------------------------------------------------------------
PRINT 'Limpiando tabla: Proveedores...';
UPDATE Proveedores SET 
    Rubro = TRIM(SUBSTRING(Nombre, CHARINDEX('|', Nombre) + 1, LEN(Nombre))),
    Nombre = TRIM(LEFT(Nombre, CHARINDEX('|', Nombre) - 1)),
    Estado = TRIM(SUBSTRING(Ciudad, CHARINDEX('|', Ciudad) + 1, LEN(Ciudad))),
    Ciudad = TRIM(LEFT(Ciudad, CHARINDEX('|', Ciudad) - 1))
WHERE Nombre LIKE '%|%' OR Ciudad LIKE '%|%';

-- ----------------------------------------------------------------------------------------------
-- 3.3. NORMALIZACIÓN CLIENTES (Separar Segmento/Nombre y Estado/Ciudad)
-- ----------------------------------------------------------------------------------------------
PRINT 'Limpiando tabla: Clientes...';
UPDATE Clientes SET 
    Segmento = CASE 
                WHEN Nombre LIKE '%|%' THEN TRIM(SUBSTRING(Nombre, CHARINDEX('|', Nombre) + 1, LEN(Nombre))) 
                ELSE Segmento 
               END,
    Nombre   = CASE 
                WHEN Nombre LIKE '%|%' THEN TRIM(LEFT(Nombre, CHARINDEX('|', Nombre) - 1)) 
                ELSE Nombre 
               END,
    Estado   = CASE 
                WHEN Ciudad LIKE '%|%' THEN TRIM(SUBSTRING(Ciudad, CHARINDEX('|', Ciudad) + 1, LEN(Ciudad))) 
                ELSE Estado 
               END,
    Ciudad   = CASE 
                WHEN Ciudad LIKE '%|%' THEN TRIM(LEFT(Ciudad, CHARINDEX('|', Ciudad) - 1)) 
                ELSE Ciudad 
               END
WHERE Nombre LIKE '%|%' OR Ciudad LIKE '%|%';

-- ----------------------------------------------------------------------------------------------
-- 3.4 NORMALIZACIÓN DE TRANSACCIONES (Pedidos, Pagos y Ventas)
-- ----------------------------------------------------------------------------------------------
PRINT 'Limpiando tabla: Pedidos...';
-- (Separar Estado de Pedido y Acción Pendiente)
UPDATE Pedidos SET 
    AccionPendiente = TRIM(SUBSTRING(Estado, CHARINDEX('|', Estado) + 1, LEN(Estado))),
    Estado = TRIM(LEFT(Estado, CHARINDEX('|', Estado) - 1))
WHERE Estado LIKE '%|%';

PRINT 'Limpiando tabla: Pagos y Ventas...';
-- (Separar Método de Institución Financiera)
UPDATE Pagos SET 
    InstitucionFinanciera = TRIM(SUBSTRING(MetodoPago, CHARINDEX('|', MetodoPago) + 1, LEN(MetodoPago))),
    MetodoPago = TRIM(LEFT(MetodoPago, CHARINDEX('|', MetodoPago) - 1))
WHERE MetodoPago LIKE '%|%';
GO

UPDATE Ventas
SET 
    UbicacionRegional = TRIM(SUBSTRING(Sucursal, CHARINDEX('|', Sucursal) + 1, LEN(Sucursal))),
    Sucursal = TRIM(LEFT(Sucursal, CHARINDEX('|', Sucursal) - 1))
WHERE Sucursal LIKE '%|%';
GO

-- ----------------------------------------------------------------------------------------------
-- 4. VALIDACIÓN FINAL DE CALIDAD (QA) (Verificar que no queden datos no atómicos)
-- ----------------------------------------------------------------------------------------------
PRINT 'Verificando resultados de la limpieza...';

-- Validación Proveedores
SELECT TOP 5 'Proveedores' AS Tabla, Nombre, Rubro, Ciudad, Estado
FROM Proveedores;

-- Validación Clientes
SELECT TOP 5 'Clientes' AS Tabla, Nombre, Ciudad, Estado
FROM Clientes;

-- Validación Pedidos
SELECT TOP 5 'Pedidos' AS Tabla, IdPedido, Estado, AccionPendiente
FROM Pedidos;

-- Validación Pagos
SELECT TOP 5 'Pagos' AS Tabla, IdPago, MetodoPago, InstitucionFinanciera
FROM Pagos;

-- Validació Ventas
SELECT TOP 5 'Ventas' AS Tabla, Sucursal, UbicacionRegional
FROM Ventas;

PRINT 'Proceso de limpieza completado exitosamente.';
GO

/* 
=================================================================================================================================================================
PROYECTO: P1_Inventario -Sistema de Gestión de Inventario.
FASE 4.1: Data Cleansing & ETL.
AUTOR: Alberto Dzib
VERSIÓN: 2.0 (Alineado a Esquemas Inventario/Operaciones & Columnas _Info)
DESCRIPCIÓN:
    - Implementación de lógica de transformación para normalizar datos no atómicos.
    - Se separan atributos compuestos (Nombre|Atributo) en columnas independientes,  para cumplir con la 1NF y asegurar la integridad en el Dashboard Excel.
=================================================================================================================================================================
*/
USE P1_Inventario;
GO

PRINT '--- PASO 1: ELIMINANDO RESTRICCIONES DE FORMATO SUCIO ---';
-- Eliminamos restricciones legacy que bloquean la limpieza de pipes
IF EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CHK_FmtEstado')
    ALTER TABLE Operaciones.Pedidos DROP CONSTRAINT CHK_FmtEstado;
GO

PRINT '--- PASO 2: PREPARANDO NUEVA ESTRUCTURA ---';
-- Agregamos todas las columnas necesarias de una vez
-- Inventario
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inventario.Categorias') AND name = 'Clasificacion')
    ALTER TABLE Inventario.Categorias ADD Clasificacion NVARCHAR(200);

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inventario.Proveedores') AND name = 'Rubro')
    ALTER TABLE Inventario.Proveedores ADD Rubro NVARCHAR(200), Estado NVARCHAR(200);

-- Operaciones
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Operaciones.Clientes') AND name = 'Segmento')
    ALTER TABLE Operaciones.Clientes ADD Segmento NVARCHAR(200), Estado NVARCHAR(200);

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Operaciones.Pedidos') AND name = 'AccionPendiente')
    ALTER TABLE Operaciones.Pedidos ADD AccionPendiente NVARCHAR(200)

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Operaciones.Pagos') AND name = 'InstitucionFinanciera')
    ALTER TABLE Operaciones.Pagos ADD InstitucionFinanciera NVARCHAR(200);

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Operaciones.Ventas_Mostrador') AND name = 'UbicacionRegional')
    ALTER TABLE Operaciones.Ventas_Mostrador ADD UbicacionRegional NVARCHAR(200);
GO

PRINT '--- PASO 3: EJECUTANDO TRANSFORMACIÓN DE DATOS (ETL) ---';

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.1 NORMALIZACIÓN DE CATEGORÍAS (Nombre -> Nombre | Clasificacion).
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT 'Limpiando tabla: Categorias...';
UPDATE Inventario.Categorias SET 
    Clasificacion = TRIM(SUBSTRING(Nombre, CHARINDEX('|', Nombre) + 1, LEN(Nombre))),
    Nombre = TRIM(LEFT(Nombre, CHARINDEX('|', Nombre) - 1))
WHERE Nombre LIKE '%|%';

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.2. NORMALIZACIÓN DE PROVEEDORES CLIENTES (Nombre -> Nombre | Rubro) y (Ciudad_Estado -> Ciudad | Estado).
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT 'Limpiando tabla: Proveedores...';
UPDATE Inventario.Proveedores SET 
    Rubro = TRIM(SUBSTRING(Nombre, CHARINDEX('|', Nombre) + 1, LEN(Nombre))),
    Nombre = TRIM(LEFT(Nombre, CHARINDEX('|', Nombre) - 1)),
    Estado = TRIM(SUBSTRING(Ciudad_Estado, CHARINDEX('|', Ciudad_Estado) + 1, LEN(Ciudad_Estado))),
    Ciudad_Estado = TRIM(LEFT(Ciudad_Estado, CHARINDEX('|', Ciudad_Estado) - 1))
WHERE Nombre LIKE '%|%' OR Ciudad_Estado LIKE '%|%'

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.3. NORMALIZACIÓN CLIENTES (Nombre -> Nombre | Segmento) y (Ciudad_Estado -> Ciudad | Estado).
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT 'Limpiando tabla: Clientes...';
UPDATE Operaciones.Clientes SET 
    Segmento = CASE WHEN Nombre LIKE '%|%' THEN TRIM(SUBSTRING(Nombre, CHARINDEX('|', Nombre) + 1, LEN(Nombre))) ELSE Segmento END,
    Nombre   = CASE WHEN Nombre LIKE '%|%' THEN TRIM(LEFT(Nombre, CHARINDEX('|', Nombre) - 1)) ELSE Nombre END,
    Estado   = CASE WHEN Ciudad_Estado LIKE '%|%' THEN TRIM(SUBSTRING(Ciudad_Estado, CHARINDEX('|', Ciudad_Estado) + 1, LEN(Ciudad_Estado))) ELSE Estado END,
    Ciudad_Estado = CASE WHEN Ciudad_Estado LIKE '%|%' THEN TRIM(LEFT(Ciudad_Estado, CHARINDEX('|', Ciudad_Estado) - 1)) ELSE Ciudad_Estado END
WHERE Nombre LIKE '%|%' OR Ciudad_Estado LIKE '%|%';

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.4 NORMALIZACIÓN DE TRANSACCIONES (Estado_Info -> Estado | AccionPendiente).
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT 'Limpiando tabla: Pedidos...';
-- (Separar Estado de Pedido y Acción Pendiente)
UPDATE Operaciones.Pedidos SET 
    AccionPendiente = TRIM(SUBSTRING(Estado_Info, CHARINDEX('|', Estado_Info) + 1, LEN(Estado_Info))),
    Estado_Info = TRIM(LEFT(Estado_Info, CHARINDEX('|', Estado_Info) - 1))
WHERE Estado_Info LIKE '%|%';
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.5 NORMALIZACIÓN PAGOS(Método de Pago -> Método | Institución Financiera).
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT 'Limpiando tabla: Pagos...';
-- (Separar Método de Institución Financiera)
UPDATE Operaciones.Pagos SET 
    InstitucionFinanciera = TRIM(SUBSTRING(Metodo_Info, CHARINDEX('|', Metodo_Info) + 1, LEN(Metodo_Info))),
    Metodo_Info = TRIM(LEFT(Metodo_Info, CHARINDEX('|', Metodo_Info) - 1))
WHERE Metodo_Info LIKE '%|%';

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.6 NORMALIZACIÓN VENTAS (Sucursal -> Sucursal | Ubicación Regional).
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT 'Limpiando tabla: Ventas...';
UPDATE Operaciones.Ventas_Mostrador SET 
    UbicacionRegional = TRIM(SUBSTRING(Sucursal_Info, CHARINDEX('|', Sucursal_Info) + 1, LEN(Sucursal_Info))),
    Sucursal_Info = TRIM(LEFT(Sucursal_Info, CHARINDEX('|', Sucursal_Info) - 1))
WHERE Sucursal_Info LIKE '%|%';

--Realizamos limpieza adicional para eliminar cualquier espacio o formato inconsistente que haya quedado después de la separación,
-- y estandarizamos a MAYÚSCULAS para facilitar la comparación y el análisis en el Dashboard Excel.
UPDATE Operaciones.Ventas_Mostrador
SET 
    Sucursal_Info = UPPER(TRIM(REPLACE(REPLACE(Sucursal_Info, 'Sucursal', ''), 'sucursal', ''))),
    UbicacionRegional = UPPER(TRIM(UbicacionRegional));

-- Al estar todo en MAYÚSCULAS, el REPLACE es infalible.
UPDATE Operaciones.Ventas_Mostrador
SET UbicacionRegional = 
    CASE 
        WHEN UbicacionRegional LIKE '%MERIDA%'    THEN 'MÉRIDA'
        WHEN UbicacionRegional LIKE '%CANCUN%'    THEN 'CANCÚN'
        WHEN UbicacionRegional LIKE '%QUERETARO%' THEN 'QUERÉTARO'
        WHEN UbicacionRegional LIKE '%MEXICO%'    THEN 'MÉXICO'
        ELSE UbicacionRegional 
    END;
GO

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PASO 3.7: NORMALIZACIÓN ROBUSTA  DE CONTENIDO (DATA GROOMING) (ETL) - Manejo de Casos Atípicos y Validación de Formato estándar global.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT '--- "Hard-coding" (DATA GROOMING) ---';
-- Proceso 1. UNIFICACIÓN DE PROVEEDORES Y CLIENTES (Estado y Ciudad)
UPDATE Inventario.Proveedores SET 
    Ciudad_Estado = UPPER(TRIM(Ciudad_Estado)),
    Estado = UPPER(TRIM(Estado));


UPDATE Operaciones.Clientes SET 
    Ciudad_Estado = UPPER(TRIM(Ciudad_Estado)),
    Estado = UPPER(TRIM(Estado));

-- Proceso 2. CORRECCIÓN UNIVERSAL DE ACENTOS (Aplica a todas las tablas críticas)
-- Usamos un enfoque de búsqueda y reemplazo masivo
UPDATE Inventario.Proveedores SET Estado = 'YUCATÁN' WHERE Estado LIKE '%YUCATAN%' OR Estado LIKE '%YUC%';
UPDATE Operaciones.Clientes SET Estado = 'YUCATÁN' WHERE Estado LIKE '%YUCATAN%' OR Estado LIKE '%YUC%';
UPDATE Operaciones.Clientes SET Estado = 'QUERÉTARO' WHERE Estado LIKE '%QRO%';
UPDATE Operaciones.Clientes SET Estado = 'PUEBLA' WHERE Estado IN ('PUE', 'PUEBLA');

-- Proceso 3. ESTANDARIZACIÓN DE FORMATO VISUAL (Capitalización)
-- Hace que 'MÉRIDA' pase a 'Mérida' para que se vea bien en el Excel

UPDATE Inventario.Proveedores SET 
    Estado = UPPER(LEFT(Estado, 1)) + LOWER(SUBSTRING(Estado, 2, 100)),
    Ciudad_Estado = UPPER(LEFT(Ciudad_Estado, 1)) + LOWER(SUBSTRING(Ciudad_Estado, 2, 100));

UPDATE Operaciones.Clientes SET 
    Estado = UPPER(LEFT(Estado, 1)) + LOWER(SUBSTRING(Estado, 2, 100)),
    Ciudad_Estado = UPPER(LEFT(Ciudad_Estado, 1)) + LOWER(SUBSTRING(Ciudad_Estado, 2, 100)),
    Nombre = UPPER(LEFT(Nombre, 1)) + LOWER(SUBSTRING(Nombre, 2, 100)); -- Limpieza extra para el nombre del cliente

-- Proceso 4. LIMPIEZA DE PEDIDOS Y PAGOS (Estandarizar Estados y Métodos)
UPDATE Operaciones.Pedidos SET 
    Estado_Info = UPPER(LEFT(Estado_Info, 1)) + LOWER(SUBSTRING(Estado_Info, 2, 100)),
    AccionPendiente = UPPER(LEFT(AccionPendiente, 1)) + LOWER(SUBSTRING(AccionPendiente, 2, 100));

UPDATE Operaciones.Pagos SET 
    Metodo_Info = UPPER(LEFT(Metodo_Info, 1)) + LOWER(SUBSTRING(Metodo_Info, 2, 100)),
    InstitucionFinanciera = UPPER(LEFT(InstitucionFinanciera, 1)) + LOWER(SUBSTRING(InstitucionFinanciera, 2, 100));
GO


-- Proceso 5. Estético: Para que en el Dashboard no se vea TODO EN MAYÚSCULAS, lo pasamos a "Formato Título" (Norte, Mérida) de forma segura.
UPDATE Operaciones.Ventas_Mostrador
SET 
    Sucursal_Info = UPPER(LEFT(Sucursal_Info, 1)) + LOWER(SUBSTRING(Sucursal_Info, 2, 100)),
    UbicacionRegional = UPPER(LEFT(UbicacionRegional, 1)) + LOWER(SUBSTRING(UbicacionRegional, 2, 100));
GO

--NEXT STEPS: Integrar tabla maestra de Dimensiones Geográficas para validar y corregir automáticamente cualquier ciudad o estado que no cumpla con el formato estándar,
--utilizando JOINs y UPDATEs basados en similitud de texto (fuzzy matching) para casos atípicos no cubiertos por las reglas hard-coded.

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4. VALIDACIÓN FINAL DE CALIDAD (QA) (Verificar que no queden datos no atómicos)
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT 'Verificando resultados de la limpieza...';

-- Validación Proveedores
SELECT TOP 3 'Proveedores' AS TBL, ProveedorID, Nombre, Rubro, Estado FROM Inventario.Proveedores;

-- Validación Clientes
SELECT TOP 3 'Clientes' AS TBL, ClienteID, Nombre, Segmento, Estado FROM Operaciones.Clientes;

-- Validación Pedidos
SELECT TOP 3 'Pedidos' AS TBL, PedidoID, Estado_Info, AccionPendiente FROM Operaciones.Pedidos;

-- Validación Pagos
SELECT TOP 5 'Pagos' AS TBL, PagoID, Metodo_Info, InstitucionFinanciera FROM Operaciones.Pagos;

-- Validación Ventas
SELECT TOP 5 'Ventas_Mostradores' AS TBL, VentaID, Sucursal_Info, UbicacionRegional FROM Operaciones.Ventas_Mostrador;

PRINT 'Proceso de limpieza completado exitosamente.';
GO

/* 
==============================================================================================================================
PROYECTO: P1_Inventario  - Sistema de Gestión de Inventario
FASE 2.1: Datos de Control - Seed Data (PascalCase & Schemas)
AUTOR: Alberto Dzib
VERSIÓN: 2.0
DESCRIPCIÓN: 
    - Inserción de registros iniciales de prueba para validación de integridad de procesos.
    - Se incluyen formatos compuestos para asegurar la funcionalidad de los procesos de limpieza (ETL) posteriores.
==============================================================================================================================
*/

USE P1_Inventario;
GO

DECLARE @StartTime DATETIME2 = SYSUTCDATETIME(); -- Para métricas de tiempo de ejecución.
-- ----------------------------------------------------------------------------------------------
-- 1. POBLADO DE TABLAS MAESTRAS (Esquema Inventario)
-- ----------------------------------------------------------------------------------------------
BEGIN
PRINT 'Insertando Categorías...';
INSERT INTO Inventario.Categorias (Nombre, Descripcion) VALUES 
('Laptops | Tecnología', 'Equipos portátiles de alto rendimiento'),
('Periféricos | Accesorios', 'Componentes externos y dispositivos de entrada'),
('Mobiliario | Oficina', 'Sillas y escritorios ergonómicos para trabajo');

PRINT 'Insertando Proveedores...';
INSERT INTO Inventario.Proveedores (Nombre, Telefono, Ciudad, IsActive) VALUES 
('Dell México | Mayorista', '555-0192', 'CDMX | Centro', 1),
('Tech Solutions | Distribuidor', '999-1234', 'Mérida | Yucatán', 1),
('Office Global | Mobiliario', '818-7654', 'Monterrey | Nuevo León', 1);

-- ----------------------------------------------------------------------------------------------
-- 2. POBLADO DE PRODUCTOS Y CLIENTES (Esquema Inventario y Operaciones)
-- ----------------------------------------------------------------------------------------------

PRINT 'Insertando Productos...';
INSERT INTO Inventario.Productos (Nombre, CategoriaID, ProveedorID, PrecioVenta, StockActual, StockMinimo) VALUES 
('Laptop Latitude 5420 | i5', 1, 1, 15800.00, 10, 5),
('Mouse MX Master 3 | Black', 2, 2, 2100.00, 3, 5), -- ⚠️ Forzado para activar alerta en Analytics (Stock < Minimo)
('Silla Ergonómica Pro | Gray', 3, 3, 5400.00, 8, 5);

PRINT 'Insertando Clientes...';
INSERT INTO Operaciones.Clientes (Nombre, Email, Telefono, Ciudad_Estado) VALUES 
('Juan Pérez | Particular', 'juan.perez@test.com', '9991112233', 'Mérida | Yucatán'),
('Empresa Alfa | Corporativo', 'compras@alfa.mx', '5554445566', 'CDMX | Centro');

-- ----------------------------------------------------------------------------------------------
-- 3. POBLADO DE TABLAS TRANSACCIONALES (Esquema Operaciones)
-- ----------------------------------------------------------------------------------------------

PRINT 'Insertando Pedidos y Pagos...';
INSERT INTO Operaciones.Pedidos (ClienteID, Estado_Info) VALUES (1, 'Pagado | Entregado');
DECLARE @Ped1 INT = SCOPE_IDENTITY(); 
-- Captura el ID del pedido recién insertado para usarlo en DetallePedido y Pagos

PRINT 'Insertando Detalles y Pagos del Pedido 1...';
INSERT INTO Operaciones.DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario) VALUES 
(@Ped1, 1, 1, 15800.00);

-- Pago de Pedido 1
INSERT INTO Operaciones.Pagos (PedidoID, Monto, Metodo_Info) VALUES
(@Ped1, 15800.00, 'Transferencia | BBVA');

-- Venta Directa (Mostrador)
INSERT INTO Operaciones.Ventas_Mostrador (ProductoID, Cantidad, PrecioAplicado, Sucursal_Info) VALUES 
(3, 1, 5400.00, 'Sucursal Norte | Mérida');
END

PRINT '=====================================================';
PRINT 'Fase 2.1: Datos iniciales cargados con éxito.';
PRINT '⏱️ Tiempo de ejecución: ' + CAST(DATEDIFF(MS, @StartTime, SYSUTCDATETIME()) AS VARCHAR) + ' ms';
PRINT '=====================================================';

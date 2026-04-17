/* 
==================================================================================================
PROYECTO: P1_Inventario -Sistema de Gestión de Inventario- | Fase 2: Datos de Control | Seed Data
                                                                     Validación de Integridad
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: Inserción de registros iniciales de prueba para validación de integridad de procesos.
             Se incluyen formatos compuestos para asegurar la funcionalidad
             de los procesos de limpieza (ETL) posteriores.
==================================================================================================
*/

USE P1_Inventario;
GO

-- ----------------------------------------------------------------------------------------------
-- 1. POBLADO DE TABLAS MAESTRAS (Catálogos)
-- ----------------------------------------------------------------------------------------------

PRINT 'Insertando Categorías...';
INSERT INTO Categorias (Nombre, Descripcion) VALUES 
('Laptops | Tecnología', 'Equipos portátiles de alto rendimiento'),
('Periféricos | Accesorios', 'Componentes externos y dispositivos de entrada'),
('Mobiliario | Oficina', 'Sillas y escritorios ergonómicos para trabajo');

PRINT 'Insertando Proveedores...';
INSERT INTO Proveedores (Nombre, Telefono, Ciudad, IsActive) VALUES 
('Dell México | Mayorista', '555-0192', 'CDMX | Centro', 1),
('Tech Solutions | Distribuidor', '999-1234', 'Mérida | Yucatán', 1),
('Office Global | Mobiliario', '818-7654', 'Monterrey | Nuevo León', 1);

-- ----------------------------------------------------------------------------------------------
-- 2. POBLADO DE TABLAS OPERATIVAS
-- ----------------------------------------------------------------------------------------------

PRINT 'Insertando Productos...';
INSERT INTO Productos (Nombre, IdCategoria, IdProveedor, Precio, Stock) VALUES 
('Laptop Latitude 5420 | i5', 1, 1, 15800.00, 10),
('Mouse MX Master 3 | Black', 2, 2, 2100.00, 25),
('Silla Ergonómica Pro | Gray', 3, 3, 5400.00, 8);

PRINT 'Insertando Clientes...';
INSERT INTO Clientes (Nombre, Email, Telefono, Ciudad) VALUES 
('Juan Pérez | Particular', 'juan.perez@test.com', '9991112233', 'Mérida | Yucatán'),
('Empresa Alfa | Corporativo', 'compras@alfa.mx', '5554445566', 'CDMX | Centro');

-- ----------------------------------------------------------------------------------------------
-- 3. POBLADO DE TABLAS TRANSACCIONALES
-- ----------------------------------------------------------------------------------------------

PRINT 'Insertando Pedidos...';
-- Nota: Cumplimiento de la restricción CHECK (Estado LIKE '%|%')
INSERT INTO Pedidos (IdCliente, Estado) VALUES
(1, 'Pagado | Entregado');

-- Guarda el ID del primer pedido con SCOPE_IDENTITY() para usarlo en detalles y pagos
DECLARE @IdPed1 INT = SCOPE_IDENTITY();

PRINT 'Insertando Detalles y Pagos del Pedido 1...';
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario) VALUES
(@IdPed1, 1, 1, 15800.00);

-- Pago de Pedido 1
INSERT INTO Pagos (IdPedido, Monto, MetodoPago) VALUES
(@IdPed1, 15800.00, 'Transferencia | BBVA');

-- Venta Directa (Mostrador)
INSERT INTO Ventas (IdProducto, Cantidad, Sucursal) VALUES 
(3, 1, 'Sucursal Norte | Mérida');

GO
PRINT 'Fase 2: Datos iniciales insertados con éxito.';

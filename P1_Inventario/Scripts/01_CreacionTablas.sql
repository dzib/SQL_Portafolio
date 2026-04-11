CREATE TABLE InventarioDB.dbo.Productos (
	IdProducto INT PRIMARY KEY IDENTITY,
	Nombre NVARCHAR(100) NOT NULL,
	Precio DECIMAL(10,2) NOT NULL,
	Stock INT NOT NULL
);

CREATE TABLE InventarioDB.dbo.Proveedores (
	IdProveedor INT PRIMARY KEY IDENTITY,
	Nombre NVARCHAR(100) NOT NULL,
	Telefono NVARCHAR(20)
);

CREATE TABLE InventarioDB.dbo.Ventas (
	IdVenta INT PRIMARY KEY IDENTITY,
	IdProducto INT FOREIGN KEY REFERENCES InventarioDB.dbo.Productos(IdProducto),
	Cantidad INT NOT NULL,
	Fecha DATETIME DEFAULT GETDATE()
);

CREATE TABLE InventarioDB.dbo.Categorias (
    IdCategoria INT PRIMARY KEY IDENTITY,
    Nombre NVARCHAR(100) NOT NULL
);

CREATE TABLE InventarioDB.dbo.Clientes (
    IdCliente INT PRIMARY KEY IDENTITY,
    Nombre NVARCHAR(100),
    Email NVARCHAR(100),
    Telefono NVARCHAR(20)
);

CREATE TABLE InventarioDB.dbo.Pedidos (
    IdPedido INT PRIMARY KEY IDENTITY,
    IdCliente INT FOREIGN KEY REFERENCES InventarioDB.dbo.Clientes(IdCliente),
    FechaPedido DATETIME DEFAULT GETDATE()
);

CREATE TABLE InventarioDB.dbo.DetallePedido (
    IdDetalle INT PRIMARY KEY IDENTITY,
    IdPedido INT FOREIGN KEY REFERENCES InventarioDB.dbo.Pedidos(IdPedido),
    IdProducto INT FOREIGN KEY REFERENCES InventarioDB.dbo.Productos(IdProducto),
    Cantidad INT NOT NULL
);

CREATE TABLE InventarioDB.dbo.Pagos (
    IdPago INT PRIMARY KEY IDENTITY,
    IdPedido INT FOREIGN KEY REFERENCES InventarioDB.dbo.Pedidos(IdPedido),
    Monto DECIMAL(10,2),
    FechaPago DATETIME DEFAULT GETDATE(),
    Metodo NVARCHAR(50)
);

-- Productos ( nombre, precio, stock, categoría, fecha creación)
-- Agregar columnas de categoría y fecha creación a la tabla Productos
ALTER TABLE InventarioDB.dbo.Productos
ADD Categoria NVARCHAR(100),
    FechaCreacion DATETIME;

-- Proveedores (nombre, teléfono, ciudad)
-- Agregar columna de ciudad a la tabla Proveedores
ALTER TABLE InventarioDB.dbo.Proveedores
ADD Ciudad NVARCHAR(100);

-- Categorías (nombre, descripción)
-- Agregar columna de descripción a la tabla Categorias
ALTER TABLE InventarioDB.dbo.Categorias
ADD Descripcion NVARCHAR(255);

-- Clientes (nombre, email, teléfono, ciudad)
-- Agregar columna de ciudad a la tabla Clientes
ALTER TABLE InventarioDB.dbo.Clientes
ADD Ciudad NVARCHAR(100);

-- Pedidos (cliente, fecha, estado)
-- Agregar columna de estado a la tabla Pedidos
ALTER TABLE InventarioDB.dbo.Pedidos
ADD Estado NVARCHAR(50);

-- DetallePedido (pedido, producto, cantidad, precio unitario)
-- Agregar columna de precio unitario a la tabla DetallePedido
ALTER TABLE InventarioDB.dbo.DetallePedido
ADD PrecioUnitario DECIMAL(10,2);

-- Ventas (producto, cantidad, fecha, sucursal)
-- Agregar columna de sucursal a la tabla Ventas
ALTER TABLE InventarioDB.dbo.Ventas
ADD Sucursal NVARCHAR(100);
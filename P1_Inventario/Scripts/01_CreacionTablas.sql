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
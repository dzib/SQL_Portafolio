-- Productos ( nombre, precio, stock, categoría, fecha creación)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO FinanzasDB.dbo.Productos (Nombre, Precio, Stock, Categoria, FechaCreacion)
    VALUES ('Producto_' + CAST(@i AS NVARCHAR(10)) + ' | Modelo_' + CAST((@i % 20)+1 AS NVARCHAR(10)),
            ROUND(RAND()*8000+200,2), -- precios entre 200 y 8200
            CAST(RAND()*200 AS INT),  -- stock entre 0 y 200
            'Categoria_' + CAST((@i % 50)+1 AS NVARCHAR(10)) + ' | Grupo_' + CAST((@i % 5)+1 AS NVARCHAR(10)),
            DATEADD(DAY, -@i, GETDATE())); -- fechas variadas
    SET @i += 1;
END;

-- Proveedores (nombre, teléfono, ciudad)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO Proveedores (Nombre, Telefono, Ciudad)
    VALUES ('Proveedor_' + CAST(@i AS NVARCHAR(10)) + ' | Tipo_' + CAST((@i % 10)+1 AS NVARCHAR(10)),
            '999' + RIGHT('000000' + CAST(@i AS NVARCHAR(6)),6),
            CASE WHEN @i % 3 = 0 THEN 'Mérida | Yucatán'
                 WHEN @i % 3 = 1 THEN 'Cancún | Quintana Roo'
                 ELSE 'Campeche | Campeche' END);
    SET @i += 1;
END;

-- Categorías (nombre, descripción)
DECLARE @i INT = 1;
WHILE @i <= 100
BEGIN
    INSERT INTO Categorias (Nombre, Descripcion)
    VALUES ('Categoria_' + CAST(@i AS NVARCHAR(10)) + ' | Área_' + CAST((@i % 10)+1 AS NVARCHAR(10)),
            'Descripción | Detalle de la categoría ' + CAST(@i AS NVARCHAR(10)));
    SET @i += 1;
END;

-- Clientes (nombre, email, teléfono, ciudad)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO Clientes (Nombre, Email, Telefono, Ciudad)
    VALUES ('Cliente_' + CAST(@i AS NVARCHAR(10)) + ' | Segmento_' + CAST((@i % 5)+1 AS NVARCHAR(10)),
            'cliente' + CAST(@i AS NVARCHAR(10)) + '|contacto@example.com',
            '999' + RIGHT('000000' + CAST(@i AS NVARCHAR(6)),6),
            CASE WHEN @i % 4 = 0 THEN 'Mérida | Yucatán'
                 WHEN @i % 4 = 1 THEN 'Cancún | Quintana Roo'
                 WHEN @i % 4 = 2 THEN 'Campeche | Campeche'
                 ELSE 'Villahermosa | Tabasco' END);
    SET @i += 1;
END;

-- Pedidos (cliente, fecha, estado)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO Pedidos (IdCliente, FechaPedido, Estado)
    VALUES ((@i % 500) + 1,
            DATEADD(DAY, -@i, GETDATE()),
            CASE WHEN @i % 2 = 0 THEN 'Completado | Facturado' ELSE 'Pendiente | En proceso' END);
    SET @i += 1;
END;

-- DetallePedido (pedido, producto, cantidad, precio unitario)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
    VALUES ((@i % 500) + 1,
            (@i % 500) + 1,
            CAST(RAND()*10 AS INT)+1,
            ROUND(RAND()*5000+100,2));
    SET @i += 1;
END;

-- Pagos (pedido, monto, método, fecha)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO Pagos (IdPedido, Monto, Metodo, FechaPago)
    VALUES ((@i % 500) + 1,
            ROUND(RAND()*10000+500,2),
            CASE WHEN @i % 3 = 0 THEN 'Tarjeta | Crédito'
                 WHEN @i % 3 = 1 THEN 'Efectivo | Caja'
                 ELSE 'Transferencia | Banco' END,
            DATEADD(DAY, -@i, GETDATE()));
    SET @i += 1;
END;

-- Ventas (producto, cantidad, fecha, sucursal)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO Ventas (IdProducto, Cantidad, Fecha, Sucursal)
    VALUES ((@i % 500) + 1,
            CAST(RAND()*20 AS INT)+1,
            DATEADD(DAY, -@i, GETDATE()),
            CASE WHEN @i % 3 = 0 THEN 'Sucursal Norte | Mérida'
                 WHEN @i % 3 = 1 THEN 'Sucursal Centro | Cancún'
                 ELSE 'Sucursal Sur | Campeche' END);
    SET @i += 1;
END;
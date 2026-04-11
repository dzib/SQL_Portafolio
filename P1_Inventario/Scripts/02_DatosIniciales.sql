---Insertar 15 productos
INSERT INTO InventarioDB.dbo.Productos (Nombre, Precio, Stock)
VALUES 
('Laptop Dell Inspiron', 14500, 18),
('Laptop HP Pavilion', 15200, 22),
('Mouse Logitech', 250, 60),
('Mouse Inalámbrico Genius', 180, 45),
('Teclado Mecánico Redragon', 950, 35),
('Monitor Samsung 27"', 4200, 12),
('Monitor LG 24"', 3100, 20),
('Impresora Epson EcoTank', 5200, 8),
('Tablet Samsung Galaxy Tab', 7800, 25),
('Smartphone Xiaomi Redmi', 6200, 40),
('Auriculares Sony WH-1000XM4', 5800, 10),
('Disco Duro Seagate 1TB', 2100, 30),
('Memoria USB Kingston 128GB', 450, 80),
('Cámara Web Logitech C920', 1400, 15),
('Silla Ergonómica OfficePro', 4800, 10);

-- Insertar 8 proveedores
INSERT INTO InventarioDB.dbo.Proveedores (Nombre, Telefono)
VALUES 
('Proveedor A - Computo', '9991234567'),
('Proveedor B - Accesorios', '9997654321'),
('Proveedor C - Muebles', '9991112233'),
('Proveedor D - Electrónica', '9994445566'),
('Proveedor E - Software', '9997778899'),
('Proveedor F - Periféricos', '9993332211'),
('Proveedor G - Almacenamiento', '9995556677'),
('Proveedor H - Telecomunicaciones', '9998881122');
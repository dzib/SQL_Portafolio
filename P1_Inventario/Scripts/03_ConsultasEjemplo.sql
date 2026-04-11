SELECT Nombre, Stock
FROM InventarioDB.dbo.Productos
WHERE Stock > 150;

SELECT P.Nombre, SUM(V.Cantidad) AS TotalVendido
FROM InventarioDB.dbo.Ventas V
JOIN InventarioDB.dbo.Productos P ON V.IdProducto = P.IdProducto
GROUP BY P.Nombre
ORDER BY TotalVendido DESC;
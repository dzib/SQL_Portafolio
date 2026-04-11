SELECT Nombre, Stock
FROM FinanzasDB.dbo.Productos
WHERE Stock > 10;

SELECT P.Nombre, SUM(V.Cantidad) AS TotalVendido
FROM FinanzasDB.dbo.Ventas V
JOIN FinanzasDB.dbo.Productos P ON V.IdProducto = P.IdProducto
GROUP BY P.Nombre;
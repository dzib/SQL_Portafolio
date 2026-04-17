/* 
==================================================================================================
PROYECTO: P1_Inventario | Fase 5: Business Intelligence (BI) & Consultas Analíticas
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: Creación de Vistas y KPIs para la toma de decisiones. 
             Este script consolida las ventas y analiza el rendimiento del inventario.
==================================================================================================
*/

USE P1_Inventario;
GO

----------------------------------------------------------------------------------------------------------------
PRINT '--- PASO 1: CREANDO VISTA CONSOLIDADA DE INGRESOS ---';
-- Esta vista une Pedidos Online y Ventas de Mostrador en un solo reporte lógico.
----------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('vw_ReporteGlobalVentas', 'V') IS NOT NULL DROP VIEW vw_ReporteGlobalVentas;
GO

CREATE VIEW vw_ReporteGlobalVentas AS
SELECT 
    'E-Commerce' AS Canal,
    p.FechaPedido AS Fecha,
    c.Nombre AS Entidad,
    cat.Nombre AS Categoria,
    pr.Nombre AS Producto,
    dp.Cantidad,
    dp.PrecioUnitario,
    (dp.Cantidad * dp.PrecioUnitario) AS Subtotal,
    p.Estado AS Estatus_Venta --En este paso se usa el estado ya limpio por el Script 04
FROM Pedidos p
JOIN Clientes c ON p.IdCliente = c.IdCliente
JOIN DetallePedido dp ON p.IdPedido = dp.IdPedido
JOIN Productos pr ON dp.IdProducto = pr.IdProducto
JOIN Categorias cat ON pr.IdCategoria = cat.IdCategoria

UNION ALL

SELECT 
    'Punto de Venta' AS Canal,
    v.Fecha AS Fecha,
    v.Sucursal AS Entidad,
    cat.Nombre AS Categoria,
    pr.Nombre AS Producto,
    v.Cantidad,
    pr.Precio AS PrecioUnitario,
    (v.Cantidad * pr.Precio) AS Subtotal,
    'Completado' AS Estatus_Venta
FROM Ventas v
JOIN Productos pr ON v.IdProducto = pr.IdProducto
JOIN Categorias cat ON pr.IdCategoria = cat.IdCategoria;
GO

----------------------------------------------------------------------------------------------------------------
PRINT '--- PASO 2: GENERANDO KPIS EJECUTIVOS ---';
-- KPI 1: Los 5 productos más vendidos (Top Sellers)
----------------------------------------------------------------------------------------------------------------

SELECT TOP 5 
    Producto, 
    SUM(Cantidad) AS Unidades_Vendidas,
    FORMAT(SUM(Subtotal), 'C', 'es-MX') AS Ingreso_Total
FROM vw_ReporteGlobalVentas
WHERE Estatus_Venta NOT IN ('Cancelado', 'Revisar') -- Solo ventas efectivas
GROUP BY Producto
ORDER BY SUM(Subtotal) DESC;

----------------------------------------------------------------------------------------------------------------
-- KPI 2: Rendimiento por Categoría y Canal
----------------------------------------------------------------------------------------------------------------

SELECT 
    Categoria, 
    Canal,
    COUNT(*) AS Numero_Transacciones,
    FORMAT(SUM(Subtotal), 'C', 'es-MX') AS Total_Ventas
FROM vw_ReporteGlobalVentas
GROUP BY Categoria, Canal
ORDER BY Categoria, Total_Ventas DESC;

----------------------------------------------------------------------------------------------------------------
-- KPI 3: Análisis de Proveedores y Stock Crítico (BI Preventivo)
----------------------------------------------------------------------------------------------------------------

SELECT 
    prov.Nombre AS Proveedor,
    prov.Rubro,
    COUNT(prod.IdProducto) AS Total_Productos,
    SUM(prod.Stock) AS Existencias_Totales,
    CASE 
        WHEN SUM(prod.Stock) < 50 THEN 'REABASTECIMIENTO URGENTE'
        WHEN SUM(prod.Stock) BETWEEN 50 AND 150 THEN 'STOCK SALUDABLE'
        ELSE 'SOBRESTOCK'
    END AS Alerta_Logistica
FROM Proveedores prov
LEFT JOIN Productos prod ON prov.IdProveedor = prod.IdProveedor
GROUP BY prov.Nombre, prov.Rubro
ORDER BY Existencias_Totales ASC;
GO

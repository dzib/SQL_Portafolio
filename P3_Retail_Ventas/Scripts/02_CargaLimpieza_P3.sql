/* 
======================================================================================================================================================
PROYECTO: P3_Retail_Ventas -Simulacion de un punto de venta minorista (POS)
FASE: 3.2 (SQL) - Proceso ETL Masivo y Normalización
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Poblado de Catalogos.Productos (Idempotente).
    - Carga masiva a Ventas.DetalleVentas con cruce de IDs.
    - Uso de transacciones para asegurar la integridad de los 50k registros.
======================================================================================================================================================
*/
-- Aseguramos que la tabla de destino esté limpia para evitar duplicados en ejecuciones repetidas.
TRUNCATE TABLE Ventas.DetalleVentas;
DELETE FROM Catalogos.Productos;
DBCC CHECKIDENT ('Catalogos.Productos', RESEED, 0);

USE P3_Retail_VentasDB;
GO

DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();

BEGIN TRY
    BEGIN TRANSACTION;

--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
--- -- 1. POBLAR CATÁLOGO DE PRODUCTOS (Se extrae nombres únicos de Staging)
--- -- Aplicamos un JOIN o NOT EXISTS para asegurar que sea idempotente.
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
    INSERT INTO Catalogos.Productos (NombreProducto, PrecioBase)
    SELECT DISTINCT Producto, MAX(Precio_Unitario) -- Tomamos el precio máximo como referencia, aunque en un caso real se podría usar otro criterio.
    FROM dbo.Staging_Ventas S
    WHERE NOT EXISTS (
        SELECT 1 FROM Catalogos.Productos P 
        WHERE P.NombreProducto = S.Producto
    )
    GROUP BY Producto;

    PRINT '====================================================================';
    PRINT '         📦 Catálogo de productos actualizado (Unique enforced).';
    PRINT '====================================================================';

--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
--- -- 2. CARGA MASIVA A TABLA FINAL (Transformación de Nombres a IDs)
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
    INSERT INTO Ventas.DetalleVentas (
        IdVenta, IdProducto, FechaVenta, Cantidad, PrecioUnitario, TotalVenta, Metadata_Cruda
    )
    SELECT 
        S.ID_Venta,
        P.IdProducto,
        S.Fecha,
        S.Cantidad,
        S.Precio_Unitario,
        S.Total,
        S.Metadata_Local -- La metadata "sucia" que  se limpiara en la Fase 3.3
    FROM dbo.Staging_Ventas S
    JOIN Catalogos.Productos P ON S.Producto = P.NombreProducto;

    DECLARE @Filas INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
--- -- 3. MÉTRICAS DE ÉXITO
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '=====================================================';
    PRINT '✅ FASE 3.2: Ingesta y Cruce Completado';
    PRINT '👥 Registros Procesados: ' + FORMAT(@Filas, 'N0');
    PRINT '⏱️  Tiempo de Proceso:   ' + CAST(DATEDIFF(MS, @StartTime, SYSUTCDATETIME()) AS VARCHAR) + ' ms';
    PRINT '=====================================================';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT '=====================================================';
    PRINT '❌ ERROR EN FASE 3.2: ' + ERROR_MESSAGE();
    PRINT '📍 Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '=====================================================';
END CATCH

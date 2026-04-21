/* 
======================================================================================================================================================
PROYECTO: P3_Retail_Ventas
FASE: 3.3 (SQL) - Refactorización de Tabla y Limpieza ETL
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Transformación de la columna Metadata_Cruda en columnas reales (MetodoPago, Ciudad, Vendedor).
    - Uso de CTE para limpieza masiva de 50,000 registros.
    - Transacción para asegurar la integridad de los datos durante la actualización.
======================================================================================================================================================
*/

USE P3_Retail_VentasDB;
GO

DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();

BEGIN TRY
    BEGIN TRANSACTION;

--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
--- -- 1. AÑADIR COLUMNAS REALES (Materialización de Datos)
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
    -- Verificamos si las columnas ya existen para evitar errores en ejecuciones repetidas.
    -- FASE A: REFACTORIZACIÓN (Añadir columnas)
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Ventas.DetalleVentas') AND name = 'MetodoPago')
    BEGIN
        ALTER TABLE Ventas.DetalleVentas ADD 
            MetodoPago NVARCHAR(50),
            Ciudad NVARCHAR(100),
            Vendedor NVARCHAR(100);
        PRINT '========================================================';
        PRINT '     ✅ Fase A: Columnas añadidas a Ventas.DetalleVentas.';
        PRINT '========================================================';
    END
END TRY

BEGIN CATCH
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '❌ Error en Fase A: ' + ERROR_MESSAGE();
    PRINT '📍 Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
END CATCH
GO -- Separamos las fases para claridad, manejo de errores específico y obligamos a aplicar los cambios antes de la siguiente fase.

--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
--- -- 2. LIMPIEZA MASIVA CON CTE (50,000 registros)
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime DATETIME2 = SYSUTCDATETIME(); -- Reiniciamos el crónometro para medir solo la fase de limpieza y transformación.
    -- Formato de Metadata_Cruda: "MetodoPago|Ciudad|Vendedor".
BEGIN TRY -- Fase B: Limpieza y transformación de datos usando CTE para eficiencia en grandes volúmenes.
    ;WITH CTE_Limpieza AS (
        SELECT 
            IdVenta,
            Metadata_Cruda,
            CHARINDEX('|', Metadata_Cruda) AS P1,
            CHARINDEX('|', Metadata_Cruda, CHARINDEX('|', Metadata_Cruda) + 1) AS P2
        FROM Ventas.DetalleVentas 
    )
    UPDATE V
    SET 
        V.MetodoPago = SUBSTRING(C.Metadata_Cruda, 1, C.P1 - 1),
        V.Ciudad = SUBSTRING(C.Metadata_Cruda, C.P1 + 1, C.P2 - C.P1 - 1),
        V.Vendedor = SUBSTRING(C.Metadata_Cruda, C.P2 + 1, LEN(C.Metadata_Cruda))
    FROM Ventas.DetalleVentas V
    JOIN CTE_Limpieza C ON V.IdVenta = C.IdVenta;

    DECLARE @Filas INT = @@ROWCOUNT;

--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
--- -- 3. PASO FINAL: ELIMINAR COLUMNA CRUDA (Para ahorrar espacio y normalizar)
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
    ALTER TABLE Ventas.DetalleVentas DROP COLUMN Metadata_Cruda;

    COMMIT TRANSACTION;

--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
--- -- 4. MÉTRICAS DE ÉXITO
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '=====================================================';
    PRINT '       ✅ FASE 3.3: ETL Y REFACTORIZACIÓN FINAL';
    PRINT '=====================================================';
    PRINT '👥 Filas Actualizadas: ' + FORMAT(@Filas, 'N0');
    PRINT '⏱️  Tiempo de Proceso:  ' + CAST(DATEDIFF(MS, @StartTime, SYSUTCDATETIME()) AS VARCHAR) + ' ms';
    PRINT '=====================================================';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '❌ ERROR EN FASE 3.3: ' + ERROR_MESSAGE();
    PRINT '📍 Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
END CATCH
GO

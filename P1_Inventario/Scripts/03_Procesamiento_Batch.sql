/* 
=================================================================================================================================
PROYECTO: P1_Inventario -Sistema de Gestión de Inventario-
Fase 3.1: Carga Masiva (Stress Testing & Legacy Data Simulation)
AUTOR: Alberto Dzib
VERSIÓN: 2.0
DESCRIPCIÓN: 
    - Poblado masivo mediante bucles T-SQL para simular volumen transaccional.
    - Uso de CHOOSE y RAND para generar datos no atómicos ("Legacy Style").
    - Implementación de transacciones para garantizar atomicidad y manejo de errores.
    - Inclusión de métricas de ejecución para análisis de performance.
    - Se respetan las relaciones de integridad referencial y se mantiene la segmentación por
    - Respeto a esquemas Inventario y Operaciones.
================================================================================================================================
*/
USE P1_Inventario;
GO

SET NOCOUNT ON;
DECLARE @Inicio DATETIME2 = SYSUTCDATETIME(); -- Métricas de tiempo de ejecución.

BEGIN TRY
    BEGIN TRANSACTION;
----- -----------------------------------------------------------------------------------------------------------------------------
------ 1. POBLADO DE MAESTROS (Esquema Inventario)
------ -----------------------------------------------------------------------------------------------------------------------------
    PRINT '--- PASO 1: POBLADO DE MAESTROS ---';
    DECLARE @i INT = 1;
    WHILE @i <= 50
    BEGIN
        -- 1. PROTECCIÓN CONTRA ERROR DE NULOS: Usamos variables con valores por defecto
        DECLARE @CatBase NVARCHAR(50) = ISNULL(CHOOSE(FLOOR(RAND()*3)+1, 'Hardware', 'Software', 'Servicios'), 'General');
        DECLARE @ProvBase NVARCHAR(50) = ISNULL(CHOOSE(FLOOR(RAND()*2)+1, 'Inc.', 'S.A.'), 'Corp');
        DECLARE @CiudadBase NVARCHAR(50) = ISNULL(CHOOSE(FLOOR(RAND()*3)+1, 'Mérida | YUC', 'Cancún | QROO', 'Monterrey | NL'), 'CDMX | Centro');

        -- 2. INSERCIÓN SEGURA (No NULLs en el Nombre)
        INSERT INTO Inventario.Categorias (Nombre, Descripcion)
        VALUES (@CatBase + ' | ' + CAST(@i AS VARCHAR(5)), 'Descripción del grupo ' + CAST(@i AS VARCHAR(5)));

        INSERT INTO Inventario.Proveedores (Nombre, Telefono, Ciudad_Estado, IsActive)
        VALUES ('Proveedor ' + CAST(@i AS VARCHAR(5)) + ' | ' + @ProvBase, 
                '999-' + CAST(FLOOR(RAND()*9000)+1000 AS VARCHAR(4)), 
                @CiudadBase, 1);
                
        SET @i += 1;
    END

------ ---------------------------------------------------------------------------------------------------------------------------
----- 2. POBLADO DE PRODUCTOS Y CLIENTES (Asociando a maestros creados)
------ ---------------------------------------------------------------------------------------------------------------------------
    PRINT '--- PASO 2: POBLADO DE PRODUCTOS Y CLIENTES ---';
    SET @i = 1;
    WHILE @i <= 100
    BEGIN
        -- Clientes con segmentos y ciudades no atómicas para simular datos legacy.
        -- Para evitar errores de FK, seleccionamos IDs existentes de Categorias y Proveedores        
        DECLARE @SegmentoBase NVARCHAR(50) = ISNULL(CHOOSE(FLOOR(RAND()*3)+1, 'Corporativo', 'Particular', 'VIP'), 'General');
        DECLARE @CiudadBaseCliente NVARCHAR(50) = ISNULL(CHOOSE(FLOOR(RAND()*4)+1, 'Querétaro | QRO', 'Mérida | YUC', 'Puebla | PUE', 'Toluca | MEX'), 'CDMX | Centro');

        INSERT INTO Operaciones.Clientes (Nombre, Email, Telefono, Ciudad_Estado)
        VALUES ('Cliente_ID_' + CAST(@i AS VARCHAR(10)) + ' | ' + @SegmentoBase,  
                'user' + CAST(@i AS VARCHAR(10)) + '@demo.com', 
                '555-' + RIGHT('0000' + CAST(@i AS VARCHAR(10)), 4), 
                @CiudadBaseCliente);

        -- Productos
        -- Seleccionamos IDs válidos para FK
        DECLARE @CatID INT = (SELECT TOP 1 CategoriaID FROM Inventario.Categorias ORDER BY NEWID());
        DECLARE @ProvID INT = (SELECT TOP 1 ProveedorID FROM Inventario.Proveedores ORDER BY NEWID());

        INSERT INTO Inventario.Productos (Nombre, CategoriaID, ProveedorID, PrecioVenta, StockActual, StockMinimo)
        VALUES ('Prod_Ref_' + CAST(@i AS VARCHAR(10)) + ' | V' + CAST(@i % 5 AS VARCHAR(5)),
                @CatID, @ProvID, ROUND((RAND()*10000), 2), (@i % 100), 10);

        SET @i += 1;
    END

------ -------------------------------------------------------------------------------------------------------------------------
----- 3. POBLADO DE TRANSACCIONES (Pedidos, Detalles, Pagos y Ventas Mostrador)
------ -------------------------------------------------------------------------------------------------------------------------
    PRINT '--- PASO 3: POBLADO DE TRANSACCIONES ---';
    SET @i = 1;
    WHILE @i <= 500
    BEGIN
        -- Pedido con estado no atómico para simular datos legacy. Se asocia a un cliente aleatorio.
        DECLARE @ClienteID INT = (SELECT TOP 1 ClienteID FROM Operaciones.Clientes ORDER BY NEWID());
        -- Estado no atómico para simular datos legacy (Ej: 'Pagado | Listo', 'Cancelado | Revisar', etc.).
        DECLARE @EstadoBase NVARCHAR(50) = ISNULL(CHOOSE(FLOOR(RAND()*2)+1, 'Pagado | Listo', 'Cancelado | Revisar'), 'Pendiente | Registro');
        
        INSERT INTO Operaciones.Pedidos (ClienteID, Estado_Info) VALUES (@ClienteID, @EstadoBase);
        DECLARE @PedidoID INT = SCOPE_IDENTITY();

        -- Detalle y Pago (Solo si el pedido existe)
        IF @PedidoID IS NOT NULL
        BEGIN
            DECLARE @ProdID INT = (SELECT TOP 1 ProductoID FROM Inventario.Productos ORDER BY NEWID());
            INSERT INTO Operaciones.DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario)
            VALUES (@PedidoID, @ProdID, FLOOR(RAND()*5)+1, ROUND(RAND()*2000+50, 2));

            -- Método de Pago no atómico para simular datos legacy (Ej: 'Efectivo | Caja', 'Tarjeta | Visa', 'Puntos | Loyalty')
            DECLARE @MetodoBase NVARCHAR(50) = ISNULL(CHOOSE(FLOOR(RAND()*3)+1, 'Efectivo | Caja', 'Tarjeta | Visa', 'Puntos | Loyalty'), 'Efectivo | Caja');

            INSERT INTO Operaciones.Pagos (PedidoID, Monto, Metodo_Info)
            VALUES (@PedidoID, ROUND(RAND()*3000, 2), @MetodoBase);
        END

        -- Ventas Directa (Mostrador)
        -- Sucursal para Ventas de Mostrador garantiza formato no atómico (Ej: 'Norte | Merida', 'Sur | Cancun', 'Centro | CDMX').
        DECLARE @SucursalBase NVARCHAR(50) = ISNULL(CHOOSE(FLOOR(RAND()*3)+1, 'Norte | Merida', 'Sur | Cancun', 'Centro | CDMX'), 'Matriz | CDMX');
        DECLARE @ProdVentaID INT = (SELECT TOP 1 ProductoID FROM Inventario.Productos ORDER BY NEWID());

        INSERT INTO Operaciones.Ventas_Mostrador (ProductoID, Cantidad, PrecioAplicado, FechaVenta, Sucursal_Info)
        VALUES (@ProdVentaID, FLOOR(RAND()*10)+1, ROUND(RAND()*2000+50, 2), 
                DATEADD(DAY, -(@i % 90), GETDATE()), 
                @SucursalBase);

        SET @i += 1;
    END

    COMMIT TRANSACTION;
    PRINT '=====================================================';
    PRINT 'Carga masiva completada exitosamente.';
    PRINT '=====================================================';
    PRINT '🚀 Carga masiva completada exitosamente.';
    PRINT '⏱️ Tiempo total: ' + CAST(DATEDIFF(MS, @Inicio, SYSUTCDATETIME()) AS VARCHAR(20)) + ' ms.';
    PRINT '=====================================================';

------ -------------------------------------------------------------------------------------------------------------------------
----- 4. LOG DE MÉTRICAS FINALES (Híbrido Narrativo/Ejecutivo))
----- --------------------------------------------------------------------------------------------------------------------------
    DECLARE @Fin DATETIME2 = SYSUTCDATETIME();
    DECLARE @Categorias INT, @Proveedores INT, @Clientes INT, @Productos INT, @Pedidos INT, @DetallePedido INT, @Pagos INT, @Ventas INT;

    -- Captura de variables para modo narrativo (Respetando Esquemas)
    SELECT @Categorias = COUNT(*) FROM Inventario.Categorias;
    SELECT @Proveedores = COUNT(*) FROM Inventario.Proveedores;
    SELECT @Clientes = COUNT(*) FROM Operaciones.Clientes;
    SELECT @Productos = COUNT(*) FROM Inventario.Productos;
    SELECT @Pedidos = COUNT(*) FROM Operaciones.Pedidos;
    SELECT @DetallePedido = COUNT(*) FROM Operaciones.DetallePedido;
    SELECT @Pagos = COUNT(*) FROM Operaciones.Pagos;
    SELECT @Ventas = COUNT(*) FROM Operaciones.Ventas_Mostrador;

    PRINT '=====================================================';
    PRINT '   📊 MÉTRICAS DE EJECUCIÓN (TABLA EJECUTIVA)';
    PRINT '=====================================================';
    
    -- Generación de tabla ejecutiva para análisis rápido
    SELECT 
        @Categorias AS Categorias,
        @Proveedores AS Proveedores,
        @Clientes AS Clientes,
        @Productos AS Productos,
        @Pedidos AS Pedidos,
        @DetallePedido AS DetallePedido,
        @Pagos AS Pagos,
        @Ventas AS Ventas_POS,
        DATEDIFF(MS, @Inicio, @Fin) AS TiempoTotal_ms;

    PRINT '=====================================================';
    PRINT '   📝 RESUMEN NARRATIVO DE LA CARGA MASIVA';
    PRINT '=====================================================';
    
    -- Modo Narrativo para stakeholders no técnicos
    PRINT '🚀 Se insertaron ' + CAST(@Categorias AS VARCHAR(10)) + ' categorías.';
    PRINT '🚀 Se insertaron ' + CAST(@Proveedores AS VARCHAR(10)) + ' proveedores.';
    PRINT '🚀 Se insertaron ' + CAST(@Clientes AS VARCHAR(10)) + ' clientes.';
    PRINT '🚀 Se insertaron ' + CAST(@Productos AS VARCHAR(10)) + ' productos.';
    PRINT '📦 Se generaron ' + CAST(@Pedidos AS VARCHAR(10)) + ' pedidos.';
    PRINT '📦 Se generaron ' + CAST(@DetallePedido AS VARCHAR(10)) + ' detalles de pedido.';
    PRINT '💰 Se registraron ' + CAST(@Pagos AS VARCHAR(10)) + ' pagos.';
    PRINT '🏪 Se registraron ' + CAST(@Ventas AS VARCHAR(10)) + ' ventas en mostrador.';
    PRINT '⏱️ Tiempo total de ejecución: ' + CAST(DATEDIFF(MS, @Inicio, @Fin) AS VARCHAR(20)) + ' ms.';
    PRINT '=====================================================';

END TRY
BEGIN CATCH
    -- Validamos si existe una transacción activa antes de hacer Rollback
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; 
    
    PRINT '=====================================================';
    PRINT '   ⚠️ ERROR DETECTADO EN CARGA MASIVA';
    PRINT '=====================================================';
    PRINT '❌ Mensaje: ' + ERROR_MESSAGE();
    PRINT '📍 Línea: ' + CAST(ERROR_LINE() AS VARCHAR(10));
    PRINT '=====================================================';
END CATCH;
GO

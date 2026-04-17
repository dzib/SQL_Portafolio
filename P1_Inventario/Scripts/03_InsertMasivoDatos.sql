/* 
=================================================================================================================================
PROYECTO: P1_Inventario -Sistema de Gestión de Inventario- | Fase 3: Carga Masiva (Stress Testing & Legacy Data Simulation)
AUTOR: Alberto Dzib
VERSIÓN: 1.1
DESCRIPCIÓN: Generación programática de 500 registros para simular un entorno 
             de producción real y validar el rendimiento del sistema.
             Se utiliza lógica aleatoria para diversificar los datos.
             Manejo de transacciones, rollback seguro y log de métricas.
================================================================================================================================
*/
USE P1_Inventario;
GO

SET NOCOUNT ON;

DECLARE @Inicio DATETIME = GETDATE();

BEGIN TRY
    BEGIN TRANSACTION;

    PRINT '--- PASO 0: LIMPIEZA PREVIA ---';
    DELETE FROM Ventas; DELETE FROM Pagos; DELETE FROM DetallePedido;
    DELETE FROM Pedidos; DELETE FROM Productos; DELETE FROM Clientes;
    DELETE FROM Proveedores; DELETE FROM Categorias;

    DECLARE @i INT = 1;

    ------ -------------------------------------------------------------------------------------------------------------------------
    -- 1. POBLADO DE MAESTROS
    ------ -------------------------------------------------------------------------------------------------------------------------
    WHILE @i <= 100
    BEGIN
        DECLARE @TipoCat VARCHAR(50) = CHOOSE(FLOOR(RAND()*3)+1, 'Software', 'Hardware', 'Servicios');
        IF @TipoCat IS NULL SET @TipoCat = 'General';

        DECLARE @TipoProv VARCHAR(50) = CHOOSE(FLOOR(RAND()*3)+1, 'Logística', 'Importación', 'Distribución');
        IF @TipoProv IS NULL SET @TipoProv = 'Mayoreo';

        DECLARE @CiudadProv VARCHAR(50) = CHOOSE(FLOOR(RAND()*3)+1, 'Mérida | YUC', 'Cancún | QRO', 'Monterrey | NL');
        IF @CiudadProv IS NULL SET @CiudadProv = 'Tijuana | BC';

        DECLARE @NombreCat VARCHAR(100) = 'Cat_' + CAST(@i AS VARCHAR(10)) + ' | ' + @TipoCat;
        DECLARE @NombreProv VARCHAR(100) = 'Prov_' + CAST(@i AS VARCHAR(10)) + ' | ' + @TipoProv;

        INSERT INTO Categorias (Nombre, Descripcion)
        VALUES (@NombreCat, 'Desc_' + CAST(@i AS VARCHAR(10)));

        INSERT INTO Proveedores (Nombre, Telefono, Ciudad)
        VALUES (@NombreProv, '999' + CAST(@i AS VARCHAR(10)), @CiudadProv);

        SET @i += 1;
    END

    ------ -------------------------------------------------------------------------------------------------------------------------
    -- 2. POBLADO DE PRODUCTOS Y CLIENTES
    ------ -------------------------------------------------------------------------------------------------------------------------
    SET @i = 1;
    WHILE @i <= 500
    BEGIN
        DECLARE @Segmento VARCHAR(50) = CHOOSE(FLOOR(RAND()*3)+1, 'Corporativo', 'Particular', 'VIP');
        IF @Segmento IS NULL SET @Segmento = 'General';

        DECLARE @CiudadCli VARCHAR(50) = CHOOSE(FLOOR(RAND()*4)+1, 'Querétaro | QRO', 'Mérida | YUC', 'Puebla | PUE', 'Toluca | MEX');
        IF @CiudadCli IS NULL SET @CiudadCli = 'CDMX | Centro';

        DECLARE @NombreCli VARCHAR(100) = 'Cliente_ID_' + CAST(@i AS VARCHAR(10)) + ' | ' + @Segmento;

        INSERT INTO Clientes (Nombre, Email, Telefono, Ciudad)
        VALUES (@NombreCli,  
                'user' + CAST(@i AS VARCHAR(10)) + '@demo.com', 
                '555-' + RIGHT('0000' + CAST(@i AS VARCHAR(10)), 4), -- Teléfono ficticio
                @CiudadCli);

        -- Seleccionamos IDs válidos para FK
        DECLARE @CatID INT = (SELECT TOP 1 IdCategoria FROM Categorias ORDER BY NEWID());
        DECLARE @ProvID INT = (SELECT TOP 1 IdProveedor FROM Proveedores ORDER BY NEWID());

        INSERT INTO Productos (Nombre, IdCategoria, IdProveedor, Precio, Stock)
        VALUES ('Prod_Ref_' + CAST(@i AS VARCHAR(10)) + ' | V' + CAST(@i % 5 AS VARCHAR(5)),
                @CatID, @ProvID,
                ROUND((RAND()*10000), 2), (@i % 100));

        SET @i += 1;
    END

    ------ -------------------------------------------------------------------------------------------------------------------------
    -- 3. POBLADO DE TRANSACCIONES
    ------ -------------------------------------------------------------------------------------------------------------------------
    SET @i = 1;
    WHILE @i <= 500
    BEGIN
        DECLARE @ClienteID INT = (SELECT TOP 1 IdCliente FROM Clientes ORDER BY NEWID());

        DECLARE @Estado VARCHAR(50) = CHOOSE(FLOOR(RAND()*2)+1, 'Pagado | Listo', 'Cancelado | Revisar');
        IF @Estado IS NULL SET @Estado = 'Pendiente | Registro';

        INSERT INTO Pedidos (IdCliente, Estado) VALUES (@ClienteID, @Estado);
        DECLARE @ID INT = SCOPE_IDENTITY();

        IF @ID IS NOT NULL
        BEGIN
            DECLARE @ProdID INT = (SELECT TOP 1 IdProducto FROM Productos ORDER BY NEWID());

            INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
            VALUES (@ID, @ProdID, FLOOR(RAND()*5)+1, ROUND(RAND()*2000+50, 2));

            DECLARE @MetodoPago VARCHAR(50) = CHOOSE(FLOOR(RAND()*3)+1, 'Efectivo | Caja', 'Tarjeta | Visa', 'Puntos | Loyalty');
            IF @MetodoPago IS NULL SET @MetodoPago = 'Efectivo | Caja';

            INSERT INTO Pagos (IdPedido, Monto, MetodoPago)
            VALUES (@ID, ROUND(RAND()*3000, 2), @MetodoPago);
        END

        DECLARE @Sucursal VARCHAR(50) = CHOOSE(FLOOR(RAND()*3)+1, 'Norte | Merida', 'Sur | Cancun', 'Centro | CDMX');
        IF @Sucursal IS NULL SET @Sucursal = 'Matriz | CDMX';

        DECLARE @ProdVentaID INT = (SELECT TOP 1 IdProducto FROM Productos ORDER BY NEWID());

        INSERT INTO Ventas (IdProducto, Cantidad, Sucursal)
        VALUES (@ProdVentaID, FLOOR(RAND()*10)+1, @Sucursal);

        SET @i += 1;
    END

    COMMIT TRANSACTION;

    PRINT 'Carga masiva completada exitosamente.';

    ------ -------------------------------------------------------------------------------------------------------------------------
    -- LOG DE MÉTRICAS
    ------ -------------------------------------------------------------------------------------------------------------------------
    DECLARE @Fin DATETIME = GETDATE();
    DECLARE @Categorias INT, @Proveedores INT, @Clientes INT, @Productos INT, @Pedidos INT, @DetallePedido INT, @Pagos INT, @Ventas INT;

    SELECT @Categorias = COUNT(*) FROM Categorias;
    SELECT @Proveedores = COUNT(*) FROM Proveedores;
    SELECT @Clientes = COUNT(*) FROM Clientes;
    SELECT @Productos = COUNT(*) FROM Productos;
    SELECT @Pedidos = COUNT(*) FROM Pedidos;
    SELECT @DetallePedido = COUNT(*) FROM DetallePedido;
    SELECT @Pagos = COUNT(*) FROM Pagos;
    SELECT @Ventas = COUNT(*) FROM Ventas;

   
    PRINT '==============================';
    PRINT '   MÉTRICAS DE EJECUCIÓN';
    PRINT '==============================';
    
    -- Generacion de tabla ejecutiva
    SELECT 
        COUNT(*) AS Categorias,
        (SELECT COUNT(*) FROM Proveedores) AS Proveedores,
        (SELECT COUNT(*) FROM Clientes) AS Clientes,
        (SELECT COUNT(*) FROM Productos) AS Productos,
        (SELECT COUNT(*) FROM Pedidos) AS Pedidos,
        (SELECT COUNT(*) FROM DetallePedido) AS DetallePedido,
        (SELECT COUNT(*) FROM Pagos) AS Pagos,
        (SELECT COUNT(*) FROM Ventas) AS Ventas,
        DATEDIFF(ms, @Inicio, @Fin) AS TiempoTotal_ms;

    PRINT '==============================';
    PRINT '   RESUMEN DE LA CARGA MASIVA';
    PRINT '==============================';
    
    -- Modo Narrativo
    PRINT 'Se insertaron ' + CAST(@Categorias AS VARCHAR(10)) + ' categorías.';
    PRINT 'Se insertaron ' + CAST(@Proveedores AS VARCHAR(10)) + ' proveedores.';
    PRINT 'Se insertaron ' + CAST(@Clientes AS VARCHAR(10)) + ' clientes.';
    PRINT 'Se insertaron ' + CAST(@Productos AS VARCHAR(10)) + ' productos.';
    PRINT 'Se generaron ' + CAST(@Pedidos AS VARCHAR(10)) + ' pedidos.';
    PRINT 'Se generaron ' + CAST(@DetallePedido AS VARCHAR(10)) + ' detalles de pedido.';
    PRINT 'Se registraron ' + CAST(@Pagos AS VARCHAR(10)) + ' pagos.';
    PRINT 'Se registraron ' + CAST(@Ventas AS VARCHAR(10)) + ' ventas.';
    PRINT 'Tiempo total de ejecución: ' + CAST(DATEDIFF(ms, @Inicio, @Fin) AS VARCHAR(20)) + ' ms.';


END TRY
BEGIN CATCH
    -- Validamos si existe una transacción activa antes de hacer Rollback
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; 
    
    PRINT '==============================';
    PRINT '   ERROR DETECTADO';
    PRINT '==============================';
    PRINT 'Mensaje: ' + ERROR_MESSAGE();
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR(10));
END CATCH;


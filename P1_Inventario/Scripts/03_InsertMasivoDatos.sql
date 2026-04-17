/* 
=================================================================================================================================
PROYECTO: P1_Inventario -Sistema de Gestión de Inventario- | Fase 3: Carga Masiva (Stress Testing & Legacy Data Simulation)
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: Generación programática de 500 registros para simular un entorno 
             de producción real y validar el rendimiento del sistema.
             Se utiliza lógica aleatoria para diversificar los datos.
================================================================================================================================
*/

USE P1_Inventario;
GO

-- Optimización de rendimiento: Evita enviar mensajes de "1 fila afectada" por cada registro
SET NOCOUNT ON;
DECLARE @i INT = 1;

PRINT 'Iniciando carga masiva de datos...';

WHILE @i <= 500
BEGIN
------ -------------------------------------------------------------------------------------------------------------------------
    -- 1. POBLADO DE MAESTROS (Cada 100 iteraciones variamos categorías y proveedores)
------ -------------------------------------------------------------------------------------------------------------------------
    IF @i <= 100
    BEGIN
        INSERT INTO Categorias (Nombre, Descripcion) 
        VALUES (
            'Cat_' + CAST(@i AS VARCHAR) + ' | ' + CHOOSE(CAST(RAND()*3+1 AS INT), 'Software', 'Hardware', 'Servicios'), 
            'Descripción automática para el lote ' + CAST(@i AS VARCHAR)
        );
        
        INSERT INTO Proveedores (Nombre, Telefono, Ciudad) 
        VALUES (
            'Prov_' + CAST(@i AS VARCHAR) + ' | ' + CHOOSE(CAST(RAND()*3+1 AS INT), 'Distribución', 'Importación', 'Logística'), 
            '999' + RIGHT('0000000' + CAST(@i AS VARCHAR), 7), 
            CHOOSE(CAST(RAND()*3+1 AS INT), 'Guadalajara | Jalisco', 'CDMX | Centro', 'Tijuana | BC')
        );
    END
------ -------------------------------------------------------------------------------------------------------------------------
    -- 2. POBLADO DE PRODUCTOS Y CLIENTES (Con dispersión geográfica y de categorías)
------ -------------------------------------------------------------------------------------------------------------------------
    INSERT INTO Productos (Nombre, IdCategoria, IdProveedor, Precio, Stock)
    VALUES (
        'Prod_Ref_' + CAST(@i AS VARCHAR) + ' | Ver_' + CAST(@i % 5 AS VARCHAR), 
        (@i % 100) + 1, -- Logica de negocio para asignar categorías de forma cíclica
        (@i % 100) + 1, -- Proveedores también asignados de forma cíclica
        ROUND((RAND()*10000), 2), 
        (@i % 100)
    );

    -- Clientes con ciudades variadas
    INSERT INTO Clientes (Nombre, Email, Ciudad)
    VALUES (
        'Cliente_ID_' + CAST(@i AS VARCHAR), 
        'user_' + CAST(@i AS VARCHAR) + '@demo.com', 
        CHOOSE(CAST(RAND()*4+1 AS INT), 'Querétaro | QRO', 'Mérida | YUC', 'Puebla | PUE', 'Toluca | MEX')
    );

------ -------------------------------------------------------------------------------------------------------------------------
    -- 3. POBLADO DE TRANSACCIONES ENCADENADAS (Pedidos -> Detalles -> Pagos)
------ -------------------------------------------------------------------------------------------------------------------------
    -- Cumplimos con el CHECK (Estado LIKE '%|%')
    INSERT INTO Pedidos (IdCliente, Estado) 
    VALUES ((@i % 500) + 1, CHOOSE(CAST(RAND()*2+1 AS INT), 'Pagado | Listo', 'Cancelado | Revisar'));
    
    DECLARE @LastPedID INT = SCOPE_IDENTITY();

    INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario) 
    VALUES (@LastPedID, (@i % 500) + 1, (CAST(RAND()*5 AS INT) + 1), ROUND(RAND()*5000, 2));

    INSERT INTO Pagos (IdPedido, Monto, MetodoPago) 
    VALUES (
        @LastPedID, 
        ROUND(RAND()*5000, 2), 
        CHOOSE(CAST(RAND()*3+1 AS INT), 'Efectivo | Caja', 'Tarjeta | Visa', 'Puntos | Loyalty')
    );

------ -------------------------------------------------------------------------------------------------------------------------
    -- 4. VENTAS DIRECTAS (Mostrador con sucursales diversas)
------ -------------------------------------------------------------------------------------------------------------------------
    INSERT INTO Ventas (IdProducto, Cantidad, Sucursal)
    VALUES (
        (@i % 500) + 1, 
        (CAST(RAND()*5 AS INT) + 1), 
        CHOOSE(CAST(RAND()*3+1 AS INT), 'Sucursal Oriente | Cancún', 'Sucursal Poniente | CDMX', 'Sucursal Sur | León')
    );

    SET @i += 1;
END

PRINT 'Carga masiva finalizada exitosamente con lógica aleatoria.';
GO

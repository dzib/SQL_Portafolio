/* 
=========================================================================================================================================================
PROYECTO: P2_Escolar - Sistema de Gestión Académica
FASE: 4 - Proceso ETL y Limpieza de Datos
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Uso de CTEs y funciones de cadena (CHARINDEX, SUBSTRING, LEN) para normalizar Metadata_ETL.
    - Transformación de tipos de datos (Strings a DATETIME2 y DECIMAL) para comnversion en información util y tipada.
    - Implementación de manejo de errores con TRY...CATCH para asegurar la robustez del proceso ETL.
    - Aislación del proceso ETL en una vista para mantener la integridad de los datos originales y facilitar futuras consultas.
 ========================================================================================================================================================
*/

USE P2_EscolarDB;
GO

-- Preparacion de entorno para proceso ETL.
SET NOCOUNT ON; -- Suuprir el mensaje: "(1 filas afectadas)".
DECLARE @StartTime DATETIME2 = SYSUTCDATETIME(); --Data Typing para métricas de tiempo.

BEGIN TRY
    BEGIN TRANSACTION;

    PRINT '--------------------------------------------------------------------';
    PRINT '🧹 Iniciando proceso ETL de normalización...';
    PRINT '--------------------------------------------------------------------';
--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 1. ELIMINACIÓN/CREACIÓN DE LA VISTA (Acción DDL)
--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
    IF OBJECT_ID('Operaciones.VW_Alumnos_Normalizados', 'V') IS NOT NULL
        DROP VIEW Operaciones.VW_Alumnos_Normalizados;
        
--- -- Ejecutamos el DDL dentro de EXEC para no interrumpir con el batch actual y mantener la claridad del proceso ETL. 
    EXEC('
        CREATE VIEW Operaciones.VW_Alumnos_Normalizados AS
        WITH Posiciones AS (
            SELECT                                     -- Proceso de Localizar los delimitadores |.
                IdAlumno,
                Nombre,
                Carrera,
                Metadata_ETL,
                    CHARINDEX(''|'', Metadata_ETL) AS P1,
                    CHARINDEX(''|'', Metadata_ETL, CHARINDEX(''|'', Metadata_ETL) + 1) AS P2
            FROM Catalogos.Alumnos
        ),
        Extraccion AS (                                -- Extracción de los segemento en la posicióm P1 y P2, con transformación de tipos.
            SELECT
                IdAlumno,
                Nombre,
                Carrera,
                    CAST(SUBSTRING(Metadata_ETL, 1, P1 - 1) AS DATETIME2) AS FechaIngreso,
                    SUBSTRING(Metadata_ETL, P1 + 1, P2 - P1 - 1) AS Estatus,
                    CAST(SUBSTRING(Metadata_ETL, P2 + 1, LEN(Metadata_ETL)) AS DECIMAL(5,2)) AS PromedioExterno
            FROM Posiciones
        )
        SELECT * FROM Extraccion
    ');
--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 2. VALIDACIÓN RÁPIDA ASEGURAR LA CORRECTA CREACIÓN DE VISTA Y MUESTRA DATOS NORMALIZADOS
--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
    DECLARE @Conteo INT;
    SELECT @Conteo = COUNT(*) FROM Operaciones.VW_Alumnos_Normalizados;
    COMMIT TRANSACTION;

--- -- -----------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 3. MÉTRICAS DE ÉXITO
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '=====================================================';
    PRINT '     ✅ Proceso ETL Completado.';
    PRINT '=====================================================';
    PRINT '📋 Registros Normalizados: ' + FORMAT(@Conteo, 'N0');
    PRINT '⏱️ Tiempo de ejecución:    ' + FORMAT(DATEDIFF(MILLISECOND, @StartTime, SYSUTCDATETIME()), 'N0') + ' ms';
    PRINT '=====================================================';

END TRY
BEGIN CATCH

--- -- -----------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 4. MANEJO DE ERRORES
--- -----------------------------------------------------------------------------------------------------------------------------------------------------
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '          ❌ ERROR EN PROCESO ETL';
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '📍 Línea del Error:   ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '📄 Mensaje:           ' + ERROR_MESSAGE();
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
END CATCH
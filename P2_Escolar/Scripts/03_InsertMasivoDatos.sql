/* 
==========================================================================================================================================================
PROYECTO: P2_Escolar - Sistema de Gestión Académica
FASE: 3 - Carga Masiva y Stress Test
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Inserción masiva de 1,000 alumnos usando bucle WHILE.
    - Implementación de transacciones para asegurar la integridad.
    - Generación de datos no atómicos en columna Metadata_ETL para futuro proceso de limpieza.
 =========================================================================================================================================================
*/

USE P2_EscolarDB;
GO

SET NOCOUNT ON; -- Para reducir tiempo se suprime el mensaje de "(1 filas afectadas)".

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables para control de bucle y métricas
-- ------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @Contador INT = 1;
DECLARE @Max INT = 1000;
DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();

----- ---------------------------------------------------------------------------------------------------------------------------------------------------
PRINT '--------------------------------------------------------------------------------------------------';
PRINT '🚀 Iniciando carga masiva de 1,000 alumnos en P2_EscolarDB...' + CAST(SYSDATETIME() AS VARCHAR);
PRINT '--------------------------------------------------------------------------------------------------';
----- ---------------------------------------------------------------------------------------------------------------------------------------------------
BEGIN TRY
    BEGIN TRANSACTION;
    -- Limpiza previa a calificaciones para evitar conflictos de FK.
    DELETE FROM Operaciones.Calificaciones;
    DELETE FROM Catalogos.Alumnos;-- Limpiamos alumnos para evitar conflictos de FK.
    DBCC CHECKIDENT ('Catalogos.Alumnos', RESEED, 0); -- <-- Reseteamos el contador de identidad para que los IdAlumno comiencen desde 1 nuevamente.

---------- ---------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. CARGA MASIVA DE ALUMNOS CON DATOS NO ATÓMICOS EN METADATA_ETL
---------- ---------------------------------------------------------------------------------------------------------------------------------------------
        WHILE @Contador <= @Max
        BEGIN
            INSERT INTO Catalogos.Alumnos (Nombre, Carrera, Metadata_ETL)
            VALUES (
                'Estudiante_ID_' + CAST(@Contador AS VARCHAR),
                CASE 
                    WHEN @Contador % 3 = 0 THEN 'Ingeniería de Datos'
                    WHEN @Contador % 3 = 1 THEN 'Ciencias de la Computación'
                    ELSE 'Administración de Sistemas'
                END,
                -- Formato intencional: "FechaIngreso|Estatus|Promedio" con datos no atómicos para limpieza futura.
                '2025-01-10|ACTIVO|' + CAST(ABS(CHECKSUM(NEWID()) % 101) AS VARCHAR) -- Genera un promedio aleatorio entre 0 y 100.
            );
            SET @Contador = @Contador + 1;
        END

------- -- ----------------------------------------------------------------------------------------------------------------------------------------------
------- -- 2. CARGA MASIVA DE CALIFICACIONES (Relacionando Alumnos y Cursos)
        PRINT '📊 Asignando calificaciones masivas...';
------- -- ----------------------------------------------------------------------------------------------------------------------------------------------
        INSERT INTO Operaciones.Calificaciones (IdAlumno, IdCurso, Nota)
        SELECT A.IdAlumno, C.IdCurso, ABS(CHECKSUM(NEWID()) % 40) + 60
        -- Genera notas entre 60 y 99 máximo. Para no sobrepar los 4 digitos de la columna Nota.
        FROM Catalogos.Alumnos A
        CROSS JOIN Catalogos.Cursos C -- Con esto se creará combinaciones para todos.
        -- Solo poblamos una muestra (2,000 registros) para no saturar, no es necesario poblar los 4,000 registros.
        WHERE A.IdAlumno IN (SELECT TOP 500 IdAlumno FROM Catalogos.Alumnos ORDER BY IdAlumno DESC);


    COMMIT TRANSACTION;

--- -- --------------------------------------------------------------------------------------------------------------------------------------------
    -- MÉTRICAS DE EJECUCIÓN
--- -- --------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '';
    PRINT '=====================================================';
    PRINT '       ✅ RESUMEN DE EJECUCIÓN EXITOSA';
    PRINT '=====================================================';
    PRINT '👥 Registros Alumnos:   ' + FORMAT(@Max, 'N0'); -- Formato numérico con separador de miles.
    PRINT '📝 Registros Notas:     ' + FORMAT(2000, 'N0'); -- (500 alumnos * 4 cursos)
    PRINT '⏱️  Tiempo de Proceso:   ' + FORMAT(DATEDIFF(MILLISECOND, @StartTime, SYSUTCDATETIME()), 'N0') + ' ms';
     PRINT '📅 Finalizado el:       ' + CAST(SYSDATETIME() AS VARCHAR);
    PRINT '=====================================================';
    PRINT '';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- Asegura que cualquier error revierta los cambios para mantener la integridad de la base de datos.

    PRINT '';
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '=====================================================';
    PRINT '          ❌ ERROR DETECTADO - TRANSACCIÓN REVERTIDA';
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '📍 Línea del Error: ' + CAST(ERROR_LINE() AS VARCHAR); -- Línea donde ocurrió el error.
    PRINT '🔢 Código de Error:   ' + CAST(ERROR_NUMBER() AS VARCHAR); -- Código de error específico.
    PRINT '📄 Mensaje:           ' + ERROR_MESSAGE();
    PRINT '⚙️  Procedimiento:     ' + ISNULL(ERROR_PROCEDURE(), 'Script Directo');
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
END CATCH

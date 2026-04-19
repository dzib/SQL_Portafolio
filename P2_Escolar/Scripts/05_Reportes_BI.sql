/* 
===========================================================================================================
PROYECTO: P2_Escolar - Sistema de Gestión Académica
FASE: 5 - Reportes de Business Intelligence (BI)
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Generación de KPIs de rendimiento académico.
    - Uso de Window Functions (RANK) para Cuadro de Honor.
    - Integración de la vista normalizada (ETL) con datos transaccionales.
 ===========================================================================================================
*/

USE P2_EscolarDB;
GO

SET NOCOUNT ON; -- Suuprir el mensaje: "(1 filas afectadas)".
DECLARE @StartTime DATETIME2 = SYSUTCDATETIME(); --Data Typing para métricas de tiempo.

PRINT '--------------------------------------------------------------------';
PRINT '📊 Generando Reportes de Inteligencia de Negocio...';
PRINT '--------------------------------------------------------------------';

BEGIN TRY
--- -- ------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 1. REPORTE: RENDIMIENTO POR CARRERA (KPI Agregado)
--- -- ------------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '=============================================================';
    PRINT '>> Reporte 1: Promedios Generales por Carrera';
    PRINT '=============================================================';
    SELECT 
        A.Carrera,
        COUNT(DISTINCT A.IdAlumno) TotalAlumnos,
        CAST(AVG(C.Nota) AS DECIMAL(5,2)) PromedioGeneral,
        CAST(MIN(C.Nota) AS DECIMAL(5,2)) NotaMinima,
        CAST(MAX(C.Nota) AS DECIMAL(5,2)) NotaMaxima
    FROM Operaciones.VW_Alumnos_Normalizados A
    JOIN Operaciones.Calificaciones C ON A.IdAlumno = C.IdAlumno
    GROUP BY A.Carrera
    ORDER BY PromedioGeneral DESC;

--- -- ------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 2. REPORTE: CUADRO DE HONOR (Aplicando Window Functions)
--- -- ------------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '=============================================================';
    PRINT CHAR(13) + '>> Reporte 2: Top 10 Alumnos (Ranking Global)';
    PRINT '=============================================================';
    SELECT TOP 10
        RANK() OVER (ORDER BY AVG(C.Nota) DESC) Posicion,
        A.Nombre,
        A.Carrera,
        CAST(AVG(C.Nota) AS DECIMAL(5,2)) PromedioFinal
    FROM Operaciones.VW_Alumnos_Normalizados A
    JOIN Operaciones.Calificaciones C ON A.IdAlumno = C.IdAlumno
    GROUP BY A.IdAlumno, A.Nombre, A.Carrera
    ORDER BY PromedioFinal DESC;

--- -- ------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 3. MÉTRICAS DE CIERRE
--- -- ------------------------------------------------------------------------------------------------------------------------------------------------
        PRINT '';
    PRINT '=====================================================';
    PRINT '     ✅ Reportes BI Generados con Éxito';
    PRINT '=====================================================';
    PRINT '⏱️ Tiempo de procesamiento: ' + FORMAT(DATEDIFF(MILLISECOND, @StartTime, SYSUTCDATETIME()), 'N0') + ' ms';
    PRINT '📅 Reporte generado el:     ' + CAST(SYSDATETIME() AS VARCHAR);
    PRINT '=====================================================';

END TRY
BEGIN CATCH
--- -- -------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 4. MANEJO DE ERRORES
--- -- -------------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '❌ Ocurrió un error durante la generación del los reportes.';
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '📍 Línea del Error:           ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '❌ ERROR al generar reportes: ' + ERROR_MESSAGE();
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
END CATCH

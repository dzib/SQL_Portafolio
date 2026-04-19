/* 
===========================================================================================================
PROYECTO: P2_Escolar - Sistema de Gestión Académica
FASE: 2 - Memoria de contexto para datos iniciales
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Poblar catálogos base (Semilla)
    - Manejo de relaciones entre tablas (Profesores-Departamentos, Cursos-Profesores)
    - Métricas de ejecución para monitoreo de performance.
 ===========================================================================================================
*/

USE P2_EscolarDB;
GO

DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();

-- ---------------------------------------------------------------------------------------------------------
-- 1. POBLAR DEPARTAMENTOS
-- ---------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Catalogos.Departamentos)
BEGIN
    INSERT INTO Catalogos.Departamentos (Nombre)
    VALUES ('Facultad de Ingeniería'), ('Ciencias Exactas'), ('Administración'), ('Humanidades');
    PRINT '✅ Catálogo: Departamentos insertado.';
END

-- ---------------------------------------------------------------------------------------------------------
-- 2. POBLAR PROFESORES (Relacionados con Deptos)
-- ---------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Catalogos.Profesores)
BEGIN
    INSERT INTO Catalogos.Profesores (IdDepartamento, Nombre, Especialidad)
    VALUES 
        (1, 'Dr. Julián Pérez', 'Sistemas Computacionales'),
        (1, 'Mtra. Elena Gómez', 'Inteligencia Artificial'),
        (2, 'Dr. Roberto Isaac', 'Cálculo Avanzado'),
        (3, 'Lic. Ana Martínez', 'Gestión de Proyectos');
    PRINT '✅ Catálogo: Profesores insertado.';
END

-- ---------------------------------------------------------------------------------------------------------
-- 3. POBLAR CURSOS
-- ---------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Catalogos.Cursos)
BEGIN
    INSERT INTO Catalogos.Cursos (Nombre, Creditos)
    VALUES 
        ('Base de Datos II', 8),
        ('Programación SQL Server', 6),
        ('Análisis de Algoritmos', 7),
        ('Ética Profesional', 4);
    PRINT '✅ Catálogo: Cursos insertado.';
END

-- ---------------------------------------------------------------------------------------------------------
-- Métrica de Ejecución
-- ---------------------------------------------------------------------------------------------------------
PRINT '---------------------------------------------------------';
PRINT '⏱️ Tiempo de ejecución: ' + CAST(DATEDIFF(MILLISECOND, @StartTime, SYSUTCDATETIME()) AS VARCHAR) + ' ms.';
PRINT '✅ Script 02 finalizado con éxito.';

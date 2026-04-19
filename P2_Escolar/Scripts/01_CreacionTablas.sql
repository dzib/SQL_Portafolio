/* 
===========================================================================================================
PROYECTO: P2_Escolar - Sistema de Gestión Académica
FASE: 1 - Estructura de Datos y Reglas de Negocio
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Implementación del Esquema relacional e Integridad bajo estándares SQL 2025.
    - Manejo  de jerarquías mediante esquemas para separar catálogos de operaciones.
    - Aplicación de Constraints Nominados para garantizar la calidad de los datos.
    - Implementación de DATETIME2 para auditar registros y facilitar procesos de limpieza (Data Cleansing). 
===========================================================================================================
*/

-- ---------------------------------------------------------------------------------------------------------
-- CREACIÓN DE BASE DE DATOS
-- ---------------------------------------------------------------------------------------------------------
USE master;
GO
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'P2_EscolarDB')
    CREATE DATABASE P2_EscolarDB;
GO
USE P2_EscolarDB;
GO

-- ---------------------------------------------------------------------------------------------------------
-- 1. ESQUEMAS
-- ---------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Catalogos')
BEGIN
    EXEC('CREATE SCHEMA Catalogos');
    PRINT '✅ Esquema [Catalogos] creado.';
END;

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Operaciones')
BEGIN 
    EXEC('CREATE SCHEMA Operaciones');
    PRINT '✅ Esquema [Operaciones] creado.';
END;
GO

-- ---------------------------------------------------------------------------------------------------------
-- 2. LIMPIEZA IDEMPOTENTE
-- ---------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS Operaciones.Asistencias;
DROP TABLE IF EXISTS Operaciones.Calificaciones;
DROP TABLE IF EXISTS Operaciones.Horarios;
DROP TABLE IF EXISTS Operaciones.CursosProfesores;
DROP TABLE IF EXISTS Catalogos.Cursos;
DROP TABLE IF EXISTS Catalogos.Profesores;
DROP TABLE IF EXISTS Catalogos.Alumnos;
DROP TABLE IF EXISTS Catalogos.Departamentos;
GO

-- ---------------------------------------------------------------------------------------------------------
-- 3. TABLAS DE CATÁLOGOS
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE Catalogos.Alumnos (
    IdAlumno INT IDENTITY(1,1),
    Nombre NVARCHAR(100) NOT NULL,
    Carrera NVARCHAR(50) NOT NULL,
    Metadata_ETL NVARCHAR(MAX), -- Datos para limpieza: "FechaIngreso|Estatus|Promedio"
    FechaRegistro DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Alumnos PRIMARY KEY (IdAlumno)
);

CREATE TABLE Catalogos.Departamentos (
    IdDepartamento INT IDENTITY(1,1),
    Nombre NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Departamentos PRIMARY KEY (IdDepartamento)
);

CREATE TABLE Catalogos.Profesores (
    IdProfesor INT IDENTITY(1,1),
    IdDepartamento INT,
    Nombre NVARCHAR(100) NOT NULL,
    Especialidad NVARCHAR(100),
    CONSTRAINT PK_Profesores PRIMARY KEY (IdProfesor),
    CONSTRAINT FK_Profesores_Deptos FOREIGN KEY (IdDepartamento) REFERENCES Catalogos.Departamentos(IdDepartamento)
);

CREATE TABLE Catalogos.Cursos (
    IdCurso INT IDENTITY(1,1),
    Nombre NVARCHAR(100) NOT NULL,
    Creditos INT CONSTRAINT CK_Creditos CHECK (Creditos BETWEEN 1 AND 12),
    CONSTRAINT PK_Cursos PRIMARY KEY (IdCurso)
);

-- ---------------------------------------------------------------------------------------------------------
-- 4. TABLAS OPERATIVAS
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE Operaciones.Calificaciones (
    IdCalificacion INT IDENTITY(1,1),
    IdAlumno INT NOT NULL,
    IdCurso INT NOT NULL,
    Nota DECIMAL(4,2) CONSTRAINT CK_Nota CHECK (Nota BETWEEN 0 AND 100),
    FechaEvaluacion DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Calificaciones PRIMARY KEY (IdCalificacion),
    CONSTRAINT FK_Cal_Alumnos FOREIGN KEY (IdAlumno) REFERENCES Catalogos.Alumnos(IdAlumno),
    CONSTRAINT FK_Cal_Cursos FOREIGN KEY (IdCurso) REFERENCES Catalogos.Cursos(IdCurso)
);

CREATE TABLE Operaciones.CursosProfesores (
    IdCurso INT NOT NULL,
    IdProfesor INT NOT NULL,
    CicloLectivo VARCHAR(10) DEFAULT '2025-1',
    CONSTRAINT PK_CursosProfesores PRIMARY KEY (IdCurso, IdProfesor),
    CONSTRAINT FK_CP_Cursos FOREIGN KEY (IdCurso) REFERENCES Catalogos.Cursos(IdCurso),
    CONSTRAINT FK_CP_Profesores FOREIGN KEY (IdProfesor) REFERENCES Catalogos.Profesores(IdProfesor)
);

-- ---------------------------------------------------------------------------------------------------------
-- 5. LOG DE EJECUCIÓN
-- ---------------------------------------------------------------------------------------------------------
PRINT '✅ Script 01_CreacionTablas ejecutado con éxito en ' + CAST(SYSDATETIME() AS VARCHAR);

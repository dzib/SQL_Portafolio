--Alumnos (nombre, carrera, fecha inscripción)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO EscolarDB.dbo.Alumnos (Nombre, Carrera, FechaInscripcion)
    VALUES ('Alumno_' + CAST(@i AS NVARCHAR(10)) + ' | Grupo_' + CAST((@i % 10)+1 AS NVARCHAR(10)),
            CASE WHEN @i % 3 = 0 THEN 'Ingeniería en Sistemas | Computación'
                 WHEN @i % 3 = 1 THEN 'Matemáticas Aplicadas | Estadística'
                 ELSE 'Administración de Empresas | Gestión' END,
            DATEADD(DAY, -@i, GETDATE()));
    SET @i += 1;
END
GO

--Cursos (nombre, créditos, fecha creación)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO EscolarDB.dbo.Cursos (Nombre, Creditos, FechaCreacion)
    VALUES ('Curso_' + CAST(@i AS NVARCHAR(10)) + ' | Nivel_' + CAST((@i % 5)+1 AS NVARCHAR(10)),
            (@i % 10)+1,
            DATEADD(DAY, -@i, GETDATE()));
    SET @i += 1;
END
GO

--Calificaciones (alumno, curso, nota, fecha)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO EscolarDB.dbo.Calificaciones (IdAlumno, IdCurso, Nota, Fecha)
    VALUES ((@i % 500)+1,
            (@i % 500)+1,
            ROUND(RAND()*10,2),
            DATEADD(DAY, -@i, GETDATE()));
    SET @i += 1;
END
GO

--Profesores (nombre, especialidad, fecha contratación)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO EscolarDB.dbo.Profesores (Nombre, Especialidad, FechaContratacion)
    VALUES ('Profesor_' + CAST(@i AS NVARCHAR(10)) + ' | Área_' + CAST((@i % 5)+1 AS NVARCHAR(10)),
            CASE WHEN @i % 2 = 0 THEN 'Bases de Datos | SQL'
                 ELSE 'Matemáticas | Estadística' END,
            DATEADD(DAY, -@i, GETDATE()));
    SET @i += 1;
END
GO

--Departamentos (nombre, descripción)
DECLARE @i INT = 1;
WHILE @i <= 100
BEGIN
    INSERT INTO EscolarDB.dbo.Departamentos (Nombre, Descripcion)
    VALUES ('Departamento_' + CAST(@i AS NVARCHAR(10)) + ' | Facultad_' + CAST((@i % 5)+1 AS NVARCHAR(10)),
            'Descripción | Área académica ' + CAST(@i AS NVARCHAR(10)));
    SET @i += 1;
END
GO

--CursosProfesores (curso, profesor, rol)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO EscolarDB.dbo.CursosProfesores (IdCurso, IdProfesor, Rol)
    VALUES ((@i % 500)+1,
            (@i % 500)+1,
            CASE WHEN @i % 2 = 0 THEN 'Titular | Coordinador' ELSE 'Adjunto | Auxiliar' END);
    SET @i += 1;
END
GO

--Horarios (curso, día, hora inicio, hora fin, aula)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO EscolarDB.dbo.Horarios (IdCurso, DiaSemana, HoraInicio, HoraFin, Aula)
    VALUES ((@i % 500)+1,
            CASE WHEN @i % 5 = 0 THEN 'Lunes | Matutino'
                 WHEN @i % 5 = 1 THEN 'Martes | Vespertino'
                 WHEN @i % 5 = 2 THEN 'Miércoles | Matutino'
                 WHEN @i % 5 = 3 THEN 'Jueves | Vespertino'
                 ELSE 'Viernes | Intensivo' END,
            '08:00', '10:00',
            'Aula_' + CAST((@i % 20)+1 AS NVARCHAR(10)) + ' | Edificio_' + CAST((@i % 3)+1 AS NVARCHAR(10)));
    SET @i += 1;
END
GO

--Asistencias (alumno, curso, fecha, presente)
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO EscolarDB.dbo.Asistencias (IdAlumno, IdCurso, Fecha, Presente)
    VALUES ((@i % 500)+1,
            (@i % 500)+1,
            DATEADD(DAY, -@i, GETDATE()),
            CASE WHEN @i % 2 = 0 THEN 1 ELSE 0 END);
    SET @i += 1;
END
GO
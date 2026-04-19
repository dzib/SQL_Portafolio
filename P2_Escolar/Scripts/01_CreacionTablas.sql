CREATE TABLE EscolarDB.dbo.Alumnos (
	IdAlumno INT PRIMARY KEY IDENTITY,
	Nombre NVARCHAR(100),
	Carrera NVARCHAR(50)
);

CREATE TABLE EscolarDB.dbo.Cursos (
	IdCurso INT PRIMARY KEY IDENTITY,
	Nombre NVARCHAR(100),
	Creditos INT
);

CREATE TABLE EscolarDB.dbo.Calificaciones (
	IdCalificaciones INT PRIMARY KEY IDENTITY,
	IdAlumno INT FOREIGN KEY REFERENCES Alumnos(IdAlumno),
	IdCurso INT FOREIGN KEY REFERENCES Cursos(IdCurso),
	Nota DECIMAL(4,2)
);

CREATE TABLE EscolarDB.dbo.Profesores (
    IdProfesor INT PRIMARY KEY IDENTITY,
    Nombre NVARCHAR(100),
    Especialidad NVARCHAR(100)
);

CREATE TABLE EscolarDB.dbo.Departamentos (
    IdDepartamento INT PRIMARY KEY IDENTITY,
    Nombre NVARCHAR(100)
);

CREATE TABLE EscolarDB.dbo.CursosProfesores (
    IdCurso INT FOREIGN KEY REFERENCES Cursos(IdCurso),
    IdProfesor INT FOREIGN KEY REFERENCES Profesores(IdProfesor),
    PRIMARY KEY (IdCurso, IdProfesor)
);

CREATE TABLE EscolarDB.dbo.Horarios (
    IdHorario INT PRIMARY KEY IDENTITY,
    IdCurso INT FOREIGN KEY REFERENCES Cursos(IdCurso),
    DiaSemana NVARCHAR(20),
    HoraInicio TIME,
    HoraFin TIME
);

CREATE TABLE EscolarDB.dbo.Asistencias (
    IdAsistencia INT PRIMARY KEY IDENTITY,
    IdAlumno INT FOREIGN KEY REFERENCES Alumnos(IdAlumno),
    IdCurso INT FOREIGN KEY REFERENCES Cursos(IdCurso),
    Fecha DATE,
    Presente BIT
);

SELECT A.Nombre, C.Nombre, Nota
FROM EscolarDB.dbo.Calificaciones Cal
JOIN EscolarDB.dbo.Alumnos A ON Cal.IdAlumno = A.IdAlumno
JOIN EscolarDB.dbo.Cursos C ON Cal.IdCurso = C.IdCurso;
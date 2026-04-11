-- Insertar alumnos ( Alumnos, Carreras, fecha de inscripción)
INSERT INTO EscolarDB.dbo.Alumnos (Nombre, Carrera, FechaInscripcion)
VALUES 
('Ana López | Grupo A', 'Ingeniería en Sistemas', GETDATE()),
('Carlos Méndez | Grupo B', 'Ingeniería Industrial', DATEADD(DAY,-1,GETDATE())),
('María Torres | Grupo C', 'Administración de Empresas', DATEADD(DAY,-2,GETDATE())),
('José Ramírez | Grupo D', 'Contaduría Pública', DATEADD(DAY,-3,GETDATE())),
('Lucía Hernández | Grupo E', 'Ingeniería Mecatrónica', DATEADD(DAY,-4,GETDATE())),
('Pedro González | Grupo F', 'Ingeniería Civil', DATEADD(DAY,-5,GETDATE())),
('Fernanda Díaz | Grupo G', 'Ingeniería Química', DATEADD(DAY,-6,GETDATE())),
('Miguel Castro | Grupo H', 'Economía', DATEADD(DAY,-7,GETDATE())),
('Laura Pérez | Grupo I', 'Mercadotecnia', DATEADD(DAY,-8,GETDATE())),
('Andrés Martínez | Grupo J', 'Ingeniería Electrónica', DATEADD(DAY,-9,GETDATE()));

-- Insertar cursos (Nombre, créditos, fecha de creación)
INSERT INTO EscolarDB.dbo.Cursos (Nombre, Creditos, FechaCreacion)
VALUES 
('Bases de Datos | Nivel Avanzado', 6, GETDATE()),
('Programación en Python | Nivel Intermedio', 5, DATEADD(DAY,-1,GETDATE())),
('Gestión de Proyectos | Metodología Agile', 4, DATEADD(DAY,-2,GETDATE())),
('Inteligencia Artificial | Machine Learning', 6, DATEADD(DAY,-3,GETDATE())),
('Redes de Computadoras | Seguridad', 5, DATEADD(DAY,-4,GETDATE())),
('Finanzas Corporativas | Análisis', 4, DATEADD(DAY,-5,GETDATE())),
('Marketing Digital | Estrategias', 3, DATEADD(DAY,-6,GETDATE())),
('Ingeniería de Software | Scrum', 5, DATEADD(DAY,-7,GETDATE())),
('Estadística Aplicada | Big Data', 6, DATEADD(DAY,-8,GETDATE())),
('Economía Internacional | Comercio', 4, DATEADD(DAY,-9,GETDATE()));
/* 
==========================================================================================================================================================
PROYECTO: P2_Escolar - Sistema de Gestión Académica
FASE: 3 -  Stress Test & Data Quality Shield
AUTOR: Alberto Dzib
VERSIÓN: 2.2 (Enterprise Load Simulation)
DESCRIPCIÓN: 
    - Inserción masiva de 10,000 alumnos usando bucle WHILE.
    - Implementación de transacciones para asegurar la integridad.
    - Generación de datos no atómicos en columna Metadata_ETL para futuro proceso de limpieza.
==========================================================================================================================================================
*/

USE P2_EscolarDB;
GO

-- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
-- -- 1. VARIABLES DE BUCLE Y MÉTRICAS PARA CONTROL.
-- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
SET NOCOUNT ON;                     -- Para reducir tiempo se suprime el mensaje de "(1 filas afectadas)".
SET XACT_ABORT ON;                  -- Para asegura que errores aborten la transacción.

BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Parámetros de stress
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();    
    DECLARE @NProf INT = 10000;    -- Volumen de profesores a agregar en stress.
    DECLARE @MaxProfesorNuevo INT = ISNULL((SELECT MAX(ProfesorID) FROM Catalogos.Profesores), 1);
    DECLARE @NAluRun INT = 10000000;   -- Volumen de alumnos a agregar para stress.
    DECLARE @MaxAlumnos INT = (SELECT ISNULL(UltimoID,0) FROM Control.Checkpoints WHERE Entidad = 'Alumnos') + @NAluRun;
    DECLARE @NombreBase NVARCHAR(50) = ISNULL(CHOOSE(FLOOR(RAND()*3)+1,'Estudiante', 'Alumno', 'Candidato'),'User');
    DECLARE @MinAsis INT = 2;
    DECLARE @MaxAsis INT = 6;
    DECLARE @MinParciales INT = 2, @MaxParciales INT = 3;
    DECLARE @NCursos INT = 1000;  -- Volumen de cursos a agregar.
    DECLARE @NMat INT = 200;    -- Volumen de materias a agregar.


    DECLARE @MaxNotas INT = 5000000;



-- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
-- -- > 2. PRIMERA LECTURA: De checkpoints actuales para control de FK (defensivo: 0).
-- -- ---------------------------------------------------------------------------------------------------------------------------------------------------

    DECLARE @UltProf INT = ISNULL((SELECT UltimoID FROM Control.Checkpoints WHERE Entidad = 'Profesores'),0);
    DECLARE @UltCurso INT = ISNULL((SELECT UltimoID FROM Control.Checkpoints WHERE Entidad = 'Cursos'),0);
    DECLARE @UltMat INT = ISNULL((SELECT UltimoID FROM Control.Checkpoints WHERE Entidad = 'Materias'),0);
    DECLARE @UltAlu INT = ISNULL((SELECT UltimoID FROM Control.Checkpoints WHERE Entidad = 'Alumnos'),0);
    DECLARE @MaxDepto INT = ISNULL((SELECT MAX(DeptoID) FROM Catalogos.Departamentos), 1);

    PRINT '--------------------------------------------------------------------------------------------------';
    PRINT '🚀 Iniciando Stress Test en P2_EscolarDB...' + CAST(SYSUTCDATETIME() AS VARCHAR);
    PRINT '--------------------------------------------------------------------------------------------------';

--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 3. POBLADO DE DEPARTAMENTOS Y PROFESORES.
--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '--------------------------------------------------------------------------------------------------';
    PRINT '🏢 Diversificando con Departamentos y con Profesores Nuevos...';
    PRINT '--------------------------------------------------------------------------------------------------';

        INSERT INTO Catalogos.Departamentos
        (Nombre, PresupuestoAnual)
    VALUES
        ('Departamento de Ciencias Exactas y Naturales', 800000),
        ('Departamento de Ciencias Económico-Administrativas', 200000),
        ('Departamento de Artes y Diseño', 450000),
        ('Departamento de Ciencias de la Salud Pública', 150000);

        ;WITH nums AS (
            SELECT TOP (@NProf) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
            FROM sys.all_columns
        )
        INSERT INTO Catalogos.Profesores (Nombre, Email, DeptoID)
        SELECT N.Nombre, N.Email, N.DeptoID
        FROM ( --Insertar solo si no existe el email (Idempotente).
            SELECT
                'Prof_Nf_' + CAST(@UltProf + rn AS VARCHAR(10)) AS Nombre,
                'prof' + CAST(@UltProf + rn AS VARCHAR(10)) + '@escolar.edu' AS Email,
                (ABS(CHECKSUM(NEWID())) % @MaxDepto) + 1 AS DeptoID
            FROM nums
        ) N
        WHERE NOT EXISTS (SELECT 1 FROM Catalogos.Profesores P WHERE P.Email = N.Email);


--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 4. DIVERSIFICACIÓN DE CURSOS Y MATERIAS (Asignando ProfesorID entre existentes)
--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
        ;WITH curs AS (
            SELECT TOP (@NCursos) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rnc
            FROM sys.all_columns
        )
        INSERT INTO Catalogos.Cursos (Nombre, Creditos)
        SELECT Nc.Nombre, Nc.Creditos
        FROM (
            SELECT
                'NCurso_' + CAST(@UltCurso + rnc AS VARCHAR(10)) AS Nombre,
                (ABS(CHECKSUM(NEWID())) % 4) + 3 AS Creditos
            FROM curs
        ) Nc
        WHERE NOT EXISTS (SELECT 1 FROM Catalogos.Cursos C WHERE C.Nombre = Nc.Nombre);

        DECLARE @InsertedCurs INT = (SELECT COUNT(*) FROM Catalogos.Cursos);
        IF @InsertedCurs = 0
        BEGIN
            RAISERROR('No se insertaron Cursos en Catalogos.Cursos. Abortar Insersion',16,1);
            RETURN;
        END
        PRINT 'Cursos insertados: ' + CAST(@InsertedCurs AS VARCHAR(12));


        ;WITH mat AS (
            SELECT TOP (@NMat) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rnm
            FROM sys.all_columns
        )
        INSERT INTO Operaciones.Materias (Nombre, Creditos, ProfesorID)
        SELECT Nm.Nombre, Nm.Creditos, Nm.ProfesorID
        FROM (
            SELECT
                'NMateria_' + CAST(@UltMat + rnm AS VARCHAR(10)) AS Nombre,
                (ABS(CHECKSUM(NEWID())) % 4) + 3 AS Creditos,
                (ABS(CHECKSUM(NEWID())) % @MaxProfesorNuevo) + 1 AS ProfesorID
            FROM mat
        ) Nm
        WHERE NOT EXISTS (SELECT 1 FROM Operaciones.Materias M WHERE M.Nombre = Nm.Nombre);

        DECLARE @InsertedMat INT = (SELECT COUNT(*) FROM Operaciones.Materias);
        IF @InsertedMat = 0
        BEGIN
            RAISERROR('No se insertaron Materias en Operaciones.M. Abortar Insersion',16,1);
            RETURN;
        END
        PRINT 'Materias insertadas: ' + CAST(@InsertedMat AS VARCHAR(12));

--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 5. CARGA MASIVA DE ALUMNOS.
--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
        PRINT '--------------------------------------------------------------------------------------------------';
        PRINT '👥 Generando ' + FORMAT(@MaxAlumnos, 'N0')+ ' alumnos con blindaje de nulos...';
        PRINT '--------------------------------------------------------------------------------------------------';

        -- Paso 1) Materializar Catalogos.Carreras en tabla temporal (blindaje lógico).
        IF OBJECT_ID('tempdb..#CarrList') IS NOT NULL DROP TABLE #CarrList;

        SELECT CarreraID, DeptoID,
            ROW_NUMBER() OVER (ORDER BY CarreraID) AS CarrRow
        INTO #CarrList
        FROM Catalogos.Carreras
        ;
        DECLARE @CarrCount INT = (SELECT COUNT(*) FROM #CarrList);
        IF @CarrCount = 0
        BEGIN
            RAISERROR('No hay filas en Catalogos.Carreras. Abortando inserción de alumnos.',16,1);
            RETURN;
        END

        -- Paso 2) Generador de filas rápido y mapeo por índice (Sin aplicar un ORDER BY NEWID() por carreras ya que es costoso en tablas grandes.)
        ;WITH RandRows AS (
            SELECT TOP (@NAluRun)
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rna
            FROM sys.all_columns
        )
        INSERT INTO Catalogos.Alumnos (Nombre, Email, FechaNacimiento, MetaData_ETL, CarreraID, DeptoID)
        SELECT
            -- Nombre y email.
            @NombreBase + '_ID_' + CAST(@UltAlu + R.rna AS VARCHAR(10)) AS Nombre,
            LOWER(@NombreBase) + CAST(@UltAlu + R.rna AS VARCHAR(10)) + '@escolar.edu' AS Email,
            -- FechaNacimiento aleatoria.
            DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 36500, GETDATE()) AS FechaNacimiento,
            -- MetaData_ETL.
            FORMAT(DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 1825, GETDATE()), 'yyyy-MM-dd') + ' | ' +
                CASE (ABS(CHECKSUM(NEWID())) % 7)
                    WHEN 0 THEN 'REGULAR' WHEN 1 THEN 'IRREGULAR' WHEN 2 THEN 'CONDICIONAL'
                    WHEN 3 THEN 'BAJA_TEMP' WHEN 4 THEN 'BAJA_DEFI' WHEN 5 THEN 'EGRESADO' ELSE 'TITULADO'
                END + ' | ' + CAST((ABS(CHECKSUM(NEWID())) % 41) + 60 AS VARCHAR(5)) AS MetaData_ETL,
            C.CarreraID,
            C.DeptoID
        FROM RandRows R
        JOIN #CarrList C
            ON C.CarrRow = ((R.rna - 1) % @CarrCount) + 1;
        -- Aplicando la técnica modular evita ordenar aleatoriamente la tabla de carreras cada vez y es mucho más escalable.

---- -- ------------------------------------------------------------------------------------------------------------------------------------------------
---- -- > 6. SEGUNDA ACTUALIZACION: Para checkpoints intermedios de proceso posterio a la creación de catálogos nuevos.
---- -- ------------------------------------------------------------------------------------------------------------------------------------------------
        MERGE Control.Checkpoints AS C
        USING (SELECT 'Profesores' AS Entidad, ISNULL(MAX(ProfesorID),0) AS UltimoID FROM Catalogos.Profesores) AS S
        ON C.Entidad = S.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = S.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (S.Entidad, S.UltimoID, SYSUTCDATETIME());

        MERGE Control.Checkpoints AS C2
        USING (SELECT 'Cursos' AS Entidad, ISNULL(MAX(CursoID),0) AS UltimoID FROM Catalogos.Cursos) AS S2
        ON C2.Entidad = S2.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = S2.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (S2.Entidad, S2.UltimoID, SYSUTCDATETIME());

        MERGE Control.Checkpoints AS C3
        USING (SELECT 'Materias' AS Entidad, ISNULL(MAX(MateriaID),0) AS UltimoID FROM Operaciones.Materias) AS S3
        ON C3.Entidad = S3.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = S3.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (S3.Entidad, S3.UltimoID, SYSUTCDATETIME());

        MERGE Control.Checkpoints AS C4
        USING (SELECT 'Alumnos' AS Entidad, ISNULL(MAX(AlumnoID),0) AS UltimoID FROM Catalogos.Alumnos) AS S4
        ON C4.Entidad = S4.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = S4.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (S4.Entidad, S4.UltimoID, SYSUTCDATETIME());

--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 7. INSCRIPCIONES MASIVAS (Se asigna MateriaID y CursoID (CursoID elegido aleatoriamente desde Catalogos.Cursos).
--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------

        -- Paso 1.1) Usamos una tabla temporal para capturar inscripciones creadas en este run.
        IF OBJECT_ID('tempdb..#NewIns') IS NOT NULL DROP TABLE #NewIns;
        CREATE TABLE #NewIns (
            InscripcionID INT,
            AlumnoID INT,
            MateriaID INT,
            CursoID INT,
            CicloEscolar NVARCHAR(20),
            NotaFinal DECIMAL(5,2)
        );

        -- Paso 1.2) Materializar Cursos y Materias (blindaje).
        IF OBJECT_ID('tempdb..#Cursos') IS NOT NULL DROP TABLE #Cursos;
        SELECT CursoID, ROW_NUMBER() OVER (ORDER BY CursoID) AS CursoRow
        INTO #Cursos
        FROM Catalogos.Cursos;

        DECLARE @CursoCount INT = (SELECT COUNT(*) FROM #Cursos);
        IF @CursoCount = 0
        BEGIN
            RAISERROR('No hay cursos en Catalogos.Cursos. Abortando.',16,1);
            RETURN;
        END

        IF OBJECT_ID('tempdb..#Materias') IS NOT NULL DROP TABLE #Materias;
        SELECT MateriaID, ROW_NUMBER() OVER (ORDER BY MateriaID) AS MateriaRow
        INTO #Materias
        FROM Operaciones.Materias;

        DECLARE @MateriaCount INT = (SELECT COUNT(*) FROM #Materias);
        IF @MateriaCount = 0
        BEGIN
            RAISERROR('No hay materias en Operaciones.Materias. Abortando.',16,1);
            RETURN;
        END
        PRINT 'Cursos materializados: ' + CAST(@CursoCount AS VARCHAR(10)) + ' | Materias: ' + CAST(@MateriaCount AS VARCHAR(10));

        -- Paso 2) CTE con extracción robusta del estatus desde MetaData_ETL (seguro frente a notas extra).
        ;WITH AluEstatus AS (
        SELECT TOP (@NAluRun) A.AlumnoID, A.MetaData_ETL,
            -- Estatus normalizado (versión robusta).
            CASE
                WHEN UPPER(LTRIM(RTRIM(SUBSTRING(A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1,
                    CASE WHEN CHARINDEX('|',A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1)=0 THEN LEN(A.MetaData_ETL) 
                        ELSE CHARINDEX('|',A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1) - CHARINDEX('|',A.MetaData_ETL) - 1 END
                )))) LIKE '%REGUL%' THEN 'REGULAR'
                WHEN UPPER(LTRIM(RTRIM(SUBSTRING(A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1,
                    CASE WHEN CHARINDEX('|',A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1)=0 THEN LEN(A.MetaData_ETL) 
                        ELSE CHARINDEX('|',A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1) - CHARINDEX('|',A.MetaData_ETL) - 1 END
                )))) LIKE '%IRREG%' THEN 'IRREGULAR'
                WHEN UPPER(LTRIM(RTRIM(SUBSTRING(A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1,
                    CASE WHEN CHARINDEX('|',A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1)=0 THEN LEN(A.MetaData_ETL) 
                        ELSE CHARINDEX('|',A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1) - CHARINDEX('|',A.MetaData_ETL) - 1 END
                )))) LIKE '%CONDIC%' THEN 'CONDICIONAL'
                ELSE NULL
            END AS EstatusAcademico
        FROM Catalogos.Alumnos A
        ORDER BY NEWID()
        )
        INSERT INTO Operaciones.Inscripciones (AlumnoID, MateriaID, CursoID, CicloEscolar, NotaFinal)
        OUTPUT inserted.InscripcionID, inserted.AlumnoID, inserted.MateriaID, inserted.CursoID, inserted.CicloEscolar, inserted.NotaFinal
        INTO #NewIns (InscripcionID, AlumnoID, MateriaID, CursoID, CicloEscolar, NotaFinal)
        SELECT A.AlumnoID,
            M.MateriaID,
            C.CursoID,
            CAST(YEAR(TRY_CAST(LEFT(A.MetaData_ETL,10) AS DATE)) AS VARCHAR(4)) + '-' +
                CASE WHEN MONTH(TRY_CAST(LEFT(A.MetaData_ETL,10) AS DATE)) <= 6 THEN '1' ELSE '2' END,
            NULL
        FROM AluEstatus A
        CROSS APPLY (
            -- generar N filas por alumno (expansión); aquí usamos sys.all_columns para repetir
            SELECT TOP ((CASE WHEN A.EstatusAcademico='REGULAR' THEN 6 WHEN A.EstatusAcademico='IRREGULAR' THEN 3 ELSE 4 END)) 1 AS dummy
            FROM sys.all_columns
        ) rep
        -- Elegir materia por índice modular (evita ORDER BY NEWID() en la tabla completa)-- Se asume #Cursos y #Materias ya materializadas con CursoRow y MateriaRow.
        CROSS APPLY (
            SELECT MateriaID
            FROM #Materias
            WHERE MateriaRow = ((ABS(CHECKSUM(CONCAT(A.AlumnoID,rep.dummy,NEWID()))) % @MateriaCount) + 1)
        ) M
        -- Elegir curso por índice modular (JOIN directo, CursoRow es único) ---Solo inserta un curso 
        JOIN #Cursos C ON C.CursoRow = ((ABS(CHECKSUM(CONCAT(A.AlumnoID,NEWID()))) % @CursoCount) + 1)
        WHERE 1=1;

        DECLARE @InsertedIns INT = (SELECT COUNT(*) FROM #NewIns);
        PRINT 'Inscripciones creadas en este run: ' + CAST(@InsertedIns AS VARCHAR(12));

        IF @InsertedIns = 0
            BEGIN
            RAISERROR('No se generaron inscripciones en este run. Revisar AluEstatus/Cantidad.',16,1);
        END

------- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
------- -- 8. CARGA DE CALIFICACIONES PARCIALES (CROSS-JOIN DE ALTO RENDIMIENTO) respetando CHK_Parcial (1..3).
------- -- Variante: 1-3 parciales aleatorios por inscripción.
------- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
        INSERT INTO Operaciones.Calificaciones (InscripcionID, ParcialNumero, AlumnoID, CursoID, Nota, FechaAplicacion)
        SELECT N.InscripcionID,
            P.ParcialNum,
            N.AlumnoID,
            N.CursoID,
            CAST((ABS(CHECKSUM(NEWID())) % 101) AS DECIMAL(5,2)),
            SYSUTCDATETIME()
        FROM #NewIns N
        CROSS JOIN (VALUES (1),(2),(3)) AS P(ParcialNum)
        LEFT JOIN Operaciones.Calificaciones C
            ON C.InscripcionID = N.InscripcionID AND C.ParcialNumero = P.ParcialNum
        WHERE C.CalificacionID IS NULL;

        PRINT 'Parciales insertados para inscripciones nuevas.';

------ -- ---------------------------------------------------------------------------------------------------------------------------------------------------
------ -- 9. AJUSTE: Actualizamos la NotaFinal en Inscripciones como promedio simple de parciales.
------ -- ---------------------------------------------------------------------------------------------------------------------------------------------------
        UPDATE I
        SET NotaFinal = C.Promedio
        FROM Operaciones.Inscripciones I
        JOIN (
            SELECT InscripcionID, CAST(AVG(Nota) AS DECIMAL(5,2)) AS Promedio
            FROM Operaciones.Calificaciones
            GROUP BY InscripcionID
        ) C ON I.InscripcionID = C.InscripcionID;

------- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
------- -- 10. CARGA ASISTENCIAS BASADO EN CICLO ESCOLAR (Fechas dentro del semestre).
------- -- ---------------------------------------------------------------------------------------------------------------------------------------------------
        -- Se genera asistencias por InscripcionID dentro del semestre (2-4 asistencias por inscripción).
        ;WITH Sem AS (
            SELECT N.InscripcionID, N.AlumnoID, N.CursoID, N.CicloEscolar,
                CASE WHEN RIGHT(N.CicloEscolar,2) = '-1' THEN DATEFROMPARTS(CAST(LEFT(N.CicloEscolar,4) AS INT),1,1)
                        ELSE DATEFROMPARTS(CAST(LEFT(N.CicloEscolar,4) AS INT),7,1) END AS SemInicio,
                CASE WHEN RIGHT(N.CicloEscolar,2) = '-1' THEN DATEFROMPARTS(CAST(LEFT(N.CicloEscolar,4) AS INT),6,30)
                        ELSE DATEFROMPARTS(CAST(LEFT(N.CicloEscolar,4) AS INT),12,31) END AS SemFin
            FROM #NewIns N
        )
        INSERT INTO Operaciones.Asistencias (InscripcionID, AlumnoID, CursoID, FechaAsistencia, Presente)
        SELECT S.InscripcionID, S.AlumnoID, S.CursoID,
            CAST(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % (DATEDIFF(DAY, S.SemInicio, S.SemFin) + 1), S.SemInicio) AS DATE),
            CASE WHEN (ABS(CHECKSUM(NEWID())) % 10) < 8 THEN 1 ELSE 0 END
        FROM Sem S
        CROSS APPLY (SELECT TOP ((ABS(CHECKSUM(NEWID())) % 3) + 2) 1 AS x FROM sys.all_columns) r
        LEFT JOIN Operaciones.Asistencias A
            ON A.InscripcionID = S.InscripcionID
            AND A.FechaAsistencia = CAST(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % (DATEDIFF(DAY, S.SemInicio, S.SemFin) + 1), S.SemInicio) AS DATE)
        WHERE A.AsistenciaID IS NULL;

        PRINT 'Asistencias generadas para inscripciones nuevas.';
        PRINT '--- Bloque Inscripciones/Parciales/Asistencias finalizado exitosamente.---';



----- -----------------------------------------------------------------------------------------------------------------------------------------------------
----- -- > 11. ULTIMA ACTUALIZACIÓN: Se cargan los checkpoints finales del proceso.
----- -----------------------------------------------------------------------------------------------------------------------------------------------------
        -- Actualizamos el Control.Checkpoints de Profesores.
        MERGE Control.Checkpoints AS Cx
        USING (SELECT 'Profesores' AS Entidad, ISNULL(MAX(ProfesorID),0) AS UltimoID FROM Catalogos.Profesores) AS Sx
        ON Cx.Entidad = Sx.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = Sx.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (Sx.Entidad, Sx.UltimoID, SYSUTCDATETIME());

        -- Actualizamos el Control.Checkpoints de Cursos.
        MERGE Control.Checkpoints AS Cx2
        USING (SELECT 'Cursos' AS Entidad, ISNULL(MAX(CursoID),0) AS UltimoID FROM Catalogos.Cursos) AS Sx2
        ON Cx2.Entidad = Sx2.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = Sx2.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (Sx2.Entidad, Sx2.UltimoID, SYSUTCDATETIME());

        -- Actualizamos el Control.Checkpoints de Materias.
        MERGE Control.Checkpoints AS Cx3
        USING (SELECT 'Materias' AS Entidad, ISNULL(MAX(MateriaID),0) AS UltimoID FROM Operaciones.Materias) AS Sx3
        ON Cx3.Entidad = Sx3.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = Sx3.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (Sx3.Entidad, Sx3.UltimoID, SYSUTCDATETIME());

        -- Actualizamos el Control.Checkpoints de Alumnos.
        MERGE Control.Checkpoints AS Cx4
        USING (SELECT 'Alumnos' AS Entidad, ISNULL(MAX(AlumnoID),0) AS UltimoID FROM Catalogos.Alumnos) AS Sx4
        ON Cx4.Entidad = Sx4.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = Sx4.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (Sx4.Entidad, Sx4.UltimoID, SYSUTCDATETIME());

        -- Actualizamos el Control.Checkpoints de Inscripciones.
        MERGE Control.Checkpoints AS Ckp
        USING (SELECT 'Inscripciones' AS Entidad, ISNULL(MAX(InscripcionID),0) AS UltimoID FROM Operaciones.Inscripciones) AS S
        ON Ckp.Entidad = S.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = S.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (S.Entidad, S.UltimoID, SYSUTCDATETIME());

        -- Actualizamos el Control.Checkpoints de Calificaciones.
        MERGE Control.Checkpoints AS Ckp2
        USING (SELECT 'Calificaciones' AS Entidad, ISNULL(MAX(CalificacionID),0) AS UltimoID FROM Operaciones.Calificaciones) AS S2
        ON Ckp2.Entidad = S2.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = S2.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (S2.Entidad, S2.UltimoID, SYSUTCDATETIME());

        -- Actualizamos el Control.Checkpoints de Asistencias.
        MERGE Control.Checkpoints AS Ckp3
        USING (SELECT 'Asistencias' AS Entidad, ISNULL(MAX(AsistenciaID),0) AS UltimoID FROM Operaciones.Asistencias) AS S3
        ON Ckp3.Entidad = S3.Entidad
        WHEN MATCHED THEN UPDATE SET UltimoID = S3.UltimoID, FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (S3.Entidad, S3.UltimoID, SYSUTCDATETIME());

        -- Aplicamos Limpieza temporal a nuesta tabla de Inscripciones.
        DROP TABLE #NewIns;
        DROP TABLE #Cursos;
        DROP TABLE #Materias;

        COMMIT;
------- --------------------------------------------------------------------------------------------------------------------------------------------------------
------- -- 12. MÉTRICAS FINALES.
------- ---------------------------------------------------------------------------------------------------------------------------------------------------------
        DECLARE @EndTime DATETIME2 = SYSUTCDATETIME();
        PRINT '';
        PRINT '=====================================================';
        PRINT '       ✅ RESUMEN DE EJECUCIÓN EXITOSA';
        PRINT '=====================================================';
        PRINT '✅ Alumnos Procesados:   ' + FORMAT(@MaxAlumnos, 'N0');
        PRINT '📝 Departamentos Inyectados: ' + FORMAT(@MaxDepto, 'N0');
        PRINT '📝 Profesores Inyectados: ' + FORMAT(@MaxProfesorNuevo, 'N0');
        PRINT '📝 Inscripciones Inyectadas: ' + FORMAT(@InsertedIns, 'N0');
        PRINT '📝 Cursos Inyectados:    ' + FORMAT(@InsertedCurs, 'N0');
        PRINT '📝 Materias Inyectadas:     ' + FORMAT(@InsertedMat, 'N0');
        PRINT '⏱️ Tiempo de Respuesta:  ' + FORMAT(DATEDIFF(MILLISECOND, @StartTime, SYSUTCDATETIME()), 'N0') + ' ms';
        PRINT '⏱️ Tiempo de Ejecución: ' + FORMAT(DATEDIFF(MILLISECOND, @StartTime, @EndTime), 'N0') + ' ms';
        PRINT '📅 Finalizado el:        ' + CAST(SYSDATETIME() AS VARCHAR);
        PRINT '=====================================================';
        PRINT '';

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000)=ERROR_MESSAGE(), @ErrLine INT = ERROR_LINE();
        PRINT '';
        PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
        PRINT '=====================================================';
        PRINT '          ❌ ERROR DETECTADO - TRANSACCIÓN REVERTIDA';
        PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
        PRINT '📍 Línea del Error: ' + CAST(ERROR_LINE() AS VARCHAR); -- Línea donde ocurrió el error.
        PRINT '🔢 Código de Error:   ' + CAST(ERROR_NUMBER() AS VARCHAR); -- Código de error específico.
        PRINT '⚙️ Procedimiento:     ' + ISNULL(ERROR_PROCEDURE(), 'Script Directo'); -- Procedimiento donde ocurrió el error.
        PRINT '    ERROR: ' + ISNULL(@ErrMsg,'(sin mensaje)') + ' en linea ' + CAST(@ErrLine AS VARCHAR(10));
        THROW; -- Re-lanza para que el caller vea el erro
        PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
END CATCH
GO
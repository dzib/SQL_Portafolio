/* 
==============================================================================================================================================================================================
PROYECTO: P2_Escolar - Sistema de Gestión Académica
FASE: 3 -  Stress Test & Data Quality Shield
AUTOR: Alberto Dzib
VERSIÓN: 2.3 (Enterprise Load Simulation por lotes, determinista)
DESCRIPCIÓN: 
    - Script de stress test adaptado para cargas grandes. Procesa inscripciones, asistencias y actualización de NotaFinal en lotes para reducir uso de log y evitar timeouts. 
    - Con generación determinista para asistencias y evita NEWID() en comprobaciones críticas.
    - Generación de datos no atómicos en columna Metadata_ETL para futuro proceso de limpieza.
===============================================================================================================================================================================================
*/

USE P2_EscolarDB;
GO
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- -- VARIABLES DE BUCLE Y MÉTRICAS PARA CONTROL.
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SET NOCOUNT ON;
-- Para reducir tiempo se suprime el mensaje de "(1 filas afectadas)".
SET XACT_ABORT ON;
-- Para asegura que errores aborten la transacción.

-- --------------------------------------------
-- Parámetros (Ajustables para pruebas).
-- --------------------------------------------
DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();
DECLARE @NProf INT = 1000;
-- Volumen de profesores a agregar en stress.
DECLARE @NAluRun INT = 10000;
-- Volumen de alumnos muestreados para inscripciones por batch
DECLARE @MinParciales INT = 2, @MaxParciales INT = 3;
DECLARE @MaxProfesorNuevo INT = ISNULL((SELECT MAX(ProfesorID)
FROM Catalogos.Profesores), 1);
DECLARE @MinAsis INT = 2, @MaxAsis INT = 4;
-- Rango de asistencias por inscripción.
DECLARE @NCursos INT = 1000;
-- Volumen de cursos a agregar.
DECLARE @NMat INT = 20000;
-- Volumen de materias a agregar.

-- Parámetros de stress inserción masiva por lotes.
DECLARE @BatchSize INT = 500;
-- Tamaño de lote para operaciones pesadas.
-- Parámetros de pausa entre batches: usar VARCHAR para WAITFOR DELAY
DECLARE @PauseBetweenBatches VARCHAR(8) = '00:00:01';
-- formato hh:mm:ss
-- Pausa de 1 segundo entre lotes para reducir presión en el log y evitar timeouts.

BEGIN TRY
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- -- > PRIMERA LECTURA: De checkpoints actuales para control de FK (defensivo: 0).
--- -- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    DECLARE @UltProf INT = ISNULL((SELECT UltimoID
FROM Control.Checkpoints
WHERE Entidad = 'Profesores'),0);
    DECLARE @UltAlu INT = ISNULL((SELECT UltimoID
FROM Control.Checkpoints
WHERE Entidad = 'Alumnos'),0);
    DECLARE @NombreBase NVARCHAR(50) = ISNULL(CHOOSE(FLOOR(RAND()*2)+1,'Alumno', 'Candidato'),'User');
    DECLARE @UltCurso INT = ISNULL((SELECT UltimoID
FROM Control.Checkpoints
WHERE Entidad = 'Cursos'),0);
    DECLARE @UltMat INT = ISNULL((SELECT UltimoID
FROM Control.Checkpoints
WHERE Entidad = 'Materias'),0);

    PRINT '--------------------------------------------------------------------------------------------------';
    PRINT '🚀 Iniciando Stress Test en P2_EscolarDB...' + CAST(SYSUTCDATETIME() AS VARCHAR);
    PRINT '--------------------------------------------------------------------------------------------------';

--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 1. POBLADO DE DEPARTAMENTOS.
--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '--------------------------------------------------------------------------------------------------';
    PRINT '🏢 Diversificando de Departamentos..'
    PRINT '--------------------------------------------------------------------------------------------------';

    INSERT INTO Catalogos.Departamentos
    (Nombre, PresupuestoAnual)
VALUES
    ('Departamento de Ciencias Exactas y Naturales', 800000),
    ('Departamento de Ciencias Económico-Administrativas', 200000),
    ('Departamento de Artes y Diseño', 450000),
    ('Departamento de Ciencias de la Salud Pública', 150000);

    DECLARE @InsertedDeptos INT = (SELECT COUNT(*)
FROM Catalogos.Departamentos);
    IF @InsertedDeptos = 0
    BEGIN
    RAISERROR('No se insertaron departamentos en Catalogos.Departamentos. Abortar Insersion',16,1);
    RETURN;
END
    PRINT 'Departamentos insertados: ' + FORMAT(@InsertedDeptos, 'N0');

--- -------------------------------------------------------------------------
--- -- 2. PREPARACIÓN: MATERIALIZAR CATÁLOGOS EN TABLAS TEMPORALES.
--- -------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#CarrList') IS NOT NULL DROP TABLE #CarrList;
    SELECT CarreraID, DeptoID, ROW_NUMBER() OVER (ORDER BY CarreraID) AS CarrRow
INTO #CarrList
FROM Catalogos.Carreras;

    IF OBJECT_ID('tempdb..#Cursos') IS NOT NULL DROP TABLE #Cursos;
    SELECT CursoID, ROW_NUMBER() OVER (ORDER BY CursoID) AS CursoRow
INTO #Cursos
FROM Catalogos.Cursos;

    IF OBJECT_ID('tempdb..#Materias') IS NOT NULL DROP TABLE #Materias;
    SELECT MateriaID, ROW_NUMBER() OVER (ORDER BY MateriaID) AS MateriaRow
INTO #Materias
FROM Operaciones.Materias;

    DECLARE @CarrCount INT = (SELECT COUNT(*)
FROM #CarrList);
    DECLARE @CursoCount INT = (SELECT COUNT(*)
FROM #Cursos);
    DECLARE @MateriaCount INT = (SELECT COUNT(*)
FROM #Materias);

    IF @CarrCount = 0 OR @CursoCount = 0 OR @MateriaCount = 0
    BEGIN
    RAISERROR('Faltan catálogos (Carreras/Cursos/Materias). Abortando.',16,1);
END
    PRINT 'Catalogos materializados: Carreras=' + FORMAT(@CarrCount, 'N0')+ ' | Cursos=' + FORMAT(@CursoCount, 'N0') + ' | Materias=' + FORMAT(@MateriaCount, 'N0');

--- -------------------------------------------------------------------------
--- -- 3. GENERACIÓN DE PROFESORES (idempotente).
--- -------------------------------------------------------------------------
    ;WITH
    nums
    AS
    (
        SELECT TOP (@NProf)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rnp
        FROM sys.all_columns
    ),
    NewProfs
    AS
    (
        SELECT
            'Prof_Nf_' + CAST(@UltProf + rnp AS VARCHAR(12)) AS Nombre,
            'Mailprof' + CAST(@UltProf + rnp AS VARCHAR(12)) + '@escolar.edu' AS Email,
            -- Se asigna DeptoID aleatorio dentro del rango existente.
            ((ABS(CHECKSUM(NEWID())) % (SELECT ISNULL(MAX(DeptoID),1)
            FROM Catalogos.Departamentos)) + 1) AS DeptoID
        FROM nums
    )
INSERT INTO Catalogos.Profesores
    (Nombre, Email, DeptoID)
SELECT N.Nombre, N.Email, N.DeptoID
FROM NewProfs N
WHERE NOT EXISTS (SELECT 1
FROM Catalogos.Profesores P
WHERE P.Email = N.Email);

    -- Se actualizar checkpoint Profesores.
    MERGE Control.Checkpoints AS C
    USING (SELECT 'Profesores' AS Entidad, ISNULL(MAX(ProfesorID),0) AS UltimoID
FROM Catalogos.Profesores) AS S
    ON C.Entidad = S.Entidad
    WHEN MATCHED THEN UPDATE SET UltimoID = S.UltimoID, FechaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (S.Entidad, S.UltimoID, SYSUTCDATETIME());

    DECLARE @InsertedProf INT=(SELECT COUNT(*)
FROM Catalogos.Profesores
WHERE ProfesorID > @UltProf);
    IF @InsertedProf = 0
    BEGIN
    RAISERROR('No se insertaron profesores en Catalogos.Profesores. Abortar Insersion',16,1);
    RETURN;
END
    PRINT 'Profesores generados/actualizados: ' + FORMAT(@InsertedProf, 'N0');

--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 4. DIVERSIFICACIÓN DE CURSOS Y MATERIAS.
--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ;WITH
    curs
    AS
    (
        SELECT TOP (@NCursos)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rnc
        FROM sys.all_columns
    )
INSERT INTO Catalogos.Cursos
    (Nombre, Creditos)
SELECT Nc.Nombre, Nc.Creditos
FROM (
        SELECT
        'NCurso_' + CAST(@UltCurso + rnc AS VARCHAR(15)) AS Nombre,
        (ABS(CHECKSUM(NEWID())) % 4) + 3 AS Creditos
    FROM curs
    ) Nc
WHERE NOT EXISTS (SELECT 1
FROM Catalogos.Cursos C
WHERE C.Nombre = Nc.Nombre);

    DECLARE @InsertedCurs INT = (SELECT COUNT(*)
FROM Catalogos.Cursos);
    IF @InsertedCurs = 0
    BEGIN
    RAISERROR('No se insertaron Cursos en Catalogos.Cursos. Abortar Insersion',16,1);
    RETURN;
END
    PRINT 'Cursos insertados: ' + FORMAT(@InsertedCurs, 'N0');

    ;WITH
    mat
    AS
    (
        SELECT TOP (@NMat)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rnm
        FROM sys.all_columns
    )
INSERT INTO Operaciones.Materias
    (Nombre, Creditos, ProfesorID)
SELECT Nm.Nombre, Nm.Creditos, Nm.ProfesorID
FROM (
        SELECT
        'NMateria_' + CAST(@UltMat + rnm AS VARCHAR(25)) AS Nombre,
        (ABS(CHECKSUM(NEWID())) % 4) + 3 AS Creditos,
        (ABS(CHECKSUM(NEWID())) % @MaxProfesorNuevo) + 1 AS ProfesorID
    FROM mat
    ) Nm
WHERE NOT EXISTS (SELECT 1
FROM Operaciones.Materias M
WHERE M.Nombre = Nm.Nombre);

    DECLARE @InsertedMat INT = (SELECT COUNT(*)
FROM Operaciones.Materias);
    IF @InsertedMat = 0
    BEGIN
    RAISERROR('No se insertaron Materias en Operaciones.Materias. Abortar Insersion',16,1);
    RETURN;
END
    PRINT 'Materias insertadas: ' + FORMAT(@InsertedMat, 'N0');

    -- Actualizar checkpoints de Cursos y Materias.
    MERGE Control.Checkpoints AS CKc
    USING (SELECT 'Cursos' AS Entidad, ISNULL(MAX(CursoID),0) AS UltimoID
FROM Catalogos.Cursos) AS Sc
    ON CKc.Entidad = Sc.Entidad
    WHEN MATCHED THEN UPDATE SET UltimoID = Sc.UltimoID, FechaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (Sc.Entidad, Sc.UltimoID, SYSUTCDATETIME());

    MERGE Control.Checkpoints AS CKm
    USING (SELECT 'Materias' AS Entidad, ISNULL(MAX(MateriaID),0) AS UltimoID
FROM Operaciones.Materias) AS Sm
    ON CKm.Entidad = Sm.Entidad
    WHEN MATCHED THEN UPDATE SET UltimoID = Sm.UltimoID, FechaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (Sm.Entidad, Sm.UltimoID, SYSUTCDATETIME());

--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 5. CARGA MASIVA DE ALUMNOS (Se asigna CarreraID, DeptoID coherente, idempotente).

--- -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '--------------------------------------------------------------------------------------------------';
    PRINT '?? Generando alumnos con blindaje de nulos...';
    PRINT '--------------------------------------------------------------------------------------------------';

    ;WITH
    RandRows
    AS
    (
        SELECT TOP (@NAluRun)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
        FROM sys.all_columns
    ),
    NewAlu
    AS
    (
        SELECT
            @NombreBase + '_ID_' + CAST(@UltAlu + R.rn AS VARCHAR(24)) AS Nombre,
            LOWER(@NombreBase) + CAST(@UltAlu + R.rn AS VARCHAR(24)) + '@escolar.edu' AS Email,
            DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 36500, GETDATE()) AS FechaNacimiento,
            -- MetaData_ETL: fecha | estatus | nota (ejemplo)
            FORMAT(DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 1825, GETDATE()), 'yyyy-MM-dd') + ' | ' +
                CASE (ABS(CHECKSUM(NEWID())) % 7)
                    WHEN 0 THEN 'REGULAR' WHEN 1 THEN 'IRREGULAR' WHEN 2 THEN 'CONDICIONAL'
                    WHEN 3 THEN 'BAJA_TEMP' WHEN 4 THEN 'BAJA_DEFI' WHEN 5 THEN 'EGRESADO' ELSE 'TITULADO'
                END + ' | ' + CAST((ABS(CHECKSUM(NEWID())) % 41) + 60 AS VARCHAR(5)) AS MetaData_ETL,
            C.CarreraID,
            C.DeptoID
        FROM RandRows R
        CROSS APPLY (
            SELECT CarreraID, DeptoID
            FROM #CarrList
            WHERE CarrRow = ((R.rn - 1) % @CarrCount) + 1
        ) C
    )
INSERT INTO Catalogos.Alumnos
    (Nombre, Email, FechaNacimiento, MetaData_ETL, CarreraID, DeptoID)
SELECT Nombre, Email, FechaNacimiento, MetaData_ETL, CarreraID, DeptoID
FROM NewAlu
WHERE NOT EXISTS (SELECT 1
FROM Catalogos.Alumnos A
WHERE A.Email = NewAlu.Email);
    -- Aplicando la técnica modular evita ordenar aleatoriamente la tabla de carreras cada vez y es mucho más escalable.
    -- Actualizar checkpoint Alumnos.
    MERGE Control.Checkpoints AS CkpAlu
    USING (SELECT 'Alumnos' AS Entidad, ISNULL(MAX(AlumnoID),0) AS UltimoID
FROM Catalogos.Alumnos) AS SAlu
    ON CkpAlu.Entidad = SAlu.Entidad
    WHEN MATCHED THEN UPDATE SET UltimoID = SAlu.UltimoID, FechaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (SAlu.Entidad, SAlu.UltimoID, SYSUTCDATETIME());

    DECLARE @InsertedAlu INT = (SELECT COUNT(*)
FROM Catalogos.Alumnos);
    IF @InsertedAlu = 0
    BEGIN
    RAISERROR('No se insertaron alumnos en Catalogos.Alumnos. Abortar Insersion',16,1);
    RETURN;
END
    PRINT 'Alumnos Totales generados: ' + FORMAT(@InsertedAlu, 'N0');

--- -- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 6. INSCRIPCIONES MASIVAS (OUTPUT -> #NewIns), Parciales y Asistencias).
--- -- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    PRINT '--------------------------------------------------------------------------------------------------';
    PRINT '  Iniciando Inscripciones, Parciales...';
    PRINT '--------------------------------------------------------------------------------------------------';
    -- Paso 1.1) Usamos una tabla temporal #NewIns para capturar inscripciones de este run.
    IF OBJECT_ID('tempdb..#NewIns') IS NOT NULL DROP TABLE #NewIns;
    CREATE TABLE #NewIns
(
    InscripcionID INT,
    AlumnoID INT,
    MateriaID INT,
    CursoID INT,
    CicloEscolar NVARCHAR(20),
    NotaFinal DECIMAL(5,2)
);


    ---------Inscripciones por lotes (batch insert)---------------------

    DECLARE @RowsAffected INT = 1;  -- Contador de filas insertadas.

    WHILE @RowsAffected > 0
    BEGIN
    BEGIN TRAN;

    ;
    WITH
        ToProcess
        AS
        (
            SELECT TOP (@BatchSize)
                A.AlumnoID,
                -- Realizamos la extracción del token EstatusAcademico para decidir cantidad, pero sin usar funciones de texto complejas en la consulta principal.
                CASE
                    WHEN CHARINDEX('|',A.MetaData_ETL) = 0 THEN NULL
                    ELSE UPPER(LTRIM(RTRIM(
                        SUBSTRING(
                        A.MetaData_ETL,
                        CHARINDEX('|',A.MetaData_ETL) + 1,
                        CASE WHEN CHARINDEX('|',A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1) = 0
                                THEN LEN(A.MetaData_ETL)
                                ELSE CHARINDEX('|',A.MetaData_ETL, CHARINDEX('|',A.MetaData_ETL)+1) - CHARINDEX('|',A.MetaData_ETL) - 1 END
                        )
                    )))
                END AS RawEstatus
            FROM Catalogos.Alumnos A
                LEFT JOIN Operaciones.Inscripciones I ON I.AlumnoID = A.AlumnoID
            WHERE I.InscripcionID IS NULL
            -- Procesar alumnos sin inscripciones aún,
            ORDER BY A.AlumnoID
        )
    INSERT INTO Operaciones.Inscripciones
        (AlumnoID, MateriaID, CursoID, CicloEscolar, NotaFinal)
    OUTPUT inserted.InscripcionID, inserted.AlumnoID, inserted.MateriaID, inserted.CursoID, inserted.CicloEscolar, inserted.NotaFinal
        INTO #NewIns (InscripcionID, AlumnoID, MateriaID, CursoID, CicloEscolar, NotaFinal)
    SELECT tp.AlumnoID,
        M.MateriaID,
        C.CursoID,
        -- Ciclo fijo para testeo.
        CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-1',
        NULL
    FROM ToProcess tp
        CROSS APPLY (
        SELECT CASE
            WHEN tp.RawEstatus LIKE '%REGUL%' THEN 6
            WHEN tp.RawEstatus LIKE '%IRREG%' THEN 4
            WHEN tp.RawEstatus LIKE '%CONDIC%' THEN 5
            ELSE 0
        END AS Cantidad
        ) Cnt
        CROSS APPLY (
            SELECT n
        FROM (
                SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
            -- Generador de números para cantidad de inscripciones por alumno basado en estatus.
            FROM (VALUES(0),
                    (0),
                    (0),
                    (0),
                    (0),
                    (0),
                    (0),
                    (0),
                    (0),
                    (0)) a(n) -- Generador de filas rápido para cantidad (hasta 10 por alumno).
                CROSS JOIN (VALUES(0),
                    (0),
                    (0),
                    (0),
                    (0),
                    (0),
                    (0),
                    (0),
                    (0),
                    (0)) b(n) -- Generador de filas rápido para cantidad (hasta 100 por alumno).
            ) Tally
        WHERE n <= Cnt.Cantidad
        ) t
        CROSS APPLY (
            SELECT TOP (1)
            MateriaID
        FROM #Materias
        WHERE MateriaRow = ((ABS(CHECKSUM(CONCAT(tp.AlumnoID, t.n))) % @MateriaCount) + 1)
        ORDER BY MateriaID
        ) M
        CROSS APPLY (
            SELECT TOP (1)
            CursoID
        FROM #Cursos
        WHERE CursoRow = ((ABS(CHECKSUM(CONCAT(tp.AlumnoID, t.n))) % @CursoCount) + 1)
        ORDER BY CursoID
        ) C
    WHERE Cnt.Cantidad > 0
        AND NOT EXISTS (
                SELECT 1
        FROM Operaciones.Inscripciones I2
        WHERE I2.AlumnoID = tp.AlumnoID
            AND I2.MateriaID = M.MateriaID
            AND I2.CursoID = C.CursoID
            AND I2.CicloEscolar = CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-1'
            );

    SET @RowsAffected = @@ROWCOUNT;
    COMMIT;

    PRINT 'Batch Inscripciones insertadas: ' + FORMAT(@RowsAffected, 'N0');
    IF @RowsAffected = 0 BREAK;
    WAITFOR DELAY @PauseBetweenBatches;
END

    DECLARE @InsertedIns INT = (SELECT COUNT(*)
FROM #NewIns);
    PRINT 'Inscripciones creadas en este run (capturadas en #NewIns): ' + FORMAT(@InsertedIns, 'N0');
    IF @InsertedIns = 0
    BEGIN
    PRINT 'No se generaron inscripciones en este run. Continuando con validaciones.';
END

--- -- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 7. INSERCION DE PARCIALES POR LOTES USANDO INSCRIPCIONID (1-3 parciales por inscripción, evitando duplicados).
--- -- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    INSERT INTO Operaciones.Calificaciones
    (InscripcionID, ParcialNumero, AlumnoID, CursoID, Nota, FechaAplicacion)
SELECT N.InscripcionID,
    P.ParcialNum,
    N.AlumnoID,
    N.CursoID,
    CAST((ABS(CHECKSUM(NEWID())) % 101) AS DECIMAL(5,2)),
    SYSUTCDATETIME()
FROM #NewIns N
    CROSS JOIN (VALUES
        (1),
        (2),
        (3)) AS P(ParcialNum)
    LEFT JOIN Operaciones.Calificaciones C ON C.InscripcionID = N.InscripcionID AND C.ParcialNumero = P.ParcialNum
WHERE C.CalificacionID IS NULL;

    DECLARE @InsertedParciales INT = (SELECT COUNT(*)
FROM #NewIns N);
    PRINT 'Calificaciónes Parciales insertados: ' + FORMAT(@InsertedParciales, 'N0');
    IF @InsertedParciales = 0
    BEGIN
    PRINT 'No se insertaron parciales en Operaciones.Calificaciones. Abortar Insersion';
END 

--- -- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 8. GENERAR ASISTENCIAS DETERMINISTAS POR LOTES (USANDO #NewIns PARA CONTROL DE FK).
--- -- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Generar asistencias por InscripcionID usando CicloEscolar 'YYYY-1' o 'YYYY-2'
-- Expandir en batches para no saturar log y evitar timeouts, generando fechas de asistencia dentro del semestre correspondiente.
    DECLARE @ProcessedAsis INT = 1;
    DECLARE @CursorOffset INT = 0;
    DECLARE @BatchInsCount INT = (SELECT COUNT(*)
FROM #NewIns);

    WHILE @CursorOffset < @BatchInsCount
    BEGIN
    BEGIN TRAN;

        ;
    WITH
        BatchIns
        AS
        (
            SELECT InscripcionID, AlumnoID, CursoID, CicloEscolar
            FROM #NewIns
            ORDER BY InscripcionID
            OFFSET @CursorOffset ROWS FETCH NEXT @BatchSize ROWS ONLY
        ),
        Sem
        AS
        (
            SELECT B.InscripcionID, B.AlumnoID, B.CursoID, B.CicloEscolar,
                CASE WHEN RIGHT(B.CicloEscolar,1) = '1' THEN DATEFROMPARTS(CAST(LEFT(B.CicloEscolar,4) AS INT),1,1)
                        ELSE DATEFROMPARTS(CAST(LEFT(B.CicloEscolar,4) AS INT),7,1) END AS SemInicio,
                CASE WHEN RIGHT(B.CicloEscolar,1) = '1' THEN DATEFROMPARTS(CAST(LEFT(B.CicloEscolar,4) AS INT),6,30)
                        ELSE DATEFROMPARTS(CAST(LEFT(B.CicloEscolar,4) AS INT),12,31) END AS SemFin
            FROM BatchIns B
        ),
        Expanded
        AS
        (
            SELECT S.*,
                ROW_NUMBER() OVER (PARTITION BY S.InscripcionID ORDER BY (SELECT NULL)) AS Seq,
                (ABS(CHECKSUM(CONCAT('C',S.InscripcionID,'-',S.AlumnoID))) % (@MaxAsis - @MinAsis + 1)) + @MinAsis AS Cantidad
            FROM Sem S
            CROSS JOIN (                                                                                                                                                                                                                SELECT 1 AS n
                UNION ALL
                    SELECT 2
                UNION ALL
                    SELECT 3
                UNION ALL
                    SELECT 4) t
            -- 4 asistencias por inscripción máximo.
        )
    INSERT INTO Operaciones.Asistencias
        (InscripcionID, AlumnoID, CursoID, FechaAsistencia, Presente)
    SELECT E.InscripcionID, E.AlumnoID, E.CursoID, CA.FechaAsistencia, CA.Presente
    FROM Expanded E
        CROSS APPLY (
        SELECT
            CAST(
                DATEADD(
                    DAY,
                    (ABS(CHECKSUM(CONCAT('D',E.InscripcionID,'-',E.Seq))) % (DATEDIFF(DAY, E.SemInicio, E.SemFin) + 1)),
                    E.SemInicio
                ) AS DATE
            ) AS FechaAsistencia,
            CASE WHEN (ABS(CHECKSUM(CONCAT('P',E.InscripcionID,'-',E.Seq))) % 10) < 8 THEN 1 ELSE 0 END AS Presente
        ) CA
    WHERE E.Seq <= E.Cantidad
        AND E.SemInicio IS NOT NULL
        AND E.SemFin IS NOT NULL
        AND NOT EXISTS (
                SELECT 1
        FROM Operaciones.Asistencias A
        WHERE A.InscripcionID = E.InscripcionID
            AND A.FechaAsistencia = CA.FechaAsistencia
            );

    SET @ProcessedAsis = @@ROWCOUNT;
    COMMIT;

    PRINT 'Batch Asistencias insertadas: ' + FORMAT(@ProcessedAsis, 'N0') + ' (offset ' + FORMAT(@CursorOffset, 'N0') + ')';

    SET @CursorOffset = @CursorOffset + @BatchSize;
    WAITFOR DELAY @PauseBetweenBatches;
END

    PRINT 'Generación de asistencias completada.';

--- -- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- -- 9. AJUSTE: Actualizamos la NotaFinal por lotes (ignorando ceros para no afectar inscripciones sin parciales aún).
--- -- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    DECLARE @RowsUpdated INT = 1;

    WHILE @RowsUpdated > 0
    BEGIN
    BEGIN TRAN;

        ;
    WITH
        CTE_Prom
        AS
        (
            SELECT TOP (@BatchSize)
                I.InscripcionID,
                ROUND(AVG(CAST(NULLIF(C.Nota,0) AS DECIMAL(7,4))),2) AS Prom
            FROM Operaciones.Inscripciones I
                JOIN Operaciones.Calificaciones C ON C.InscripcionID = I.InscripcionID
            WHERE I.NotaFinal IS NULL
            GROUP BY I.InscripcionID
            ORDER BY I.InscripcionID
        )
        UPDATE I
        SET NotaFinal = P.Prom
        FROM Operaciones.Inscripciones I
        JOIN CTE_Prom P ON I.InscripcionID = P.InscripcionID;

    SET @RowsUpdated = @@ROWCOUNT;
    COMMIT;

    PRINT 'Batch NotaFinal actualizado: ' + FORMAT(@RowsUpdated, 'N0');
    WAITFOR DELAY @PauseBetweenBatches;
END

--- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- -- > 10.  ACTUALIZACION: Para checkpoints de Inscripcion, Calificaciones y Asistencias (para control de FK en procesos posteriores).
--- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    MERGE Control.Checkpoints AS CkpI
    USING (SELECT 'Inscripciones' AS Entidad, ISNULL(MAX(InscripcionID),0) AS UltimoID
FROM Operaciones.Inscripciones) AS SI
    ON CkpI.Entidad = SI.Entidad
    WHEN MATCHED THEN UPDATE SET UltimoID = SI.UltimoID, FechaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (SI.Entidad, SI.UltimoID, SYSUTCDATETIME());

    MERGE Control.Checkpoints AS CkpC
    USING (SELECT 'Calificaciones' AS Entidad, ISNULL(MAX(CalificacionID),0) AS UltimoID
FROM Operaciones.Calificaciones) AS SCal
    ON CkpC.Entidad = SCal.Entidad
    WHEN MATCHED THEN UPDATE SET UltimoID = SCal.UltimoID, FechaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (SCal.Entidad, SCal.UltimoID, SYSUTCDATETIME());

    MERGE Control.Checkpoints AS CkpA
    USING (SELECT 'Asistencias' AS Entidad, ISNULL(MAX(AsistenciaID),0) AS UltimoID
FROM Operaciones.Asistencias) AS SEn
    ON CkpA.Entidad = SEn.Entidad
    WHEN MATCHED THEN UPDATE SET UltimoID = SEn.UltimoID, FechaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (Entidad, UltimoID, FechaActualizacion) VALUES (SEn.Entidad, SEn.UltimoID, SYSUTCDATETIME());


    -- Aplicamos Limpieza temporal a nuesta tabla de Inscripciones.
    -- NOTA: durante pruebas deja las temp tables para inspección
    --IF OBJECT_ID('tempdb..#NewIns') IS NOT NULL DROP TABLE #NewIns;
    --IF OBJECT_ID('tempdb..#Cursos') IS NOT NULL DROP TABLE #Cursos;
    --IF OBJECT_ID('tempdb..#Materias') IS NOT NULL DROP TABLE #Materias;
    --IF OBJECT_ID('tempdb..#CarrList') IS NOT NULL DROP TABLE #CarrList;

------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------- -- 12. MÉTRICAS FINALES.
------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    DECLARE @EndTime DATETIME2 = SYSUTCDATETIME();
    PRINT '';
    PRINT '============================================================================';
    PRINT '       ✅ RESUMEN DE EJECUCIÓN EXITOSA';
    PRINT '============================================================================';
    PRINT '✅ Alumnos Procesados:   ' + FORMAT(@InsertedAlu, 'N0');
    PRINT '📝 Departamentos Inyectados: ' + FORMAT(@InsertedDeptos, 'N0');
    PRINT '📝 Profesores Inyectados: ' + FORMAT(@InsertedProf, 'N0');
    PRINT '📝 Inscripciones Inyectadas: ' + FORMAT(@InsertedIns, 'N0');
    PRINT '📝 Materias Inyectadas:     ' + FORMAT(@InsertedMat, 'N0');
    PRINT '📝 Cursos Inyectados:    ' + FORMAT(@InsertedCurs, 'N0');
    PRINT '⏱️ Tiempo de Respuesta:  ' + FORMAT(DATEDIFF(MILLISECOND, @StartTime, SYSUTCDATETIME()), 'N0') + ' ms';
    PRINT '⏱️ Tiempo de Ejecución: ' + FORMAT(DATEDIFF(MILLISECOND, @StartTime, @EndTime), 'N0') + ' ms';
    PRINT '📅 Finalizado el:        ' + CAST(SYSDATETIME() AS VARCHAR);
    PRINT '============================================================================';
    PRINT '';

END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    DECLARE @ErrMsg NVARCHAR(4000)=ERROR_MESSAGE(), @ErrLine INT = ERROR_LINE();
    PRINT '';
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '==============================================================================';
    PRINT '          ❌ ERROR DETECTADO - TRANSACCIÓN REVERTIDA';
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '🔢 Código de Error:: ' + ISNULL(@ErrMsg,'(sin mensaje)') + ' en 📍 Línea del Error ' + CAST(@ErrLine AS VARCHAR(10));
    PRINT '⚙️ Procedimiento:     ' + ISNULL(ERROR_PROCEDURE(), 'Script Directo'); -- Procedimiento donde ocurrió el error.
    PRINT '';
    PRINT '    ERROR: ' + ISNULL(@ErrMsg,'(sin mensaje)') + ' en Linea: ' + CAST(@ErrLine AS VARCHAR(10));
    THROW;
END CATCH;

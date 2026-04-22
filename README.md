# 🚀 SQL & Data Engineering Portfolio - 👷 Alberto Dzib 📊

![SQL Server](https://img.shields.io/badge/SQL_Server-2025-blue)
![Python](https://img.shields.io/badge/Python-3.13-yellow)
![Power BI](https://img.shields.io/badge/PowerBI-Dashboard-orange)
![License](https://img.shields.io/badge/License-MIT-green)

> 📖 ¡Bienvenido a mi portafolio!  
> Ingeniero de Soluciones de Datos especializado en arquitecturas híbridas. Diseño pipelines que procesan **50,000 registros en menos de 2 segundos**, con rigor transaccional y escalabilidad empresarial.

---

## 📌 Incluye:

- Tablas jerárquicas y normalizadas.
- Diversidad temporal en registros.
- Ejemplos prácticos para dashboards y BI.
- Este portafolio aporta valor como base técnica para proyectos de transformación digital y ciencia de datos.

---

## 🎯 Objetivos del portafolio
* Con cada proyecto se busca simular un entorno de negocio distinto.

- 🗂️ **Modelado de datos* y Tablas jerárquicas normalizadas*: diseño de esquemas relacionales con integridad referencial y reglas de negocio.
- 📈 **Generación masiva de datasets realistas**
- ⏳ **Diversidad temporal en registros, fechas variadas para análisis de tendencias**
- 🔍 **Consultas analíticas para BI y dashboards**

---

## 💻 Stack Tecnológico
En este portafolio se buscó aplicar un rigor de ingeniería en cada línea de código:

- **Motores:** SQL Server 2025 | SSMS 22.
- **Lenguajes:** T-SQL Avanzado y Python 3.13 (Pandas, SQLAlchemy).
- **Metodología de Calidad:** 
  - **Idempotencia:** Scripts re‑ejecutables sin duplicidad de datos.
  - **Integridad:** Uso de Transacciones (`COMMIT`/`ROLLBACK`) y bloques `TRY/CATCH`.
  - **Performance:** Monitoreo de tiempos de ejecución en milisegundos para procesos masivos.
  - **Git Flow:** Gestión de ramas (`Feature` -> `Develop` -> `Main`) y `SemVer`.

---
## 📊 Métricas de Impacto y Performance (Hito v3.0)
> *Benchmarks ejecutados en entorno local optimizado (SSD Expansion & Write Caching).*

| Categoría              | Métrica                  | Benchmark               | Stack Clave                        | Estado |
|:----------------------:|:------------------------:|:-----------------------:|:----------------------------------:|:------:|
| **Ingesta Masiva**     | Velocidad de Carga       | **1.84 s** (50,000 reg.)| `SQLAlchemy` + `fast_executemany`  | ✅     |
| **Transformación (ETL)**| Limpieza y Normalización | **809 ms**              | `T-SQL` + `CTEs` + `Materialización` | ✅   |
| **Analítica de Negocio**| Tiempo de Respuesta BI  | **0.53 s**              | `Pandas` + `DirectQuery Ready`     | ✅     |
| **Confiabilidad**      | Ratio de Idempotencia    | **100 %**               | `TRY/CATCH` + `DBCC CHECKIDENT`    | ⚡     |

---

## 📇 Estructura del repositorio

El repositorio está organizado por proyectos independientes, cada uno con su propio ciclo de vida (DDL, DML, ETL y BI):

- `📂 P1_Inventario`: Gestión de stock y fundamentos relacionales.
- `📂 P2_Escolar`: Arquitectura avanzada, esquemas segregados y limpieza con CTEs.
- `📂 P3_Retail_Ventas`: Pipeline híbrido (Python + SQL) y procesamiento de Big Data.
- `📝 README Y DOCUMENTACIÓN :` Documentación por proyecto de sus estándares y "Lineamientos de Estructura" aplicados.

```text
SQL_Portafolio/
├── P1_Inventario/              # Gestión de Stock y Fundamentos Relacionales
│   ├── Scripts/                # Pipeline 01-05 (SQL Puro)
│   └── Documentacion.md
├── P2_Escolar/                 # Arquitectura Avanzada y ETL con CTEs
│   ├── Scripts/                # Pipeline 01-05 (SQL Pro)
│   ├── img/                    # Evidencias de Ranking y Métricas
│   └── Documentacion.md
└── P3_Retail_Ventas/           # Pipeline Híbrido Big Data (Python + SQL)
    ├── Scripts/                # Scripts .py y .sql (Orquestación Híbrida)
    ├── Datos/                  # Datasets generados (50,000 registros)
    ├── img/                    # Dashboards de Analítica
    └── Documentacion.md
```

---

## 📁 Proyectos destacados

### 🐍 [P3] Pipeline Híbrido: Retail & Big Data (v3.0.0)
*Integración avanzada de Python y SQL para el procesamiento de volúmenes masivos.*
- **Ingesta:** Generación y carga de **50,000 registros** sintéticos en **1.84 segundos**.
- **ETL:** Normalización de metadatos no  atómicos  mediante **CTEs** y actualización masiva (809 ms).
- **BI:** Reporte de analítica en consola con **Pandas**, logrando tiempos de respuesta de **0.53 s**.
- **Key Skills:** Orquestación híbrida, Middleware ODBC, Optimización de I/O.

### 🎓 [P2] Sistema de Gestión Académica (v2.1.0)
*Arquitectura relacional robusta y procesos de limpieza profunda.*
- **Estructura:** Diseño de esquemas segregados (`Catálogos`, `Operaciones`).
- **Calidad:** Implementación de bloques **TRY/CATCH**, transacciones y manejo de desbordamientos decimales.
- **ETL:** Transformación de strings complejos en datos tipados (`DATETIME2`, `DECIMAL`).
- **Key Skills:** Window Functions (RANK), Idempotencia (`RESEED`), Constraints Nominados.

### 📦 [P1] Control de Inventarios (v1.0.0)
*Fundamentos de bases de datos y gestión de stock.*
- **Lógica:** Implementación de CRUD básico y lógica de inventarios.
- **Ejemplos:** De limpieza de datos (ETL) y reportes ejecutivos.
- **Key Skills:** PK/FK, Joins básicos, Relaciones 1:N.

---

## 🌐 Estándares aplicados
En cada proyecto aplico rigor de ingeniería para asegurar código de nivel empresarial:
1. **Idempotencia:** Scripts capaces de ejecutarse múltiples veces sin corromper datos mediante `DROP IF EXISTS` y `DBCC CHECKIDENT`.
2. **Seguridad Transaccional:** Garantía de integridad mediante bloques `TRY/CATCH` y `ROLLBACK` ante fallos críticos.
3. **Métricas de Performance:** Optimización I/O, documentación obligatoria de tiempos de ejecución y carga de CPU.
4. **Documentación de Retos:** Enfoque en la resolución de problemas técnicos (Bug fixes & Refactoring).
5. **Middleware:** Integración vía ODBC Driver 17 y SQLAlchemy para flujos híbridos.

---

## ⚠️ Retos técnicos
A lo largo de los proyectos se resolvieron desafíos complejos de arquitectura:
- **Pipeline Híbrido:** Ingesta de 50,000 registros desde Python a SQL en < 2 segundos.
- **Normalización ETL:** Transformación de metadatos no atómico mediante expresiones de tabla comunes (CTEs).
- **Optimización I/O:** Configuración de hardware y memoria virtual para el manejo de datasets masivos.

---

## 💾 Uso del repositorio
1. **Explorar por carpeta:** Cada proyecto contiene una subcarpeta `Scripts/` con el orden de ejecución (01, 02, etc.).
2. **Consultar Documentación:** Cada proyecto incluye un `Documentación.md` con evidencias visuales y métricas de rendimiento.
3. **Requisitos:** Tener instalado SQL Server 2025 y el Driver ODBC 17 para las integraciones con Python.

---

## 🚩 Roadmap
- [ ] **Dockerización:** Implementar contenedores para el despliegue rápido de entornos SQL.
- [ ] **Data Visualization:** Conexión de pipelines a herramientas de visualización (**Power BI / Tableau**) para dashboards dinámicos.
- [ ] **Automatización:** Aplicando scripts mediante **Task Schedulers**.
- [ ] **Cloud Migration:** Explorar la migración de procesos ETL hacia Azure SQL Database.


---
| **Contacto:** 🔗 linkedin.com/in/jesusalberto-dzib-ku | ✉️ dzibjesusalberto@gmail.com |
 **Autor:** MIT © 2026 Jesús Alberto Dzib Ku | 
 *Ingeniería de Datos | SQL & Python Developer* |
 *🚧 En constante evolución.* | 


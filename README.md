# 📊 SQL Portafolio – SSMS 22
Repositorio con tres proyectos en SQL Server Management Studio 22 (SSMS) que muestran mis habilidades en modelado de datos, generación masiva de datasets realistas y consultas analíticas.
--

Incluye:

-Tablas jerárquicas y normalizadas
-Diversidad temporal en registros
-Ejemplos prácticos para dashboards y BI
-Este portafolio aporta valor como base técnica para proyectos de transformación digital y ciencia de datos.

---
## 🎯 Objetivos del portafolio

- 🗂️ **Modelado de datos* y Tablas jerárquicas normalizadas*: diseño de esquemas relacionales con integridad referencial y reglas de negocio.
- 📈 **Generación masiva de datasets realistas**
-    **Diversidad temporal en registos, fechas variadas para análisis de tendencias**
- 🔍 **Consultas analíticas para BI y dashboards**

Cada proyecto simula un entorno de negocio distinto (Inventario, Escolar, Finanzas), demostrando versatilidad en el uso de SQL para distintos dominios.

---

## 🚀 Proyectos incluidos
1. **P1_Inventario**
   -Arquitectura de tablas para gestión de inventario.
   -Scripts de carga masiva con 500 registros aleatorios.
   -Ejemplos de limpieza de datos (ETL) y reportes ejecutivos.
   -Incluye diagrama ERD y demo de aplicación en C#.
2. **P2_Escolar (en proceso de mejora)**
   -Modelado de alumnos, cursos, profesores y calificaciones.
   -Inserción masiva de datos simulados.
   -Consultas analíticas para métricas académicas.
3. **P3_Finanzas** (en proceso de mejora)
    -Modelado de usuarios, cuentas, transacciones y presupuestos.
    -Scripts de inserción masiva para simular movimientos financieros.
    -Reportes de métricas clave para control presupuestal.
---

## 📂 Estructura del repositorio

```text
SQL_Portfolio/
├── P1_Inventario/
│   ├── Scripts/
│   │   ├── 01_CreacionTablas.sql        # Arquitectura y reglas de negocio
│   │   ├── 02_DatosIniciales.sql        # Inserción de datos base
│   │   ├── 03_InsertMasivoDatos.sql     # Generación masiva de 500 registros
│   │   ├── 04_LimpiezaDatos_ETL.sql     # Normalización y limpieza de datos
│   │   └── 05_Reportes_BI.sql           # Consultas analíticas y métricas
│   ├── Diagramas/
│   │   └── Inventario_ERD.png
│   ├── AppDemo/
│   │   └── Program.cs
│   └── Documentacion.md
│
├── P2_Escolar/
│   ├── Scripts/...
│   ├── Diagramas/...
│   ├── AppDemo/...
│   └── Documentacion.md
│
└── P3_Finanzas/
    ├── Scripts/...
    ├── Diagramas/...
    ├── AppDemo/...
    └── Documentacion.md
```
---

## 📌 Próximos pasos

Mejorar los proyectos Escolar y Finanzas con el mismo nivel de detalle que Inventario.

Añadir ejemplos de integración con Power BI y Tableau para visualización.

Documentar casos de uso de ETL y normalización para mostrar procesos de limpieza de datos.
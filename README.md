# 📊 SQL Portafolio – SSMS 22
Repositorio con tres proyectos en SSMS 22 que muestran el modelado de datos, la generación masiva de datasets realistas y las consultas analíticas. Incluye tablas jerárquicas, diversidad temporal y ejemplos prácticos para dashboards y BI, aportando valor como portafolio técnico y base para transformación digital
---
El presente repositorio consta de  tres proyectos en **SQL Server Management Studio 22 (SSMS)** , con el objetivo de demostrar mis habilidades en:

- 🗂️ **Modelado de datos**
- 📈 **Generación masiva de datasets realistas**
- 🔍 **Consultas analíticas para BI y dashboards**

Cada proyecto simula escenarios de negocio con categorías jerárquicas, diversidad temporal y referencias ejecutivas, aportando valor como portafolio técnico y como base para proyectos de transformación digital y de ciencia de datos.

---

## 🚀 Proyectos incluidos
1. **Generación de datos masivos**  
   Scripts SQL optimizados para crear datasets realistas con nombres, ciudades y periodos variados.

2. **Modelado jerárquico de tablas**  
   Diseño de estructuras con categorías y subcategorías para análisis multinivel.

3. **Consultas analíticas avanzadas**  
   Ejemplos prácticos de reportes ejecutivos y métricas clave para dashboards.

---

## 📂 Estructura del repositorio
SQL_Portfolio/
├── P1_Inventario/
│   ├── Scripts/
│   │   ├── 01_CreacionTablas.sql
│   │   │   ├── Productos (IdProducto PK, Nombre, Precio, Stock, Categoría, FechaCreación)
│   │   │   ├── Proveedores (IdProveedor PK, Nombre, Teléfono)
│   │   │   ├── Ventas (IdVenta PK, IdProducto FK, Cantidad, Fecha)
│   │   │   ├── Categorías (IdCategoria PK, Nombre)
│   │   │   ├── Clientes (IdCliente PK, Nombre, Email, Teléfono)
│   │   │   ├── Pedidos (IdPedido PK, IdCliente FK, FechaPedido)
│   │   │   ├── DetallePedido (IdDetalle PK, IdPedido FK, IdProducto FK, Cantidad)
│   │   │   └── Pagos (IdPago PK, IdPedido FK, Monto, FechaPago, Metodo)
│   │   ├── 02_DatosIniciales.sql
│   │   ├── 03_ConsultasEjemplo.sql
│   │   └── 04_InsertMasivo.sql   <-- Genera 500 registros aleatorios
│   ├── Diagramas/
│   │   └── Inventario_ERD.png
│   ├── AppDemo/
│   │   └── Program.cs
│   └── Documentacion.md
│
├── P2_Escolar/
│   ├── Scripts/
│   │   ├── 01_CreacionTablas.sql
│   │   │   ├── Alumnos (IdAlumno PK, Nombre, Carrera)
│   │   │   ├── Cursos (IdCurso PK, Nombre, Créditos)
│   │   │   ├── Calificaciones (IdCalificacion PK, IdAlumno FK, IdCurso FK, Nota)
│   │   │   ├── Profesores (IdProfesor PK, Nombre, Especialidad)
│   │   │   ├── Departamentos (IdDepartamento PK, Nombre)
│   │   │   ├── CursosProfesores (IdCurso FK, IdProfesor FK)
│   │   │   ├── Horarios (IdHorario PK, IdCurso FK, DiaSemana, HoraInicio, HoraFin)
│   │   │   └── Asistencias (IdAsistencia PK, IdAlumno FK, IdCurso FK, Fecha, Presente BIT)
│   │   ├── 02_DatosIniciales.sql
│   │   ├── 03_ConsultasEjemplo.sql
│   │   └── 04_InsertMasivo.sql   <-- Genera 500 registros aleatorios
│   ├── Diagramas/
│   │   └── Escolar_ERD.png
│   ├── AppDemo/
│   │   └── Program.cs
│   └── Documentacion.md
│
└── P3_Finanzas/
├── Scripts/
│   ├── 01_CreacionTablas.sql
│   │   ├── Movimientos (IdMovimientos PK, Tipo, Monto, Fecha)
│   │   ├── Usuarios (IdUsuario PK, Nombre, Email)
│   │   ├── Cuentas (IdCuenta PK, IdUsuario FK, TipoCuenta, Saldo)
│   │   ├── Transacciones (IdTransaccion PK, IdCuenta FK, Monto, Fecha, Tipo)
│   │   ├── Categorías (IdCategoria PK, Nombre)
│   │   └── Presupuestos (IdPresupuesto PK, IdUsuario FK, IdCategoria FK, MontoAsignado, Periodo)
│   ├── 02_DatosIniciales.sql
│   ├── 03_Reportes.sql
│   └── 04_InsertMasivo.sql   <-- Genera 500 registros aleatorios
├── Diagramas/
│   └── Finanzas_ERD.png
├── AppDemo/
│   └── Program.cs
└── Documentacion.md

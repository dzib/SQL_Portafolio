# 📘 Documentación Técnica – Proyecto P1_Inventario

## 📌 Descripción general
Este proyecto fundamenta el rigor transaccional y la lógica de normalización, manejando deliberadamente datos no atómicos para simular entornos legacy y procesos de remediación ETL.

---

## 🏗️ Ciclo de Vida del Dato

* Fase 1: Diseño de Esquema e Integridad Referencial. (Script 01_CreacionTablas.sql)
-Se definen las tablas maestras, operativas y transaccionales.
-Se incluyen llaves primarias (`PK`), llaves foráneas (`FK`) y restricciones de negocio (`CHECK`, `UNIQUE`).
-Ejemplo de reglas de negocio:
	-`CHK_PrecioPos`: evita precios negativos en productos.
	-`CHK_FmtEstado`: obliga a que el campo `Estado` en pedidos tenga el formato `Estado | Acción`.
	-`IsActive` en proveedores: implementa borrado lógico.

* Fase 2: Datos iniciales. (Script 02_DatosIniciales.sql)
-Inserción manual de registros base para pruebas rápidas.
-Ejemplo: categorías iniciales como`Software | Licencias`, `Hardware | Equipos`.

* Fase 3: Generación masiva de datos. (Script 03_InsertMasivoDatos.sql)
-Inserción de 500 registros aleatorios en clientes, productos, pedidos y ventas.
-Uso de funciones como `RAND()`, `NEWID()` y `CHOOSE()` para diversificar datos.
-Manejo de transacciones con `TRY…CATCH` para rollback seguro.
-Métricas al final para validar la carga: 
	-Conteo de registros por tabla.
	-Tiempo total de ejecución en milisegundos.

* Fase 4: Pipeline de Limpieza y Normalización (ETL). (Script 04_LimpiezaDatos_ETL.sql)
-Procesos de ETL para transformar datos “sucios” en valores normalizados.
-Ejemplo: separar `Mérida | YUC` en columnas `Ciudad = Mérida`, `Estado = Yucatán`.
-Preparación de datos para análisis en BI.

* Fase 5: Reportes ejecutivos (Script 05_Reportes_BI.sql)
-Consultas analíticas para dashboards.
-Ejemplos:
	-Ventas por sucursal.
	-Pedidos por estado.
	-Top 10 productos más vendidos.
---

## 📊 Ejemplo de métricas de ejecución

| **#** | **Dimensión**       | **Registros** | **Operación**                | **Performance** |
|:-----:|:-------------------:|:-------------:|:----------------------------:|:---------------:|
| 1     | Carga Transaccional | 3,200 (Total) | Inserción Masiva Aleatoria   | 1,776 ms        |
| 2     | Integridad          | 100 %          | Validación de PK/FK y CHECK  | Verificado      |
| 3     | Normalización       | 500 + filas    | Separación de Metadata (ETL) | < 1 s            |

---

## 📂 Estructura del proyecto

```text
P1_Inventario/
├── Scripts/
│   ├── 01_CreacionTablas.sql
│   ├── 02_DatosIniciales.sql
│   ├── 03_InsertMasivoDatos.sql
│   ├── 04_LimpiezaDatos_ETL.sql
│   └── 05_Reportes_BI.sql
├── Diagramas/
│   └── Inventario_ERD.png
├── AppDemo/
│   └── Program.cs
└── Documentacion.md
```

---
## 🛠️ Key Engineering Feature

- **Idempotencia:** Scripts diseñados con `DROP IF EXISTS` para permitir despliegues continuos sin errores.
- **Borrado Lógico:** Implementación de `IsActive` para preservar la trazabilidad histórica de proveedores.
- **Seguridad:** Bloques `BEGIN TRANSACTION` con `ROLLBACK` automático para prevenir corrupción en fallos de carga masiva.


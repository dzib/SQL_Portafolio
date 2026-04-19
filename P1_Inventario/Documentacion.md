# 📘 Documentación Técnica – Proyecto P1_Inventario

## 📌 Descripción general
El proyecto P1_Inventario implementa un esquema relacional en SQL Server Management Studio 22 (SSMS) para simular un sistema de gestión de inventario.
Se diseñó con datos no atómicos (separados por |) de forma intencional, con el objetivo de demostrar procesos de normalización y limpieza (ETL) en fases posteriores.
---

## 🏗️ Fases del proyecto
1. Creación de tablas (Script 01_CreacionTablas.sql)
-Se definen las tablas maestras, operativas y transaccionales.
-Se incluyen llaves primarias (`PK`), llaves foráneas (`FK`) y restricciones de negocio (`CHECK`, `UNIQUE`).
-Ejemplo de reglas de negocio:
	-`CHK_PrecioPos`: evita precios negativos en productos.
	-`CHK_FmtEstado`: obliga a que el campo `Estado` en pedidos tenga el formato `Estado | Acción`.
	-`IsActive` en proveedores: implementa borrado lógico.

2. Datos iniciales (Script 02_DatosIniciales.sql)
-Inserción manual de registros base para pruebas rápidas.
-Ejemplo: categorías iniciales como`Software | Licencias`, `Hardware | Equipos`.

3. Generación masiva de datos (Script 03_InsertMasivoDatos.sql)
-Inserción de 500 registros aleatorios en clientes, productos, pedidos y ventas.
-Uso de funciones como `RAND()`, `NEWID()` y `CHOOSE()` para diversificar datos.
-Manejo de transacciones con `TRY…CATCH` para rollback seguro.
-Métricas al final para validar la carga: 
	-Conteo de registros por tabla.
	-Tiempo total de ejecución en milisegundos.

4. Limpieza y normalización (Script 04_LimpiezaDatos_ETL.sql)
-Procesos de ETL para transformar datos “sucios” en valores normalizados.
-Ejemplo: separar `Mérida | YUC` en columnas `Ciudad = Mérida`, `Estado = Yucatán`.
-Preparación de datos para análisis en BI.

5. Reportes ejecutivos (Script 05_Reportes_BI.sql)
-Consultas analíticas para dashboards.
-Ejemplos:
	-Ventas por sucursal.
	-Pedidos por estado.
	-Top 10 productos más vendidos.
---

## 📊 Ejemplo de métricas de ejecución
Tras la carga masiva de datos:

| Categorías | Proveedores | Clientes | Productos | Pedidos | DetallePedido | Pagos | Ventas | TiempoTotal_ms |
| :--------- | :---------- | :------- | :-------- | :------ | :------------ | :---- | :----- | :------------- |
| 100 | 100 | 500 | 500 | 500 | 500 | 500 | 500 | 1776 |
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
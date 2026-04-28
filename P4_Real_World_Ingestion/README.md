# 💎 P4: Real-World Global Supply Chain Ingestion
**Estado:** 🛠️ En Desarrollo ( Fase 4.5: BI y Observabilidad.)
---

## 🎯 Objetivo
Construir un pipeline híbrido de alto rendimiento para procesar datasets reales de cadenas de suministro globales, integrando Python 3.13 para la orquestación y SQL Server 2025 para la explotación analítica.

## 🚀 Retos Técnicos a Resolver
- **Ingesta Masiva:** Lograr tasas de transferencia de ~27k reg/seg.
- **Data Cleansing:** Normalización de datos crudos (Kaggle) mediante CTEs y T-SQL.
- **Hardware Optimization:** Ejecución eficiente mediante gestión de servicios SQL y optimización de I/O.

## 🏗️ Estructura del Proyecto (Pipeline 01-05)
1. **01_Setup_DDL:** Esquemas y constraints nominados.
2. **02_Ingesta_Pro:** Orquestación con SQLAlchemy + fast_executemany.
3. **03_Orquestacion_Transacciones:** Manejo de atomicidad con `TRY`/`CATCH`.
4. **04_ETL_Cleaning:** Estandarización y calidad de datos.
5. **05_BI_Observabilidad:** Análisis de desempeño logístico.

## 🛠️ 📝
- **"Reto Técnico: Scope de variables en lotes SQL (GO)"**
Este error ocurrió porque en SQL Server, cuando usamos la palabra clave `GO`, el motor de base de datos finaliza el lote (batch) y "olvida" las variables declaradas anteriormente. Al tener un `GO` después de declarar @StartTime, la variable de tiempo dejó de existir para el bloque siguiente.

- **Error en `FROM Analytics.SupplyChain_Shipments`**
- Este ocurre porque SQL Server todavía no ha actualizado su "caché" de metadatos (IntelliSense). Como se acaba de crear la tabla hace unos segundos mediante un script, VS Code cree que aún no existe y por eso la marca en rojo.
-- **Cómo se soluciono:**
Refrescar IntelliSense: En el VS Code, abrimos la paleta de comandos con (Ctrl + Shift + P) y ejecutamos "MS SQL: Refresh IntelliSense Cache". Posterior se ejecuta la consulta.

- **Troubleshooting de Infraestructura de Desarrollo**
- Ejecución de "limpieza de entorno", lo que sucedió es que Git intento rastrear archivos del sistema operativo y/o carpetas de configuración de usuario, debido a que el repositorio se inicializó o se activó en una carpeta superior en la jerarquía de directorios.
-- **Plan de Acción: Resetear el Tracking**
Se procede a borrar el rastreo del archivo `.git` en la carpeta del usuario. Regresamos al fichero del proyecto. En ocasiones VS Code mantiene en memoria el conteo de archivos aunque ya no existan es necesario cerar VS Code por completo y abrirlo directamente a la carpeta correspondiente.

- **Error de `Index out of range` o Reto de Entorno de Desarrollo**
- No es un error del código SQL, sino un pequeño "glitch" o fallo de comunicación de la extensión SQLTools o del servidor de lenguaje de VS Code al intentar procesar el archivo.
- **Solucion:**
Asegurar de que no haya un `GO` que esté confundiendo a la extensión

- **Escenario de "Dependencias de Base de Datos"**
- Reto: Error al intentar eliminar una columna con una restricción de valor predeterminado (Default Constraint).
- Causa: SQL Server protege la integridad referencial impidiendo el borrado de columnas que tienen objetos dependientes activos.
- **Solución Aplicada:**
Se procedió con la ejecución del pipeline principal, validando que el script de limpieza fuera capaz de manejar la existencia previa de la columna mediante el bloque `IF NOT EXISTS` y SQL Dinámico (`sp_executesql`).

# 💎 P4: Real-World Global Supply Chain Ingestion
**Estado:** 🛠️ En Desarrollo (Fase 01: Setup)
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
3. **03_Orquestacion_Transacciones:** Manejo de atomicidad con TRY/CATCH.
4. **04_ETL_Cleaning:** Estandarización y calidad de datos.
5. **05_BI_Observabilidad:** Análisis de desempeño logístico.

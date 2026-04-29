/*
========================================================================================================================
PROYECTO: P4_Real_World_Ingestion - Global Supply Chain Analytics (Kaggle Dataset)
FASE: 4.4.1 (SQL) - Corrección de Anomalías Nulas en la tabla de envíos.
AUTOR: Alberto Dzib
VERSIÓN: 1.1
ARCHIVO: HOTFIX (FIX_NULL_ANOMALIES.sql)
DESCRIPCIÓN:
    - Identificación y corrección de registros con anomalías nulas en la tabla de envíos posterior a la ingesta.
    - Asegurar que todos los registros tengan un valor definido en la columna Is_Anomaly luego de la verificación de anomalías.
========================================================================================================================
*/

USE P4_Global_SupplyChain;
GO

-- FIX DE INTEGRIDAD: Asegurar que registros existentes no queden como NULL
UPDATE Analytics.SupplyChain_Shipments
SET Is_Anomaly = 0
WHERE Is_Anomaly IS NULL;

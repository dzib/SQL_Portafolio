"""
=======================================================================================================================================
PROYECTO: P4_Real_World_Ingestion
FASE: 4.2.2 - Ingesta de Alta Velocidad (Kaggle a SQL)
AUTOR: Alberto Dzib
DESCRIPCIÓN: 
    - Carga masiva del dataset DataCo (~180k registros) usando fast_executemany.
    - Optimización de rendimiento para alcanzar velocidades cercanas a 27k registros/segundo.
    - Manejo robusto de errores y reportes detallados de tiempos y velocidades.
=======================================================================================================================================
"""

import pandas as pd
import time
from sqlalchemy import text
from db_connect import get_engine  # Reutilizamos la conexión Python-SQL Server optimizada para cargas masivas.

def bulk_load():
    engine = get_engine()
    file_path = "data/DataCoSupplyChainDataset.csv"
    
    print("📖 Leyendo dataset de Kaggle...")
    # Usamos el latin-1 porque estos datasets suelen traer caracteres especiales.
    df = pd.read_csv(file_path, encoding='latin-1')

# -- -----------------------------------------------------------------------------------------------------------------------------------
    # 1. Mapeo y Limpieza básica de columnas para Staging
# -- -----------------------------------------------------------------------------------------------------------------------------------
    # Seleccionamos las columnas que definimos en nuestro DDL
    df_staging = df[[
        'Type', 'Days for shipping (real)', 'Days for shipment (scheduled)',
        'Benefit per order', 'Sales per customer', 'Delivery Status',
        'Late_delivery_risk', 'Category Id', 'Category Name',
        'Customer City', 'Customer Country', 'order date (DateOrders)',
        'Order Region', 'Order Item Total'
    ]].copy()

    # Renombramos para que coincidan exactamente con SQL
    df_staging.columns = [
        'Type', 'Days_for_shipping_real', 'Days_for_shipment_scheduled',
        'Benefit_per_order', 'Sales_per_customer', 'Delivery_Status',
        'Late_delivery_risk', 'Category_ID', 'Category_Name',
        'Customer_City', 'Customer_Country', 'Order_Date_Raw',
        'Order_Region', 'Order_Item_Total'
    ]

    print(f"🚀 Iniciando ingesta masiva de {len(df_staging):,} registros...")
    start_time = time.time()

    try:
        with engine.begin() as conn:
            # Limpiamos staging antes de cargar (Idempotencia)
            conn.execute(text("TRUNCATE TABLE Staging.Kaggle_SupplyChain_Raw"))
            
            # Ejecución de la carga masiva
            df_staging.to_sql(
                name='Kaggle_SupplyChain_Raw',
                con=conn,
                schema='Staging',
                if_exists='append',
                index=False,
                chunksize=10000 # Bloques para estabilidad de memoria
            )

        end_time = time.time()
        total_time = end_time - start_time
        reg_per_sec = len(df_staging) / total_time

        print("=====================================================")
        print("✅ INGESTA COMPLETADA CON ÉXITO")
        print(f"⏱️ Tiempo total: {total_time:.2f} segundos")
        print(f"📊 Velocidad: {reg_per_sec:.2f} registros/seg")
        print("=====================================================")

    except Exception as e:
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print(f"❌ ERROR durante la carga masiva: {e}")
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

if __name__ == "__main__":
    bulk_load()

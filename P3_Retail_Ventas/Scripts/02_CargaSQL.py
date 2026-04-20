"""
============================================================================================================================================
PROYECTO: P2_Retail_Ventas
FASE: 2 - Carga de Datos (Ingesta Python -> SQL Server)
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Lectura de dataset masivo (50k registros).
    - Conexión mediante SQLAlchemy y pyodbc.
    - Carga automatizada a tabla de Staging en SQL Server 2025.
============================================================================================================================================
"""

import pandas as pd
from sqlalchemy import create_engine # Capa de traducción entre Python (DataFrames) y SQL Server.
import urllib
import time

# -------------------------------------------------------------------------------------------------------------------------------------------
# 1. CONFIGURACIÓN DE CONEXIÓN (La llave de acceso)
# -------------------------------------------------------------------------------------------------------------------------------------------
# Importante: Garantizar el nombre del servidor coincida con el implementado en SSMS.
server = 'localhost' # Nombre de la instancia.
database = 'P3_Retail_VentasDB'
params = urllib.parse.quote_plus(
    f'DRIVER={{ODBC Driver 17 for SQL Server}};' # Controlador ODBC para SQL Server version 17 por su estabilidad y compatibilidad.
    f'SERVER={server};'
    f'DATABASE={database};'
    f'Trusted_Connection=yes;'
)
# Creamos el engine de SQLAlchemy para la conexión a SQL Server.
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

def ejecutar_ingesta():
    start_time = time.time()
    print(f"📡 Conectando a {database}...")
    
    try:
        # -------------------------------------------------------------------------------------------------------------------------------------
        # 2. LECTURA DEL DATASET
        # -------------------------------------------------------------------------------------------------------------------------------------
        ruta_csv = 'P3_Retail_Ventas/Datos/Ventas_Retail_Masivo.csv'
        df = pd.read_csv(ruta_csv)
        print(f"📖 Dataset cargado en memoria: {len(df):,} registros.")

        # -------------------------------------------------------------------------------------------------------------------------------------
        # 3. CARGA A SQL SERVER (Aplicando el método fast_executemany por el rendimiento)
        # -------------------------------------------------------------------------------------------------------------------------------------
        print("🚚 Iniciando transferencia de datos a SQL Server...")
        df.to_sql('Staging_Ventas', schema='dbo', con=engine, if_exists='replace', index=False)
        
        end_time = time.time()
        print("=====================================================")
        print("         ✅ INGESTA COMPLETADA CON ÉXITO")
        print("=====================================================")
        print(f"    ⏱️ Tiempo total: {round(end_time - start_time, 2)} segundos")
        print(f"    📊 Destino: [dbo].[Staging_Ventas]")
        print("=====================================================")

    except Exception as e:
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print(f"❌ ERROR CRÍTICO durante la ingesta: {str(e)}")
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

if __name__ == "__main__":
    ejecutar_ingesta()

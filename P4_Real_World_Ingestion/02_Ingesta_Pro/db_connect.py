"""
=======================================================================================================================================
PROYECTO: P4_Real_World_Ingestion - Global Supply Chain Analytics (Kaggle Dataset)
FASE: 4.2 - Módulo de Conexión Robusta a SQL Server
AUTOR: Alberto Dzib
DESCRIPCIÓN:
    - Establece el puente entre Python y SQL Server 2025 usando SQLAlchemy.
    - Configuración segura mediante variables de entorno (.env).
    - Optimización para cargas masivas con fast_executemany=True.
=======================================================================================================================================
"""

import os # Para acceder a variables de entorno.
from dotenv import load_dotenv # Para cargar variables de entorno desde un archivo .env.
from sqlalchemy import create_engine, text # create_engine para establecer la conexión, text para ejecutar consultas SQL de prueba.
import urllib # Para construir la cadena de conexión de manera segura y compatible con SQL Server.

# --------------------------------------------------------------------------------------------------------------------------------------
# 1. CARGAR CONFIGURACIÓN desde .env
# --------------------------------------------------------------------------------------------------------------------------------------
load_dotenv()

def get_engine():
    """Configura y retorna el motor de conexión SQLAlchemy."""
    server = os.getenv('DB_SERVER')
    database = os.getenv('DB_NAME')
    
    # Driver estándar para SQL Server en Windows. Es recomendable verificar que esté instalado en el entorno donde se ejecutará el script.
    driver = "ODBC Driver 17 for SQL Server"
    
    # String de conexión para Windows Authentication (Trusted Connection).
    params = urllib.parse.quote_plus(
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"Trusted_Connection=yes;"
    )
    
    conn_str = f"mssql+pyodbc:///?odbc_connect={params}"
    
    try:
        # fast_executemany=True es la clave para obtener altas velocidades de carga.
        engine = create_engine(conn_str, fast_executemany=True)
        return engine
    except Exception as e:
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print(f"❌ Error al crear el engine: {e}")
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        return None # En caso de error, retornamos None para manejarlo en la función de prueba.

def test_connection():
    """Prueba rápida de salud de la conexión."""
    engine = get_engine()
    if engine:
        try:
            with engine.connect() as conn:
                result = conn.execute(text("SELECT @@VERSION")).fetchone()
                print("=====================================================")
                print("✅ CONEXIÓN EXITOSA A SQL SERVER 2025")
                print(f"🚀 Versión: {result[0][:50]}...")
                print("=====================================================")
        except Exception as e:
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            print(f"❌ Fallo en la prueba de conexión: {e}")
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

if __name__ == "__main__":
    test_connection()

"""
=======================================================================================================================================
PROYECTO: P3_Retail_Ventas
FASE: 4 - Business Intelligence (Analítica Híbrida Python-SQL)
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Conexión a base de datos de producción P3_Retail_VentasDB.
    - Extracción de datos normalizados para análisis de desempeño.
    - Generación de KPIs: Top Vendedores y Métodos de Pago más utilizados.
======================================================================================================================================
"""

import pandas as pd
from sqlalchemy import create_engine # Capa de traducción entre Python (DataFrames) y SQL Server.
import urllib # Para construir la cadena de conexión de manera segura y compatible con SQL Server.
import time # Para medir el tiempo de ejecución del proceso de analítica.

# ------------------------------------------------------------------------------------------------------------------------------------
# 1. CONFIGURACIÓN DE CONEXIÓN
# ------------------------------------------------------------------------------------------------------------------------------------
server = 'localhost'
database = 'P3_Retail_VentasDB'
params = urllib.parse.quote_plus(
    f'DRIVER={{ODBC Driver 17 for SQL Server}};'
    f'SERVER={server};'
    f'DATABASE={database};'
    f'Trusted_Connection=yes;'
)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}") # Creamos el engine de SQLAlchemy para la conexión a SQL Server.

def generar_reporte_bi():
    print("📊 Generando Reporte de Inteligencia de Negocios...")
    start_time = time.time()

    try:
        # -----------------------------------------------------------------------------------------------------------------------------
        # 2. EXTRACCIÓN MEDIANTE SQL (Consumiendo la tabla ya limpia)
        # -----------------------------------------------------------------------------------------------------------------------------
        query = """
            SELECT 
                Vendedor, 
                SUM(TotalVenta) as Ventas_Totales,
                COUNT(IdVenta) as Cantidad_Transacciones
            FROM Ventas.DetalleVentas
            GROUP BY Vendedor
            ORDER BY Ventas_Totales DESC
        """
        
        df_ranking = pd.read_sql(query, engine)

        # -----------------------------------------------------------------------------------------------------------------------------
        # 3. TRANSFORMACIÓN ADICIONAL CON PANDAS (KPI de Ticket Promedio)
        # -----------------------------------------------------------------------------------------------------------------------------
        df_ranking['Ticket_Promedio'] = (df_ranking['Ventas_Totales'] / df_ranking['Cantidad_Transacciones']).round(2)

        # -----------------------------------------------------------------------------------------------------------------------------
        # 4. PRESENTACIÓN DE RESULTADOS
        # -----------------------------------------------------------------------------------------------------------------------------
        # Se aplica formato de moneda y miles a las columnas numéricas.
        df_ranking['Ventas_Totales'] = df_ranking['Ventas_Totales'].apply(lambda x: f"${x:,.2f}") # Formato de moneda con separador de miles y dos decimales.
        df_ranking['Ticket_Promedio'] = df_ranking['Ticket_Promedio'].apply(lambda x: f"${x:,.2f}") # Formato de moneda para ticket promedio.
        df_ranking['Cantidad_Transacciones'] = df_ranking['Cantidad_Transacciones'].apply(lambda x: f"{x:,}") # Formato de miles para cantidad de transacciones.

        print("="*50)
        print("\n🏆 TOP 5 VENDEDORES (RANKING GLOBAL)")
        print("="*70) #Ajustamos el ancho del separador para mejorar la estética.
        print(df_ranking.head(5).to_string(index=False, justify='center', col_space=20)) # Ajustamos el espacio entre columnas para mejorar la legibilidad.
        print("="*70)
        
        # Métrica por Método de Pago (Consumiendo la columna que limpiamos con la CTE)
        query_pagos = "SELECT MetodoPago, COUNT(*) as Frecuencia FROM Ventas.DetalleVentas GROUP BY MetodoPago"
        df_pagos = pd.read_sql(query_pagos, engine)
        df_pagos['Frecuencia'] = df_pagos['Frecuencia'].apply(lambda x: f"{x:,}") # Formato de miles para frecuencia.
        
        print("\n💳 PREFERENCIAS DE PAGO")
        print("-"*30)
        print(df_pagos.to_string(index=False))
        print("-"*30)

        end_time = time.time()
        print(f"\n✅ Reporte generado en {round(end_time - start_time, 3)} segundos.")

    except Exception as e:
        print("!"*60)
        print(f"❌ Error al procesar analítica: {str(e)}")
        print("!"*60)

if __name__ == "__main__":
    generar_reporte_bi()

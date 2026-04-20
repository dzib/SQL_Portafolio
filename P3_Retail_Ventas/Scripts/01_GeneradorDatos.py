"""
===========================================================================================================
PROYECTO: P3_Retail_Ventas - Simulación de salida de datos de un punto de venta (POS)
FASE: 1 - Generador de Datos
AUTOR: Alberto Dzib
VERSIÓN: 1.0
DESCRIPCIÓN: 
    - Objetivo Técnico: Generar un archivo CSV de 50,000 filas con datos "sucios" y variados 
      para nuestro futuro ETL.
===========================================================================================================
"""

import pandas as pd
from faker import Faker
import random
import os
from datetime import datetime

# ---------------------------------------------------------------------------------------------------------
# CONFIGURACIÓN INICIAL
# ---------------------------------------------------------------------------------------------------------
fake = Faker()  # Instancia de Faker para generar datos aleatorios.
Faker.seed(42)  # Garantiza que el dataset sea reproducible.

def generar_dataset_ventas(num_registros=50000):
    print(f"🚀 Iniciando generación de {num_registros} registros...")
    
    data = []
    productos = ['Laptop Pro', 'Monitor 4K', 'Teclado Mecánico', 'Mouse Gamer', 'Hub USB-C', 'Silla Ergonómica']
    
    # -----------------------------------------------------------------------------------------------------
    # 1. BUCLE DE GENERACIÓN DE DATOS (Simulación de Transacciones)
    # -----------------------------------------------------------------------------------------------------
    for i in range(num_registros):
        fecha = fake.date_time_between(start_date='-1y', end_date='now')
        producto = random.choice(productos)
        cantidad = random.randint(1, 5)
        precio_unitario = round(random.uniform(20.0, 1500.0), 2)
        total = round(cantidad * precio_unitario, 2)
        
        # Metadata para reto ETL: Formato "MetodoPago|Ciudad|Vendedor"
        metadata = f"{random.choice(['Efectivo', 'Tarjeta', 'Transferencia'])}|{fake.city()}|{fake.name()}"
        
        data.append({
            'ID_Venta': i + 1,
            'Fecha': fecha,
            'Producto': producto,
            'Cantidad': cantidad,
            'Precio_Unitario': precio_unitario,
            'Total': total,
            'Metadata_Local': metadata
        })
    
    # -----------------------------------------------------------------------------------------------------
    # 2. PROCESAMIENTO Y EXPORTACIÓN (Pandas Engine)
    # -----------------------------------------------------------------------------------------------------
    # Convertimos la lista de diccionarios a un DataFrame de Pandas.
    df = pd.DataFrame(data)
    
        # Verificamos si la carpeta "Datos" existe, si no, la creamos.
    if not os.path.exists('P3_Retail_Ventas/Datos'): 
        os.makedirs('P3_Retail_Ventas/Datos')
        print("📂 Carpeta 'Datos' creada.")

    # Exportamos el DataFrame a un archivo CSV.    
    nombre_archivo = 'P3_Retail_Ventas/Datos/Ventas_Retail_Masivo.csv'
    df.to_csv(nombre_archivo, index=False, encoding='utf-8')
    
    print(f"✅ Archivo '{nombre_archivo}' generado con éxito.")

if __name__ == "__main__":
    generar_dataset_ventas()


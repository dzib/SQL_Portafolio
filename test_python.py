from collections import namedtuple
from datetime import datetime

# Concepto: namedtuple (Fila inmutable y ligera)
# Ideal para representar registros de base de datos sin usar mucha memoria
Venta = namedtuple('Venta', ['id', 'producto', 'precio', 'fecha'])

# Creamos una instancia (simulando una fila de SQL)
nueva_venta = Venta(id=1, producto='Monitor 4K', precio=350.50, fecha=datetime.now())

print(f"🚀 Objeto creado: {nueva_venta}")
print(f"📦 Producto: {nueva_venta.producto} | 💰 Precio: ${nueva_venta.precio}")
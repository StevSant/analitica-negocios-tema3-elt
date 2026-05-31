# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""
Generador de datos crudos para la práctica ELT (Tema 3).

Produce 3 CSV que simulan tres sistemas fuente distintos de la empresa
RetailXYZ (variedad de fuentes). Los archivos se cargan TAL CUAL en la
capa RAW de BigQuery; toda la transformación ocurre después, dentro del
warehouse (paradigma ELT).

Uso:
    uv run generate_data.py

Solo usa la librería estándar: corre en cualquier máquina sin instalar nada.
"""

import csv
import os
import random
from datetime import date, timedelta

# ---------------------------------------------------------------------------
# CONFIG  (capa de configuración del script — ajusta aquí, no más abajo)
# ---------------------------------------------------------------------------
SEED = 42                     # reproducibilidad: misma semilla -> mismos datos
N_PRODUCTOS = 200
N_CLIENTES = 5_000
N_VENTAS = 300_000            # filas de hechos; sube/baja según el lab
FECHA_INICIO = date(2024, 1, 1)
FECHA_FIN = date(2025, 12, 31)
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "data")

CATEGORIAS = {
    "Tecnología": ["Laptops", "Celulares", "Accesorios"],
    "Hogar": ["Cocina", "Muebles", "Decoración"],
    "Moda": ["Hombre", "Mujer", "Calzado"],
    "Deportes": ["Fitness", "Outdoor", "Ciclismo"],
}
MARCAS = ["Acme", "Globex", "Initech", "Umbrella", "Stark", "Wayne"]
CIUDADES = ["Manta", "Portoviejo", "Guayaquil", "Quito", "Cuenca", "Montecristi"]
SEGMENTOS = ["Retail", "Mayorista", "Corporativo", "VIP"]
CANALES = ["Online", "Tienda", "App", "Teléfono"]


def _ensure_output_dir() -> None:
    os.makedirs(OUTPUT_DIR, exist_ok=True)


def _write_csv(filename: str, header: list, rows: list) -> str:
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(header)
        writer.writerows(rows)
    return path


def generar_productos() -> list:
    """dim fuente: catálogo de productos con costo unitario."""
    productos = []
    for i in range(1, N_PRODUCTOS + 1):
        categoria = random.choice(list(CATEGORIAS.keys()))
        subcategoria = random.choice(CATEGORIAS[categoria])
        costo = round(random.uniform(5, 800), 2)
        productos.append(
            [
                f"P{i:04d}",
                f"{subcategoria} {random.choice(MARCAS)} {i}",
                categoria,
                subcategoria,
                costo,
                random.choice(MARCAS),
            ]
        )
    return productos


def generar_clientes() -> list:
    """dim fuente: maestro de clientes."""
    clientes = []
    for i in range(1, N_CLIENTES + 1):
        registro = FECHA_INICIO - timedelta(days=random.randint(0, 1095))
        clientes.append(
            [
                f"C{i:05d}",
                f"Cliente {i}",
                random.choice(CIUDADES),
                random.choice(SEGMENTOS),
                registro.isoformat(),
            ]
        )
    return clientes


def generar_ventas(productos: list, clientes: list) -> list:
    """fuente transaccional: hechos de venta que referencian las dim."""
    rango_dias = (FECHA_FIN - FECHA_INICIO).days
    product_ids = [p[0] for p in productos]
    costo_por_producto = {p[0]: p[4] for p in productos}
    customer_ids = [c[0] for c in clientes]

    ventas = []
    for i in range(1, N_VENTAS + 1):
        product_id = random.choice(product_ids)
        costo = costo_por_producto[product_id]
        markup = random.uniform(1.2, 2.5)
        precio_unitario = round(costo * markup, 2)
        fecha = FECHA_INICIO + timedelta(days=random.randint(0, rango_dias))
        ventas.append(
            [
                f"O{i:07d}",
                fecha.isoformat(),
                random.choice(customer_ids),
                product_id,
                random.randint(1, 10),
                precio_unitario,
                round(random.choice([0, 0, 0, 0.05, 0.10, 0.15, 0.30]), 2),
                random.choice(CANALES),
            ]
        )
    return ventas


def main() -> None:
    random.seed(SEED)
    _ensure_output_dir()

    productos = generar_productos()
    clientes = generar_clientes()
    ventas = generar_ventas(productos, clientes)

    p1 = _write_csv(
        "productos.csv",
        ["product_id", "nombre", "categoria", "subcategoria", "costo_unitario", "marca"],
        productos,
    )
    p2 = _write_csv(
        "clientes.csv",
        ["customer_id", "nombre", "ciudad", "segmento", "fecha_registro"],
        clientes,
    )
    p3 = _write_csv(
        "ventas.csv",
        [
            "order_id",
            "fecha",
            "customer_id",
            "product_id",
            "cantidad",
            "precio_unitario",
            "descuento",
            "canal",
        ],
        ventas,
    )

    print("CSV generados:")
    for path, n in ((p1, N_PRODUCTOS), (p2, N_CLIENTES), (p3, N_VENTAS)):
        size_mb = os.path.getsize(path) / (1024 * 1024)
        print(f"  {path}  ({n:,} filas, {size_mb:.1f} MB)")


if __name__ == "__main__":
    main()

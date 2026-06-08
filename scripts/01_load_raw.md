# 01 — Carga de la capa RAW (la "L" del ELT)

> **Idea clave del ELT:** primero **cargamos** los datos crudos sin tocarlos
> (todo como `STRING`), y recién dentro del warehouse los **transformamos**.
> En ETL clásico habríamos limpiado/tipado los datos ANTES de cargarlos, en un
> servidor de capacidad fija. Aquí la transformación la hace el cómputo elástico
> de BigQuery.

## Requisito previo

Haber ejecutado `00_setup.sql` (crea los datasets `raw`, `staging`, `analytics`).

## Pasos en la consola web de BigQuery (por cada CSV)

1. En el panel **Explorer**, despliega tu proyecto y haz clic en el dataset `raw`.
2. Clic en **CREATE TABLE** (Crear tabla).
3. **Source / Origen:**
   - *Create table from:* **Upload**
   - *Select file:* elige el CSV correspondiente desde la carpeta `data/`
   - *File format:* **CSV**
4. **Destination / Destino:**
   - *Table:* el nombre indicado abajo (`productos`, `clientes`, `ventas`).
5. **Schema / Esquema:** activa **Edit as text** y pega el bloque de esquema
   de abajo. Cargamos **todo como STRING** a propósito (carga cruda).
6. **Advanced options / Opciones avanzadas:**
   - *Header rows to skip / Filas de encabezado a omitir:* **1**
7. Clic en **CREATE TABLE**. Repite para los 3 archivos.

> ⏱️ Los 3 archivos juntos cargan en ~1 minuto. `ventas.csv` (~15 MB / 300k
> filas) es el más pesado y está muy por debajo del límite de 100 MB de la UI.

---

### Tabla `raw.productos`  (origen: `data/productos.csv`)

```text
product_id:STRING,nombre:STRING,categoria:STRING,subcategoria:STRING,costo_unitario:STRING,marca:STRING
```

### Tabla `raw.clientes`  (origen: `data/clientes.csv`)

```text
customer_id:STRING,nombre:STRING,ciudad:STRING,segmento:STRING,fecha_registro:STRING
```

### Tabla `raw.ventas`  (origen: `data/ventas.csv`)

```text
order_id:STRING,fecha:STRING,customer_id:STRING,product_id:STRING,cantidad:STRING,precio_unitario:STRING,descuento:STRING,canal:STRING
```

---

## Verificación rápida

Ejecuta en el editor de consultas (reemplaza `august-tower-470819-s6`):

```sql
SELECT 'productos' AS tabla, COUNT(*) AS filas FROM `august-tower-470819-s6.raw.productos`
UNION ALL SELECT 'clientes', COUNT(*) FROM `august-tower-470819-s6.raw.clientes`
UNION ALL SELECT 'ventas',   COUNT(*) FROM `august-tower-470819-s6.raw.ventas`;
```

Deberías ver **200**, **5 000** y **300 000** filas respectivamente. Si coincide,
la capa RAW está lista y pasamos a `02_staging.sql`.

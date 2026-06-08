# Guía práctica — Demo ELT en 15 minutos (Grupo 3)

**Proyecto BigQuery:** `august-tower-470819-s6`  
**Patrón:** ELT (Extract → **Load** → **Transform**) · Arquitectura medallion  
**Duración total:** ≤ 15 min · **3 integrantes** (todos deben poder explicar cualquier bloque)

---

## Antes de mañana (hacer en casa — 30 min)

- [ ] Entrar a [BigQuery](https://console.cloud.google.com/bigquery) con el proyecto `august-tower-470819-s6`.
- [ ] Tener los CSV en `data/` accesibles (USB, Drive o repo clonado).
- [ ] Ensayar el flujo completo **una vez** siguiendo esta guía.
- [ ] Si el proyecto ya tiene datos de un ensayo, puedes **reutilizarlo** mañana (ahorra ~5 min) o borrar datasets y repetir en vivo.

> **Regla de oro:** datasets y tablas en región **US**. Si algo falla por región, recrea con `00_setup.sql`.

---

## Reparto de roles y tiempos

| Min | Integrante | Qué hace | Archivos |
|-----|------------|----------|----------|
| 0–4 | **A** | Setup + carga RAW (la **L**) | `00_setup.sql`, `01_load_raw.md` |
| 4–9 | **B** | Transformación (la **T**) | `02_staging.sql`, `03_analytics_star.sql` |
| 9–15 | **C** | KPIs + visual + costos | `04_kpis.sql`, `06_visualizaciones.sql`, `05_cost_demo.sql` |

Mientras uno ejecuta, los otros **narran** (frases sugeridas abajo).

---

## Bloque A — Carga cruda (~4 min) · Integrante A

### Paso 1 — Abrir BigQuery (30 s)
1. Consola → proyecto **`august-tower-470819-s6`**.
2. Mostrar Explorer vacío (o con datasets si reutilizan ensayo).

**Narrar:** *"En ELT primero cargamos crudo; en ETL limpiaríamos antes en un servidor aparte."*

### Paso 2 — Crear datasets (30 s)
1. **+ Consulta en SQL** → pegar y ejecutar todo `scripts/00_setup.sql`.
2. Mostrar en Explorer: `raw`, `staging`, `analytics`.

### Paso 3 — Subir 3 CSV (2 min)
Por cada archivo, en dataset **`raw`** → **Crear tabla** → **Subir**:

| Archivo | Nombre tabla | Esquema (Editar como texto) | Encabezado |
|---------|--------------|----------------------------|------------|
| `productos.csv` | `productos` | `product_id:STRING,nombre:STRING,categoria:STRING,subcategoria:STRING,costo_unitario:STRING,marca:STRING` | Omitir **1** fila |
| `clientes.csv` | `clientes` | `customer_id:STRING,nombre:STRING,ciudad:STRING,segmento:STRING,fecha_registro:STRING` | Omitir **1** fila |
| `ventas.csv` | `ventas` | `order_id:STRING,fecha:STRING,customer_id:STRING,product_id:STRING,cantidad:STRING,precio_unitario:STRING,descuento:STRING,canal:STRING` | Omitir **1** fila |

**Importante:** desactivar detección automática; todo **STRING**.

### Paso 4 — Verificar (1 min)
```sql
SELECT 'productos' AS tabla, COUNT(*) AS filas FROM `august-tower-470819-s6.raw.productos`
UNION ALL SELECT 'clientes', COUNT(*) FROM `august-tower-470819-s6.raw.clientes`
UNION ALL SELECT 'ventas',   COUNT(*) FROM `august-tower-470819-s6.raw.ventas`;
```
**Debe mostrar:** 200 · 5 000 · 300 000.

---

## Bloque B — Transformación en el warehouse (~5 min) · Integrante B

### Paso 5 — Staging (2 min)
1. Nueva consulta → ejecutar todo `scripts/02_staging.sql`.
2. Abrir `staging.stg_ventas` → mostrar columnas `DATE`, `NUMERIC`, `monto_neto`.

**Narrar:** *"La transformación ocurre dentro de BigQuery, con cómputo elástico. Son vistas: no duplican almacenamiento."*

### Paso 6 — Modelo estrella (3 min)
1. Ejecutar todo `scripts/03_analytics_star.sql`.
2. En Explorer, mostrar `analytics`: `dim_cliente`, `dim_producto`, `dim_fecha`, `fact_ventas`.
3. Señalar: **particionada por fecha** y **clusterizada** (menor costo en consultas por periodo).

**Narrar:** *"Modelo estrella: un hecho (`fact_ventas`) y dimensiones para contexto. Menos JOINs = consultas más rápidas."*

Verificación rápida:
```sql
SELECT COUNT(*) AS filas FROM `august-tower-470819-s6.analytics.fact_ventas`;
-- 300000
```

---

## Bloque C — KPIs, visual y costos (~6 min) · Integrante C

### Paso 7 — KPIs (2 min)
1. Ejecutar todo `scripts/04_kpis.sql`.
2. Consultar:
```sql
SELECT * FROM `august-tower-470819-s6.analytics.kpi_ventas_mensuales` ORDER BY anio, mes;
SELECT * FROM `august-tower-470819-s6.analytics.kpi_margen_categoria` ORDER BY margen DESC LIMIT 5;
```

**Narrar:** *"Un KPI nuevo = una vista SQL más. Eso es la agilidad del ELT."*

### Paso 8 — Antes / después visual (2 min)
Ejecutar consultas de `scripts/06_visualizaciones.sql` (una por pestaña).

1. **Antes (raw)** vs **después (staging)** — misma venta, distinto formato.
2. **KPI mensual** → pestaña **Visualización** → gráfico de **línea** (`nombre_mes` × `ventas_netas`).
3. **Por canal** → gráfico **circular** (`canal` × `ventas_netas`).

**Narrar:** *"Pasamos de 300 000 filas crudas a métricas que gerencia puede leer en segundos."*

### Paso 9 — Demo de costos (2 min) · 4 ejecuciones separadas

⚠️ **No ejecutar todo `05_cost_demo.sql` de una vez** (error en `DECLARE`).

**9a** — Nueva pestaña, solo:
```sql
CREATE OR REPLACE TABLE `august-tower-470819-s6.analytics.fact_ventas_flat` AS
SELECT * FROM `august-tower-470819-s6.analytics.fact_ventas`;
```

**9b** — Consulta **(A)** particionada; anotar bytes del aviso antes de Ejecutar:
```sql
SELECT canal, ROUND(SUM(monto_neto), 2) AS ventas
FROM `august-tower-470819-s6.analytics.fact_ventas`
WHERE fecha BETWEEN '2025-01-01' AND '2025-03-31'
GROUP BY canal;
```

**9c** — Consulta **(B)** plana; anotar bytes:
```sql
SELECT canal, ROUND(SUM(monto_neto), 2) AS ventas
FROM `august-tower-470819-s6.analytics.fact_ventas_flat`
WHERE fecha BETWEEN '2025-01-01' AND '2025-03-31'
GROUP BY canal;
```

**9d** — Nueva pestaña **solo** con bytes reales (reemplazar los `0`):
```sql
DECLARE bytes_particionada INT64 DEFAULT 0;   -- bytes de (A)
DECLARE bytes_plana        INT64 DEFAULT 0;   -- bytes de (B)
DECLARE precio_usd_por_tib FLOAT64 DEFAULT 6.25;

SELECT
  bytes_particionada AS bytes_A_particionada,
  bytes_plana        AS bytes_B_plana,
  ROUND(bytes_particionada / POW(1024, 4) * precio_usd_por_tib, 6) AS costo_A_usd,
  ROUND(bytes_plana        / POW(1024, 4) * precio_usd_por_tib, 6) AS costo_B_usd,
  ROUND((1 - SAFE_DIVIDE(bytes_particionada, bytes_plana)) * 100, 1) AS ahorro_pct;
```

**Narrar cierre:** *"Mismo resultado de negocio, ~85–90% menos bytes en la tabla particionada → menos costo y menos latencia. En ELT optimizamos con SQL; en ETL reconfiguramos un servidor fijo."*

---

## Frases clave para defensa (cualquiera del grupo)

| Pregunta del docente | Respuesta corta |
|---------------------|-----------------|
| ¿ETL vs ELT? | ELT: primero carga cruda, transforma en el warehouse elástico. |
| ¿Por qué modelo estrella? | Hechos + dimensiones → menos JOINs, KPIs más rápidos. |
| ¿Por qué particionar? | Filtros por fecha leen menos datos = menos costo. |
| ¿Cuándo adoptar ELT? | Alta volatilidad, muchas fuentes, analítica madura en nube. |
| ¿Y predictiva? | Capa `analytics` limpia alimenta modelos de ML. |

---

## Plan B (sin internet en el aula)

- Mostrar capturas del ensayo en casa.
- Tener este archivo y los `.sql` en local/USB.
- Opcional: DuckDB offline con los mismos CSV (ver `runbook.md`).

---

## Checklist final (30 s antes de presentar)

- [ ] Proyecto `august-tower-470819-s6` seleccionado en BigQuery.
- [ ] Scripts abiertos en pestañas o en el repo local.
- [ ] CSV en carpeta accesible (si harán carga en vivo).
- [ ] Roles A / B / C asignados.
- [ ] Bytes de (A) y (B) anotados si ya ensayaron el paso 9.

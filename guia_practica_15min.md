# Guía práctica — Demo ELT en 15 minutos (desde cero)

**Patrón:** ELT (Extract → **Load** → **Transform**) · Arquitectura medallion  
**Duración:** ≤ 15 min · **3 integrantes**  
**Importante:** **cada persona/grupo crea su propio proyecto** en BigQuery. No reutilicen el de otro compañero.

---

## Paso 0 — Crear proyecto nuevo en BigQuery (~2 min) · Integrante A

Hacer **en vivo** al inicio de la demo (o ensayar en casa con un proyecto de prueba que borres después).

### 0.1 Crear el proyecto

1. Ir a [Google Cloud Console](https://console.cloud.google.com/).
2. Arriba, clic en el **selector de proyecto** → **Nuevo proyecto**.
3. Nombre sugerido: `elt-retail-grupo3` (o tu nombre).
4. Clic en **Crear**.
5. **Anotar el ID del proyecto** (no el nombre). Ejemplo: `elt-retail-grupo3-482910`.
   - Lo ves en el selector de proyectos o en el panel izquierdo de BigQuery.

### 0.2 Abrir BigQuery

1. Menú ☰ → **BigQuery** → **SQL workspace**.
2. Confirmar que arriba está seleccionado **tu proyecto nuevo** (Explorer vacío, sin datasets).

### 0.3 Reemplazar `PROJECT_ID` en los scripts

En **cada archivo `.sql`** (y en las consultas de esta guía), sustituye `PROJECT_ID` por tu ID real.

**Opción rápida en BigQuery:** al pegar un script, **Ctrl+H** (Buscar/Reemplazar):
- Buscar: `PROJECT_ID`
- Reemplazar: `tu-id-de-proyecto` (ej. `elt-retail-grupo3-482910`)
- Reemplazar todo → Ejecutar

Archivos a tocar:
- `scripts/00_setup.sql` … `06_visualizaciones.sql`
- Las consultas sueltas de verificación y costos (abajo)

> **Regla de oro:** los 3 datasets deben quedar en región **US** (`00_setup.sql` ya lo define).

---

## Antes de mañana (ensayo en casa — recomendado)

- [ ] Clonar el repo: `https://github.com/DweskZ/analitica-negocios-tema3-elt`
- [ ] Crear **un proyecto de ensayo**, ejecutar todo el flujo una vez, borrar o ignorar ese proyecto.
- [ ] Tener los CSV de `data/` en USB/Drive/laptop.
- [ ] Mañana: **proyecto nuevo desde cero** (como pide el laboratorio).

---

## Reparto de roles y tiempos

| Min | Integrante | Qué hace |
|-----|------------|----------|
| 0–2 | **A** | Crear proyecto GCP + anotar ID |
| 2–5 | **A** | `00_setup.sql` + carga 3 CSV |
| 5–10 | **B** | `02_staging.sql` + `03_analytics_star.sql` |
| 10–15 | **C** | `04_kpis.sql` + visual + `05` costos |

Mientras uno ejecuta, los otros **narran**.

---

## Bloque A — Proyecto + carga RAW (~5 min) · Integrante A

### Paso 1 — Proyecto vacío (ya hecho en Paso 0)

**Narrar:** *"Partimos de un proyecto en blanco en la nube. No hay servidor ETL: el warehouse es BigQuery."*

### Paso 2 — Crear datasets (30 s)

1. **+ Consulta en SQL** → pegar `scripts/00_setup.sql`.
2. **Ctrl+H:** `PROJECT_ID` → tu ID → Ejecutar.
3. Explorer: deben aparecer `raw`, `staging`, `analytics`.

### Paso 3 — Subir 3 CSV (2 min)

Dataset **`raw`** → **Crear tabla** → **Subir** (repetir 3 veces):

| Archivo | Tabla | Esquema (Editar como texto) | Encabezado |
|---------|-------|----------------------------|------------|
| `productos.csv` | `productos` | `product_id:STRING,nombre:STRING,categoria:STRING,subcategoria:STRING,costo_unitario:STRING,marca:STRING` | Omitir **1** |
| `clientes.csv` | `clientes` | `customer_id:STRING,nombre:STRING,ciudad:STRING,segmento:STRING,fecha_registro:STRING` | Omitir **1** |
| `ventas.csv` | `ventas` | `order_id:STRING,fecha:STRING,customer_id:STRING,product_id:STRING,cantidad:STRING,precio_unitario:STRING,descuento:STRING,canal:STRING` | Omitir **1** |

- Desactivar **detección automática**.
- Todo **STRING** (carga cruda a propósito).

### Paso 4 — Verificar (30 s)

Reemplaza `TU_PROJECT_ID` por tu ID:

```sql
SELECT 'productos' AS tabla, COUNT(*) AS filas FROM `TU_PROJECT_ID.raw.productos`
UNION ALL SELECT 'clientes', COUNT(*) FROM `TU_PROJECT_ID.raw.clientes`
UNION ALL SELECT 'ventas',   COUNT(*) FROM `TU_PROJECT_ID.raw.ventas`;
```

**Debe mostrar:** 200 · 5 000 · 300 000.

**Narrar:** *"Esto es la **L** del ELT: cargamos crudo sin transformar."*

---

## Bloque B — Transformación (~5 min) · Integrante B

### Paso 5 — Staging (2 min)

1. Pegar `02_staging.sql` → Ctrl+H `PROJECT_ID` → tu ID → Ejecutar.
2. Abrir `staging.stg_ventas` → tipos `DATE`, `NUMERIC`, columna `monto_neto`.

**Narrar:** *"La **T** ocurre dentro de BigQuery, con cómputo elástico."*

### Paso 6 — Modelo estrella (3 min)

1. Pegar `03_analytics_star.sql` → reemplazar ID → Ejecutar.
2. Mostrar en Explorer: `dim_cliente`, `dim_producto`, `dim_fecha`, `fact_ventas`.
3. Mencionar: **particionada por fecha** + **clusterizada**.

```sql
SELECT COUNT(*) AS filas FROM `TU_PROJECT_ID.analytics.fact_ventas`;
-- 300000
```

---

## Bloque C — KPIs, visual y costos (~5 min) · Integrante C

### Paso 7 — KPIs (1,5 min)

1. Ejecutar `04_kpis.sql` (con tu ID).
2. Consultar:

```sql
SELECT * FROM `TU_PROJECT_ID.analytics.kpi_ventas_mensuales` ORDER BY anio, mes;
SELECT * FROM `TU_PROJECT_ID.analytics.kpi_margen_categoria` ORDER BY margen DESC LIMIT 5;
```

**Narrar:** *"Un KPI nuevo = una vista SQL. Eso es agilidad ELT."*

### Paso 8 — Antes / después visual (1,5 min)

Consultas de `06_visualizaciones.sql` (una por pestaña, reemplazar ID):

1. Raw vs staging (tabla comparativa).
2. KPI mensual → **Visualización** → gráfico **línea**.
3. Por canal → gráfico **circular**.

### Paso 9 — Demo de costos (2 min) · 4 pestañas separadas

⚠️ No ejecutar todo `05_cost_demo.sql` junto.

**9a** — Crear tabla plana:
```sql
CREATE OR REPLACE TABLE `TU_PROJECT_ID.analytics.fact_ventas_flat` AS
SELECT * FROM `TU_PROJECT_ID.analytics.fact_ventas`;
```

**9b** — Consulta (A) particionada → **anotar bytes** antes de Ejecutar:
```sql
SELECT canal, ROUND(SUM(monto_neto), 2) AS ventas
FROM `TU_PROJECT_ID.analytics.fact_ventas`
WHERE fecha BETWEEN '2025-01-01' AND '2025-03-31'
GROUP BY canal;
```

**9c** — Consulta (B) plana → anotar bytes:
```sql
SELECT canal, ROUND(SUM(monto_neto), 2) AS ventas
FROM `TU_PROJECT_ID.analytics.fact_ventas_flat`
WHERE fecha BETWEEN '2025-01-01' AND '2025-03-31'
GROUP BY canal;
```

**9d** — Solo este bloque en pestaña nueva (pegar bytes reales):
```sql
DECLARE bytes_particionada INT64 DEFAULT 0;
DECLARE bytes_plana        INT64 DEFAULT 0;
DECLARE precio_usd_por_tib FLOAT64 DEFAULT 6.25;

SELECT
  bytes_particionada AS bytes_A,
  bytes_plana        AS bytes_B,
  ROUND((1 - SAFE_DIVIDE(bytes_particionada, bytes_plana)) * 100, 1) AS ahorro_pct;
```

**Narrar cierre:** *"Mismo resultado, ~85–90% menos bytes → menos costo en la nube."*

---

## Frases para defensa

| Pregunta | Respuesta |
|----------|-----------|
| ¿ETL vs ELT? | ELT: primero carga cruda, transforma en el warehouse. |
| ¿Por qué proyecto nuevo? | Cada equipo demuestra el flujo completo desde cero en sandbox. |
| ¿Por qué `PROJECT_ID`? | Placeholder; cada quien usa su ID de GCP. |
| ¿Modelo estrella? | Hechos + dimensiones = consultas rápidas. |
| ¿Particiones? | Menos bytes escaneados = menos costo. |

---

## Checklist antes de presentar

- [ ] Proyecto **nuevo** creado hoy (tu ID anotado en papel/notas).
- [ ] `PROJECT_ID` reemplazado en cada script que pegues.
- [ ] CSV en `data/` accesibles.
- [ ] Roles A / B / C asignados.
- [ ] Repo clonado: `github.com/DweskZ/analitica-negocios-tema3-elt`

---

## Plan B (sin internet)

Capturas del ensayo + este archivo + `.sql` en USB. Explicar el flujo con imágenes.

# Runbook del Laboratorio — Práctica ELT (Tema 3)

Guion para ejecutar la demo **en vivo y sin errores**. Pensado para **3
integrantes**, ~15 minutos. Ajusta los roles si son menos personas.

## 0. Preparación (ANTES del laboratorio — hacer en casa)

- [ ] Ejecutar `uv run generate_data.py` y confirmar que existen los 3 CSV en `data/`.
- [ ] Crear/confirmar acceso a un proyecto de **BigQuery sandbox** (cuenta Google, sin tarjeta).
- [ ] Hacer **Ctrl+H** en cada `.sql` y reemplazar `PROJECT_ID` por el ID real → guardar.
- [ ] Tener los CSV en una carpeta de fácil acceso en la máquina del lab (USB/Drive).
- [ ] Ensayar el flujo completo al menos una vez.

> **Regla de oro:** los datasets (`00_setup`) y los CSV deben quedar en la
> **misma región** (US). Si no coinciden, las consultas fallan.

---

## 1. Reparto de roles (distribución equitativa — rúbrica criterio 6)

| Integrante | Bloque | Archivos a su cargo | Tiempo |
|---|---|---|---|
| **Integrante A** | Setup + carga RAW (la "L") | `00_setup.sql`, `01_load_raw.md` | ~4 min |
| **Integrante B** | Transformación (la "T") | `02_staging.sql`, `03_analytics_star.sql` | ~5 min |
| **Integrante C** | KPIs + demo de costos | `04_kpis.sql`, `05_cost_demo.sql` | ~5 min |

> Todos deben poder explicar cualquier bloque: el docente puede preguntar a
> cualquiera. Mientras uno ejecuta, los otros narran qué está pasando.

---

## 2. Guion paso a paso

### Bloque A — Carga cruda (Integrante A) · ~4 min
1. Abrir la consola de BigQuery. Mostrar el proyecto vacío.
2. Ejecutar `00_setup.sql`. Mostrar que aparecen los datasets `raw`, `staging`, `analytics`.
3. Cargar los 3 CSV en `raw` siguiendo `01_load_raw.md` (esquema todo `STRING`).
4. Correr la consulta de verificación → mostrar **200 / 5 000 / 300 000** filas.
5. **Narrar:** "Cargamos los datos crudos sin transformar: esto es la *L* del ELT.
   En ETL clásico habríamos limpiado antes de cargar, en un servidor aparte."

### Bloque B — Transformación en el warehouse (Integrante B) · ~5 min
6. Ejecutar `02_staging.sql`. Abrir `staging.stg_ventas` y mostrar tipos ya
   casteados (DATE, INT64, NUMERIC) y las columnas derivadas `monto_neto`.
7. **Narrar:** "La transformación ocurre DENTRO de BigQuery, con su cómputo
   elástico. Usamos vistas: no ocupan almacenamiento."
8. Ejecutar `03_analytics_star.sql`. Mostrar el modelo estrella en el Explorer
   (1 hechos + 3 dimensiones) y señalar las **llaves** y que `fact_ventas` está
   **particionada por fecha y clusterizada**.

   > 👉 El "cómo mostrar" paso a paso (qué clicar y qué decir) está en la
   > **sección 5** de este runbook. Lo que ves al abrir el dataset `analytics`
   > (las 4 tablas `dim_cliente`, `dim_fecha`, `dim_producto`, `fact_ventas`)
   > **ESO es la estrella** — BigQuery no la dibuja, la explicas tú.

### Bloque C — KPIs y costos (Integrante C) · ~5 min
9. Ejecutar `04_kpis.sql`. Consultar `kpi_ventas_mensuales` y `kpi_margen_categoria`.
   **Narrar:** "Agregar un KPI = una vista SQL más. Eso es la agilidad del ELT."
10. Ejecutar `05_cost_demo.sql` paso a paso:
    - Crear `fact_ventas_flat`.
    - Antes de correr (A) y (B), **leer y anotar los bytes** del aviso del editor.
    - Pegar los bytes en el bloque `DECLARE` y correr el cálculo de ahorro.
11. **Narrar el cierre:** "La consulta sobre la tabla particionada escanea ~85-90%
    menos bytes → menos costo y menos latencia. A escala empresarial, ese es el
    ahorro que justifica migrar de ETL a ELT en la nube."

---

## 3. Checklist de defensa (posibles preguntas del docente)

- **¿Por qué ELT y no ETL?** Transforma con cómputo elástico, conserva el dato
  crudo, escala a cero, y un KPI nuevo es solo SQL.
- **¿Por qué un modelo estrella?** Desnormalizado → menos JOINs → consultas
  rápidas para analítica descriptiva/diagnóstica.
- **¿Por qué particionar por fecha?** La mayoría de los análisis filtran por
  tiempo; el *partition pruning* reduce bytes escaneados = costo.
- **¿Qué pasa si llega una fuente nueva?** Se carga cruda en `raw` y se agrega
  su `stg_*`; el resto del pipeline no cambia (agilidad/variedad de fuentes).
- **¿Cómo se conecta con analítica predictiva?** La capa `analytics` limpia y
  modelada es justo el insumo para entrenar modelos.

---

## 4. Plan B (si falla internet / login en el lab)

Tener instalado **DuckDB** local como respaldo: los mismos CSV y casi el mismo
SQL (cambian las funciones de fecha) corren offline. Mantener este runbook y los
scripts a mano para no improvisar.

---

## 5. Cómo MOSTRAR el modelo en la consola de BigQuery (UI paso a paso)

La consola **no dibuja** la estrella ni los KPIs automáticamente: navegas el
**Explorer** (panel izquierdo) y abres pestañas. Esto es lo que se clica y se dice.

### 5.1 Mostrar el modelo estrella

1. En el **Explorer**, despliega tu proyecto → dataset **`analytics`**.
2. Verás **4 tablas**: `fact_ventas`, `dim_cliente`, `dim_producto`, `dim_fecha`.
   **→ ESO es la estrella.** No hay un diagrama; las 4 tablas SON el modelo.
3. **Narrar:** *"`fact_ventas` es la tabla de hechos en el centro; las tres
   `dim_*` son las dimensiones que la rodean. Por eso se llama modelo estrella."*

> 💡 Si quieres una imagen de la estrella para proyectar, está el diagrama ASCII
> en el README (sección 3). También puedes dibujarla en la pizarra: un rectángulo
> central (hechos) con 3 flechas hacia las dimensiones.

### 5.2 Mostrar las LLAVES (PK / FK)

1. Clic en la tabla **`fact_ventas`** → pestaña **SCHEMA** (Esquema): se ven las
   columnas y cuáles son `NOT NULL`.
2. Para ver las restricciones PK/FK declaradas, ejecuta en el editor:

   ```sql
   SELECT table_name, constraint_name, constraint_type
   FROM `hackiaton-ia.analytics.INFORMATION_SCHEMA.TABLE_CONSTRAINTS`
   ORDER BY table_name;
   ```

3. **Narrar:** *"`fact_ventas` tiene PK en `order_id` y tres FK que apuntan a las
   dimensiones. Son `NOT ENFORCED`: documentan el modelo y guían al optimizador,
   sin frenar la carga."*

### 5.3 Mostrar PARTICIÓN + CLUSTERING

1. Clic en **`fact_ventas`** → pestaña **DETAILS** (Detalles).
2. Busca los campos **"Partitioned by: fecha (DAY)"** y
   **"Clustered by: canal, product_id"**.
3. Alternativa con SQL (muestra el DDL completo con `PARTITION BY` / `CLUSTER BY`):

   ```sql
   SELECT ddl
   FROM `hackiaton-ia.analytics.INFORMATION_SCHEMA.TABLES`
   WHERE table_name = 'fact_ventas';
   ```

4. **Narrar:** *"Está particionada por fecha y clusterizada por canal y producto.
   Por eso una consulta con filtro de fecha solo escanea las particiones
   necesarias — lo demostramos en bytes con `05`."*

### 5.4 Mostrar los KPIs (Bloque C)

1. En `analytics` verás también las **vistas** `kpi_*` (ícono distinto al de tabla).
2. Para verlas en acción, en el editor:

   ```sql
   SELECT * FROM `hackiaton-ia.analytics.kpi_ventas_mensuales`;
   SELECT * FROM `hackiaton-ia.analytics.kpi_margen_categoria`;
   ```

3. **Narrar:** *"Cada KPI es una vista SQL sobre la estrella. Agregar un KPI nuevo
   = escribir una vista más; no se reprocesa el pipeline. Esa es la agilidad del ELT."*

---

## 6. Glosario rápido (para responder al instante)

| Término | En una frase |
|---|---|
| **ETL** | Extrae → **Transforma** (servidor fijo) → Carga. Limpia ANTES de cargar. |
| **ELT** | Extrae → **Carga** (crudo) → **Transforma** dentro del warehouse elástico. |
| **Medallion** | Capas de calidad creciente: `raw` (crudo) → `staging` (limpio) → `analytics` (negocio). |
| **`raw`** | CSV cargados tal cual, todo `STRING`. La "L". Reprocesable. |
| **`staging`** | Vistas que limpian, castean y deduplican. La "T" paso 1. |
| **`analytics`** | Modelo estrella + KPIs. La "T" paso 2. |
| **Modelo estrella** | 1 tabla de **hechos** central + N **dimensiones** alrededor. Desnormalizado → rápido. |
| **Tabla de hechos** | Eventos medibles del negocio + métricas numéricas (`fact_ventas`). |
| **Dimensión** | Contexto para filtrar/agrupar: cliente, producto, fecha (`dim_*`). |
| **PK (primaria)** | Identifica de forma única cada fila. |
| **FK (foránea)** | Apunta a la PK de otra tabla; conecta la estrella. |
| **`NOT ENFORCED`** | La llave se declara pero BigQuery no la valida; documenta y optimiza. |
| **Particionado** | Divide la tabla por fecha en bloques físicos. |
| **Partition pruning** | Filtrar por fecha hace leer SOLO las particiones de ese rango → menos bytes. |
| **Clustering** | Ordena los datos dentro de cada partición por columnas (canal, producto). |
| **Bytes procesados** | Lo que BigQuery factura por consulta. Menos bytes = menos costo. |
| **Casteo (CAST)** | Convertir texto crudo a su tipo real (DATE, INT64, NUMERIC). |
| **Deduplicar** | Conservar una sola fila por clave si llega repetida (`QUALIFY ROW_NUMBER()`). |
| **Vista vs Tabla** | Vista = consulta guardada sin almacenamiento; Tabla = datos físicos. |
| **KPI** | Métrica de negocio; aquí cada uno es una vista SQL. |
| **Sandbox** | BigQuery gratis, 1 TiB/mes de consulta, sin tarjeta. |

> Glosario **ampliado y con más detalle** en el `README.md`, sección 7.

# Práctica Tema 3 — ELT para la Agilidad y Reducción de Costos

**Asignatura:** Analítica de Negocios · 7mo A
**Grupo:** Parte práctica
**Plataforma:** Google BigQuery (sandbox gratuito)
**Patrón:** ELT (Extract → **Load** → **Transform**) en arquitectura medallion

---

## 1. ¿Qué demuestra esta práctica?

Construimos un pipeline **ELT** de punta a punta: tomamos 3 fuentes de datos
crudas (CSV) de un comercio ("RetailXYZ"), las **cargamos sin transformar** en
BigQuery, y **transformamos dentro del warehouse** usando SQL hasta obtener un
modelo estrella con KPIs listos para la gerencia.

El objetivo de negocio: pasar de archivos crudos dispersos a **métricas
confiables en minutos**, reduciendo costos de infraestructura y acelerando la
toma de decisiones.

## 2. ETL vs. ELT (el corazón del tema)

| | ETL clásico | **ELT moderno (esta práctica)** |
|---|---|---|
| Orden | Extrae → **Transforma** → Carga | Extrae → **Carga** → Transforma |
| ¿Dónde transforma? | Servidor intermedio de capacidad **fija** | Dentro del **warehouse elástico** |
| Costo | Pagas el servidor esté o no en uso | Pagas por **bytes procesados**; escala a cero |
| Agilidad | Nuevo requerimiento = reconfigurar el servidor ETL | Nuevo KPI = **escribir una vista SQL** |
| Datos crudos | Se pierden (ya vienen transformados) | Quedan en la capa RAW (re-procesables) |

> En la nube, el cómputo y el almacenamiento se facturan por separado y de forma
> elástica. Eso es lo que hace que el ELT sea más barato y ágil que el ETL: no
> mantienes infraestructura ociosa y transformas con el músculo del warehouse.

## 3. Arquitectura (medallion)

```
  data/*.csv            BigQuery
 ┌──────────┐      ┌──────────────────────────────────────────────┐
 │ productos │      │  raw          staging          analytics      │
 │ clientes  │─────►│  (STRING) ──► (vistas:    ──►  (modelo         │
 │ ventas    │ Load │  crudo      limpieza,         estrella +       │
 └──────────┘       │             casteo,           KPIs,            │
                    │             dedupe)           particionado)    │
                    └──────────────────────────────────────────────┘
        L                         T (paso 1)        T (paso 2)
```

**Modelo estrella (capa `analytics`):**

```
        dim_fecha
            │
 dim_cliente ── fact_ventas ── dim_producto
            (particionada por fecha,
             clusterizada por canal/producto)
```

- `fact_ventas` — hechos (KPIs numéricos: monto_bruto, monto_neto, cantidad).
- `dim_cliente`, `dim_producto`, `dim_fecha` — contexto operativo.

## 4. Estructura del repositorio

```
practica-elt/
├── data/                      # CSV generados (3 fuentes)
├── scripts/
│   ├── 00_setup.sql           # crea datasets raw/staging/analytics
│   ├── 01_load_raw.md         # guía de carga por la consola (la "L")
│   ├── 02_staging.sql         # limpieza + casteo (la "T", paso 1)
│   ├── 03_analytics_star.sql  # modelo estrella con llaves y particiones
│   ├── 04_kpis.sql            # vistas de KPIs de negocio
│   └── 05_cost_demo.sql       # demo de costos: particionado vs plano
├── generate_data.py           # generador de los CSV (uv run)
├── runbook.md                 # guion del laboratorio: pasos, tiempos y roles
└── README.md                  # este archivo
```

## 5. Cómo ejecutar (resumen)

1. **Generar datos** (en tu máquina): `uv run generate_data.py`
2. **Crear datasets**: ejecuta `scripts/00_setup.sql` (reemplaza `PROJECT_ID`).
3. **Cargar RAW**: sigue `scripts/01_load_raw.md` (carga los 3 CSV por la UI).
4. **Transformar**: ejecuta en orden `02_staging.sql` → `03_analytics_star.sql` → `04_kpis.sql`.
5. **Demostrar costos**: ejecuta `05_cost_demo.sql` y registra los bytes.

> **Antes de empezar:** reemplaza `PROJECT_ID` por el ID real de tu proyecto en
> todos los `.sql` (Ctrl+H en el editor de BigQuery).

## 6. Cuándo conviene ELT (cierre del tema)

Adoptar ELT cuando hay: **alta volatilidad de mercado** (se necesitan decisiones
rápidas), **gran variedad de fuentes** (cargar crudo y unificar después es más
simple) y un **proyecto de analítica maduro** sobre la nube. El ELT democratiza
el acceso (cualquiera con SQL consulta), potencia la **analítica descriptiva en
tiempo real** y deja los datos listos para alimentar **modelos predictivos**.

## 7. Glosario de términos (todo lo que pueden preguntarte)

### Patrón y arquitectura

- **ETL** (Extract, Transform, Load): extraes los datos, los **transformas en un
  servidor intermedio** y luego los cargas ya limpios al destino. El servidor de
  transformación tiene capacidad fija y se paga esté o no en uso.
- **ELT** (Extract, **Load**, **Transform**): cargas el dato **crudo** primero y
  lo transformas **dentro del warehouse** con SQL. Aprovecha el cómputo elástico
  de la nube y conserva el dato original.
- **Data warehouse**: base de datos analítica para consultas masivas (aquí,
  **BigQuery**). Separa cómputo y almacenamiento y los factura por separado.
- **Arquitectura medallion**: organiza el pipeline en capas de calidad creciente:
  - **`raw`** (bronce): datos crudos cargados tal cual, todo como `STRING`. Es la
    **"L"** del ELT. Si algo sale mal, siempre puedes reprocesar desde aquí.
  - **`staging`** (plata): datos **limpios y tipados** (la **"T", paso 1**).
    Implementado con **vistas** (no ocupan almacenamiento).
  - **`analytics`** (oro): **modelo estrella + KPIs** listos para negocio
    (la **"T", paso 2**). Tablas físicas optimizadas.

### Modelo de datos

- **Modelo estrella (star schema)**: diseño con **una tabla de hechos central**
  rodeada de **tablas de dimensión**. Visualmente parece una estrella. Está
  **desnormalizado** a propósito → menos JOINs → consultas más rápidas.
- **Tabla de hechos (`fact_ventas`)**: contiene los **eventos medibles** del
  negocio (cada venta) y sus **métricas numéricas** (cantidad, monto_bruto,
  monto_neto). Es la tabla grande (300 000 filas).
- **Tabla de dimensión (`dim_*`)**: contiene el **contexto descriptivo** para
  filtrar y agrupar los hechos: quién (`dim_cliente`), qué (`dim_producto`),
  cuándo (`dim_fecha`). Son tablas pequeñas.
- **`dim_fecha` generada con SQL**: no viene de ningún CSV; se crea con
  `GENERATE_DATE_ARRAY` y permite agrupar por año, mes, trimestre, día de semana.
- **Normalización vs desnormalización**: normalizar evita datos repetidos (bueno
  para sistemas transaccionales); **desnormalizar** (estrella) repite contexto
  para acelerar lectura analítica. En analítica preferimos lo segundo.

### Llaves y restricciones

- **Llave primaria (PRIMARY KEY / PK)**: columna que **identifica de forma única**
  cada fila (ej. `order_id` en hechos, `customer_id` en `dim_cliente`).
- **Llave foránea (FOREIGN KEY / FK)**: columna que **apunta a la PK de otra
  tabla** (ej. `fact_ventas.customer_id` → `dim_cliente.customer_id`). Es lo que
  "conecta" la estrella.
- **`NOT ENFORCED`**: en BigQuery las PK/FK **se declaran pero no se validan** en
  cada inserción. Sirven para **documentar el modelo** y para que el **optimizador**
  genere mejores planes de consulta, sin penalizar la carga.
- **`NOT NULL`**: la columna **no admite valores vacíos** (garantiza integridad
  mínima de las claves).

### Optimización y costo

- **Particionado (PARTITION BY fecha)**: BigQuery **divide físicamente** la tabla
  en bloques por fecha (un bloque por día). 
- **Partition pruning**: cuando una consulta filtra por fecha
  (`WHERE fecha BETWEEN ...`), BigQuery **solo lee las particiones de ese rango**
  e **ignora el resto** → escanea menos bytes.
- **Clustering (CLUSTER BY canal, product_id)**: **ordena los datos** dentro de
  cada partición por esas columnas, de modo que filtros por `canal`/`product_id`
  también lean menos bloques.
- **Bytes procesados**: en BigQuery on-demand **pagas por los bytes que escanea
  cada consulta**, no por un servidor. Menos bytes = menos costo y menos latencia.
  El editor muestra *"This query will process X when run"* antes de ejecutar.
- **BigQuery Sandbox**: modo gratuito sin tarjeta; incluye **1 TiB/mes** de
  consulta gratis. La práctica no cuesta nada, pero la **métrica de bytes**
  demuestra el modelo de costo real de una empresa.

### Transformación (SQL)

- **Casteo (CAST / SAFE_CAST)**: convertir un texto crudo a su tipo real
  (`STRING` → `DATE`, `INT64`, `NUMERIC`). `SAFE_CAST` devuelve `NULL` en vez de
  error si el valor no es convertible.
- **`NUMERIC` / `INT64` / `DATE`**: tipos de dato — decimal exacto (dinero),
  entero, fecha. Se cargan como `STRING` en `raw` y se castean en `staging`.
- **Deduplicación (`QUALIFY ROW_NUMBER()`)**: si una clave llega repetida,
  conserva **una sola fila** por clave de negocio.
- **Vista (VIEW) vs tabla (TABLE)**: una **vista** es una consulta guardada que
  **no almacena datos** (se recalcula al consultarse, ideal para `staging`/KPIs);
  una **tabla** sí ocupa almacenamiento (la usamos en `analytics` para poder
  particionar/clusterizar).
- **KPI** (Key Performance Indicator): métrica de negocio (ventas mensuales,
  margen por categoría, ticket promedio…). Aquí, **cada KPI es una vista SQL** —
  agregar uno nuevo no requiere reprocesar nada (esa es la **agilidad** del ELT).
- **JOIN ... USING (clave)**: combina la tabla de hechos con una dimensión por su
  clave común (patrón estrella) para traer el contexto a la métrica.

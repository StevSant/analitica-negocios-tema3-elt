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

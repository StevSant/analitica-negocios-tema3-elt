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

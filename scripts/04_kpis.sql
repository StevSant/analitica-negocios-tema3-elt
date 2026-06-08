-- =============================================================================
-- 04_kpis.sql  —  KPIs de negocio sobre el modelo estrella.
-- =============================================================================
-- Cada KPI es una VISTA que consume gerencia. Agregar un KPI nuevo en ELT =
-- escribir una vista más; NO hay que rediseñar ni reprocesar el pipeline.
-- Eso es la "agilidad" del título del tema.
--
-- Todas las vistas hacen JOIN de la tabla de hechos con sus dimensiones
-- (patrón estrella). Reemplaza `PROJECT_ID`.
-- =============================================================================

-- KPI 1 — Ventas netas por mes (tendencia temporal, analítica descriptiva)
CREATE OR REPLACE VIEW `hackiaton-ia.analytics.kpi_ventas_mensuales` AS
SELECT
  f.anio,
  f.mes,
  f.nombre_mes,
  COUNT(*)                       AS num_ordenes,
  ROUND(SUM(v.monto_neto), 2)    AS ventas_netas,
  ROUND(AVG(v.monto_neto), 2)    AS ticket_promedio
FROM `hackiaton-ia.analytics.fact_ventas` v
JOIN `hackiaton-ia.analytics.dim_fecha`   f USING (fecha)
GROUP BY f.anio, f.mes, f.nombre_mes
ORDER BY f.anio, f.mes;

-- KPI 2 — Rentabilidad por categoría (margen = ventas - costo)
-- Demuestra el JOIN hechos<->dim_producto para traer el costo.
CREATE OR REPLACE VIEW `hackiaton-ia.analytics.kpi_margen_categoria` AS
SELECT
  p.categoria,
  ROUND(SUM(v.monto_neto), 2)                              AS ventas_netas,
  ROUND(SUM(v.cantidad * p.costo_unitario), 2)             AS costo_total,
  ROUND(SUM(v.monto_neto - v.cantidad * p.costo_unitario), 2) AS margen,
  ROUND(SAFE_DIVIDE(
      SUM(v.monto_neto - v.cantidad * p.costo_unitario),
      SUM(v.monto_neto)) * 100, 1)                         AS margen_pct
FROM `hackiaton-ia.analytics.fact_ventas`   v
JOIN `hackiaton-ia.analytics.dim_producto`  p USING (product_id)
GROUP BY p.categoria
ORDER BY margen DESC;

-- KPI 3 — Desempeño por canal de venta
CREATE OR REPLACE VIEW `hackiaton-ia.analytics.kpi_ventas_canal` AS
SELECT
  canal,
  COUNT(*)                    AS num_ordenes,
  ROUND(SUM(monto_neto), 2)   AS ventas_netas,
  ROUND(AVG(monto_neto), 2)   AS ticket_promedio
FROM `hackiaton-ia.analytics.fact_ventas`
GROUP BY canal
ORDER BY ventas_netas DESC;

-- KPI 4 — Ventas por segmento de cliente
CREATE OR REPLACE VIEW `hackiaton-ia.analytics.kpi_ventas_segmento` AS
SELECT
  c.segmento,
  COUNT(DISTINCT v.customer_id) AS clientes_activos,
  ROUND(SUM(v.monto_neto), 2)   AS ventas_netas
FROM `hackiaton-ia.analytics.fact_ventas`  v
JOIN `hackiaton-ia.analytics.dim_cliente`  c USING (customer_id)
GROUP BY c.segmento
ORDER BY ventas_netas DESC;

-- KPI 5 — Top 10 clientes por valor
CREATE OR REPLACE VIEW `hackiaton-ia.analytics.kpi_top_clientes` AS
SELECT
  c.customer_id,
  c.nombre,
  c.ciudad,
  c.segmento,
  ROUND(SUM(v.monto_neto), 2) AS valor_total
FROM `hackiaton-ia.analytics.fact_ventas`  v
JOIN `hackiaton-ia.analytics.dim_cliente`  c USING (customer_id)
GROUP BY c.customer_id, c.nombre, c.ciudad, c.segmento
ORDER BY valor_total DESC
LIMIT 10;

-- --- Demostración en vivo (consultar cualquiera) ---------------------------
-- SELECT * FROM `hackiaton-ia.analytics.kpi_ventas_mensuales`;
-- SELECT * FROM `hackiaton-ia.analytics.kpi_margen_categoria`;

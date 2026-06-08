-- =============================================================================
-- 06_visualizaciones.sql — Consultas para demo visual (antes/después + KPIs)
-- =============================================================================
-- Ejecutar UNA consulta por pestaña. En Resultados → pestaña "Visualización".
-- Proyecto: PROJECT_ID
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. ANTES vs DESPUÉS — misma venta: raw (STRING) vs staging (tipado + negocio)
--    Visualización: tabla de resultados (comparar columnas)
-- ---------------------------------------------------------------------------
SELECT
  'ANTES (raw)' AS etapa,
  fecha,
  cantidad,
  precio_unitario,
  CAST(NULL AS STRING) AS monto_neto
FROM `PROJECT_ID.raw.ventas`
LIMIT 5

UNION ALL

SELECT
  'DESPUÉS (staging)' AS etapa,
  CAST(fecha AS STRING),
  CAST(cantidad AS STRING),
  CAST(precio_unitario AS STRING),
  CAST(monto_neto AS STRING)
FROM `PROJECT_ID.staging.stg_ventas`
LIMIT 5;

-- ---------------------------------------------------------------------------
-- 2. DESPUÉS — Ventas por mes (gráfico de LÍNEA o BARRAS)
--    Dimensión: nombre_mes (o anio+mes) · Medición: ventas_netas
-- ---------------------------------------------------------------------------
SELECT nombre_mes, anio, mes, ventas_netas, num_ordenes, ticket_promedio
FROM `PROJECT_ID.analytics.kpi_ventas_mensuales`
ORDER BY anio, mes;

-- ---------------------------------------------------------------------------
-- 3. DESPUÉS — Ventas por canal (gráfico CIRCULAR)
--    Dimensión: canal · Medición: ventas_netas
-- ---------------------------------------------------------------------------
SELECT canal, ventas_netas, num_ordenes
FROM `PROJECT_ID.analytics.kpi_ventas_canal`
ORDER BY ventas_netas DESC;

-- ---------------------------------------------------------------------------
-- 4. DESPUÉS — Margen por categoría (gráfico de BARRAS)
--    Dimensión: categoria · Medición: margen o ventas_netas
-- ---------------------------------------------------------------------------
SELECT categoria, ventas_netas, margen, margen_pct
FROM `PROJECT_ID.analytics.kpi_margen_categoria`
ORDER BY margen DESC;

-- ---------------------------------------------------------------------------
-- 5. DESPUÉS — Top 10 clientes (ranking en BARRAS)
-- ---------------------------------------------------------------------------
SELECT nombre_cliente, ciudad, valor_total
FROM `PROJECT_ID.analytics.kpi_top_clientes`
ORDER BY valor_total DESC
LIMIT 10;

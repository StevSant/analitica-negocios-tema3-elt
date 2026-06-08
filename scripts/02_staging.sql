-- =============================================================================
-- 02_staging.sql  —  Capa STAGING: la "T" del ELT (paso 1: limpiar y tipar).
-- =============================================================================
-- Aquí ocurre la transformación DENTRO del warehouse (no antes de cargar).
-- Usamos VISTAS: no consumen almacenamiento y se recalculan al consultarse,
-- lo que ilustra el espíritu del ELT (transformación bajo demanda y elástica).
--
-- Por cada fuente:
--   * casteamos los STRING crudos a su tipo real (DATE, INT64, NUMERIC)
--   * limpiamos espacios (TRIM) y descartamos filas sin clave
--   * deduplicamos con QUALIFY ROW_NUMBER() (una fila por clave de negocio)
--   * derivamos columnas útiles (monto_bruto, monto_neto)
--
-- Recuerda reemplazar `august-tower-470819-s6`.
-- =============================================================================

-- --- Productos -------------------------------------------------------------
CREATE OR REPLACE VIEW `august-tower-470819-s6.staging.stg_productos` AS
SELECT
  TRIM(product_id)                       AS product_id,
  TRIM(nombre)                           AS nombre,
  TRIM(categoria)                        AS categoria,
  TRIM(subcategoria)                     AS subcategoria,
  CAST(costo_unitario AS NUMERIC)        AS costo_unitario,
  TRIM(marca)                            AS marca
FROM `august-tower-470819-s6.raw.productos`
WHERE product_id IS NOT NULL
-- deduplica: si una clave llega repetida, conserva una sola fila
QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(product_id) ORDER BY TRIM(product_id)) = 1;

-- --- Clientes --------------------------------------------------------------
CREATE OR REPLACE VIEW `august-tower-470819-s6.staging.stg_clientes` AS
SELECT
  TRIM(customer_id)                          AS customer_id,
  TRIM(nombre)                               AS nombre,
  TRIM(ciudad)                               AS ciudad,
  TRIM(segmento)                             AS segmento,
  SAFE.PARSE_DATE('%Y-%m-%d', fecha_registro) AS fecha_registro
FROM `august-tower-470819-s6.raw.clientes`
WHERE customer_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(customer_id) ORDER BY TRIM(customer_id)) = 1;

-- --- Ventas (hechos) -------------------------------------------------------
CREATE OR REPLACE VIEW `august-tower-470819-s6.staging.stg_ventas` AS
SELECT
  TRIM(order_id)                                       AS order_id,
  SAFE.PARSE_DATE('%Y-%m-%d', fecha)                   AS fecha,
  TRIM(customer_id)                                    AS customer_id,
  TRIM(product_id)                                     AS product_id,
  CAST(cantidad AS INT64)                              AS cantidad,
  CAST(precio_unitario AS NUMERIC)                     AS precio_unitario,
  CAST(descuento AS NUMERIC)                           AS descuento,
  TRIM(canal)                                          AS canal,
  -- columnas derivadas (métricas base de los KPIs)
  CAST(cantidad AS INT64) * CAST(precio_unitario AS NUMERIC)            AS monto_bruto,
  ROUND(CAST(cantidad AS INT64) * CAST(precio_unitario AS NUMERIC)
        * (1 - CAST(descuento AS NUMERIC)), 2)                          AS monto_neto
FROM `august-tower-470819-s6.raw.ventas`
WHERE order_id IS NOT NULL
  AND SAFE.PARSE_DATE('%Y-%m-%d', fecha) IS NOT NULL   -- descarta fechas inválidas
QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(order_id) ORDER BY TRIM(order_id)) = 1;

-- --- Verificación ----------------------------------------------------------
-- SELECT * FROM `august-tower-470819-s6.staging.stg_ventas` LIMIT 20;

-- =============================================================================
-- 03_analytics_star.sql  —  Capa ANALYTICS: modelo estrella (la "T", paso 2).
-- =============================================================================
-- Materializamos un esquema en ESTRELLA: una tabla de hechos central rodeada
-- de tablas de dimensión. Aquí SÍ creamos tablas físicas (no vistas) porque:
--   * la tabla de hechos se PARTICIONA por fecha y se CLUSTERIZA -> consultas
--     baratas y rápidas (esto se demuestra en 05_cost_demo.sql).
--   * declaramos LLAVES (PRIMARY/FOREIGN KEY) y restricciones NOT NULL para
--     documentar el modelo y guiar al optimizador (rúbrica: uso de llaves).
--
-- BigQuery soporta PRIMARY KEY / FOREIGN KEY como restricciones NOT ENFORCED:
-- no bloquean la carga, pero documentan el modelo y el motor las aprovecha.
--
-- Reemplaza `PROJECT_ID`.
-- =============================================================================

-- --- DIMENSIÓN: Cliente ----------------------------------------------------
CREATE OR REPLACE TABLE `hackiaton-ia.analytics.dim_cliente`
(
  customer_id    STRING NOT NULL,
  nombre         STRING,
  ciudad         STRING,
  segmento       STRING,
  fecha_registro DATE,
  PRIMARY KEY (customer_id) NOT ENFORCED
)
AS SELECT customer_id, nombre, ciudad, segmento, fecha_registro
   FROM `hackiaton-ia.staging.stg_clientes`;

-- --- DIMENSIÓN: Producto ---------------------------------------------------
CREATE OR REPLACE TABLE `hackiaton-ia.analytics.dim_producto`
(
  product_id     STRING NOT NULL,
  nombre         STRING,
  categoria      STRING,
  subcategoria   STRING,
  costo_unitario NUMERIC,
  marca          STRING,
  PRIMARY KEY (product_id) NOT ENFORCED
)
AS SELECT product_id, nombre, categoria, subcategoria, costo_unitario, marca
   FROM `hackiaton-ia.staging.stg_productos`;

-- --- DIMENSIÓN: Fecha (generada con SQL, no viene de ningún CSV) -----------
CREATE OR REPLACE TABLE `hackiaton-ia.analytics.dim_fecha`
(
  fecha       DATE NOT NULL,
  anio        INT64,
  trimestre   INT64,
  mes         INT64,
  nombre_mes  STRING,
  dia         INT64,
  dia_semana  STRING,
  PRIMARY KEY (fecha) NOT ENFORCED
)
AS
SELECT
  d                                  AS fecha,
  EXTRACT(YEAR    FROM d)            AS anio,
  EXTRACT(QUARTER FROM d)            AS trimestre,
  EXTRACT(MONTH   FROM d)            AS mes,
  FORMAT_DATE('%B', d)              AS nombre_mes,
  EXTRACT(DAY     FROM d)            AS dia,
  FORMAT_DATE('%A', d)              AS dia_semana
FROM UNNEST(GENERATE_DATE_ARRAY(DATE '2024-01-01', DATE '2025-12-31')) AS d;

-- --- HECHOS: Ventas --------------------------------------------------------
-- Particionada por fecha + clusterizada por canal y producto:
-- las consultas con filtro de fecha solo escanean las particiones necesarias.
CREATE OR REPLACE TABLE `hackiaton-ia.analytics.fact_ventas`
(
  order_id        STRING  NOT NULL,
  fecha           DATE    NOT NULL,
  customer_id     STRING  NOT NULL,
  product_id      STRING  NOT NULL,
  cantidad        INT64,
  precio_unitario NUMERIC,
  descuento       NUMERIC,
  canal           STRING,
  monto_bruto     NUMERIC,
  monto_neto      NUMERIC,
  PRIMARY KEY (order_id) NOT ENFORCED,
  FOREIGN KEY (customer_id) REFERENCES `hackiaton-ia.analytics.dim_cliente`  (customer_id) NOT ENFORCED,
  FOREIGN KEY (product_id)  REFERENCES `hackiaton-ia.analytics.dim_producto` (product_id)  NOT ENFORCED,
  FOREIGN KEY (fecha)       REFERENCES `hackiaton-ia.analytics.dim_fecha`    (fecha)       NOT ENFORCED
)
PARTITION BY fecha
CLUSTER BY canal, product_id
AS
SELECT
  order_id, fecha, customer_id, product_id,
  cantidad, precio_unitario, descuento, canal, monto_bruto, monto_neto
FROM `hackiaton-ia.staging.stg_ventas`;

-- --- Verificación ----------------------------------------------------------
-- SELECT COUNT(*) FROM `hackiaton-ia.analytics.fact_ventas`;   -- 300000

-- =============================================================================
-- 05_cost_demo.sql  —  El argumento de COSTO y AGILIDAD (precisión matemática).
-- =============================================================================
-- Objetivo: demostrar con números reales que el diseño ELT en la nube reduce
-- costos. En BigQuery on-demand PAGAS POR BYTES PROCESADOS, no por servidor fijo.
-- Particionar/clusterizar la tabla de hechos hace que una consulta escanee
-- MENOS bytes -> cuesta menos dinero y responde más rápido.
--
-- PRECIO ON-DEMAND (referencia, ajústalo al vigente): 6.25 USD por TiB escaneado.
--   costo_usd = bytes_procesados / (1024^4) * 6.25
--
-- Reemplaza `PROJECT_ID`.
-- =============================================================================

-- PASO 1 — Crear una copia SIN particionar (simula un diseño "ETL plano"
--          o una tabla mal modelada). Misma data, sin partición ni clustering.
CREATE OR REPLACE TABLE `hackiaton-ia.analytics.fact_ventas_flat` AS
SELECT * FROM `hackiaton-ia.analytics.fact_ventas`;

-- -----------------------------------------------------------------------------
-- PASO 2 — Ejecutar las DOS consultas siguientes UNA POR UNA y, ANTES de correr
-- cada una, leer en la esquina superior derecha del editor el aviso:
--     "This query will process X when run"  (bytes que se facturarán)
-- Anota ese valor para cada consulta: esa es la métrica que se traduce a dinero.
-- -----------------------------------------------------------------------------

-- (A) Tabla PARTICIONADA  ->  BigQuery hace "partition pruning":
--     solo lee las particiones del rango de fechas pedido.
SELECT canal, ROUND(SUM(monto_neto), 2) AS ventas
FROM `hackiaton-ia.analytics.fact_ventas`
WHERE fecha BETWEEN '2025-01-01' AND '2025-03-31'
GROUP BY canal;

-- (B) Tabla PLANA (sin partición)  ->  escanea TODA la tabla aunque
--     pidas solo 3 meses. Mismo resultado, MUCHOS más bytes facturados.
SELECT canal, ROUND(SUM(monto_neto), 2) AS ventas
FROM `hackiaton-ia.analytics.fact_ventas_flat`
WHERE fecha BETWEEN '2025-01-01' AND '2025-03-31'
GROUP BY canal;

-- -----------------------------------------------------------------------------
-- PASO 3 — Calcular el costo y el ahorro con los bytes anotados.
-- Reemplaza los dos números por los bytes reales que reportó cada consulta.
--
-- ⚠️ IMPORTANTE: selecciona y ejecuta SOLO este bloque (de DECLARE hacia abajo).
-- En BigQuery las sentencias DECLARE deben ir al inicio del script; si corres
-- todo el archivo de una vez, dará error de sintaxis.
-- -----------------------------------------------------------------------------
DECLARE bytes_particionada INT64 DEFAULT 0;   -- <- pega los bytes de la consulta (A)
DECLARE bytes_plana        INT64 DEFAULT 0;   -- <- pega los bytes de la consulta (B)
DECLARE precio_usd_por_tib FLOAT64 DEFAULT 6.25;

SELECT
  bytes_particionada                                              AS bytes_A_particionada,
  bytes_plana                                                     AS bytes_B_plana,
  ROUND(bytes_particionada / POW(1024, 4) * precio_usd_por_tib, 6) AS costo_A_usd,
  ROUND(bytes_plana        / POW(1024, 4) * precio_usd_por_tib, 6) AS costo_B_usd,
  ROUND((1 - SAFE_DIVIDE(bytes_particionada, bytes_plana)) * 100, 1) AS ahorro_pct;

-- -----------------------------------------------------------------------------
-- LECTURA DE NEGOCIO (lo que se dice frente al docente):
--   * La consulta (A) escanea solo ~1 trimestre de datos; la (B) escanea los
--     2 años completos -> el ahorro de bytes (y de dinero) ronda el 85-90%.
--   * A escala empresarial (TB-PB por día, miles de consultas), ese % es la
--     diferencia entre una factura de cientos y de miles de USD al mes.
--   * Sandbox de BigQuery: 1 TiB/mes GRATIS, así que la práctica no cuesta nada;
--     pero la MÉTRICA de bytes demuestra exactamente el modelo de costo real.
--   * Agilidad: en ELT, optimizar = reescribir SQL/redefinir la tabla. En ETL
--     clásico habría que reconfigurar un servidor de transformación de capacidad
--     fija. ELT escala a cero cuando no se consulta -> no pagas infra ociosa.
-- -----------------------------------------------------------------------------

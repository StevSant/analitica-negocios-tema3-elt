-- =============================================================================
-- 00_setup.sql  —  Crea las 3 capas (datasets) del pipeline ELT en BigQuery.
-- =============================================================================
-- Arquitectura medallion:
--   raw       -> datos crudos cargados TAL CUAL desde los CSV (la "L" del ELT)
--   staging   -> limpieza, casteo y deduplicación con SQL (la "T", paso 1)
--   analytics -> modelo estrella + KPIs listos para la gerencia (la "T", paso 2)
--
-- INSTRUCCIONES:
--   1. Reemplaza TODAS las apariciones de `PROJECT_ID` por el ID real de tu
--      proyecto de BigQuery (Editor -> Buscar/Reemplazar, o Ctrl+H).
--   2. Mantén las 3 capas en la MISMA región/location que los CSV que cargues.
--   3. Ejecuta este script ANTES de cargar los CSV (ver 01_load_raw.md).
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.raw`
  OPTIONS (location = 'US', description = 'Capa cruda: CSV cargados sin transformar (EL)');

CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.staging`
  OPTIONS (location = 'US', description = 'Capa intermedia: limpieza y casteo (T - paso 1)');

CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.analytics`
  OPTIONS (location = 'US', description = 'Capa de negocio: modelo estrella y KPIs (T - paso 2)');

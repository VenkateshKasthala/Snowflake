-- Warehouses: dedicated per team, scale up vs. scale out
USE ROLE SYSADMIN;
USE DATABASE OUR_FIRST_DB;
USE SCHEMA PUBLIC;

-- 1. Dedicated warehouses per workload / team
-- Idea:
--   - Separate warehouses for ETL, BI, Data Science, etc.
--   - Isolates performance & cost per workload. [web:249][web:251]

-- ETL warehouse: heavy batch jobs, low concurrency
CREATE OR REPLACE WAREHOUSE WH_ETL
  WAREHOUSE_SIZE      = 'MEDIUM'
  AUTO_SUSPEND        = 300           -- 5 minutes
  AUTO_RESUME         = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT             = 'Dedicated ETL warehouse (heavy queries, low concurrency)';

-- BI warehouse: dashboards, many users, mostly read-only
CREATE OR REPLACE WAREHOUSE WH_BI
  WAREHOUSE_SIZE      = 'SMALL'
  AUTO_SUSPEND        = 300
  AUTO_RESUME         = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT             = 'Dedicated BI/reporting warehouse (high concurrency, lighter queries)';

-- Data Science warehouse: ad-hoc, spiky usage
CREATE OR REPLACE WAREHOUSE WH_DS
  WAREHOUSE_SIZE      = 'MEDIUM'
  AUTO_SUSPEND        = 600
  AUTO_RESUME         = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT             = 'Dedicated data science / exploration warehouse';

SHOW WAREHOUSES;

-- 2. Scaling UP – make a single cluster bigger

-- Scale up = increase WAREHOUSE_SIZE (XS -> S -> M -> L ...). 
-- Use when individual ETL queries are heavy / spilling and run slowly
-- even when there is no queue.

-- Example: ETL runs long on MEDIUM; scale up to LARGE
ALTER WAREHOUSE WH_ETL SET WAREHOUSE_SIZE = 'LARGE';

-- Optionally scale back down after peak ETL window:
-- ALTER WAREHOUSE WH_ETL SET WAREHOUSE_SIZE = 'MEDIUM';

DESC WAREHOUSE WH_ETL;

-- Key notes:
-- - A single query uses ONE cluster; scaling up gives that cluster more CPU/memory so each heavy query can run faster.
-- - This does NOT multiply concurrency; it just makes each query
-- - individually more powerful. 

-- 3. Scaling OUT – multi-cluster for concurrency
-- Scale out = multiple clusters per warehouse via MIN/MAX_CLUSTER_COUNT.
-- Use when queries are individually “fine” but many users queue
-- (typical BI / dashboard pattern).

-- Turn WH_BI into a SMALL multi-cluster warehouse
ALTER WAREHOUSE WH_BI
  SET
    WAREHOUSE_SIZE     = 'SMALL',   -- size per cluster
    MIN_CLUSTER_COUNT  = 1,
    MAX_CLUSTER_COUNT  = 4,
    SCALING_POLICY     = 'STANDARD'; -- add clusters when queued

DESC WAREHOUSE WH_BI;

-- Key notes:
-- - Each BI query still runs entirely on ONE of the clusters.
-- - Extra clusters are added only when there is concurrency/queue pressure
--   and removed when load drops, controlling cost.
-- - Good for serving many dashboard users without contention.

-- 4. Example usage by workload

-- ETL job:
USE WAREHOUSE WH_ETL;
-- Run heavy transforms here (large joins, aggregations, COPY INTO, etc.)

-- BI dashboards / analysts:
USE WAREHOUSE WH_BI;
-- Run dashboard queries, business reports, self-service analytics here.

-- Data science:
USE WAREHOUSE WH_DS;
-- Run notebooks, ad-hoc exploration, model feature queries.


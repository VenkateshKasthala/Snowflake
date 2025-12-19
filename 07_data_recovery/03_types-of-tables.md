# Types of Tables

Snowflake has three main table types for storage: permanent, transient, and temporary, plus specialized types like external and dynamic tables.​

Permanent is the default when you CREATE TABLE without extra keywords.​

## Permanent tables

Designed for data needing the highest protection: full Time Travel window (up to 90 days on higher editions) plus 7‑day Fail-safe.​

Persist until dropped; used for core fact/dimension tables, production marts, and regulatory data.​

Example:
```
CREATE TABLE sales (
  id        NUMBER,
  amount    NUMBER,
  sale_date DATE
);
```

## Transient tables

Behave like permanent tables but no Fail-safe and Time Travel is limited to 0 or 1 day.​

Ideal when data can be reloaded or recomputed if lost (e.g., staging, ETL intermediate results) and you want to reduce storage/protection overhead.​

Example:
```
CREATE TRANSIENT TABLE stg_sales (
  id        NUMBER,
  amount    NUMBER,
  load_ts   TIMESTAMP_NTZ
)
DATA_RETENTION_TIME_IN_DAYS = 1;
```


## Temporary tables

Exist only for the current session; dropped automatically when the session ends and are not visible to other sessions.​

Best for short‑lived scratch data in complex queries or procedural logic; no Fail-safe and at most 1 day of Time Travel while the session is alive.​

Example:
```
CREATE TEMPORARY TABLE tmp_calc AS
SELECT ...
FROM   some_source;
```

### Other specialized table types (high level)

External tables:Reference data stored outside Snowflake (e.g., S3, Azure Blob, GCS); great for data lakes and query‑in‑place.​

Dynamic tables: “Materialized + streaming” style tables that auto‑refresh based on a defining query, useful for near real‑time transformations.
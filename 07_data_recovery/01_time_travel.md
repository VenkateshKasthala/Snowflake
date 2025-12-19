# Time Travel

It lets you look at and restore past versions of data in Snowflake for a defined number of days, even after changes or drops.​

### What Time Travel can do

Snowflake keeps historical versions of tables, schemas, and databases for a retention period so you can:​

Query historical data as of a past time or statement.

Clone objects (tables/schemas/databases) as they were in the past.

Restore dropped objects using UNDROP.

After the retention period, historical data for permanent objects moves into Fail‑safe, where only Snowflake Support can recover it as a last resort.​

### Data retention period

Whenever data is changed or dropped, Snowflake preserves the previous state for the retention period.​

Default retention is 1 day for permanent tables.​

Enterprise edition and above allow up to 90 days of Time Travel retention.​

Transient and temporary objects have much shorter or zero Time Travel and no Fail‑safe, to control storage cost.​

You can set retention at object creation or later:

```
CREATE TABLE sales (
  id NUMBER, amount NUMBER
)
DATA_RETENTION_TIME_IN_DAYS = 7;
```

```
ALTER TABLE sales
  SET DATA_RETENTION_TIME_IN_DAYS = 3;
```

Longer retention = more historical micro‑partitions kept = more storage cost, so choose values based on recovery/audit
needs.​

## Querying history with AT / BEFORE

Time Travel adds AT and BEFORE clauses to SELECT so you can see how data looked at a specific point.​

Supported forms (use one at a time):

AT (TIMESTAMP => '<timestamp>')

AT (OFFSET => -<seconds>) – relative to current time

AT (STATEMENT => '<query_id>') – as of a specific DML statement

BEFORE (TIMESTAMP => ...), BEFORE (STATEMENT => ...)

Examples:

By timestamp:
```
SELECT * FROM sales
  AT (TIMESTAMP => '2025-12-18 10:00:00'::timestamp_ntz);
```

Using an offset (e.g., “10 minutes ago”):
```
SELECT * FROM sales
  AT (OFFSET => -600);
```

Using a previous statement’s query ID:
```
SELECT * FROM sales
  BEFORE (STATEMENT => '01b1f32a-0601-9a12-0000-437b01be0a12');
```


## Cloning historical data

Time Travel works together with zero‑copy cloning. You can clone a table, schema, or database as of a point in time; Snowflake just reuses existing micro‑partitions and writes metadata.​

```
-- Clone current version
CREATE OR REPLACE TABLE sales_clone CLONE sales;
```

```
-- Clone as of a timestamp
CREATE OR REPLACE TABLE sales_2025_12_01
  CLONE sales
  AT (TIMESTAMP => '2025-12-01 00:00:00'::timestamp_ntz);
```


```
-- Clone an entire schema/database as of a time
CREATE SCHEMA reporting_clone
  CLONE reporting
  AT (OFFSET => -86400);  -- 1 day ago
```
Use this for sandboxing, point‑in‑time reporting environments, or backups before major changes.

### Restoring dropped objects (UNDROP)

If a table, schema, or database is dropped, you can restore it during its Time Travel retention window.​
```
DROP TABLE test_table;
```
```
-- Within retention days:
UNDROP TABLE test_table;
-- The same works for schemas and databases:

UNDROP SCHEMA my_schema;
UNDROP DATABASE my_db;
```
Restrictions:

You must free up the original name (e.g., rename any new table with the same name) before UNDROP, because undrop restores the original object ID.​

After retention expires, UNDROP is no longer possible; only Fail‑safe (support) might recover data for permanent objects.​

### Time Travel vs Fail‑safe

##### Time Travel

User‑controlled; you can query, clone, and UNDROP within the retention period.

Retention is configurable per object (up to 90 days depending on edition).

Meant for operational mistakes, audits, and historical analysis.

##### Fail‑safe​

Last‑resort recovery after Time Travel retention ends.

Fixed at 7 days for permanent objects; not configurable.

Not queryable by you; only Snowflake Support can restore, for critical failure scenarios.

### Cost and best practices

Historical data kept for Time Travel and Fail‑safe is stored as extra micro‑partitions, so it increases storage usage and cost on permanent tables.​

Use shorter retention for:

Staging / intermediate tables.

Very large but low‑risk datasets.

Use longer retention only where you truly need long audit windows or regulatory history.​

Common pattern:

Permanent tables in curated layers with 7–30 days retention.

Transient/temporary tables for staging/scratch, with minimal or zero Time Travel to save cost.​

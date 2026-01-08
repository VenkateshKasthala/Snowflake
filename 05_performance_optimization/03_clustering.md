# Micro‑Partitions and Clustering

### Micro‑partitions - how data is stored

When data is loaded into a Snowflake table, it is automatically split into many small micro‑partitions, each typically containing 50–500 MB of compressed columnar data.​

Each micro‑partition has rich metadata: row count, min/max values per column, number of distinct values, and other statistics.​

You do not manage micro‑partitions directly; Snowflake creates and manages them as part of normal DML (COPY, INSERT, MERGE, DELETE).​

Key idea: micro‑partitions are the basic physical unit Snowflake reads, prunes, and caches.

### Partition pruning – main performance mechanism

When a query has filters (for example WHERE order_date >= '2025-01-01' AND order_date < '2025-02-01'), the optimizer uses micro‑partition metadata to decide which partitions cannot contain matching rows.​

Partitions whose min/max ranges are completely outside the predicate are skipped (not read from storage), which reduces I/O and speeds up queries.​

Pruning works best when:

The filtered column values are well‑grouped inside partitions (good clustering).

Predicates are sargable: they use the column directly, not wrapped in functions (order_date >= '2025‑01‑01' is better than DATE(order_date) = '2025‑01‑01').​

## Natural clustering vs. clustering keys

### Natural clustering

If you load data in a consistent order (e.g., daily batch by order_date), micro‑partitions naturally end up ordered by that column.​

Many workloads never define cluster keys at all and rely solely on this natural clustering plus pruning.​

Example:
Daily sales loaded by day → partitions for January, then February, etc.
Queries filtered by order_date automatically prune away large date ranges.

### When natural clustering degrades

Clustering can degrade when:
Inserts occur out of order (late‑arriving data, random timestamps).
Frequent MERGE/UPDATE operations move values but leave them in old partitions.
Main filter column is a random key (UUID) or semi‑structured field.​

Symptoms:
Queries use selective filters but still scan many micro‑partitions (visible in Query Profile).​
SYSTEM$CLUSTERING_INFORMATION shows high clustering depth (poor clustering).​

### Cluster keys – tells Snowflake how to organize data

A cluster key is an expression (usually one or more columns) that Snowflake uses as the ordering target for micro‑partitions in a table.​

Defined with CLUSTER BY on a table:

```
ALTER TABLE FACT_SALES
  CLUSTER BY (ORDER_DATE, REGION_ID);
```

Snowflake tracks how well the table’s partitions follow that order (clustering depth) and can recluster over time.​

Goals:
Concentrate similar cluster‑key values into the same or adjacent micro‑partitions.
Maximize partition pruning for filters on those key columns, reducing bytes scanned.

### Choosing good cluster keys

Guidelines for large tables (hundreds of GB/TB):​

Pick columns that:
Appear frequently in WHERE clauses and join conditions.
Are reasonably selective (filter down a lot of data).
Have enough cardinality but not extreme randomness (dates, IDs, regions).

Common patterns:
Time‑series fact table: CLUSTER BY (ORDER_DATE) or (ORDER_DATE, CUSTOMER_ID).
Geo + time queries: CLUSTER BY (REGION_ID, EVENT_DATE).
Semi‑structured: CLUSTER BY (payload:customer_id::NUMBER) if most queries filter by that JSON field.

Avoid:
Clustering on columns rarely used in queries.
Too many columns in the cluster key; this increases clustering cost without proportional pruning benefit.​

## Reclustering

Maintaining that order over time
Even with a cluster key, new data and DML will gradually make partitions less ordered.

Reclustering = physically reorganizing micro‑partitions to restore good order along the cluster key:​

Snowflake selects badly clustered partitions.

Reads them, sorts rows by the cluster key, and writes new, better‑clustered partitions.

Replaces old partitions and updates metadata.

Result: rows with similar cluster‑key values are again stored together, improving pruning for future queries.

### Automatic clustering service

Snowflake’s automatic clustering service manages reclustering for you on clustered tables:​
Monitors how clustered the table is (clustering depth) as new data arrives.

Schedules reclustering tasks in the background when the table drifts beyond internal thresholds.

Runs on Snowflake‑managed compute, not your warehouses, so you don’t have to run separate jobs or pick a warehouse.

Works incrementally and doesn’t block user queries or DML on the table.​

You can see auto‑clustering status in table metadata and can suspend/resume it if needed.​

## Cost and when to use clustering

Clustering and reclustering consume compute resources, so use them where they pay off.​

Recommended:

Very large tables (fact tables) with stable schema.

Clear query patterns filtering on a small set of columns (dates, keys, regions).

Queries with those filters are frequent and performance‑critical.

### Usually not worth it

Small / medium tables where scans are cheap anyway.

Highly volatile tables with lots of random inserts/updates where reclustering would run constantly.

Tables where filters are unpredictable and spread across many columns.​

### Practical tuning steps

For a candidate large table:

Review queries (via QUERY_HISTORY) to find the most common filter columns.​

Check how many micro‑partitions are scanned for typical queries (Query Profile).​

Run SYSTEM$CLUSTERING_INFORMATION('<db>.<schema>.<table>') to see clustering depth on the potential key.​

If scans are high and clustering is poor, define a cluster key on those columns.​

Let automatic clustering run, then re‑measure bytes scanned and query time.

Keep clustering only if performance benefits justify the extra compute; otherwise drop the cluster key.
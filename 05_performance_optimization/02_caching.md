# Caching

### Snowflake uses three relevant caches

Result cache -- stores full query results for 24 hours.​

Warehouse (local) cache – keeps recently used micro‑partitions on SSD for a specific warehouse.​

Metadata cache – keeps partition statistics and other metadata for pruning.​

You don’t manage these manually, but you can write queries and design warehouses to benefit from them.

## Result cache (0 compute for repeat queries)

After a query finishes, its result is stored for 24 hours, tied to:

Same user/role,
Same warehouse,
Same query text,

And no underlying data changes that would invalidate it.​

If you run the exact same query again, Snowflake can return results directly from the cache with no warehouse compute.​

#### How to maximize

Avoid unnecessary randomness in queries (e.g., don’t SELECT CURRENT_TIMESTAMP() unless needed).​

Don’t add meaningless columns or change query text constantly in BI tools; stable query text → better cache hits.​

## Warehouse cache (data blocks on SSD)

Each warehouse keeps recently scanned micro‑partitions in its local cache.​

If another query on the same warehouse needs those partitions soon after, it can read from cache instead of cloud storage (S3/Blob/GCS), which is much faster.​

### How to benefit

Run related workloads on the same warehouse rather than bouncing between multiple warehouses for the same data.​

Avoid constantly suspending/resuming during an active analysis session; suspending drops the local cache.​

#### Metadata cache and pruning

Snowflake keeps metadata for micro‑partitions: row counts, min/max values per column, etc.​
During planning, it uses this to prune partitions that cannot satisfy a filter (WHERE order_date >= ...).​

Your role:
Write filters in a way that uses the column directly (order_date >= '2025-01-01') instead of wrapping it in functions (DATE(order_date) = ...), which can block pruning.​

Choose good clustering/ingest patterns so partitions are naturally ordered by commonly filtered columns (date, region).​

### Practical checklist for “using caching”

For repeated analytics/dashboards:
Keep query text stable (so the result cache can kick in).​
Reuse the same BI warehouse for the same dashboards to leverage both result and local caches.​

For exploratory work:
Avoid restarting warehouses every few minutes; keep one XS/Small warehouse running so local cache stays warm.​

For query writing:
Filter on base columns with sargable predicates so metadata cache + pruning minimize I/O.​
